import 'package:flutter/material.dart';

class TextFiltering extends StatelessWidget {
  final FocusNode focusNode;
  final TextEditingController controller;

  const TextFiltering({
    Key? key,
    required this.focusNode,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: focusNode,
      builder: (context, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutSine,
          height: focusNode.hasFocus ? 42.0 : 0.0,
          width: 300.0,
          child: child,
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: TextField(
          decoration: const InputDecoration(
            border: InputBorder.none,
            filled: true,
            prefixIcon: Icon(Icons.search),
            suffixIcon: Icon(Icons.clear),
          ),
          focusNode: focusNode,
          controller: controller,
        ),
      ),
    );
  }
}
