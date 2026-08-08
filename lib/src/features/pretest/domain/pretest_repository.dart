import 'dart:typed_data';

import 'pretest_models.dart';

class PretestException implements Exception {
  const PretestException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract class PretestRepository {
  Future<PretestQuestion> fetchCurrentQuestion();

  Future<PretestAnswerResult> submitAnswer(PretestAnswer answer);

  Future<String> uploadEvidenceImage({
    required Uint8List bytes,
    required String filename,
    required String mimeType,
  });

  Future<KnowledgeState> selectPath(String pathOption);
}
