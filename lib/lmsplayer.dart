final List<LmsPlayer> players = List.empty(growable: true);

class LmsPlayer {
  String ipAddr = "";
  String playerId = "";
  String deviceName = "";
  String wifiSignalStrength = "";
  int powerState = 0;
  bool supportsTelnet = false;

  String getPowerOffCommandStr() {
    return "$playerId power 0";
  }
  
  String getPowerOnCommandStr() {
    return "$playerId power 1";
  }
  
  String getPlayCommandStr() {
     return "$playerId button play";
  }

  String getStopCommandStr() {
    return "$playerId button stop";
  }
}
