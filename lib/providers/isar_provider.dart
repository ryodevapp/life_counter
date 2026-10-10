import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../repositories/daily_record_repository.dart';
import '../repositories/important_person_repository.dart';
import '../repositories/meeting_log_repository.dart';
import '../models/meeting_log.dart';

/// Isarインスタンス（main.dartでオーバーライド）
final isarProvider = Provider<Isar>((ref) {
  throw UnimplementedError('Override in main.dart');
});

final dailyRecordRepositoryProvider = Provider<DailyRecordRepository>((ref) {
  return DailyRecordRepository(ref.watch(isarProvider));
});

final importantPersonRepositoryProvider =
    Provider<ImportantPersonRepository>((ref) {
  return ImportantPersonRepository(ref.watch(isarProvider));
});

final meetingLogRepositoryProvider = Provider<MeetingLogRepository>((ref) {
  return MeetingLogRepository(ref.watch(isarProvider));
});

/// 会えた日の記録（新しい順）
final meetingLogsProvider = StreamProvider<List<MeetingLog>>((ref) {
  return ref.watch(meetingLogRepositoryProvider).watchAll();
});
