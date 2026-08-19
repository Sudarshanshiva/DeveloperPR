import 'dart:convert';
import 'package:dio/dio.dart';
import '../../core/error/exceptions.dart';
import '../../domain/entities/file_change.dart';
import '../models/pr_analysis_model.dart';

abstract class AiRemoteDataSource {
  Future<PRAnalysisResultModel> analyzePullRequest({
    required String apiKey,
    required String provider, // 'gemini' | 'groq' | 'claude' | 'openai'
    required String prTitle,
    String? prDescription,
    required List<FileChange> files,
  });
}

class AiRemoteDataSourceImpl implements AiRemoteDataSource {
  final Dio dio;

  AiRemoteDataSourceImpl({required this.dio});

  static const int _maxDiffCharBudget = 14000;

  @override
  Future<PRAnalysisResultModel> analyzePullRequest({
    required String apiKey,
    required String provider,
    required String prTitle,
    String? prDescription,
    required List<FileChange> files,
  }) async {
    final (promptContent, isTruncated, analyzedCount) = _buildPrompt(
      prTitle: prTitle,
      prDescription: prDescription,
      files: files,
    );

    switch (provider.toLowerCase()) {
      case 'gemini':
        return _callGeminiApi(
            apiKey: apiKey, prompt: promptContent, isTruncated: isTruncated, analyzedCount: analyzedCount);
      case 'groq':
        return _callGroqApi(
            apiKey: apiKey, prompt: promptContent, isTruncated: isTruncated, analyzedCount: analyzedCount);
      case 'openai':
        return _callOpenAiApi(
            apiKey: apiKey, prompt: promptContent, isTruncated: isTruncated, analyzedCount: analyzedCount);
      case 'claude':
      default:
        return _callClaudeApi(
            apiKey: apiKey, prompt: promptContent, isTruncated: isTruncated, analyzedCount: analyzedCount);
    }
  }

