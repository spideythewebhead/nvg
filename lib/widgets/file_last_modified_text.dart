import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final _formatter = DateFormat('dd MMM yyyy');

class FileLastModified extends StatelessWidget {
  final DateTime datetime;

  const FileLastModified({
    Key? key,
    required this.datetime,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      _formatter.format(datetime),
      style: Theme.of(context).textTheme.caption!.copyWith(fontSize: 12.0),
    );
  }
}
