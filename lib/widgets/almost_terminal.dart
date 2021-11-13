import 'dart:convert';
import 'dart:io';

import 'package:file_manager/db_manager.dart';
import 'package:file_manager/noop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;

class _Command {
  final String command;
  final DateTime executedAt = DateTime.now();
  String output = '';

  _Command(this.command);
}

class AlmostTerminal extends StatefulWidget {
  final Directory? directory;
  final bool open;

  const AlmostTerminal({
    Key? key,
    required this.open,
    this.directory,
  }) : super(key: key);

  @override
  State<AlmostTerminal> createState() => _AlmostTerminalState();
}

class _AlmostTerminalState extends State<AlmostTerminal> {
  final scrollController = ScrollController();
  final textController = TextEditingController();
  final focusNode = FocusNode();
  final commands = <_Command>[];

  final overlayController = _SuggestionsOverlayController();

  late Process proc;

  late intl.DateFormat cmdDateFormat;

  OverlayEntry? suggestionsOverlay;

  @override
  void initState() {
    super.initState();

    initProcess();

    textController.addListener(onTextChanged);

    focusNode
      ..addListener(onFocusChanged)
      ..requestFocus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    cmdDateFormat = intl.DateFormat(
      'hh:mm a',
    );
  }

  @override
  void didUpdateWidget(covariant AlmostTerminal oldWidget) {
    super.didUpdateWidget(oldWidget);

    // if (!widget.open) {
    //   focusNode.unfocus();
    // } else {
    //   focusNode.requestFocus();
    // }
  }

  @override
  void dispose() {
    scrollController.dispose();
    textController.dispose();
    focusNode.dispose();
    proc.kill();
    super.dispose();
  }

  void initProcess() async {
    proc = await Process.start(
      '/bin/sh',
      [],
      runInShell: false,
      workingDirectory: widget.directory?.path,
    );

    proc.stdout.transform(utf8.decoder).listen(onTextReceived);
    proc.stderr.transform(utf8.decoder).listen(onTextReceived);
  }

  void onTextChanged() {
    if (!focusNode.hasPrimaryFocus) {
      return;
    }

    if (textController.text.isEmpty) {
      hideSuggestions();
    } else {
      showSuggestions(textController.text, calcOffset(textController.text));
    }
  }

  void onFocusChanged() {
    if (!focusNode.hasFocus) {
      hideSuggestions();
    } else if (textController.text.isNotEmpty) {
      showSuggestions(textController.text, calcOffset(textController.text));
    }
  }

