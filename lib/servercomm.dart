import 'dart:typed_data';
import 'dart:io';
import 'logger.dart';
import 'lmsappprefs.dart';
import 'lmsplayer.dart';


class _ServerCommBase {
  late Socket _serverSocket;
  bool _serverConnectionIsOpen = false;
  late Function _updateUi;

  void setUpdateCallback(Function f) {
    _updateUi = f;
  }

  bool isConnectionOpen() {
    return _serverConnectionIsOpen;
  }

  void _serverSocketErrorHandler(Object error, StackTrace trace) {
    logger.logActivity("[error] $error");
    _serverSocket.close();
    _serverSocketDoneHandler();
  }

  void _serverSocketDoneHandler() {
    _serverConnectionIsOpen = false;
    _serverSocket.destroy();
  }
}

class ServerPlayerQuery extends _ServerCommBase {
  LmsPlayer _currentQueryPlayer = LmsPlayer();
  int _playerCount = 0;
  int _queryPlayerIdx = -1;
  final String _playerCountQueryStr = "player count ";
  // these query strings are based on player server index rather than player id
  String _playerModelQueryStr = "";
  String _playerNameQueryStr = "";
  String _playerIpQueryStr = "";
  String _playerIdQueryStr = "";

  Future<void> beginPlayerQuery() async {
    if (_serverConnectionIsOpen) {
      logger.logActivity("request to connect to LMS ${appPrefs.serverIpAddr} declined due to open connection");
      return;
    }

    if (appPrefs.serverIpAddr.isEmpty || appPrefs.serverIpAddrPort == 0) {
      return;
    }

    logger.reset("Activity:");
    logger.logActivity("opening connection to ${appPrefs.serverIpAddr}:${appPrefs.serverIpAddrPort}");
    players.clear();
    InternetAddress addr;
    try {
      addr = InternetAddress(appPrefs.serverIpAddr);
    }
    catch(e) {
      logger.logActivity("$e");
      return;
    }

    Duration timeoutVal = const Duration(seconds:10);
    Socket.connect(addr, appPrefs.serverIpAddrPort, timeout:timeoutVal).then((Socket sock) {
      _serverSocket = sock;
      logger.logActivity("connected to LMS, begin server query");
      _serverConnectionIsOpen = true;
      _serverSocket.listen(_serverQueryDataHandler, 
        onError: _serverSocketErrorHandler, 
        onDone: _serverSocketDoneHandler, 
        cancelOnError: true);
      _serverSocket.write("$_playerCountQueryStr?\n");
    }).catchError((e) {
      logger.logActivity("Unable to connect to LMS, error caught: $e");
      _updateUi();
    });
  }

