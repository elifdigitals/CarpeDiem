import 'package:equatable/equatable.dart';
import 'package:app/model/user_model.dart';

abstract class RegisterState extends Equatable {
  const RegisterState();

  @override
  List<Object> get props => [];
}

class RegisterFormState extends RegisterState {}

class RegisterLoadingState extends RegisterState {}

class RegisterSuccessState extends RegisterState {
  final User user;

  const RegisterSuccessState(this.user);

  @override
  List<Object> get props => [user];
}

class RegisterErrorState extends RegisterState {
  final Exception exception;

  const RegisterErrorState(this.exception);

  @override
  List<Object> get props => [exception];
}
