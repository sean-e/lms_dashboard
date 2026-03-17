import 'package:hive_flutter/hive_flutter.dart';

LmsAppPrefs appPrefs = LmsAppPrefs();

class LmsAppPrefs {
  String serverIpAddr = "";
  int serverIpAddrPort = 0;
  String playerTelnetUserName = "";
  String playerTelnetPassword = "";

  Future<void> init() async {
    await Hive.initFlutter();
    _initialPrefs = await Hive.openBox("dashboard_prefs");
  }

  void loadSettings() {
    // do not set a default ip address since it will most likely be wrong and 
    // will cause an error to appear on first launch after install/update
    serverIpAddr = _initialPrefs.get("server_ip_addr") ?? "";

    serverIpAddrPort = _initialPrefs.get("server_ip_addr_port") ?? 9090;
    playerTelnetUserName = _initialPrefs.get("player_telnet_username") ?? "root";
    playerTelnetPassword = _initialPrefs.get("player_telnet_password") ?? "1234";
    _initialPrefs.close();
  }

  void storeSettings() async {
    final Box prefs = await Hive.openBox("dashboard_prefs");
    prefs.put("server_ip_addr", serverIpAddr);
    prefs.put("server_ip_addr_port", serverIpAddrPort);
    prefs.put("player_telnet_username", playerTelnetUserName);
    prefs.put("player_telnet_password", playerTelnetPassword);
    prefs.close();
  }
  
  late final Box _initialPrefs;
}
