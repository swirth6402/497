import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';

class SecondScreen extends StatelessWidget {
  final String payload;

  const SecondScreen(this.payload, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notification Clicked")),
      body: Center(child: Text("Payload: $payload")),
    );
  }
}