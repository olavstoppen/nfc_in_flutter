import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nfc_in_flutter/nfc_in_flutter.dart';

class ReadExampleScreen extends StatefulWidget {
  @override
  _ReadExampleScreenState createState() => _ReadExampleScreenState();
}

class _ReadExampleScreenState extends State<ReadExampleScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Read NFC"),
      ),
      body: Center(
          child: RaisedButton(
        child: const Text("Toggle scan"),
        onPressed: () => {},
      )),
    );
  }
}
