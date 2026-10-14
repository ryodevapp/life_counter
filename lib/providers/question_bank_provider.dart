import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/question_bank.dart';

/// 365問(main.dart で読み込んでオーバーライド)
final questionBankProvider = Provider<QuestionBank>((ref) {
  throw UnimplementedError('Override in main.dart');
});
