import 'package:equatable/equatable.dart';

abstract class RegisterEvent extends Equatable {
  const RegisterEvent();
}

class RegisterRequestEvent extends RegisterEvent {
  final String email;
  final String password;
  // final String cellphone;
  final String username;

  const RegisterRequestEvent({
    required this.email,
    required this.password,
    // required this.cellphone,
    required this.username
  });

  @override
  List<Object?> get props => [email, password];
}
