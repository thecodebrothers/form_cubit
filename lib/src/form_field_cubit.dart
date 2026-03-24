import 'dart:async';

import 'package:form_cubit/src/form_field_state.dart';
import 'package:form_cubit/src/form_validator.dart';
import 'package:single_value_cubit/single_value_cubit.dart';

class FormFieldCubit<T> extends SingleValueCubit<FormFieldState<T>> {
  FormFieldCubit({
    required T initialValue,
    this.validator,
    this.fieldName,
  }) : super(FormFieldState(value: initialValue));

  final FormValidator<T>? validator;
  final String? fieldName;

  void updateValue(T newValue) {
    emit(state.copyWith(value: newValue, setWithCode: false));
  }

  void updateValueCode(T newValue) {
    emit(state.copyWith(value: newValue, setWithCode: true));
  }

  bool validate() {
    final error = validator?.validate(state.value);
    emit(state.copyWith(validationError: error));
    return error == null;
  }

  void setLoading({required bool isLoading}) {
    emit(state.copyWith(isLoading: isLoading));
  }

  void clearError() {
    emit(state.copyWith(validationError: null));
  }

  void addValidationError(FormFieldValidationError error) {
    emit(state.copyWith(validationError: error));
  }

  Stream<T> streamUserChanges() {
    return stream
        .where((state) => !state.setWithCode)
        .map((state) => state.value);
  }
}
