final List<LmsPlayer> players = List.empty(growable: true);

class LmsPlayer {
  String ipAddr = "";
  String playerId = "";
  String deviceName = "";
  String wifiSignalStrength = "";
  int powerState = 0;
  bool supportsTelnet = false;
  String currentMode = "";
  String currentSong = "";
  String currentArtist = "";
  String currentAlbum = "";
  String currentSongPath = "";
  String currentYear = "";

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

  // Query strings include trailing space to fix returned text matching
  String getConnectedQueryStr() {
    return "$playerId connected ";
  }

  String getWifiQueryStr() {
    return "$playerId signalstrength ";
  }

  String getPowerQueryStr() {
    return "$playerId power ";
  }

  String getModeQueryStr() {
    return "$playerId mode ";
  }

  String getSongQueryStr() {
    return "$playerId title ";
  }

  String getArtistQueryStr() {
    return "$playerId artist ";
  }

  String getAlbumQueryStr() {
    return "$playerId album ";
  }

  String getSongPathQueryStr() {
    return "$playerId path ";
  }

  String getSongYearQueryStr() {
    if (currentSongPath.isNotEmpty) {
      String path = Uri.encodeFull(currentSongPath);
      return "songinfo 0 30 url:$path y";
    }

    return "";
  }

  String getNowPlaying() {
    if (currentMode == "play") {
      if (currentYear.isEmpty) {
        return "$currentSong\n$currentArtist\n$currentAlbum";
      }

      return "$currentSong\n$currentArtist\n$currentAlbum ($currentYear)";
    }

    return "";
  }
}
