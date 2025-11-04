import 'package:flutter/material.dart';

class Sportequipment extends StatelessWidget {
  const Sportequipment({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sport Equipment")),
      body: const Center(
        child: Text("Sport Equipment", style: TextStyle(fontSize: 22)),
      ),
    );
  }
}
