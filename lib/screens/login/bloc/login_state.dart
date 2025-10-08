import 'package:equatable/equatable.dart';
import 'package:app/model/user_model.dart';

abstract class LoginState extends Equatable {
  const LoginState();

  @override
  List<Object> get props => [];
}

class LoginFormState extends LoginState {}

class LoginLoadingState extends LoginState {}

class LoginSuccessState extends LoginState {
  final User user;

  const LoginSuccessState(this.user);

  @override
  List<Object> get props => [user];
}

class LoginErrorState extends LoginState {
  final Exception exception;

  const LoginErrorState(this.exception);

  @override
  List<Object> get props => [exception];
}