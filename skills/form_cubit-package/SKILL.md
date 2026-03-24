---
name: form_cubit-package
description: >
  Use this skill whenever working with the `form_cubit` Flutter package — adding form fields,
  writing validators, wiring up a FormCubit, binding fields to UI with TextFormFieldBinder,
  handling remote/local validation errors, or understanding how FormFieldCubit state works.
  Trigger on any request that mentions form_cubit, form cubit, form field cubit, FormCubit, FormFieldCubit, TextFormFieldCubit,
  TextFormFieldBinder, FormBuilder, or form validation in a Flutter BLoC/Cubit context.
---

# form_cubit Package

`form_cubit` models each form field as its own `FormFieldCubit<T>` and groups fields under a `FormCubit`. The package is built on top of `flutter_bloc`.

## Core concepts

| Class | Role |
|---|---|
| `FormFieldCubit<T>` | State for a single typed field: value, validation error, focus, loading |
| `TextFormFieldCubit` | Abstract subclass of `FormFieldCubit<String>`; always subclass this, never use it directly |
| `BoolFormFieldCubit` | `FormFieldCubit<bool>` with `toggleValue()` |
| `ListFormFieldCubit<T>` | `FormFieldCubit<List<…>>` with add/remove/clear helpers |
| `FormCubit` | Abstract base; owns `List<FormFieldCubit<Object?>> fields`; emits `FormState(isValid)` |
| `TextFormFieldBinder<T>` | Preferred widget for text fields; provides `TextEditingController`, `FocusNode`, `FormFieldState<String>` |
| `FormBuilder<S, T>` | Generic widget for non-text fields; provides state + `updateValue` callback |
| `FormValidator<T>` | Abstract validator; return `null` for valid, a `FormFieldValidationError` for invalid |
| `NonEmptyStringValidator` | Built-in: fails if `String` is blank |
| `NonEmptyObjectValidator` | Built-in: fails if `Object?` is null |
| `CommonValidationError` | Wraps `CommonValidationErrorType` enum (`empty`, `wrongFormat`, `tooShort`, `tooLong`) |
| `RemoteValidationError` | Carries a server-provided error message string |

## Key import rules

- Import `package:form_cubit/form_cubit.dart` (barrel export).
- `FormState` and `FormFieldState` conflict with Flutter's own types — always hide them:
  ```dart
  import 'package:flutter/material.dart' hide FormState, FormFieldState;
  ```

## Step-by-step pattern

### 1. Subclass TextFormFieldCubit for each text field

`TextFormFieldCubit` is abstract — you must subclass it. Encapsulate the validator inside the cubit so the field owns its own validation rules:

```dart
class _EmailValidator extends FormValidator<String> {
  static final _regex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.]+$');

  @override
  FormFieldValidationError? validate(String value) {
    if (value.trim().isEmpty) return CommonValidationError(CommonValidationErrorType.empty);
    if (!_regex.hasMatch(value.trim())) return CommonValidationError(CommonValidationErrorType.wrongFormat);
    return null;
  }
}

class EmailFormFieldCubit extends TextFormFieldCubit {
  EmailFormFieldCubit() : super(validator: _EmailValidator(), fieldName: 'Email');
}

class PasswordFormFieldCubit extends TextFormFieldCubit {
  PasswordFormFieldCubit() : super(validator: NonEmptyStringValidator(), fieldName: 'Password');
}
```

### 2. Create the FormCubit with constructor injection

Receive field cubits as required constructor arguments — do not create them inside the FormCubit. Override `fields` to register them for validation. Override `close()` to dispose them:

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

### 3. Provide cubits with MultiBlocProvider

Field cubits are provided individually so they can be resolved via `context.read<FieldCubit>()` anywhere in the subtree. The form cubit is provided last since it depends on the field cubits:

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
  child: const MyFormPage(),
)
```

### 4. Bind text fields with TextFormFieldBinder

`TextFormFieldBinder<T>` where `T` is the concrete cubit type. It resolves the cubit from context automatically and manages the `TextEditingController` and `FocusNode` lifecycle — do **not** create your own:

```dart
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
```

You can also pass `cubit:` explicitly if the cubit is not in scope: `TextFormFieldBinder(cubit: someCubit, builder: ...)`.

### 5. Use FormBuilder for non-text fields

```dart
FormBuilder<bool, BoolFormFieldCubit>(
  builder: (context, state, updateValue) {
    return Switch(
      value: state.value,
      onChanged: updateValue,
    );
  },
)
```

### 6. React to form-level validity and trigger validation

Use `BlocBuilder<MyFormCubit, FormState>` for the submit button. Call `validate()` on submit — it runs validation on every field and emits `FormState(isValid: ...)`:

```dart
BlocBuilder<RegisterFormCubit, FormState>(
  builder: (context, state) {
    return ElevatedButton(
      onPressed: () {
        final isValid = context.read<RegisterFormCubit>().validate();
        if (isValid) { /* submit */ }
      },
      child: const Text('Submit'),
    );
  },
)
```

`validate()` short-circuits on the first invalid field — fields after it won't have their validation state updated until the next call.

## Translating validation errors to UI strings

A helper function is the cleanest pattern:

```dart
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
```

## Push server-side errors into fields

After a failed API call, push errors directly into individual fields or mark the whole form invalid:

```dart
formCubit.email.addValidationError(RemoteValidationError('Email already taken'));
formCubit.addValidationError(); // emits FormState(isValid: false) without re-validating fields
```

## FormFieldState properties

| Property | Description |
|---|---|
| `value` | Current field value |
| `validationError` | `null` if valid, otherwise a `FormFieldValidationError` |
| `isLoading` | Show a spinner while an async check is running |
| `isFocused` | Managed by `TextFormFieldBinder` via `FocusNode` |
| `setWithCode` | `true` when value was set via `updateValueCode()` — distinguishes programmatic from user changes |
| `isEmpty` | Built-in empty check (string trim or null check); customisable via `isEmptyCheck` |

Use `streamUserChanges()` to react only to user-driven input (filters out programmatic `updateValueCode` calls):

```dart
cubit.streamUserChanges().listen((value) { /* triggered only by user typing */ });
```

## Common mistakes

- **Do not use `TextFormFieldCubit` directly** — it is abstract. Always create a named subclass.
- **Do not hide only `FormState`** — `FormFieldState` also conflicts with Flutter. Hide both:
  `import 'package:flutter/material.dart' hide FormState, FormFieldState;`
- **Do not create `TextEditingController` yourself** when using `TextFormFieldBinder` — the binder owns it.
- **Do not forget to close field cubits** inside `FormCubit.close()`.
- **Do not register a field in `fields`** if it should be excluded from global validation (e.g. optional or conditionally required).
