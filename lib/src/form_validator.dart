import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

abstract class FormFieldValidationError {}

class CommonValidationError implements FormFieldValidationError {
  CommonValidationError(this.error);

  final CommonValidationErrorType error;
}

class RemoteValidationError implements FormFieldValidationError {
  RemoteValidationError(this.message);

  final String message;
}

enum CommonValidationErrorType { empty, wrongFormat, tooShort, tooLong }

abstract class FormValidator<T> {
  FormFieldValidationError? validate(T value);
}

class NonEmptyStringValidator extends FormValidator<String> {
  NonEmptyStringValidator();

  @override
  CommonValidationError? validate(String? value) {
    if (value?.trim().isEmpty ?? true) {
      return CommonValidationError(CommonValidationErrorType.empty);
    }

    return null;
  }
}

class NonEmptyObjectValidator extends FormValidator<Object?> {
  NonEmptyObjectValidator();

  @override
  CommonValidationError? validate(Object? value) {
    if (value == null) {
      return CommonValidationError(CommonValidationErrorType.empty);
    }

    return null;
  }
}

class FormErrorTranslator {
  FormErrorTranslator({required this.callback});

  final String? Function(FormFieldValidationError error) callback;

  String? translate(FormFieldValidationError error) {
    if (error is RemoteValidationError) {
      return error.message;
    }

    return callback(error);
  }
}

class BaseFormErrorTranslationProvider extends SingleChildStatelessWidget {
  const BaseFormErrorTranslationProvider({
    required this.translate,
    super.child,
    super.key,
  });

  final String? Function(FormFieldValidationError error) translate;

  @override
  Widget buildWithChild(BuildContext context, Widget? child) {
    return Provider(
      create: (context) => FormErrorTranslator(callback: translate),
      child: child,
    );
  }
}
