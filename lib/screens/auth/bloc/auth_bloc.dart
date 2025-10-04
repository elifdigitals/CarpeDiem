import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:app/model/user_model.dart';
import 'package:app/services/auth_service.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthLoadingState()) {
    on<AuthLogoutEvent>((event, emit) async {
      AuthService.logout();
      emit(AuthUnauthenticatedState());
    });

    on<AuthLoadUserEvent>((event, emit) async {
      emit(AuthLoadingState());
      try {
        User user = await AuthService.loadUser();
        emit(AuthAuthenticatedState(user: user));
      } catch (e) {
        emit(AuthUnauthenticatedState());
      }
    });

    on<AuthAuthenticateEvent>((event, emit) async {
      emit(AuthAuthenticatedState(user: event.user));
    });

    add(AuthLoadUserEvent());
  }
}
