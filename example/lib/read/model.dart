
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:nfc_in_flutter/nfc_in_flutter.dart';

class ReadTagModel
{
  bool isReadingContinuous = false;
  String get continuousButtonTitle => isReadingContinuous ? "Stop" : "Start";
  List<NFCResult> continuousTags = List();

  bool supported = false;
  bool enabled = false;

  StreamSubscription<NFCResult> _continuousStream;

  VoidCallback reload;

  String error;

  void start(VoidCallback reload) async
  {
    this.reload = reload;

    enabled = await NFC.isEnabled;
    supported = await NFC.isSupported;

    if (enabled && supported)
      error = null;
    else if (!supported)
      error = "Not supported";
    else if (!enabled)
      error = "Not enabled";

    reload();
  }

  void stop()
  {
    stopContinuous();
  }

  Future toggleContinuous() async
  {
    if(isReadingContinuous)
    {
      stopContinuous();
      isReadingContinuous = false;
    }
    else
    {
      continuousTags.clear();
      //stopContinuous();
      //isReadingContinuous = true;

      reload();

      _continuousStream = NFC.read().listen((tag)
      {
        print("Scanned tag with id ${tag.id}");
        continuousTags.add(tag);
        reload();
      },
      onError: (e){
        print('scannedTag onError: $e');
        _continuousStream.cancel();
        _continuousStream = null;
        continuousTags.clear();
      },
      onDone: () {
        //print('scannedTag onDone');
      }
      );
    }
  }

  void stopContinuous()
  {
    if(_continuousStream != null)
    {
      _continuousStream.cancel();
    }
    _continuousStream = null;

    isReadingContinuous = false;
    reload();
  }
}
