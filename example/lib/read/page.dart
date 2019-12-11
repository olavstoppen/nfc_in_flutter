import 'package:flutter/material.dart';
import 'package:nfc_in_flutter_example/read/model.dart';
import 'package:nfc_in_flutter/nfc_in_flutter.dart';

class ReadTagPage extends StatefulWidget {
  @override
  _ReadTagPageState createState() => _ReadTagPageState();
}

class _ReadTagPageState extends State<ReadTagPage> {

  final model = ReadTagModel();
  NDEFMessage oneShotMessage;


  @override
  void initState() {
    model.start(reload);
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    model.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Read NFC"),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text("Toggle continuous read",
                style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            RaisedButton(
              child: Text(model.continuousButtonTitle),
              textColor: Colors.blue,
              color: Colors.white,
              onPressed: continuousClicked,
            ),
            Text("Results"),
            buildStreamResults()
          ],
        )
      )
    );
  }

  Widget buildStreamResults()
  {
    var widgets = List<Widget>();
    for(var tag in model.continuousTags){
      widgets.add(Text("ID: " + tag.id));
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget section(String title, String buttonTitle, VoidCallback onPressed)
  {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600)),
        SizedBox(height: 8),
        RaisedButton(
          child: Text(buttonTitle),
          textColor: Colors.blue,
          color: Colors.white,
          onPressed: onPressed,
        )
      ],
    );
  }

  void continuousClicked() {
    model.toggleContinuous();
  }

  void reload() {
    setState(() {

    });
  }
}
