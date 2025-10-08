import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app/screens/register/bloc/register_bloc.dart';
import 'package:app/screens/register/bloc/register_event.dart';
import 'package:app/screens/register/bloc/register_state.dart';
import 'package:app/exceptions/form_exceptions.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registration")),
      body: BlocProvider(
        create: (_) => RegisterBloc(),
        child: BlocConsumer<RegisterBloc, RegisterState>(
          listener: (context, state) {
            if (state is RegisterSuccessState) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Registration successful"),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pop(context);
            } else if (state is RegisterErrorState) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Error: ${state.exception}",
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is RegisterLoadingState) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: "Username",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                      value!.isEmpty ? "Введите имя" : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: "Email",
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) =>
                      value!.isEmpty ? "Введите email" : null,
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
                          onPressed: () => setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          }),
                        ),
                      ),
                      validator: (value) =>
                      value!.length < 6 ? "Минимум 6 символов" : null,
                    ),
                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          context.read<RegisterBloc>().add(
                            RegisterRequestEvent(
                              email: _emailController.text.trim(),
                              password: _passwordController.text.trim(),
                              username: _usernameController.text.trim(),
                            ),
                          );
                        }
                      },
                      child: const Text("Register"),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
