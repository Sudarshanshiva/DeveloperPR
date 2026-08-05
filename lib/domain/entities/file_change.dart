import 'package:equatable/equatable.dart';

class FileChange extends Equatable {
  final String filename;
  final String status; // 'added', 'modified', 'removed', 'renamed'
  final int additions;
  final int deletions;
  final int changes;
  final String? patch;
  final String? rawUrl;

  const FileChange({
    required this.filename,
    required this.status,
    required this.additions,
    required this.deletions,
    required this.changes,
    this.patch,
    this.rawUrl,
  });

  @override
  List<Object?> get props => [
        filename,
        status,
        additions,
        deletions,
        changes,
        patch,
        rawUrl,
      ];
}
