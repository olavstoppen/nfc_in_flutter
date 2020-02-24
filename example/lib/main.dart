import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nfc_in_flutter/nfc_in_flutter.dart';

import 'emulate/page.dart';
import 'read/page.dart';
import 'write/page.dart';

void main() => runApp(ExampleApp());

class ExampleApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text("NFC in Flutter examples"),
        ),
        body: Builder(builder: (context) {
          return ListView(
            children: <Widget>[
              ListTile(
                title: const Text("Read NFC"),
                onTap: () {
                  Navigator.pushNamed(context, "/read_example");
                },
              ),
              ListTile(
                title: const Text("Write NFC"),
                onTap: () {
                  Navigator.pushNamed(context, "/write_example");
                },
              ),
              ListTile(
                title: const Text("Emulate NFC TAG"),
                onTap: () {
                  Navigator.pushNamed(context, "/emulate_nfc_tag_example");
                },
              ),
            ],
          );
        }),
      ),
      routes: {
        "/read_example": (context) => ReadTagPage(),
        "/write_example": (context) => WriteNfcPage(),
        "/emulate_nfc_tag_example": (context) => EmulateNfcTagPage(),
      },
    );
  }
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // _stream is a subscription to the stream returned by `NFC.read()`.
  // The subscription is stored in state so the stream can be canceled later
  StreamSubscription<NFCResult> _stream;

  // _tags is a list of scanned tags
  List<NFCResult> _tags = [];

  bool _supportsNFC = false;

  // _readNFC() calls `NFC.readNDEF()` and stores the subscription and scanned
  // tags in state
  void _readNFC(BuildContext context) {
    try {
      // ignore: cancel_subscriptions
      StreamSubscription<NFCResult> subscription = NFC.read().listen(
          (tag) {
        // On new tag, add it to state
        setState(() {
          _tags.insert(0, tag);
        });
      },
          // When the stream is done, remove the subscription from state
          onDone: () {
        setState(() {
          _stream = null;
        });
      },
          // Errors are unlikely to happen on Android unless the NFC tags are
          // poorly formatted or removed too soon, however on iOS at least one
          // error is likely to happen. NFCUserCanceledSessionException will
          // always happen unless you call readNDEF() with the `throwOnUserCancel`
          // argument set to false.
          // NFCSessionTimeoutException will be thrown if the session timer exceeds
          // 60 seconds (iOS only).
          // And then there are of course errors for unexpected stuff. Good fun!
          onError: (e) {
        setState(() {
          _stream = null;
        });

        if (!(e is NFCUserCanceledSessionException)) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Error!"),
              content: Text(e.toString()),
            ),
          );
        }
      });

      setState(() {
        _stream = subscription;
      });
    } catch (err) {
      print("error: $err");
    }
  }

  // _stopReading() cancels the current reading stream
  void _stopReading() {
    _stream?.cancel();
    setState(() {
      _stream = null;
    });
  }

  @override
  void initState() {
    super.initState();
    NFC.isNDEFSupported.then((supported) {
      setState(() {
        _supportsNFC = true;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _stream?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.grey,
      ),
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text('NFC in Flutter'),
          actions: <Widget>[
            Builder(
              builder: (context) {
                if (!_supportsNFC) {
                  return FlatButton(
                    child: Text("NFC unsupported"),
                    onPressed: null,
                  );
                }
                return FlatButton(
                  child:
                      Text(_stream == null ? "Start reading" : "Stop reading"),
                  onPressed: () {
                    if (_stream == null) {
                      _readNFC(context);
                    } else {
                      _stopReading();
                    }
                  },
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.clear_all),
              onPressed: () {
                setState(() {
                  _tags.clear();
                });
              },
              tooltip: "Clear",
            ),
          ],
        ),
        // Render list of scanned tags
        body: ListView.builder(
          itemCount: _tags.length,
          itemBuilder: (context, index) {

            var ndef = _tags[index] as NFCNDEFResult;
            var tag = _tags[index] as NFCTagResult;

            if (ndef != null)
              return ndefCell(ndef);
            if (tag != null)
              return tagCell(tag);
            return Text("Unknown");
          },
        ),
      ),
    );
  }

  Widget tagCell(NFCTagResult tag)
  {
    return Padding(
    padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text("NFC Tag ${tag.id}",style: const TextStyle(fontWeight: FontWeight.bold)),
      ]
    ));
  }

  static const TextStyle payloadTextStyle = const TextStyle(fontSize: 15,color: const Color(0xFF454545),);

  Widget ndefCell(NFCNDEFResult ndef)
  {
    return Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text("NDEF Tag",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Builder(
                    builder: (context) {
                      // Build list of records
                      List<Widget> records = [];
                      for (int i = 0; i < ndef.message.records.length; i++) {
                        records.add(Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              "Record ${i + 1} - ${ndef.message.records[i].type}",
                              style: const TextStyle(
                                fontSize: 13,
                                color: const Color(0xFF666666),
                              ),
                            ),
                            Text(
                              ndef.message.records[i].payload,
                              style: payloadTextStyle,
                            ),
                            Text(
                              ndef.message.records[i].data,
                              style: payloadTextStyle,
                            ),
                          ],
                        ));
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: records,
                      );
                    },
                  )
                ],
              ),
            );
  }
}
