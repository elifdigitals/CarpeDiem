import 'package:equatable/equatable.dart';

abstract class LobbyEvent extends Equatable {
  const LobbyEvent();

  @override
  List<Object?> get props => [];
}

class LobbyCreateRequestEvent extends LobbyEvent {
  final String hostId;
  final String mode;

  const LobbyCreateRequestEvent({required this.hostId, required this.mode});

  @override
  List<Object?> get props => [hostId, mode];
}