  void _serverQueryDataHandler(Uint8List data) {
    if (!_serverConnectionIsOpen) {
      return;
    }

    var txt = String.fromCharCodes(data).trim();
    txt = Uri.decodeFull(txt);
    if (txt.startsWith(_playerCountQueryStr)) {
      _playerCount = int.parse(txt.substring(_playerCountQueryStr.length));
      _queryPlayerIdx = 0;
      _serverQueryNextPlayer();
    }
    else if (txt.startsWith(_playerIdQueryStr)) {
      _currentQueryPlayer.playerId = txt.substring(_playerIdQueryStr.length);
      _serverSocket.write("${_currentQueryPlayer.getConnectedQueryStr()}?\n");
    }
    else if (txt.startsWith(_currentQueryPlayer.getConnectedQueryStr())) {
      int connected = int.parse(txt.substring(_currentQueryPlayer.getConnectedQueryStr().length));
      if (connected == 1) {
        _serverSocket.write("$_playerModelQueryStr?\n");
        return;
      }

      // don't display disconnected players
      _serverQueryNextPlayer();
    }
    else if (txt.startsWith(_playerModelQueryStr)) {
      if (txt.contains(" fab4")) {
        _currentQueryPlayer.supportsTelnet = true;
      }
      else {
        _currentQueryPlayer.supportsTelnet = false;
      }
      _serverSocket.write("$_playerNameQueryStr?\n");
    }
    else if (txt.startsWith(_playerNameQueryStr)) {
      _currentQueryPlayer.deviceName = txt.substring(_playerNameQueryStr.length);
      _serverSocket.write("$_playerIpQueryStr?\n");
    }
    else if (txt.startsWith(_playerIpQueryStr)) {
      int pos = txt.indexOf(':');
      if (pos == -1) {
        _currentQueryPlayer.ipAddr = txt.substring(_playerIpQueryStr.length);
      }
      else {
        _currentQueryPlayer.ipAddr = txt.substring(_playerIpQueryStr.length, pos);
      }
      _serverSocket.write("${_currentQueryPlayer.getWifiQueryStr()}?\n");
    }
    else if (txt.startsWith(_currentQueryPlayer.getWifiQueryStr())) {
      _currentQueryPlayer.wifiSignalStrength = txt.substring(_currentQueryPlayer.getWifiQueryStr().length);
      _serverSocket.write("${_currentQueryPlayer.getPowerQueryStr()}?\n");
    }
    else if (txt.startsWith(_currentQueryPlayer.getPowerQueryStr())) {
      txt = txt.substring(_currentQueryPlayer.getPowerQueryStr().length);
      _currentQueryPlayer.powerState = int.parse(txt);
      if (_currentQueryPlayer.powerState == 1) {
        _serverSocket.write("${_currentQueryPlayer.getModeQueryStr()}?\n");
        return;
      }

      _serverQueryNextPlayer();
    }
    else if (txt.startsWith(_currentQueryPlayer.getModeQueryStr())) {
      _currentQueryPlayer.currentMode = txt.substring(_currentQueryPlayer.getModeQueryStr().length);
      if (_currentQueryPlayer.currentMode == "play") {
        _serverSocket.write("${_currentQueryPlayer.getSongQueryStr()}?\n");
        return;
      }

      _serverQueryNextPlayer();
    }
    else if (txt.startsWith(_currentQueryPlayer.getSongQueryStr())) {
      _currentQueryPlayer.currentSong = txt.substring(_currentQueryPlayer.getSongQueryStr().length);
      _serverSocket.write("${_currentQueryPlayer.getArtistQueryStr()}?\n");
    }
    else if (txt.startsWith(_currentQueryPlayer.getArtistQueryStr())) {
      _currentQueryPlayer.currentArtist = txt.substring(_currentQueryPlayer.getArtistQueryStr().length);
      _serverSocket.write("${_currentQueryPlayer.getAlbumQueryStr()}?\n");
    }
    else if (txt.startsWith(_currentQueryPlayer.getAlbumQueryStr())) {
      _currentQueryPlayer.currentAlbum = txt.substring(_currentQueryPlayer.getAlbumQueryStr().length);
      _serverSocket.write("${_currentQueryPlayer.getSongPathQueryStr()}?\n");
    }
    else if (_currentQueryPlayer.getAlbumQueryStr().startsWith(txt)) {
      // radio stream does not support album, songPath, year
      _serverQueryNextPlayer();
    }
    else if (txt.startsWith(_currentQueryPlayer.getSongPathQueryStr())) {
      int pos = txt.indexOf(" path file");
      if (-1 != pos) {
        _currentQueryPlayer.currentSongPath = txt.substring(pos + 6);
        String qryTxt = _currentQueryPlayer.getSongYearQueryStr();
        if (qryTxt.isNotEmpty) {
          _serverSocket.write("$qryTxt?\n");
          return;
        }
      }
      
      _serverQueryNextPlayer();
    }
    else if (_currentQueryPlayer.getSongYearQueryStr().length > 25 &&
              0 == txt.indexOf(Uri.decodeFull(_currentQueryPlayer.getSongYearQueryStr()))) {
      int pos = txt.indexOf(" year:");
      if (-1 != pos) {
        String txt2 = txt.substring(pos + 6);
        pos = txt2.indexOf(" ");
        if (pos > 0) {
          _currentQueryPlayer.currentYear = txt2.substring(0, pos);
        }
      }

      _serverQueryNextPlayer();
    }
    else {
      logger.logActivity("[unhandled server response] $txt");
      _serverSocket.close();
      _serverSocketDoneHandler();
      logger.logActivity("server connection closed");
      _updateUi();
    }
  }

