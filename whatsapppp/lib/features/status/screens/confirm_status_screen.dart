import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConfirmStatusScreen extends ConsumerWidget {
  static const String routeName = '/confirm-status-screen';
  final File file;

  ConfirmStatusScreen({required this.file});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold();
  }
}
