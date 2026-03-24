# form_cubit

A Flutter package that provides a BLoC/Cubit-based approach to form state management. It models each form field as its own `FormFieldCubit` and groups them under a `FormCubit`, giving you fine-grained reactive control over validation, loading states, and error display.

## Features

- **`FormFieldCubit<T>`** — manages value, validation error, focus, and loading state for a single field
- **`FormCubit`** — owns a list of field cubits and orchestrates whole-form validation
- **`FormBuilder`** — a widget that binds a `FormFieldCubit` to UI, providing state and an `updateValue` callback
- **Built-in validators** — `NonEmptyStringValidator`, `NonEmptyObjectValidator`, plus a `FormValidator<T>` base class for custom rules
- **Built-in field types** — `TextFormFieldCubit`, `BoolFormFieldCubit`, `ListFormFieldCubit<T>`
- **Remote errors** — `RemoteValidationError` lets you push server-side messages into field state

## Installation

```yaml
dependencies:
  form_cubit: ^0.0.1
  flutter_bloc: ^9.0.0
```

## Usage

### 1. Define validators and concrete field cubits

Each field gets its own cubit subclass that owns its validator:

```dart
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
```

### 2. Create a FormCubit

The form cubit receives its field cubits via constructor injection:

```dart
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
```

### 3. Provide cubits and bind fields to UI

Field cubits are provided individually so they can be resolved independently:

```dart
MultiBlocProvider(
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
)

// Bind a text field with TextFormFieldBinder
TextFormFieldBinder<EmailFormFieldCubit>(
  cubit: context.read<RegisterFormCubit>().email,
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
)
```

### 4. Validate on submit

```dart
ElevatedButton(
  onPressed: () {
    final isValid = context.read<RegisterFormCubit>().validate();
    if (isValid) {
      // proceed
    }
  },
  child: const Text('Register'),
)
```

### Handling remote validation errors

```dart
// After a failed API call:
formCubit.email.addValidationError(RemoteValidationError('Email already taken'));
formCubit.addValidationError(); // mark whole form invalid
```

## API overview

| Class                     | Description                                                                      |
| ------------------------- | -------------------------------------------------------------------------------- |
| `FormCubit`               | Abstract base; override `fields` to list all field cubits                        |
| `FormFieldCubit<T>`       | Cubit for a single typed field                                                   |
| `TextFormFieldCubit`      | Abstract `FormFieldCubit<String>`; subclass to create concrete text field cubits |
| `BoolFormFieldCubit`      | `FormFieldCubit<bool>` with `toggleValue()`                                      |
| `ListFormFieldCubit<T>`   | `FormFieldCubit<List<…>>` with add/remove helpers                                |
| `TextFormFieldBinder<T>`  | Widget for text fields; provides `TextEditingController`, `FocusNode`, and state |
| `FormBuilder<S, T>`       | Generic widget that rebuilds on field state changes                              |
| `FormValidator<T>`        | Abstract validator; return `null` for valid                                      |
| `NonEmptyStringValidator` | Validates that a `String` is not blank                                           |
| `NonEmptyObjectValidator` | Validates that an `Object?` is not null                                          |
| `CommonValidationError`   | Wraps a `CommonValidationErrorType` enum value                                   |
| `RemoteValidationError`   | Carries a server-provided error message                                          |

## Example

A full working example (register form with email + password) is available in the [`example/`](example/) directory.
