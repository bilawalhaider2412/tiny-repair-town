import 'package:test/test.dart';
import 'package:tiny_repair_town/puzzles/build_order.dart';

BuildOrderEngine wagonEngine() {
  return BuildOrderEngine(steps: [
    BuildStep(id: 'step_base', partId: 'part_base', labelEn: 'Base', labelUr: 'بنیاد', prerequisites: []),
    BuildStep(id: 'step_body', partId: 'part_body', labelEn: 'Body', labelUr: 'ڈھانچہ', prerequisites: ['step_base']),
    BuildStep(id: 'step_handle', partId: 'part_handle', labelEn: 'Handle', labelUr: 'ہینڈل', prerequisites: ['step_body']),
  ]);
}

void main() {
  group('BuildOrderEngine (System B)', () {
    test('steps complete in dependency order', () {
      final e = wagonEngine();
      expect(e.availableSteps.map((s) => s.id), ['step_base']);
      var r = e.selectPart('part_base');
      expect(r.accepted, isTrue);
      expect(r.outcome, 'accepted');
      expect(r.completedStepId, 'step_base');
      expect(e.availableSteps.map((s) => s.id), ['step_body']);
      r = e.selectPart('part_body');
      expect(r.accepted, isTrue);
      r = e.selectPart('part_handle');
      expect(r.accepted, isTrue);
      expect(e.isComplete, isTrue);
    });

    test('wrong sequence gives hint cue, never resets progress', () {
      final e = wagonEngine();
      e.selectPart('part_base');
      final r = e.selectPart('part_handle'); // skipped step_body
      expect(r.accepted, isFalse);
      expect(r.outcome, 'wrong_step');
      // completed step survives the mistake
      expect(e.completedStepIds, contains('step_base'));
      expect(e.availableSteps.map((s) => s.id), ['step_body']);
      // now do it right
      final r2 = e.selectPart('part_body');
      expect(r2.accepted, isTrue);
    });

    test('re-selecting a completed step is already_done, not an error reset', () {
      final e = wagonEngine();
      e.selectPart('part_base');
      final r = e.selectPart('part_base');
      expect(r.accepted, isFalse);
      expect(r.outcome, 'already_done');
      expect(e.completedStepIds.length, 1);
    });

    test('unknown part id handled gently', () {
      final e = wagonEngine();
      final r = e.selectPart('part_nope');
      expect(r.accepted, isFalse);
      expect(r.outcome, 'unknown_part');
      expect(e.completedStepIds, isEmpty);
    });

    test('multiple valid next steps when authored with fulfilled prerequisites', () {
      final e = BuildOrderEngine(steps: [
        BuildStep(id: 's1', partId: 'p1', labelEn: 'A', labelUr: 'ا', prerequisites: []),
        BuildStep(id: 's2', partId: 'p2', labelEn: 'B', labelUr: 'ب', prerequisites: []),
        BuildStep(id: 's3', partId: 'p3', labelEn: 'C', labelUr: 'ت', prerequisites: ['s1', 's2']),
      ]);
      expect(e.availableSteps.map((s) => s.id), containsAll(['s1', 's2']));
      e.selectPart('p2');
      e.selectPart('p1');
      expect(e.availableSteps.map((s) => s.id), ['s3']);
      expect(e.selectPart('p3').accepted, isTrue);
      expect(e.isComplete, isTrue);
    });

    test('authored diamond prerequisites (L15 style)', () {
      final e = BuildOrderEngine(steps: [
        BuildStep(id: 'a', partId: 'pa', labelEn: 'A', labelUr: 'ا', prerequisites: []),
        BuildStep(id: 'b', partId: 'pb', labelEn: 'B', labelUr: 'ب', prerequisites: []),
        BuildStep(id: 'c', partId: 'pc', labelEn: 'C', labelUr: 'ت', prerequisites: ['a']),
        BuildStep(id: 'd', partId: 'pd', labelEn: 'D', labelUr: 'ٹ', prerequisites: ['a', 'c']),
      ]);
      expect(e.selectPart('pd').accepted, isFalse); // needs a and c
      expect(e.selectPart('pa').accepted, isTrue);
      expect(e.selectPart('pd').accepted, isFalse); // still needs c
      expect(e.selectPart('pc').accepted, isTrue);
      expect(e.selectPart('pd').accepted, isTrue);
      expect(e.selectPart('pb').accepted, isTrue);
      expect(e.isComplete, isTrue);
    });

    test('completed steps stay visible via completedStepIds', () {
      final e = wagonEngine();
      e.selectPart('part_base');
      e.selectPart('part_body');
      expect(e.completedStepIds, containsAll(['step_base', 'step_body']));
      expect(e.isComplete, isFalse);
    });

    test('reset clears for replay', () {
      final e = wagonEngine();
      e.selectPart('part_base');
      e.reset();
      expect(e.completedStepIds, isEmpty);
      expect(e.availableSteps.map((s) => s.id), ['step_base']);
    });
  });
}
