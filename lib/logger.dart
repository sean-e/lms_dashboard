import 'package:flutter/material.dart';

Logger logger = Logger();

class Logger {
  String _logTxt = "Not connected";
  final _logViewController = TextEditingController(); 

  void init() {
    _logViewController.text = _logTxt;
  }

  void dispose() {
    _logViewController.dispose();
  }

  void reset(String txt) {
    _logTxt = txt;
  }

  TextEditingController getController() {
    return _logViewController;
  }

  String getLogText() {
    return _logTxt;
  }

  void logActivity(String text, [bool ln = true]) {
    if (ln) {
      _logTxt += "\n$text";
    }
    else {
      _logTxt += text;
    }
    _logViewController.text = _logTxt;
  }

  void clearLog() {
    _logViewController.text = _logTxt = "";
  }
}
