
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nfc_in_flutter/nfc_in_flutter.dart';

class EmulateNfcTagPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _EmulateNfcTagPageState();
  }
}

class _EmulateNfcTagPageState extends State<EmulateNfcTagPage> {
  StreamSubscription<NDEFMessage> _stream;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Emulate NFC TAG"),
      ),
      body: Center(
          child: RaisedButton(
            child: const Text("Toggle scan"),
            onPressed: startHostEmulation,
          )),
    );
  }


  void startHostEmulation() async {
    var running = await NFC.startHostEmulationService();
    print(running);
  }
}
