import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app/screens/register/register_page.dart';
import 'package:app/exceptions/form_exceptions.dart';
import 'package:app/screens/login/bloc/login_bloc.dart';
import 'package:app/screens/login/bloc/login_event.dart';
import 'package:app/screens/login/bloc/login_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoginBloc(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Entrance"),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: BlocListener<LoginBloc, LoginState>(
            listener: (context, state) {
              if (state is LoginSuccessState) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Successfully logged in!")),
                );
                // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
              } else if (state is LoginErrorState) {
                String errorMessage = 'Unknown error';
                if (state.exception is FormGeneralException) {
                  errorMessage = (state.exception as FormGeneralException).message;
                } else if (state.exception is FormFieldsException) {
                  errorMessage = 'Please check your input fields';
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(errorMessage)),
                );
              }
            },
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: "Email",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) =>
                    value!.isEmpty ? "Input email" : null,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: "Password",
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () => setState(
                                () => _isPasswordVisible = !_isPasswordVisible),
                      ),
                    ),
                    validator: (value) =>
                    value!.isEmpty ? "Input password" : null,
                  ),
                  const SizedBox(height: 20),

                  BlocBuilder<LoginBloc, LoginState>(
                    builder: (context, state) {
                      return ElevatedButton(
                        onPressed: state is LoginLoadingState
                            ? null
                            : () {
                          if (_formKey.currentState!.validate()) {
                            context.read<LoginBloc>().add(
                              LoginRequestEvent(
                                email: _emailController.text,
                                password: _passwordController.text,
                              ),
                            );
                          }
                        },
                        child: state is LoginLoadingState
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Text("Login"),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RegisterPage()),
                      );
                    },
                    child:
                    const Text("Нет аккаунта? Зарегистрируйтесь"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}