  (String prompt, bool isTruncated, int analyzedCount) _buildPrompt({
    required String prTitle,
    String? prDescription,
    required List<FileChange> files,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('Analyze this pull request code diff and return JSON.');
    buffer.writeln('PR Title: $prTitle');
    if (prDescription != null && prDescription.isNotEmpty) {
      buffer.writeln('PR Description: $prDescription');
    }
    buffer.writeln('\nChanged Files Overview:');

    for (final f in files) {
      buffer.writeln('- ${f.filename} (${f.status}, +${f.additions}/-${f.deletions})');
    }

    buffer.writeln('\nCODE DIFFS:');

    int currentCharCount = buffer.length;
    bool isTruncated = false;
    int analyzedCount = 0;

    // Sort files to prioritize non-generated / non-lock files
    final sortedFiles = List<FileChange>.from(files)
      ..sort((a, b) {
        final aLock = a.filename.contains('lock') || a.filename.contains('generated');
        final bLock = b.filename.contains('lock') || b.filename.contains('generated');
        if (aLock && !bLock) return 1;
        if (!aLock && bLock) return -1;
        return (b.additions + b.deletions).compareTo(a.additions + a.deletions);
      });

    for (final f in sortedFiles) {
      if (f.patch == null || f.patch!.trim().isEmpty) continue;

      final fileHeader = '\n--- File: ${f.filename} (${f.status}) ---\n';
      final patchText = f.patch!;

      if (currentCharCount + fileHeader.length + patchText.length > _maxDiffCharBudget) {
        final availableSpace = _maxDiffCharBudget - currentCharCount - fileHeader.length;
        if (availableSpace > 300) {
          buffer.write(fileHeader);
          buffer.write(patchText.substring(0, availableSpace));
          buffer.writeln('\n[...patch truncated due to size...]');
          analyzedCount++;
        }
        isTruncated = true;
        break;
      } else {
        buffer.write(fileHeader);
        buffer.write(patchText);
        currentCharCount += fileHeader.length + patchText.length;
        analyzedCount++;
      }
    }

    if (analyzedCount == 0 && sortedFiles.isNotEmpty) {
      analyzedCount = sortedFiles.length;
    }

    buffer.writeln('\n\nINSTRUCTIONS:');
    buffer.writeln('Return ONLY a valid JSON object (no markdown, no preamble) matching this schema:');
    buffer.writeln('''
{
  "summary": "One-paragraph plain-English summary of what changed and its core purpose.",
  "riskLevel": "low" | "medium" | "high",
  "potentialIssues": [
    {
      "file": "path/to/file.dart",
      "line": 42,
      "issue": "Explanation of potential bug, race condition, or memory leak",
      "severity": "high" | "medium" | "low"
    }
  ],
  "suggestions": [
    "Clear actionable code improvement or refactoring suggestion"
  ],
  "testCoverage": "Comment on whether unit/widget tests were added or modified, and if test coverage is adequate."
}
''');

    return (buffer.toString(), isTruncated, analyzedCount);
  }

  // ─── Gemini (FREE - Recommended) ───────────────────────────────────────────
  Future<PRAnalysisResultModel> _callGeminiApi({
    required String apiKey,
    required String prompt,
    required bool isTruncated,
    required int analyzedCount,
  }) async {
    try {
      final response = await dio.post(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
        options: Options(headers: {'content-type': 'application/json'}),
        data: {
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'response_mime_type': 'application/json',
            'temperature': 0.2,
            'maxOutputTokens': 1500,
          },
        },
      );

      if (response.statusCode == 200) {
        final candidates = response.data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final parts = candidates.first['content']?['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            final rawText = parts.first['text']?.toString() ?? '';
            final jsonMap = _parseJsonResponse(rawText);
            return PRAnalysisResultModel.fromJson(
              jsonMap,
              isTruncated: isTruncated,
              analyzedFileCount: analyzedCount,
            );
          }
        }
      }
      throw ServerException('Invalid response from Gemini API', statusCode: response.statusCode);
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final msg = e.response?.data?['error']?['message']?.toString() ?? '';
        if (msg.toLowerCase().contains('api key')) {
          throw AuthException('Invalid Gemini API Key. Get a free key at aistudio.google.com');
        }
      }
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        throw AuthException('Invalid Gemini API Key. Get a free key at aistudio.google.com');
      }
      if (e.response?.statusCode == 429) {
        final retryAfter = int.tryParse(e.response?.headers.value('retry-after') ?? '') ?? 0;
        throw RateLimitException(
          'Gemini rate limit reached. Free tier allows 15 requests/min — please wait a moment.',
          resetTimestamp: retryAfter,
        );
      }
      throw ServerException(
        e.response?.data?['error']?['message']?.toString() ?? e.message ?? 'Failed to connect to Gemini API',
        statusCode: e.response?.statusCode,
      );
    }
  }

  // ─── Groq (FREE - Ultra Fast) ───────────────────────────────────────────────
  Future<PRAnalysisResultModel> _callGroqApi({
    required String apiKey,
    required String prompt,
    required bool isTruncated,
    required int analyzedCount,
  }) async {
    try {
      final response = await dio.post(
        'https://api.groq.com/openai/v1/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'content-type': 'application/json',
          },
        ),
        data: {
          'model': 'llama-3.1-8b-instant',
          'response_format': {'type': 'json_object'},
          'messages': [
            {'role': 'system', 'content': 'You are a senior code reviewer. Analyze the diff and return JSON only.'},
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': 1500,
          'temperature': 0.2,
        },
      );

      if (response.statusCode == 200) {
        final choices = response.data['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          final rawText = choices.first['message']['content']?.toString() ?? '';
          final jsonMap = _parseJsonResponse(rawText);
          return PRAnalysisResultModel.fromJson(
            jsonMap,
            isTruncated: isTruncated,
            analyzedFileCount: analyzedCount,
          );
        }
      }
      throw ServerException('Invalid response from Groq API', statusCode: response.statusCode);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw AuthException('Invalid Groq API Key. Get a free key at console.groq.com');
      }
      if (e.response?.statusCode == 429) {
        final retryAfter = int.tryParse(e.response?.headers.value('retry-after') ?? '') ?? 0;
        throw RateLimitException(
          'Groq rate limit reached. Free tier allows 30 req/min — please wait a moment.',
          resetTimestamp: retryAfter,
        );
      }
      throw ServerException(
        e.response?.data?['error']?['message']?.toString() ?? e.message ?? 'Failed to connect to Groq API',
        statusCode: e.response?.statusCode,
      );
    }
  }

  // ─── Claude (Paid) ──────────────────────────────────────────────────────────
  Future<PRAnalysisResultModel> _callClaudeApi({
    required String apiKey,
    required String prompt,
    required bool isTruncated,
    required int analyzedCount,
  }) async {
    try {
      final response = await dio.post(
        'https://api.anthropic.com/v1/messages',
        options: Options(
          headers: {
            'x-api-key': apiKey,
            'anthropic-version': '2023-06-01',
            'content-type': 'application/json',
          },
        ),
        data: {
          'model': 'claude-3-5-sonnet-20241022',
          'max_tokens': 1500,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
        },
      );

      if (response.statusCode == 200) {
        final contentList = response.data['content'] as List?;
        if (contentList != null && contentList.isNotEmpty) {
          final rawText = contentList.first['text']?.toString() ?? '';
          final jsonMap = _parseJsonResponse(rawText);
          return PRAnalysisResultModel.fromJson(
            jsonMap,
            isTruncated: isTruncated,
            analyzedFileCount: analyzedCount,
          );
        }
      }
      throw ServerException('Invalid response from Claude API', statusCode: response.statusCode);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw AuthException('Invalid Claude API Key. Please check your key in settings.');
      }
      if (e.response?.statusCode == 429) {
        final retryAfter = int.tryParse(e.response?.headers.value('retry-after') ?? '') ?? 0;
        throw RateLimitException(
          'Claude API rate limit reached. Please wait a moment and try again.',
          resetTimestamp: retryAfter,
        );
      }
      throw ServerException(
        e.response?.data?['error']?['message']?.toString() ?? e.message ?? 'Failed to connect to Claude API',
        statusCode: e.response?.statusCode,
      );
    }
  }

  // ─── OpenAI (Paid) ──────────────────────────────────────────────────────────
  Future<PRAnalysisResultModel> _callOpenAiApi({
    required String apiKey,
    required String prompt,
    required bool isTruncated,
    required int analyzedCount,
  }) async {
    try {
      final response = await dio.post(
        'https://api.openai.com/v1/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'content-type': 'application/json',
          },
        ),
        data: {
          'model': 'gpt-3.5-turbo',
          'response_format': {'type': 'json_object'},
          'messages': [
            {'role': 'system', 'content': 'You are a senior code reviewer. Analyze the diff and return JSON.'},
            {'role': 'user', 'content': prompt}
          ],
        },
      );

      if (response.statusCode == 200) {
        final choices = response.data['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          final rawText = choices.first['message']['content']?.toString() ?? '';
          final jsonMap = _parseJsonResponse(rawText);
          return PRAnalysisResultModel.fromJson(
            jsonMap,
            isTruncated: isTruncated,
            analyzedFileCount: analyzedCount,
          );
        }
      }
      throw ServerException('Invalid response from OpenAI API', statusCode: response.statusCode);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw AuthException('Invalid OpenAI API Key. Please check your key in settings.');
      }
      if (e.response?.statusCode == 429) {
        final retryAfter = int.tryParse(e.response?.headers.value('retry-after') ?? '') ?? 0;
        throw RateLimitException(
          'OpenAI API rate limit reached. Please wait a moment and try again.',
          resetTimestamp: retryAfter,
        );
      }
      throw ServerException(
        e.response?.data?['error']?['message']?.toString() ?? e.message ?? 'Failed to connect to OpenAI API',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Map<String, dynamic> _parseJsonResponse(String rawText) {
    String cleanText = rawText.trim();
    if (cleanText.startsWith('```json')) {
      cleanText = cleanText.substring(7);
    } else if (cleanText.startsWith('```')) {
      cleanText = cleanText.substring(3);
    }
    if (cleanText.endsWith('```')) {
      cleanText = cleanText.substring(0, cleanText.length - 3);
    }
    cleanText = cleanText.trim();

    try {
      final decoded = json.decode(cleanText);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {};
    } catch (_) {
      throw ServerException('Failed to parse AI response into JSON format.');
    }
  }
}