  Offset calcOffset(String text) {
    final tp = TextPainter(
      text: TextSpan(
        text: textController.text,
        style: GoogleFonts.firaMono(),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    return Offset(
      tp.width + focusNode.offset.dx,
      focusNode.offset.dy,
    );
  }

  void onTextReceived(String text) {
    commands.last.output += text.trim();
    setState(() {});

    jumpToEnd();
  }

  void jumpToEnd() {
    Future.delayed(const Duration(milliseconds: 10), () {
      scrollController.jumpTo(scrollController.position.maxScrollExtent);
    });
  }

  void showSuggestions(String text, Offset offset) async {
    if (suggestionsOverlay == null) {
      suggestionsOverlay = OverlayEntry(
        builder: (_) => _SuggestionsOverlay(
          controller: overlayController,
          attachedFocusNode: focusNode,
          onSuggestionClick: onCommandEntered,
        ),
      );

      Overlay.of(context)?.insert(suggestionsOverlay!);
    }

    final suggestions = await DbManager.instance.terminalSuggestionsBox.then((box) => box.values);

    overlayController.update(
      suggestions: suggestions.where((sug) => sug.startsWith(text)).toList(),
      offset: offset.translate(0.0, -24.0),
    );
  }

  void hideSuggestions() {
    suggestionsOverlay?.remove();
    suggestionsOverlay = null;
  }

  void onCommandEntered(cmd) {
    cmd = cmd.trim();

    commands.add(_Command(cmd));
    setState(() {});
    jumpToEnd();

    textController.clear();
    proc.stdin.writeln(cmd);

    DbManager.instance.terminalSuggestionsBox.then<void>((box) {
      box.put(cmd, cmd);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTextStyle(
      style: GoogleFonts.jetBrainsMono(),
      child: Padding(
        padding: const EdgeInsets.all(8.0) - const EdgeInsets.only(top: 8.0),
        child: Material(
          borderRadius: BorderRadius.circular(8.0),
          color: theme.colorScheme.background,
          elevation: 8.0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Flexible(
                child: ListView.builder(
                  padding: const EdgeInsets.all(6.0),
                  itemCount: commands.length,
                  controller: scrollController,
                  itemBuilder: (context, index) {
                    final cmd = commands[index];

                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              const Text('\$ '),
                              Text(cmd.command),
                              const SizedBox(width: 8.0),
                              Text(
                                cmdDateFormat.format(cmd.executedAt),
                                style: Theme.of(context).textTheme.caption,
                              )
                            ],
                          ),
                          if (cmd.output.isNotEmpty)
                            Card(
                              elevation: 4.0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6.0),
                              ),
                              margin: const EdgeInsets.symmetric(
                                vertical: 6.0,
                                horizontal: 12.0,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  cmd.output,
                                  style: GoogleFonts.firaMono(),
                                ),
                              ),
                            )
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4.0),
                  child: TextField(
                    textInputAction: TextInputAction.none,
                    controller: textController,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      filled: true,
                      prefix: Text('\$  '),
                    ),
                    focusNode: focusNode,
                    autofocus: true,
                    onSubmitted: onCommandEntered,
                    style: GoogleFonts.firaMono(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuggestionsOverlayController extends ChangeNotifier {
  List<String> _suggestions = const <String>[];
  List<String> get suggestions => _suggestions;

  Offset _offset = Offset.zero;
  Offset get offset => _offset;

  update({
    required List<String> suggestions,
    required Offset offset,
  }) {
    _suggestions = suggestions;
    _offset = offset;

    notifyListeners();
  }
}

class _SuggestionsOverlay extends StatefulWidget {
  final _SuggestionsOverlayController controller;
  final FocusNode attachedFocusNode;
  final ValueChanged<String> onSuggestionClick;

  const _SuggestionsOverlay({
    Key? key,
    required this.controller,
    required this.onSuggestionClick,
    required this.attachedFocusNode,
  }) : super(key: key);

  @override
  State<_SuggestionsOverlay> createState() => _SuggestionsOverlayState();
}

class _SuggestionsOverlayState extends State<_SuggestionsOverlay> {
  @override
  void initState() {
    super.initState();

    widget.controller.addListener(updateState);

    HardwareKeyboard.instance.addHandler(onKeyEvent);
  }

  @override
  void didUpdateWidget(covariant _SuggestionsOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(updateState);
      widget.controller.addListener(updateState);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(updateState);
    HardwareKeyboard.instance.removeHandler(onKeyEvent);

    super.dispose();
  }

  void updateState() {
    setState(noop);
  }

  bool onKeyEvent(KeyEvent event) {
    if (!widget.attachedFocusNode.hasPrimaryFocus || event is! KeyDownEvent || event.character == null) {
      return false;
    }

    if (!HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.altLeft)) {
      return false;
    }

    final digit = int.tryParse(event.character!);

    if (digit != null) {
      if (digit != 0 && digit <= widget.controller.suggestions.length) {
        widget.onSuggestionClick(widget.controller.suggestions[digit - 1]);
      }

      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: CustomSingleChildLayout(
        delegate: _SuggestionsLayoutDelegate(widget.controller.offset),
        child: Material(
          color: theme.colorScheme.secondaryVariant,
          elevation: 4.0,
          borderRadius: BorderRadius.circular(3.0),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutSine,
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: 200.0,
              ),
              child: DefaultTextStyle(
                style: GoogleFonts.firaMono(
                  fontStyle: FontStyle.italic,
                ),
                child: IntrinsicWidth(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < widget.controller.suggestions.length; ++i)
                        Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: InkWell(
                              onTap: () => widget.onSuggestionClick,
                              borderRadius: BorderRadius.circular(4.0),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text('${1 + i}) ${widget.controller.suggestions[i]}'),
                              ),
                            ),
                          ),
                        ),
                      if (widget.controller.suggestions.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Use alt + number to select suggestion',
                            style: theme.textTheme.caption,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SuggestionsLayoutDelegate extends SingleChildLayoutDelegate {
  final Offset preferredPosition;

  _SuggestionsLayoutDelegate(this.preferredPosition);

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    return Offset(preferredPosition.dx, preferredPosition.dy - childSize.height);
  }

  @override
  bool shouldRelayout(covariant _SuggestionsLayoutDelegate oldDelegate) {
    return oldDelegate.preferredPosition != preferredPosition;
  }
}
