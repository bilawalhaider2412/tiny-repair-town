/// System C — "Restore the pattern" puzzle engine (pure Dart, no Flutter).
///
/// The child fills grid cells with tiles to recreate a reference pattern.
/// Wrong tiles can be replaced freely — there is no penalty.
library;

/// One cell of the pattern grid.
class PatternCell {
  /// Cell id, e.g. "cell_0_0".
  final String id;

  /// Grid position.
  final int row;
  final int col;

  /// Tile id that restores this cell.
  final String solutionTileId;

  /// Alternative tile ids also accepted for this cell.
  final List<String> alternativeTileIds;

  const PatternCell({
    required this.id,
    required this.row,
    required this.col,
    required this.solutionTileId,
    required this.alternativeTileIds,
  });

  /// True when [tileId] is an accepted tile for this cell.
  bool accepts(String tileId) =>
      tileId == solutionTileId || alternativeTileIds.contains(tileId);
}

/// A tile the child can place into a cell.
class PatternTile {
  /// Tile id, e.g. "tile_red_star".
  final String id;

  /// Shape marking (in addition to colour, never colour-only).
  final String shape;

  /// Pattern marking, e.g. "stripes".
  final String pattern;

  const PatternTile({
    required this.id,
    required this.shape,
    required this.pattern,
  });
}

/// Engine for the "Restore the pattern" puzzle system.
class RestorePatternEngine {
  /// All grid cells.
  final List<PatternCell> cells;

  /// All available tiles.
  final List<PatternTile> tiles;

  /// Grid rows (from config; falls back to the cells' extent).
  final int rows;

  /// Grid columns (from config; falls back to the cells' extent).
  final int cols;

  /// cellId -> tileId for currently filled cells.
  final Map<String, String> filled = {};

  RestorePatternEngine({
    required this.cells,
    required this.tiles,
    int? rows,
    int? cols,
  })  : rows = rows ?? _extent(cells, (c) => c.row),
        cols = cols ?? _extent(cells, (c) => c.col);

  /// Grid extent helper: max coordinate + 1, or 0 when there are no cells.
  static int _extent(List<PatternCell> cells, int Function(PatternCell) pick) {
    var max = -1;
    for (final c in cells) {
      final v = pick(c);
      if (v > max) max = v;
    }
    return max + 1;
  }

  /// Builds an engine from a level `config` map (see CONTENT_SCHEMA.md).
  factory RestorePatternEngine.fromConfig(Map<String, dynamic> config) {
    final cells = <PatternCell>[];
    for (final c in (config['cells'] as List? ?? [])) {
      final m = (c as Map).cast<String, dynamic>();
      cells.add(PatternCell(
        id: (m['id'] ?? '').toString(),
        row: ((m['row'] as num?) ?? 0).toInt(),
        col: ((m['col'] as num?) ?? 0).toInt(),
        solutionTileId: (m['solutionTileId'] ?? '').toString(),
        alternativeTileIds:
            ((m['alternativeTileIds'] as List?) ?? const [])
                .map((t) => t.toString())
                .toList(),
      ));
    }
    final tiles = <PatternTile>[];
    for (final t in (config['tiles'] as List? ?? [])) {
      final m = (t as Map).cast<String, dynamic>();
      tiles.add(PatternTile(
        id: (m['id'] ?? '').toString(),
        shape: (m['shape'] ?? '').toString(),
        pattern: (m['pattern'] ?? '').toString(),
      ));
    }
    return RestorePatternEngine(
      cells: cells,
      tiles: tiles,
      rows: (config['rows'] as num?)?.toInt(),
      cols: (config['cols'] as num?)?.toInt(),
    );
  }

  /// Places [tileId] into [cellId], always replacing what was there.
  ///
  /// Returns true iff the tile is accepted for the cell (solution or
  /// alternative). Returns false for unknown cells. Wrong tiles stay placed
  /// and can be replaced without penalty.
  bool fillCell(String cellId, String tileId) {
    final cell = _cellById(cellId);
    if (cell == null) return false;
    filled[cellId] = tileId;
    return cell.accepts(tileId);
  }

  /// Removes the tile from [cellId] (no-op when empty).
  void clearCell(String cellId) {
    filled.remove(cellId);
  }

  /// True when the cell holds an accepted tile.
  bool isCellCorrect(String cellId) {
    final cell = _cellById(cellId);
    final tileId = filled[cellId];
    if (cell == null || tileId == null) return false;
    return cell.accepts(tileId);
  }

  /// True when every cell holds an accepted tile.
  bool get isComplete => cells.every((c) => isCellCorrect(c.id));

  /// Clears all filled cells (replay support).
  void reset() {
    filled.clear();
  }

  PatternCell? _cellById(String id) {
    for (final c in cells) {
      if (c.id == id) return c;
    }
    return null;
  }
}
