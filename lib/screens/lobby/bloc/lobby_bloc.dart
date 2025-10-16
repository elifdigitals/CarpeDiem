import 'package:flutter_bloc/flutter_bloc.dart';
import 'lobby_event.dart';
import 'lobby_state.dart';
import 'package:app/services/lobby_service.dart';
import 'package:app/exceptions/form_exceptions.dart';

class LobbyBloc extends Bloc<LobbyEvent, LobbyState> {
  LobbyBloc() : super(LobbyInitialState()) {
    on<LobbyCreateRequestEvent>((event, emit) async {
      emit(LobbyLoadingState());
      try {
        final lobby = await LobbyService.createLobby(
          hostId: event.hostId,
          mode: event.mode,
        );
        emit(LobbyCreatedState(lobby.id));
      } on FormGeneralException catch (e) {
        emit(LobbyErrorState(e));
      } catch (e) {
        emit(LobbyErrorState(
          FormGeneralException(message: 'Unknown error'),
        ));
      }
    });
  }
}
