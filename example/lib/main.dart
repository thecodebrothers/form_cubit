import 'package:flutter/material.dart' hide FormState, FormFieldState;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:form_cubit/form_cubit.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => EmailFormFieldCubit()),
          BlocProvider(create: (_) => PasswordFormFieldCubit()),
          BlocProvider(
            create: (context) => RegisterFormCubit(
              email: context.read<EmailFormFieldCubit>(),
              password: context.read<PasswordFormFieldCubit>(),
            ),
          ),
        ],
        child: const RegisterPage(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Form cubit
// ---------------------------------------------------------------------------

class _EmailValidator extends FormValidator<String> {
  static final _emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.]+$');

  @override
  FormFieldValidationError? validate(String value) {
    if (value.trim().isEmpty) {
      return CommonValidationError(CommonValidationErrorType.empty);
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return CommonValidationError(CommonValidationErrorType.wrongFormat);
    }
    return null;
  }
}

class EmailFormFieldCubit extends TextFormFieldCubit {
  EmailFormFieldCubit()
    : super(validator: _EmailValidator(), fieldName: 'Email');
}

class PasswordFormFieldCubit extends TextFormFieldCubit {
  PasswordFormFieldCubit()
    : super(validator: NonEmptyStringValidator(), fieldName: 'Password');
}

class RegisterFormCubit extends FormCubit {
  RegisterFormCubit({required this.email, required this.password});

  final EmailFormFieldCubit email;
  final PasswordFormFieldCubit password;

  @override
  List<FormFieldCubit<Object?>> get fields => [email, password];

  @override
  Future<void> close() {
    email.close();
    password.close();
    return super.close();
  }
}

// ---------------------------------------------------------------------------
// UI
// ---------------------------------------------------------------------------

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _EmailField(),
            const SizedBox(height: 16),
            _PasswordField(),
            const SizedBox(height: 32),
            _SubmitButton(),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 8),
            const _FieldStateDebugView(),
          ],
        ),
      ),
    );
  }
}

class _EmailField extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextFormFieldBinder<EmailFormFieldCubit>(
      builder: (context, controller, focusNode, state) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: 'Email',
            errorText: _errorText(state.validationError),
          ),
        );
      },
    );
  }
}

class _PasswordField extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextFormFieldBinder<PasswordFormFieldCubit>(
      builder: (context, controller, focusNode, state) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Password',
            errorText: _errorText(state.validationError),
          ),
        );
      },
    );
  }
}

class _SubmitButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RegisterFormCubit, FormState>(
      builder: (context, state) {
        return ElevatedButton(
          onPressed: () {
            final isValid = context.read<RegisterFormCubit>().validate();
            if (isValid) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Form submitted!')));
            }
          },
          child: const Text('Register'),
        );
      },
    );
  }
}

class _FieldStateDebugView extends StatelessWidget {
  const _FieldStateDebugView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RegisterFormCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BlocBuilder<EmailFormFieldCubit, FormFieldState<String>>(
          bloc: cubit.email,
          builder: (context, state) => _StateText(label: 'email', state: state),
        ),
        const SizedBox(height: 4),
        BlocBuilder<PasswordFormFieldCubit, FormFieldState<String>>(
          bloc: cubit.password,
          builder: (context, state) =>
              _StateText(label: 'password', state: state),
        ),
      ],
    );
  }
}

class _StateText extends StatelessWidget {
  const _StateText({required this.label, required this.state});

  final String label;
  final FormFieldState<String> state;

  @override
  Widget build(BuildContext context) {
    final error = state.validationError == null
        ? 'none'
        : _errorText(state.validationError)!;
    return Text(
      '$label: value="${state.value}" focused=${state.isFocused}  error=$error  loading=${state.isLoading}',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        fontFamily: 'monospace',
        color: Colors.grey[600],
      ),
    );
  }
}

String? _errorText(FormFieldValidationError? error) {
  if (error == null) return null;
  if (error is CommonValidationError) {
    return switch (error.error) {
      CommonValidationErrorType.empty => 'This field is required',
      CommonValidationErrorType.wrongFormat => 'Invalid format',
      CommonValidationErrorType.tooShort => 'Too short',
      CommonValidationErrorType.tooLong => 'Too long',
    };
  }
  if (error is RemoteValidationError) return error.message;
  return 'Invalid value';
}
