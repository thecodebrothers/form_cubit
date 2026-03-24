import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:form_cubit/src/form_validator.dart';

@immutable
class FormFieldState<T> extends Equatable {
  const FormFieldState({
    required this.value,
    this.setWithCode = false,
    this.isFocused,
    this.validationError,
    this.isEmptyCheck,
    this.isLoading = false,
  });

  final FormFieldValidationError? validationError;
  final T value;
  final bool? isFocused;
  final bool isLoading;
  final bool setWithCode;
  final bool Function(T? value)? isEmptyCheck;

  bool get isEmpty {
    if (isEmptyCheck != null) {
      return isEmptyCheck!(value);
    }
    if (T == String) {
      return (value as String?)?.trim().isEmpty ?? true;
    }

    return value == null;
  }

  @override
  List<Object?> get props => [
    value,
    isFocused,
    validationError,
    isLoading,
    setWithCode,
  ];

  FormFieldState<T> copyWith({
    FutureOr<T>? value = const Omit(),
    FutureOr<bool>? isFocused = const Omit(),
    FutureOr<FormFieldValidationError>? validationError = const Omit(),
    FutureOr<bool> isLoading = const Omit(),
    FutureOr<bool> setWithCode = const Omit(),
  }) {
    return FormFieldState<T>(
      value: value is Omit ? this.value : value as T,
      isFocused: isFocused is Omit ? this.isFocused : isFocused as bool?,
      validationError: validationError is Omit
          ? this.validationError
          : validationError as FormFieldValidationError?,
      isLoading: isLoading is Omit ? this.isLoading : isLoading as bool,
      setWithCode: setWithCode is Omit ? this.setWithCode : setWithCode as bool,
    );
  }
}

final class Omit<T> implements Future<T> {
  const Omit();
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}
