import 'package:app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app/screens/register/register_page.dart';
import 'package:app/exceptions/form_exceptions.dart';
import 'package:app/screens/login/bloc/login_bloc.dart';
import 'package:app/screens/login/bloc/login_event.dart';
import 'package:app/screens/login/bloc/login_state.dart';
import 'package:app/model/user_model.dart';
import 'package:app/main.dart';

class LoginPage extends StatefulWidget {
  final Function(User)? onLoginSuccess;

  const LoginPage({super.key, this.onLoginSuccess});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  String _getFriendlyErrorMessage(Object? error) {
    if (error is FormGeneralException) {
      final msg = error.message.toLowerCase();
      if (msg.contains('invalid') || msg.contains('credentials')) {
        return 'Неверный email или пароль';
      } else if (msg.contains('user') && msg.contains('not found')) {
        return 'Пользователь не найден';
      } else {
        return 'Ошибка авторизации. Повторите попытку.';
      }
    } else if (error is FormFieldsException) {
      return 'Проверьте правильность заполнения полей';
    } else {
      return 'Произошла неизвестная ошибка';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocProvider(
          create: (_) => LoginBloc(),
          child: BlocListener<LoginBloc, LoginState>(
            listener: (context, state) {
              if (state is LoginSuccessState) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text(" Вы успешно вошли в систему!")),
                );

                widget.onLoginSuccess?.call(state.user);

                Future.delayed(const Duration(milliseconds: 500), () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MyHomePage(
                        camera: (context.findAncestorWidgetOfExactType<MyApp>()!).camera,
                        user: state.user,
                        onLogout: () {
                          AuthService.logout();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LoginPage(onLoginSuccess: (_) {}),
                            ),
                          );
                        },
                      ),
                    ),
                        (route) => false,
                  );
                });
              } else if (state is LoginErrorState) {
                final errorMessage = _getFriendlyErrorMessage(state.exception);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      errorMessage,
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Вход в CarpeDiem",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: "Email",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) =>
                      value!.isEmpty ? "Введите email" : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: "Пароль",
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                      validator: (value) =>
                      value!.isEmpty ? "Введите пароль" : null,
                    ),
                    const SizedBox(height: 24),
                    BlocBuilder<LoginBloc, LoginState>(
                      builder: (context, state) {
                        final isLoading = state is LoginLoadingState;
                        return ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () {
                            if (_formKey.currentState!.validate()) {
                              context.read<LoginBloc>().add(
                                LoginRequestEvent(
                                  email: _emailController.text.trim(),
                                  password:
                                  _passwordController.text.trim(),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: isLoading
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : const Text(
                            "Войти",
                            style: TextStyle(fontSize: 16),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RegisterPage()),
                        );
                      },
                      child: const Text("Нет аккаунта? Зарегистрируйтесь"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}