  void _serverQueryNextPlayer() {
    if (_currentQueryPlayer.deviceName.isNotEmpty) {
      players.add(_currentQueryPlayer);
      _currentQueryPlayer = LmsPlayer();
    }

    if (_queryPlayerIdx < _playerCount) {
      _playerModelQueryStr = "player model $_queryPlayerIdx ";
      _playerNameQueryStr = "player name $_queryPlayerIdx ";
      _playerIpQueryStr = "player ip $_queryPlayerIdx ";
      _playerIdQueryStr = "player id $_queryPlayerIdx ";
      if (_queryPlayerIdx == 0) {
        logger.logActivity("player ${_queryPlayerIdx+1}");
      }
      else {
        logger.logActivity(", ${_queryPlayerIdx+1}", false);
      }
      _serverSocket.write("$_playerIdQueryStr?\n");
      _queryPlayerIdx++;
    }
    else {
      _serverSocket.write("exit\n");
      _serverConnectionIsOpen = false;
      _serverSocket.close();
      logger.logActivity("server connection closed");
      String prevLogTxt = logger.getLogText();
      Future.delayed(Duration(seconds: 4), () { 
        if (prevLogTxt == logger.getLogText()) {
          logger.clearLog();
        }
      });
      _updateUi();
    }
  }
}

class ServerPlayerControl extends _ServerCommBase {
  LmsPlayer _selectedPlayer = LmsPlayer();
  late Function _requeryCallback;

  void setRequeryCallback(Function f) {
    _requeryCallback = f;
  }

  void togglePlayerPower(LmsPlayer p) async {
    _selectedPlayer = p;
    if (_selectedPlayer.powerState == 1) {
      _powerOnOrOffPlayer(false);
    }
    else if (_selectedPlayer.powerState == 0) {
      _powerOnOrOffPlayer(true);
    }
  }

  void _powerOnOrOffPlayer(bool powerOn) async {
    final String onOrOff = powerOn ? "on" : "off";
    if (_serverConnectionIsOpen) {
      logger.logActivity("request to power $onOrOff ${_selectedPlayer.deviceName} declined due to open connection");
      return;
    }

    logger.reset("Activity:");
    logger.logActivity("attempting to power $onOrOff ${_selectedPlayer.deviceName}");
    InternetAddress addr;
    try {
      addr = InternetAddress(appPrefs.serverIpAddr);
    }
    catch(e) {
      logger.logActivity("$e");
      return;
    }

    Duration timeoutVal = const Duration(seconds:10);
    Socket.connect(addr, appPrefs.serverIpAddrPort, timeout:timeoutVal).then((Socket sock) {
      _serverSocket = sock;
      logger.logActivity("connected to LMS");
      _serverConnectionIsOpen = true;
      _serverSocket.listen(_serverPlayerControlDataHandler, 
        onError: _serverSocketErrorHandler, 
        onDone: _serverSocketDoneHandler, 
        cancelOnError: true);
      final String commandStr = powerOn ? _selectedPlayer.getPowerOnCommandStr() : _selectedPlayer.getPowerOffCommandStr();
      _serverSocket.write("$commandStr\n");
    }).catchError((e) {
      logger.logActivity("Unable to connect to LMS, error caught: $e");
      _updateUi();
    });
  }

  void _serverPlayerControlDataHandler(Uint8List data) {
    if (!_serverConnectionIsOpen) {
      return;
    }

    var txt = String.fromCharCodes(data).trim();
    txt = Uri.decodeFull(txt);
    if (txt.startsWith(_selectedPlayer.getPowerOnCommandStr())) {
      logger.logActivity("[server response] $txt");
      _serverSocket.write("${_selectedPlayer.getStopCommandStr()}\n");
    }
    else if (txt.startsWith(_selectedPlayer.getStopCommandStr())) {
      logger.logActivity("[server response] $txt");
      _serverSocket.write("${_selectedPlayer.getPlayCommandStr()}\n");
    }
    else if (txt.startsWith(_selectedPlayer.getPowerOffCommandStr()) || txt.startsWith(_selectedPlayer.getPlayCommandStr())) {
      logger.logActivity("[server response] $txt");
      _serverConnectionIsOpen = false;
      _serverSocket.write("exit\n");
      _serverSocket.close();
      logger.logActivity("server connection closed, pausing before refresh");
      Future.delayed(Duration(seconds: 2), () { 
        _requeryCallback();
      });
    }
    else {
      logger.logActivity("[unhandled server response] $txt");
      _serverSocket.close();
      _serverSocketDoneHandler();
      logger.logActivity("server connection closed");
    }
  }
}
