import '../../domain/entities/file_change.dart';

class FileChangeModel extends FileChange {
  const FileChangeModel({
    required super.filename,
    required super.status,
    required super.additions,
    required super.deletions,
    required super.changes,
    super.patch,
    super.rawUrl,
  });

  factory FileChangeModel.fromJson(Map<String, dynamic> json) {
    return FileChangeModel(
      filename: (json['filename'] as String?) ?? 'file',
      status: (json['status'] as String?) ?? 'modified',
      additions: (json['additions'] as int?) ?? 0,
      deletions: (json['deletions'] as int?) ?? 0,
      changes: (json['changes'] as int?) ?? 0,
      patch: json['patch'] as String?,
      rawUrl: json['raw_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'filename': filename,
      'status': status,
      'additions': additions,
      'deletions': deletions,
      'changes': changes,
      'patch': patch,
      'raw_url': rawUrl,
    };
  }
}
