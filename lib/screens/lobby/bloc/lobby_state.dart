import 'package:equatable/equatable.dart';
import 'package:app/model/user_model.dart';

abstract class LobbyState extends Equatable {
  const LobbyState();

  @override
  List<Object?> get props => [];
}

class LobbyInitialState extends LobbyState {}

class LobbyLoadingState extends LobbyState {}

class LobbyCreatedState extends LobbyState {
  final String lobbyId;

  const LobbyCreatedState(this.lobbyId);

  @override
  List<Object?> get props => [lobbyId];
}

class LobbyErrorState extends LobbyState {
  final Exception exception;

  const LobbyErrorState(this.exception);

  @override
  List<Object?> get props => [exception];
}
