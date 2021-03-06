import 'package:file_manager/widgets/icon_button.dart';
import 'package:flutter/material.dart';

class TextFiltering extends StatelessWidget {
  final FocusNode focusNode;
  final TextEditingController controller;
  final VoidCallback onEnterPressed;

  const TextFiltering({
    Key? key,
    required this.focusNode,
    required this.controller,
    required this.onEnterPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: focusNode,
      builder: (context, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutSine,
          height: focusNode.hasFocus ? 50.0 : 0.0,
          padding: focusNode.hasFocus ? const EdgeInsets.symmetric(vertical: 4.0) : EdgeInsets.zero,
          width: 300.0,
          child: child,
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: TextField(
          decoration: InputDecoration(
            border: InputBorder.none,
            filled: true,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: FMIconButton(
              onTap: controller.clear,
              child: Icon(
                Icons.clear,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          textInputAction: TextInputAction.none,
          onSubmitted: (s) {
            onEnterPressed();
          },
          focusNode: focusNode,
          controller: controller,
        ),
      ),
    );
  }
}
