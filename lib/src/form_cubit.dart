import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:form_cubit/src/form_field_cubit.dart';

class FormState extends Equatable {
  const FormState({required this.isValid});

  final bool isValid;

  @override
  List<Object?> get props => [isValid];
}

abstract class FormCubit extends Cubit<FormState> {
  FormCubit() : super(const FormState(isValid: true));

  List<FormFieldCubit<Object?>> get fields;

  bool validate() {
    var invalidFieldsCount = 0;
    for (var field in fields) {
      if (!field.validate()) {
        invalidFieldsCount++;
      }
    }

    final isValid = invalidFieldsCount == 0;
    emit(FormState(isValid: isValid));
    return isValid;
  }

  void addValidationError() {
    emit(const FormState(isValid: false));
  }
}

extension FormFieldsExtension on List<FormFieldCubit<Object?>> {
  List<String> get invalidFieldNames {
    return where(
      (field) => field.state.validationError != null,
    ).map((field) => field.fieldName ?? 'UnnamedField').toList(growable: false);
  }
}
