import 'package:flutter/material.dart';

class WriteExampleScreen extends StatefulWidget {
  @override
  _WriteExampleScreenState createState() => _WriteExampleScreenState();
}

class _WriteExampleScreenState extends State<WriteExampleScreen> {
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
