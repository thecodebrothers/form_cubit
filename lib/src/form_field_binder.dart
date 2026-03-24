import 'package:flutter/material.dart' hide FormFieldState;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:form_cubit/src/common_form_field_cubits.dart';
import 'package:form_cubit/src/form_field_cubit.dart';
import 'package:form_cubit/src/form_field_state.dart';
import 'package:single_value_cubit/single_value_cubit.dart';

class FormBuilder<S, T extends FormFieldCubit<S>> extends StatefulWidget {
  const FormBuilder({required this.builder, super.key, this.cubit});

  final T? cubit;
  final Widget Function(
    BuildContext context,
    FormFieldState<S> state,
    void Function(S newValue) updateValue,
  )
  builder;

  @override
  State<FormBuilder<S, T>> createState() => _FormBuilderState<S, T>();
}

class _FormBuilderState<S, T extends FormFieldCubit<S>>
    extends State<FormBuilder<S, T>> {
  late T cubit;

  @override
  void initState() {
    super.initState();
    cubit = widget.cubit ?? context.read<T>();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<T, FormFieldState<S>>(
      bloc: cubit,
      builder: (context, state) => widget.builder(
        context,
        state,
        (newValue) => cubit.updateValue(newValue),
      ),
    );
  }
}

class FocusCubitBinder<S extends SingleValueCubit<T>, T>
    extends StatefulWidget {
  const FocusCubitBinder({
    required this.builder,
    required this.getFocusCallback,
    required this.updateValue,
    this.cubit,
    super.key,
  });

  final S? cubit;
  final Widget Function(BuildContext context, FocusNode focusNode) builder;
  final bool Function(T value) getFocusCallback;
  final T Function(T value, bool focused) updateValue;

  @override
  State<FocusCubitBinder<S, T>> createState() => _FocusCubitBinderState();
}

class _FocusCubitBinderState<S extends SingleValueCubit<T>, T>
    extends State<FocusCubitBinder<S, T>> {
  late FocusNode _focusNode;
  late S _cubit;

  late final void Function() _listener;

  @override
  void initState() {
    super.initState();
    _cubit = widget.cubit ?? context.read<S>();
    _focusNode = FocusNode();

    final value = widget.getFocusCallback(_cubit.state);
    if (value != _focusNode.hasFocus) {
      if (value) {
        _focusNode.requestFocus();
      } else {
        _focusNode.unfocus();
      }
    }
    _listener = () => _cubit.set(
      widget.updateValue(_cubit.state, _focusNode.hasFocus),
    );
    _focusNode.addListener(_listener);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SingleValueCubit<T>, T>(
      listenWhen: (previous, current) {
        final previousValue = widget.getFocusCallback(previous);
        final newValue = widget.getFocusCallback(current);

        return previousValue != newValue;
      },
      bloc: _cubit,
      listener: (context, state) {
        final value = widget.getFocusCallback(state);
        if (value != _focusNode.hasFocus) {
          _focusNode.removeListener(_listener);
          if (value) {
            _focusNode.requestFocus();
          } else {
            _focusNode.unfocus();
          }
          _focusNode.addListener(_listener);
        }
      },
      child: Builder(
        builder: (context) => widget.builder(context, _focusNode),
      ),
    );
  }
}


class TextFormFieldBinder<T extends TextFormFieldCubit> extends StatefulWidget {
  const TextFormFieldBinder({required this.builder, this.cubit, super.key});

  final Widget Function(
    BuildContext context,
    TextEditingController controller,
    FocusNode focusNode,
    FormFieldState<String> state,
  )
  builder;
  final T? cubit;

  @override
  State<TextFormFieldBinder<T>> createState() => _TextFormFieldBinderState<T>();
}

class _TextFormFieldBinderState<T extends TextFormFieldCubit>
    extends State<TextFormFieldBinder<T>> {
  late T cubit;

  @override
  void initState() {
    super.initState();
    cubit = widget.cubit ?? context.read<T>();
  }

  @override
  Widget build(BuildContext context) {
    return GenericTextCubitBinder<FormFieldState<String>>(
      cubit: cubit,
      builder: (context, controller) =>
          FocusCubitBinder<FormFieldCubit<String>, FormFieldState<String>>(
            cubit: cubit,
            builder: (context, focusNode) => widget.builder(
              context,
              controller,
              focusNode,
              context.watch<T>().state,
            ),
            getFocusCallback: (value) => value.isFocused ?? false,
            updateValue: (value, focused) => value.copyWith(isFocused: focused),
          ),
      getInputCallback: (value) => value.value,
      updateValue: (value, text) => value.copyWith(value: text),
    );
  }
}
