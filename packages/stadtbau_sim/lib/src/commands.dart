// SPDX-License-Identifier: AGPL-3.0-or-later
import 'tile_type.dart';

/// Player intents. The same commands travel over the network in multiplayer.
sealed class Command {
  const Command();

  Map<String, dynamic> toJson();

  static Command fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'place':
        return PlaceTile(json['x'] as int, json['y'] as int, TileType.fromId(json['tile'] as String));
      case 'remove':
        return RemoveTile(json['x'] as int, json['y'] as int);
      case 'tick':
        return AdvanceTick((json['count'] as int?) ?? 1);
      default:
        throw FormatException('unknown command ${json['type']}');
    }
  }
}

class PlaceTile extends Command {
  const PlaceTile(this.x, this.y, this.tile);
  final int x;
  final int y;
  final TileType tile;

  @override
  Map<String, dynamic> toJson() => {'type': 'place', 'x': x, 'y': y, 'tile': tile.id};
}

class RemoveTile extends Command {
  const RemoveTile(this.x, this.y);
  final int x;
  final int y;

  @override
  Map<String, dynamic> toJson() => {'type': 'remove', 'x': x, 'y': y};
}

class AdvanceTick extends Command {
  const AdvanceTick([this.count = 1]);
  final int count;

  @override
  Map<String, dynamic> toJson() => {'type': 'tick', 'count': count};
}

enum CommandError { outOfBounds, sameTile, insufficientBudget, tileNotAllowed, tileExhausted }

class CommandResult {
  const CommandResult.ok({this.costKEur = 0}) : error = null;
  const CommandResult.failed(this.error) : costKEur = 0;

  final CommandError? error;
  final double costKEur;

  bool get ok => error == null;
}

/// A command together with the tick it was applied at, for replays.
class CommandRecord {
  const CommandRecord(this.tick, this.command);
  final int tick;
  final Command command;

  Map<String, dynamic> toJson() => {'tick': tick, 'command': command.toJson()};

  static CommandRecord fromJson(Map<String, dynamic> json) =>
      CommandRecord(json['tick'] as int, Command.fromJson(json['command'] as Map<String, dynamic>));
}
