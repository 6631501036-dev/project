import 'package:flutter/material.dart';
import 'package:flutter_application_1/student/student.dart';

void main() {
  runApp(
    MaterialApp(
      home: Student(),
      navigatorObservers: [routeObserver], // ✅ Required for auto-refresh
      debugShowCheckedModeBanner: false,
    ),
  ); //MaterialApp
}
