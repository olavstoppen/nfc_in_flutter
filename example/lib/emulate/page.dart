
import 'package:flutter/material.dart';

class EmulateNfcTagPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _EmulateNfcTagPageState();
  }
}

class _EmulateNfcTagPageState extends State<EmulateNfcTagPage>
{
  @override
  Widget build(BuildContext context)
  {
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
