/// Level model and content validation for Tiny Repair Town.
///
/// Contract: `docs/CONTENT_SCHEMA.md`. Levels are loaded from
/// `assets/levels/level_L*.json`; this file must stay free of Flutter imports.
library;

/// A single graded hint: strength 1 (nudge) .. 3 (demonstration).
class LevelHint {
  /// Hint strength, must be 1, 2 or 3.
  final int strength;

  /// English hint text.
  final String en;

  /// Urdu hint text.
  final String ur;

  const LevelHint({
    required this.strength,
    required this.en,
    required this.ur,
  });

  factory LevelHint.fromJson(Map<String, dynamic> json) => LevelHint(
        strength: (json['strength'] as num?)?.toInt() ?? 0,
        en: (json['en'] ?? '').toString(),
        ur: (json['ur'] ?? '').toString(),
      );
}

/// One playable level of Tiny Repair Town.
class Level {
  /// Unique id, e.g. "L01".."L20".
  final String id;

  /// Content schema version (currently 1).
  final int schemaVersion;

  /// "free" (L01-L10) or "pack" (L11-L20).
  final String accessTier;

  /// "matchParts" | "buildOrder" | "restorePattern" | "finale".
  final String puzzleType;

  /// One of workshop | toyCorner | bicycleStop | playground | sunnyPark.
  final String locationId;

  /// Level ids that must be completed before this level unlocks.
  final List<String> prerequisites;

  /// Localised level title.
  final Map<String, String> title;

  /// Localised one-sentence request from the character.
  final Map<String, String> request;

  /// Character id: mira | pip | nori.
  final String requester;

  /// Show the skippable demo on first entry.
  final bool tutorial;

  /// Exactly 3 hints with strengths 1, 2, 3.
  final List<LevelHint> hints;

  /// Sticker reward id earned on completion.
  final String rewardId;

  /// Town-map improvement id unlocked on completion.
  final String mapImprovementId;

  /// Puzzle-type specific configuration (see CONTENT_SCHEMA.md).
  final Map<String, dynamic> config;

  /// True for Stage-2 scaffolds (L02-L20) that are not yet playable.
  final bool stub;

  /// Raw level JSON this instance was parsed from; used for full-file
  /// checks (no-remote-URLs rule, asset/narration id references).
  final Map<String, dynamic> _source;

  const Level({
    required this.id,
    required this.schemaVersion,
    required this.accessTier,
    required this.puzzleType,
    required this.locationId,
    required this.prerequisites,
    required this.title,
    required this.request,
    required this.requester,
    required this.tutorial,
    required this.hints,
    required this.rewardId,
    required this.mapImprovementId,
    required this.config,
    required this.stub,
    Map<String, dynamic> source = const {},
  }) : _source = source;

  /// Localised string map helper (keeps only String values).
  static Map<String, String> _strings(dynamic value) {
    final out = <String, String>{};
    if (value is Map) {
      value.forEach((k, v) {
        if (v is String) out[k.toString()] = v;
      });
    }
    return out;
  }

