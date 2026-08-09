import '../../../core/localization/app_language.dart';
import '../domain/edge_model_router.dart';

class DeterministicLocalRuntime {
  const DeterministicLocalRuntime();

  String generate({required EdgeTaskType task, required String prompt}) {
    final normalizedPrompt = prompt.toLowerCase();

    return switch (task) {
      EdgeTaskType.intentParse => _intentParse(normalizedPrompt),
      EdgeTaskType.tutorHint => _hint(normalizedPrompt),
      EdgeTaskType.tutorEvaluate => _evaluate(normalizedPrompt),
      EdgeTaskType.pretestReasoningGrade => _reasoningGrade(normalizedPrompt),
      EdgeTaskType.quizGenerate => _quizPrompt(normalizedPrompt),
      EdgeTaskType.summaryGenerate => _summary(normalizedPrompt),
      EdgeTaskType.tutorExplain => _explainFallback(normalizedPrompt),
    };
  }

  String _intentParse(String prompt) {
    if (prompt.contains('?')) {
      return 'intent=ask_question';
    }
    if (prompt.contains('bantu') || prompt.contains('tolong')) {
      return 'intent=request_help';
    }
    return 'intent=general_reflection';
  }

  String _hint(String prompt) {
    if (prompt.contains('turunan') || prompt.contains('derivative')) {
      return AppLanguage.copy.tutorHintDerivativeLabel;
    }
    return AppLanguage.copy.tutorHintGenericLabel;
  }

  String _evaluate(String prompt) {
    if (prompt.contains('2x') || prompt.contains('benar')) {
      return AppLanguage.copy.tutorEvaluateCloseLabel;
    }
    return AppLanguage.copy.tutorEvaluateInconsistentLabel;
  }

  String _reasoningGrade(String prompt) {
    if (prompt.length < 30) {
      return AppLanguage.copy.reasoningTooShortLabel;
    }
    return AppLanguage.copy.reasoningClearLabel;
  }

  String _quizPrompt(String prompt) {
    return AppLanguage.copy.quizPromptLabel;
  }

  String _summary(String prompt) {
    return AppLanguage.copy.summaryFallbackLabel;
  }

  String _explainFallback(String prompt) {
    if (prompt.contains('turunan') || prompt.contains('derivative')) {
      return AppLanguage.copy.explainDerivativeLabel;
    }
    return AppLanguage.copy.explainGenericLabel;
  }
}
