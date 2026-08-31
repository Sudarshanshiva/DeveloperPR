import 'package:equatable/equatable.dart';

class UserQuota extends Equatable {
  final int usedToday;
  final int maxDailyFree;
  final bool isProMember;
  final bool hasCustomKey;

  const UserQuota({
    required this.usedToday,
    this.maxDailyFree = 3,
    required this.isProMember,
    required this.hasCustomKey,
  });

  bool get isUnlimited => isProMember || hasCustomKey;
  int get remainingFree => isUnlimited ? 999 : (maxDailyFree - usedToday).clamp(0, maxDailyFree);
  bool get canAnalyze => isUnlimited || usedToday < maxDailyFree;

  @override
  List<Object?> get props => [usedToday, maxDailyFree, isProMember, hasCustomKey];
}