  factory Level.fromJson(Map<String, dynamic> json) {
    final hintsJson = json['hints'];
    return Level(
      id: (json['id'] ?? '').toString(),
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 0,
      accessTier: (json['accessTier'] ?? '').toString(),
      puzzleType: (json['puzzleType'] ?? '').toString(),
      locationId: (json['locationId'] ?? '').toString(),
      prerequisites: (json['prerequisites'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      title: _strings(json['title']),
      request: _strings(json['request']),
      requester: (json['requester'] ?? '').toString(),
      tutorial: json['tutorial'] == true,
      hints: (hintsJson as List? ?? [])
          .whereType<Map>()
          .map((h) => LevelHint.fromJson(h.cast<String, dynamic>()))
          .toList(),
      rewardId: (json['rewardId'] ?? '').toString(),
      mapImprovementId: (json['mapImprovementId'] ?? '').toString(),
      config: (json['config'] as Map? ?? {}).cast<String, dynamic>(),
      stub: json['stub'] == true,
      source: json,
    );
  }

  /// True when this level ships with the free game (L01-L10).
  bool get isFree => accessTier == 'free';

  /// True when this level is actually playable (not a scaffold stub).
  bool get isPlayable => !stub;

  /// Level availability for a player (CONTENT_SCHEMA.md § "Save data").
  ///
  /// L01 is always available. Ln (n > 1) needs L(n−1) complete — the launch
  /// chain rule — plus every id in [level.prerequisites] to be present in
  /// [completedLevels]. Levels with accessTier "pack" additionally require
  /// [entitlementGranted].
  static bool isLevelAvailable({
    required Level level,
    required Set<String> completedLevels,
    required bool entitlementGranted,
  }) {
    if (level.id == 'L01') return true;
    final n = int.tryParse(level.id.substring(1));
    if (n != null && n > 1) {
      final prev = 'L${(n - 1).toString().padLeft(2, '0')}';
      if (!completedLevels.contains(prev)) return false;
    }
    for (final p in level.prerequisites) {
      if (!completedLevels.contains(p)) return false;
    }
    if (level.accessTier == 'pack' && !entitlementGranted) return false;
    return true;
  }

  /// Validates a whole level catalog (exactly L01..L20, cross-references,
  /// no prerequisite cycles). Returns a list of human-readable errors.
  static List<String> validateCatalog(List<Level> levels) {
    final errors = <String>[];
    final byId = <String, Level>{};
    for (final l in levels) {
      if (byId.containsKey(l.id)) {
        errors.add('Duplicate level id "${l.id}".');
      }
      byId[l.id] = l;
    }
    for (var n = 1; n <= 20; n++) {
      final id = 'L${n.toString().padLeft(2, '0')}';
      if (!byId.containsKey(id)) errors.add('Missing level id "$id".');
    }
    for (final l in levels) {
      for (final p in l.prerequisites) {
        if (!byId.containsKey(p)) {
          errors.add('${l.id}: prerequisite "$p" does not exist.');
        }
      }
    }
    // Cycle detection across the catalog (DFS with colours).
    final colour = <String, int>{}; // 0 = unvisited, 1 = in stack, 2 = done
    bool visit(String id, List<String> stack) {
      colour[id] = 1;
      stack.add(id);
      final level = byId[id];
      if (level != null) {
        for (final p in level.prerequisites) {
          if (!byId.containsKey(p)) continue;
          if (colour[p] == 1) {
            errors.add(
                'Prerequisite cycle: ${[...stack, p].join(' -> ')}.');
            return true;
          }
          if (colour[p] != 2 && visit(p, stack)) return true;
        }
      }
      stack.removeLast();
      colour[id] = 2;
      return false;
    }

    for (final id in byId.keys) {
      if (colour[id] != 2) visit(id, []);
    }
    return errors;
  }

  /// Validates this level against every rule in CONTENT_SCHEMA.md that is
  /// checkable from the JSON alone.
  ///
  /// Pass [catalog] (id -> Level) to also check prerequisite existence and
  /// prerequisite cycles; without it those checks are skipped.
  List<String> validate({Map<String, Level>? catalog}) {
    final errors = <String>[];
    final idRe = RegExp(r'^L\d{2}$');
    if (!idRe.hasMatch(id)) {
      errors.add('Invalid id "$id": must match L01..L20.');
    }
    final num = int.tryParse(id.length == 3 ? id.substring(1) : '');
    if (num == null || num < 1 || num > 20) {
      errors.add('Invalid id "$id": must be L01..L20.');
    } else {
      final expectedTier = num <= 10 ? 'free' : 'pack';
      if (accessTier != expectedTier) {
        errors.add(
            'Invalid accessTier "$accessTier" for $id: expected "$expectedTier".');
      }
    }
    if (schemaVersion != 1) {
      errors.add('Invalid schemaVersion $schemaVersion: expected 1.');
    }
    const puzzleTypes = {
      'matchParts',
      'buildOrder',
      'restorePattern',
      'finale'
    };
    if (!puzzleTypes.contains(puzzleType)) {
      errors.add('Unknown puzzleType "$puzzleType".');
    }
    const locations = {
      'workshop',
      'toyCorner',
      'bicycleStop',
      'playground',
      'sunnyPark'
    };
    if (!locations.contains(locationId)) {
      errors.add('Unknown locationId "$locationId".');
    }
    const requesters = {'mira', 'pip', 'nori'};
    if (!requesters.contains(requester)) {
      errors.add('Unknown requester "$requester".');
    }
    for (final entry in {'title': title, 'request': request}.entries) {
      for (final lang in ['en', 'ur']) {
        final v = entry.value[lang];
        if (v == null || v.isEmpty) {
          errors.add('Missing ${entry.key}.$lang text.');
        }
      }
    }
    // Hints: exactly 3, strengths 1, 2, 3, en+ur each.
    if (hints.length != 3) {
      errors.add('hints must have exactly 3 entries, found ${hints.length}.');
    } else {
      final strengths = hints.map((h) => h.strength).toList()..sort();
      if (strengths.join(',') != '1,2,3') {
        errors.add(
            'hints must have strengths 1, 2, 3; found ${strengths.join(',')}.');
      }
    }
    for (var i = 0; i < hints.length; i++) {
      final h = hints[i];
      if (h.en.isEmpty) errors.add('hints[$i] missing en text.');
      if (h.ur.isEmpty) errors.add('hints[$i] missing ur text.');
    }
    // Referenced ids must be non-empty (rule 3).
    if (rewardId.isEmpty) errors.add('rewardId must be non-empty.');
    if (mapImprovementId.isEmpty) {
      errors.add('mapImprovementId must be non-empty.');
    }
    for (final key in ['assets', 'narrationIds']) {
      final section = _source[key];
      if (section is Map) {
        section.forEach((k, v) {
          if (v is! String || v.isEmpty) {
            errors.add('$key["$k"] must be a non-empty id.');
          }
        });
      }
    }
    // No remote URLs anywhere in the level file (rule 8).
    final urls = <String>[];
    _collectUrls(_source, urls);
    for (final u in urls) {
      errors.add('Remote URL not allowed: "$u".');
    }
    // Per-system config checks.
    switch (puzzleType) {
      case 'matchParts':
        errors.addAll(_validateMatchParts(config));
      case 'buildOrder':
        errors.addAll(_validateBuildOrder(config));
      case 'restorePattern':
        errors.addAll(_validateRestorePattern(config));
      case 'finale':
        errors.addAll(_validateFinale(config));
    }
    // Prerequisite checks against the catalog (existence + cycles).
    if (catalog != null) {
      for (final p in prerequisites) {
        if (!catalog.containsKey(p)) {
          errors.add('Prerequisite "$p" does not exist in catalog.');
        }
      }
      // DFS from this level's prerequisites looking for a cycle back.
      final visited = <String>{};
      bool reaches(String from, String target, Set<String> seen) {
        if (from == target) return true;
        if (!seen.add(from)) return false;
        final l = catalog[from];
        if (l == null) return false;
        return l.prerequisites.any((p) => reaches(p, target, seen));
      }

      for (final p in prerequisites) {
        if (reaches(p, id, visited)) {
          errors.add('Prerequisite cycle involving "$id".');
          break;
        }
      }
    }
    return errors;
  }

  /// Recursively collects string values that look like remote URLs.
  static void _collectUrls(dynamic node, List<String> out) {
    if (node is String) {
      final t = node.trim().toLowerCase();
      if (t.startsWith('http://') || t.startsWith('https://')) out.add(node);
    } else if (node is Map) {
      node.values.forEach((v) => _collectUrls(v, out));
    } else if (node is List) {
      node.forEach((v) => _collectUrls(v, out));
    }
  }

  /// matchParts rules: slot<->piece cross-refs and solvability.
  static List<String> _validateMatchParts(Map<String, dynamic> config) {
    final errors = <String>[];
    final slots = (config['slots'] as List? ?? []).whereType<Map>().toList();
    final pieces = (config['pieces'] as List? ?? []).whereType<Map>().toList();
    final pieceIds = pieces.map((p) => p['id'].toString()).toSet();
    if (pieces.where((p) => p['isDistractor'] != true).isEmpty) {
      errors.add('matchParts: at least one non-distractor piece required.');
    }
    final seenAccepts = <String>{};
    for (var i = 0; i < slots.length; i++) {
      final s = slots[i];
      final accepts = s['acceptsPartId']?.toString() ?? '';
      if (!pieceIds.contains(accepts)) {
        errors.add(
            'matchParts: slot "${s['id']}" acceptsPartId "$accepts" has no matching piece.');
        continue;
      }
      final piece = pieces.firstWhere((p) => p['id'].toString() == accepts);
      if (piece['isDistractor'] == true) {
        errors.add(
            'matchParts: slot "${s['id']}" accepts distractor piece "$accepts".');
      }
      if (!seenAccepts.add(accepts)) {
        errors.add(
            'matchParts: piece "$accepts" is accepted by more than one slot '
            '(each slot needs exactly one matching piece).');
      }
      final orientations = (s['allowedOrientations'] as List? ?? [])
          .map((o) => (o as num).toInt())
          .toList();
      if (orientations.isEmpty) {
        errors.add(
            'matchParts: slot "${s['id']}" has no allowedOrientations.');
      }
    }
    return errors;
  }

  /// buildOrder rules: 3-5 steps, acyclic, every step reachable from a root.
  static List<String> _validateBuildOrder(Map<String, dynamic> config) {
    final errors = <String>[];
    final steps = (config['steps'] as List? ?? []).whereType<Map>().toList();
    if (steps.length < 3 || steps.length > 5) {
      errors.add(
          'buildOrder: need 3-5 steps, found ${steps.length}.');
      return errors;
    }
    final byId = <String, Map>{};
    for (final s in steps) {
      byId[s['id'].toString()] = s;
    }
    for (final s in steps) {
      for (final p in (s['prerequisites'] as List? ?? [])) {
        if (!byId.containsKey(p.toString())) {
          errors.add(
              'buildOrder: step "${s['id']}" prerequisite "$p" does not exist.');
        }
      }
    }
    // Acyclic check (Kahn's algorithm) over valid edges.
    final indegree = <String, int>{for (final id in byId.keys) id: 0};
    for (final s in steps) {
      for (final p in (s['prerequisites'] as List? ?? [])) {
        final ps = p.toString();
        if (byId.containsKey(ps)) indegree[s['id'].toString()] =
            indegree[s['id'].toString()]! + 1;
      }
    }
    final queue =
        indegree.entries.where((e) => e.value == 0).map((e) => e.key).toList();
    var visited = 0;
    while (queue.isNotEmpty) {
      final id = queue.removeLast();
      visited++;
      for (final s in steps) {
        final prereqs =
            (s['prerequisites'] as List? ?? []).map((p) => p.toString());
        if (prereqs.contains(id)) {
          final sid = s['id'].toString();
          indegree[sid] = indegree[sid]! - 1;
          if (indegree[sid] == 0) queue.add(sid);
        }
      }
    }
    if (visited != byId.length) {
      errors.add('buildOrder: step graph contains a cycle.');
      return errors;
    }
    // Reachability: every step reachable from a step with no prerequisites.
    final roots = steps
        .where((s) => (s['prerequisites'] as List? ?? []).isEmpty)
        .map((s) => s['id'].toString())
        .toList();
    if (roots.isEmpty) {
      errors.add('buildOrder: no root step (a step with no prerequisites).');
      return errors;
    }
    final reachable = <String>{};
    final stack = [...roots];
    while (stack.isNotEmpty) {
      final id = stack.removeLast();
      if (!reachable.add(id)) continue;
      for (final s in steps) {
        final prereqs =
            (s['prerequisites'] as List? ?? []).map((p) => p.toString());
        if (prereqs.contains(id)) stack.add(s['id'].toString());
      }
    }
    for (final id in byId.keys) {
      if (!reachable.contains(id)) {
        errors.add('buildOrder: step "$id" is not reachable from a root step.');
      }
    }
    return errors;
  }

  /// restorePattern rules: 3-8 cells, every solutionTileId exists in tiles.
  static List<String> _validateRestorePattern(Map<String, dynamic> config) {
    final errors = <String>[];
    final cells = (config['cells'] as List? ?? []).whereType<Map>().toList();
    final tiles = (config['tiles'] as List? ?? []).whereType<Map>().toList();
    if (cells.length < 3 || cells.length > 8) {
      errors.add(
          'restorePattern: need 3-8 cells, found ${cells.length}.');
    }
    final tileIds = tiles.map((t) => t['id'].toString()).toSet();
    final seenCells = <String>{};
    for (final c in cells) {
      final cid = c['id'].toString();
      if (!seenCells.add(cid)) {
        errors.add('restorePattern: duplicate cell id "$cid".');
      }
      final solution = c['solutionTileId']?.toString() ?? '';
      if (!tileIds.contains(solution)) {
        errors.add(
            'restorePattern: cell "$cid" solutionTileId "$solution" has no matching tile.');
      }
      for (final alt in (c['alternativeTileIds'] as List? ?? [])) {
        if (!tileIds.contains(alt.toString())) {
          errors.add(
              'restorePattern: cell "$cid" alternativeTileId "$alt" has no matching tile.');
        }
      }
    }
    return errors;
  }

  /// finale rules (L20 only): stages reuse their system's rules.
  static List<String> _validateFinale(Map<String, dynamic> config) {
    final errors = <String>[];
    final stages =
        (config['stages'] as List? ?? []).whereType<Map>().toList();
    if (stages.isEmpty) {
      errors.add('finale: at least one stage required.');
      return errors;
    }
    for (final st in stages) {
      final sid = st['stageId']?.toString() ?? '?';
      final ptype = st['puzzleType']?.toString() ?? '';
      final sconfig =
          (st['config'] as Map? ?? {}).cast<String, dynamic>();
      switch (ptype) {
        case 'matchParts':
          errors.addAll(
              _validateMatchParts(sconfig).map((e) => 'finale.$sid: $e'));
        case 'buildOrder':
          errors.addAll(
              _validateBuildOrder(sconfig).map((e) => 'finale.$sid: $e'));
        case 'restorePattern':
          errors.addAll(
              _validateRestorePattern(sconfig).map((e) => 'finale.$sid: $e'));
        default:
          errors.add('finale.$sid: unknown puzzleType "$ptype".');
      }
    }
    return errors;
  }
}
