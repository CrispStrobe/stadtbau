// SPDX-License-Identifier: AGPL-3.0-or-later

/// Coarse land-use category of a tile type.
enum TileCategory {
  nature('nature'),
  greenUrban('green_urban'),
  residential('residential'),
  work('work'),
  infrastructure('infrastructure');

  const TileCategory(this.id);

  /// Stable identifier used in `data/params/tiles.json`.
  final String id;

  static TileCategory fromId(String id) =>
      values.firstWhere((c) => c.id == id, orElse: () => throw ArgumentError('Unknown category $id'));

  /// Nature and urban green count as habitat and as recreational green.
  bool get isGreen => this == nature || this == greenUrban;

  /// Built tiles cost demolition money to remove.
  bool get isBuilt => this == residential || this == work || this == infrastructure;
}

/// The ten tile types of model v1. Ids match `data/params/tiles.json` and the
/// ARB keys `tile_<id>` in the app.
enum TileType {
  meadow('meadow'),
  cropland('cropland'),
  forest('forest'),
  water('water'),
  park('park'),
  housingLow('housing_low'),
  housingHigh('housing_high'),
  commercial('commercial'),
  industry('industry'),
  road('road');

  const TileType(this.id);

  /// Stable identifier used in params, levels, save games and network messages.
  final String id;

  static final Map<String, TileType> _byId = {for (final t in values) t.id: t};

  static TileType fromId(String id) {
    final t = _byId[id];
    if (t == null) throw ArgumentError('Unknown tile type $id');
    return t;
  }

  /// The base terrain a removed tile reverts to.
  static const TileType terrain = TileType.meadow;
}
