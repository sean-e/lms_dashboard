import 'package:hive_flutter/hive_flutter.dart';

LmsAppPrefs appPrefs = LmsAppPrefs();

class LmsAppPrefs {
  String serverIpAddr = "";
  int serverIpAddrPort = 0;
  String playerTelnetUserName = "";
  String playerTelnetPassword = "";

  Future<void> init() async {
    await Hive.initFlutter();
    _prefs = await Hive.openBox("dashboard_prefs");
  }

  void close() {
    Hive.close();
  }

  void loadSettings() {
    // do not set a default ip address since it will most likely be wrong and 
    // will cause an error to appear on first launch after install/update
    serverIpAddr = _prefs.get("server_ip_addr") ?? "";

    serverIpAddrPort = _prefs.get("server_ip_addr_port") ?? 9090;
    playerTelnetUserName = _prefs.get("player_telnet_username") ?? "root";
    playerTelnetPassword = _prefs.get("player_telnet_password") ?? "1234";
  }

  void storeSettings() async {
    _prefs.put("server_ip_addr", serverIpAddr);
    _prefs.put("server_ip_addr_port", serverIpAddrPort);
    _prefs.put("player_telnet_username", playerTelnetUserName);
    _prefs.put("player_telnet_password", playerTelnetPassword);
  }
  
  late final Box _prefs;
}
