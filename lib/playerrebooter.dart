import 'dart:typed_data';
import 'dart:io';
import 'logger.dart';
import 'lmsappprefs.dart';
import 'lmsplayer.dart';

class PlayerRebooter {
  bool _playerConnectionIsOpen = false;
  late Socket _playerSocket;
  late LmsPlayer _player;

  void reboot(LmsPlayer p) {
    if (isConnectionOpen()) {
      logger.logActivity("request to reboot ${p.deviceName} declined due to open connection");
      return;
    }

    _player = p;
    _rebootPlayer();
  }

  bool isConnectionOpen() {
    return _playerConnectionIsOpen;
  }

  void _rebootPlayer() async {
    logger.reset("Activity:");
    logger.logActivity("attempting to reboot ${_player.deviceName}");
    InternetAddress addr;
    try {
      addr = InternetAddress(_player.ipAddr);
    }
    catch(e) {
      logger.logActivity("$e");
      return;
    }

    Duration timeoutVal = const Duration(seconds:10);
    Socket.connect(addr, 23, timeout:timeoutVal).then((Socket sock) {
      _playerSocket = sock;
      logger.logActivity("connected to ${_playerSocket.remoteAddress.address}:${_playerSocket.remotePort}");
      _playerConnectionIsOpen = true;
      _playerSocket.listen(_playerDataHandler, 
        onError: _playerSocketErrorHandler, 
        onDone: _playerSocketDoneHandler, 
        cancelOnError: true);
    }).catchError((e) {
      logger.logActivity("Unable to connect to player, error caught: $e");
    });
  }

  void _playerDataHandler(Uint8List data) {
    if (!_playerConnectionIsOpen) {
      return;
    }

    Uint8List telnetNegotiation = Uint8List.fromList([255, 253, 1, 255, 253, 31, 255, 251, 1, 255, 251, 3]);
    var txt = String.fromCharCodes(data).trim();
    if (data.length == telnetNegotiation.length && txt == String.fromCharCodes(telnetNegotiation)) {
      // telnet negotiation settings in initial response, 
      // sometimes with login prompt, sometimes alone
      logger.logActivity("player sent telnet negotiation");
    }
    else if (txt.endsWith("SqueezeboxTouch login:")) {
      if (txt.length > 25) {
        txt = txt.substring(15);
        logger.logActivity("[player responded (with telnet negotiation)] $txt");
      } 
      else {
        logger.logActivity("[player responded] $txt");
      }
      _playerSocket.write("${appPrefs.playerTelnetUserName}\n");
    }
    else if (txt.endsWith("Password:")) {
      logger.logActivity("[player responded] $txt");
      _playerSocket.write("${appPrefs.playerTelnetPassword}\n");
    }
    else if (txt.contains("Enjoy!")) {
      logger.logActivity("logged in, sending reboot command");
      _playerSocket.write("reboot\n");
      // socket.write("exit\n"); // for debugging
      sleep(const Duration(milliseconds: 500)); // reboot fails if socket is closed too quickly
      _playerConnectionIsOpen = false;
      logger.logActivity("closing player connection");
      _playerSocket.close();
    }
    else if (
      txt == appPrefs.playerTelnetUserName || 
      txt == "") {
      // don't log anything
    }
    else {
      logger.logActivity("[unhandled player response] $txt");
    }
  }

  void _playerSocketErrorHandler(Object error, StackTrace trace) {
    logger.logActivity("[error] $error");
    _playerSocket.close();
    _playerSocketDoneHandler();
  }

  void _playerSocketDoneHandler() {
    _playerConnectionIsOpen = false;
    _playerSocket.destroy();
  }
}
