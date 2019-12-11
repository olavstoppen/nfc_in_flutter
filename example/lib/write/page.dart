import 'package:flutter/material.dart';

class WriteNfcPage extends StatefulWidget {
  @override
  _WriteNfcPageState createState() => _WriteNfcPageState();
}

class _WriteNfcPageState extends State<WriteNfcPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Write NFC"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Center(
            child: RaisedButton(
              child: const Text("Write to tag"),
              onPressed: () => {},
            ),
          ),
        ],
      ),
    );
  }
}
