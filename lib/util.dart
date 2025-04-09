import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'font_size.dart';

void showSnackBar(BuildContext context, String message) {
  final fontSizeProvider = context.read<FontSizeProvider>();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: TextStyle(fontSize: fontSizeProvider.fontSize - 2),
      ),
    ),
  );
}