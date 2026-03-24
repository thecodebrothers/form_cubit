import 'package:form_cubit/src/form_field_cubit.dart';
import 'package:form_cubit/src/form_field_state.dart';

abstract class TextFormFieldCubit extends FormFieldCubit<String> {
  TextFormFieldCubit({super.validator, super.fieldName})
    : super(initialValue: '');
}

class BoolFormFieldCubit extends FormFieldCubit<bool> {
  BoolFormFieldCubit({bool? initialValue, super.validator, super.fieldName})
    : super(initialValue: initialValue ?? false);

  void toggleValue() {
    emit(state.copyWith(value: !state.value));
  }
}

abstract class ListFormFieldCubit<T>
    extends FormFieldCubit<List<FormFieldState<T>>> {
  ListFormFieldCubit({List<T>? initialValue, super.validator, super.fieldName})
    : super(
        initialValue: (initialValue ?? [])
            .map((e) => FormFieldState<T>(value: e))
            .toList(),
      );

  T emptyItem();

  List<T> get items => state.value.map((e) => e.value).toList();

  void setItems(List<T> items) {
    final updatedList = items.map((e) => FormFieldState<T>(value: e)).toList();
    emit(state.copyWith(value: updatedList));
  }

  void addEmptyItem() {
    final updatedList = List<FormFieldState<T>>.from(state.value)
      ..add(FormFieldState<T>(value: emptyItem()));
    emit(state.copyWith(value: updatedList));
  }

  void addItem(T item) {
    final updatedList = List<T>.from(state.value.map((e) => e.value))
      ..add(item);
    setItems(updatedList);
  }

  void removeItem(T item) {
    final updatedList = List<T>.from(state.value.map((e) => e.value))
      ..remove(item);
    setItems(updatedList);
  }

  void removeItemAt(int index) {
    final updatedList = List<FormFieldState<T>>.from(state.value)
      ..removeAt(index);
    emit(state.copyWith(value: updatedList));
  }

  void clearItems() {
    emit(state.copyWith(value: []));
  }

  void updateItem(int index, T newItem) {
    final updatedList = List<T>.from(state.value.map((e) => e.value));
    updatedList[index] = newItem;
    setItems(updatedList);
  }

  void moveItem(int oldIndex, int newIndex) {
    final updatedList = List<T>.from(state.value.map((e) => e.value));
    final item = updatedList.removeAt(oldIndex);
    updatedList.insert(newIndex, item);
    setItems(updatedList);
  }

  void onReorder(int oldIndex, int newIndex) {
    moveItem(oldIndex, newIndex);
  }
}
