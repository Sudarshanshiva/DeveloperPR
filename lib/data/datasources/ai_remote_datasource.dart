import 'dart:convert';
import 'package:dio/dio.dart';
import '../../core/error/exceptions.dart';
import '../../domain/entities/file_change.dart';
import '../models/pr_analysis_model.dart';

abstract class AiRemoteDataSource {
  Future<PRAnalysisResultModel> analyzePullRequest({
    required String apiKey,
    required String provider,
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

    return _callGeminiApi(
      apiKey: apiKey,
      prompt: promptContent,
      isTruncated: isTruncated,
      analyzedCount: analyzedCount,
    );
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

  // ─── Google Gemini (100% FREE - Primary AI Engine) ─────────────────────────

  /// Fetches the list of models available for this API key and returns
  /// the first one that supports generateContent, preferring flash variants.
  Future<String> _discoverGeminiModel(String apiKey) async {
    final listUrl =
        'https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey';
    try {
      final res = await dio.get(listUrl,
          options: Options(headers: {'content-type': 'application/json'}));
      if (res.statusCode == 200) {
        final models = (res.data['models'] as List?) ?? [];
        // Build preferred order — flash is fast & free, then pro
        final preferred = [
          'gemini-2.0-flash',
          'gemini-2.0-flash-lite',
          'gemini-1.5-flash',
          'gemini-1.5-flash-latest',
          'gemini-1.5-flash-8b',
          'gemini-1.5-pro',
          'gemini-1.5-pro-latest',
        ];
        final available = models
            .where((m) {
              final methods =
                  (m['supportedGenerationMethods'] as List?)?.cast<String>() ?? [];
              return methods.contains('generateContent');
            })
            .map((m) => (m['name'] as String).replaceFirst('models/', ''))
            .toList();

        for (final pref in preferred) {
          if (available.any((a) => a == pref || a.startsWith(pref))) {
            return available.firstWhere((a) => a == pref || a.startsWith(pref));
          }
        }
        // Fallback: any available generateContent model
        if (available.isNotEmpty) return available.first;
      }
    } catch (_) {
      // ignore — fall through to default
    }
    return 'gemini-2.0-flash'; // best-effort default
  }

  Future<PRAnalysisResultModel> _callGeminiApi({
    required String apiKey,
    required String prompt,
    required bool isTruncated,
    required int analyzedCount,
  }) async {
    // Discover which model this API key actually supports
    final model = await _discoverGeminiModel(apiKey);
    final url =
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey';

    try {
      final response = await dio.post(
        url,
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
      throw ServerException('Invalid response from Gemini API',
          statusCode: response.statusCode);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode ?? 0;
      final msg =
          e.response?.data?['error']?['message']?.toString() ?? e.message ?? '';

      if (statusCode == 401 || statusCode == 403 ||
          (statusCode == 400 &&
              (msg.toLowerCase().contains('api key') ||
                  msg.toLowerCase().contains('invalid')))) {
        throw AuthException(
            'Invalid Gemini API Key. Get a free key at aistudio.google.com');
      }
      if (statusCode == 429) {
        final retryAfter =
            int.tryParse(e.response?.headers.value('retry-after') ?? '') ?? 0;
        throw RateLimitException(
          'Gemini rate limit reached. Free tier: 15 req/min — wait a moment.',
          resetTimestamp: retryAfter,
        );
      }
      throw ServerException(msg.isNotEmpty ? msg : 'Failed to connect to Gemini API',
          statusCode: statusCode);
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
