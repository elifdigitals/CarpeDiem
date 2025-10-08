import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'register_event.dart';
import 'register_state.dart';
import 'package:app/exceptions/form_exceptions.dart';
import 'package:app/model/user_model.dart';
import 'package:app/services/auth_service.dart';



class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  RegisterBloc() : super(RegisterFormState()) {
    on<RegisterRequestEvent>((event, emit) async {
      emit(RegisterLoadingState());
      try {
        final user = await AuthService.register(
          email: event.email,
          password: event.password,
          username: event.username,
          // cellphone: event.cellphone,
        );
        emit(RegisterSuccessState(user));
      } on FormGeneralException catch (e) {
        emit(RegisterErrorState(e));
      } on FormFieldsException catch (e) {
        emit(RegisterErrorState(e));
      } catch (e) {
        emit(RegisterErrorState(
          FormGeneralException(message: 'Unidentified error'),
        ));
      }
    });
  }
}
