/// System B — "Build in order" puzzle engine (pure Dart, no Flutter).
///
/// The child taps parts in the right assembly order. Steps form a DAG:
/// a step is available once all its prerequisites are completed.
library;

/// One assembly step.
class BuildStep {
  /// Step id, e.g. "step_base".
  final String id;

  /// Part id the child selects to complete this step.
  final String partId;

  /// English label shown on the part.
  final String labelEn;

  /// Urdu label shown on the part.
  final String labelUr;

  /// Ids of steps that must be completed before this step is available.
  final List<String> prerequisites;

  const BuildStep({
    required this.id,
    required this.partId,
    required this.labelEn,
    required this.labelUr,
    required this.prerequisites,
  });
}

/// Outcome of selecting a part.
class StepResult {
  /// True when the selection completed a step.
  final bool accepted;

  /// 'accepted' | 'already_done' | 'wrong_step' | 'unknown_part'.
  final String outcome;

  /// Id of the step that was completed (only when accepted).
  final String? completedStepId;

  /// Step ids available after this selection.
  final List<String> nowAvailable;

  const StepResult({
    required this.accepted,
    required this.outcome,
    this.completedStepId,
    required this.nowAvailable,
  });
}

/// Engine for the "Build in order" puzzle system.
///
/// Wrong selections only produce a gentle hint — completed steps are never
/// reset.
class BuildOrderEngine {
  /// All steps in authoring order.
  final List<BuildStep> steps;

  /// Ids of steps the child has completed.
  final Set<String> completedStepIds = {};

  BuildOrderEngine({required this.steps});

  /// Builds an engine from a level `config` map (see CONTENT_SCHEMA.md).
  factory BuildOrderEngine.fromConfig(Map<String, dynamic> config) {
    final steps = <BuildStep>[];
    for (final s in (config['steps'] as List? ?? [])) {
      final m = (s as Map).cast<String, dynamic>();
      final label = (m['label'] as Map?)?.cast<String, dynamic>() ?? {};
      steps.add(BuildStep(
        id: (m['id'] ?? '').toString(),
        partId: (m['partId'] ?? '').toString(),
        labelEn: (label['en'] ?? '').toString(),
        labelUr: (label['ur'] ?? '').toString(),
        prerequisites: ((m['prerequisites'] as List?) ?? const [])
            .map((p) => p.toString())
            .toList(),
      ));
    }
    return BuildOrderEngine(steps: steps);
  }

  /// Steps whose prerequisites are all completed and which are not done yet.
  List<BuildStep> get availableSteps => steps
      .where((s) =>
          !completedStepIds.contains(s.id) &&
          s.prerequisites.every(completedStepIds.contains))
      .toList();

  /// Selects a part. Accepted iff it completes an available step.
  StepResult selectPart(String partId) {
    BuildStep? step;
    for (final s in steps) {
      if (s.partId == partId) {
        step = s;
        break;
      }
    }
    final available = availableSteps.map((s) => s.id).toList();
    if (step == null) {
      return StepResult(
          accepted: false, outcome: 'unknown_part', nowAvailable: available);
    }
    if (completedStepIds.contains(step.id)) {
      return StepResult(
          accepted: false, outcome: 'already_done', nowAvailable: available);
    }
    if (!available.contains(step.id)) {
      return StepResult(
          accepted: false, outcome: 'wrong_step', nowAvailable: available);
    }
    completedStepIds.add(step.id);
    final now = availableSteps.map((s) => s.id).toList();
    return StepResult(
      accepted: true,
      outcome: 'accepted',
      completedStepId: step.id,
      nowAvailable: now,
    );
  }

  /// True when every step is completed.
  bool get isComplete => steps.every((s) => completedStepIds.contains(s.id));

  /// Clears completed steps (replay support).
  void reset() {
    completedStepIds.clear();
  }
}
