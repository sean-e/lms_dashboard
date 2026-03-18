import 'package:flutter/material.dart';
import 'logger.dart';
import 'lmsappprefs.dart';
import 'playerrebooter.dart';
import 'servercomm.dart';
import 'lmsplayer.dart';


void main() async {
  // await can't happen in _DashboardAppState.init because it doesn't complete 
  // before _DashboardHomePageState is constructed where the prefs are needed
  await appPrefs.init();

  runApp(const DashboardApp());
}

class DashboardApp extends StatefulWidget {
  const DashboardApp({super.key});

  @override
  State<DashboardApp> createState() => _DashboardAppState();
}

class _DashboardAppState extends State<DashboardApp> {
  _DashboardAppState();

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    // Avoid errors caused by flutter upgrade.
    WidgetsFlutterBinding.ensureInitialized();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "LMS Dashboard",
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const DashboardHomePage(),
    );
  }
}

class DashboardHomePage extends StatefulWidget {
  const DashboardHomePage({super.key});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  State<DashboardHomePage> createState() => _DashboardHomePageState();
}

class _DashboardHomePageState extends State<DashboardHomePage> {
  final ServerPlayerQuery server = ServerPlayerQuery();
  final ServerPlayerControl playerControl = ServerPlayerControl();
  final PlayerRebooter rebooter = PlayerRebooter();

  final _ipAddrController = TextEditingController();
  final _ipAddrPortController = TextEditingController();

  _DashboardHomePageState() {
    logger.init();
    appPrefs.loadSettings();
    _ipAddrController.text = appPrefs.serverIpAddr;
    _ipAddrPortController.text = "${appPrefs.serverIpAddrPort}";

    playerControl.setUpdateCallback(update);
    playerControl.setRequeryCallback(beginPlayerQuery);

    server.setUpdateCallback(update);
    beginPlayerQuery();
  }

  @override
  void dispose() {
    appPrefs.close();
    // Clean up the controller when the widget is disposed.
    _ipAddrController.dispose();
    _ipAddrPortController.dispose();
    logger.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      // appBar: AppBar(
      //   // Here we take the value from the DashboardHomePage object that was created by
      //   // the App.build method, and use it to set our appbar title.
      //   //title: Text(widget.title),
      // ),
      body: RefreshIndicator(onRefresh: beginPlayerQuery, child:
      Container(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child:
        ListView(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          // crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // const SizedBox(height: 35), -- unnecessary with ListView, this was needed when it was Column instead
            const Text(
              "Lyrion Music Server IP address and CLI port:",
              textAlign: TextAlign.left,
              textScaler: TextScaler.linear(1.1),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  flex: 2,
                  child:
                    TextField(
                      controller: _ipAddrController,
                      maxLength: 15,
                      style: Theme.of(context).textTheme.headlineSmall,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                    ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child:
                    TextField(
                      controller: _ipAddrPortController,
                      maxLength: 5,
                      style: Theme.of(context).textTheme.headlineSmall,
                      textInputAction: TextInputAction.done,
                      keyboardType: TextInputType.number,
                      onSubmitted: (String value) {
                        _submitServerPlayerQuery();
                      },
                    ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: server.isConnectionOpen() ? null : () {
                    _submitServerPlayerQuery();
                  },
                  child: const Text(
                    "Refresh",
                  ),
                ),
              ]
            ),

            const SizedBox(height: 25),

            if (players.isEmpty)
              const Text(
                "No players",
                textAlign: TextAlign.left,
                textScaler: TextScaler.linear(1.25),
              ),

            // add row for each player 
            for (LmsPlayer currentPlayer in players)
              Column(children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded (
                      flex: 13,
                      child:
                        Text(
                          currentPlayer.deviceName,
                          textAlign: TextAlign.left,
                          textScaler: const TextScaler.linear(1.1),
                          overflow: TextOverflow.fade,
                        ),
                    ),
                    if (currentPlayer.wifiSignalStrength.isNotEmpty && currentPlayer.wifiSignalStrength != "0")
                      const SizedBox(),
                    if (currentPlayer.wifiSignalStrength.isNotEmpty && currentPlayer.wifiSignalStrength != "0")
                    Text(
                      "${currentPlayer.wifiSignalStrength}%",
                    ),
                    const Expanded(
                      child:
                      SizedBox(),
                    ),
                    OutlinedButton(
                      onPressed: rebooter.isConnectionOpen() || currentPlayer.supportsTelnet == false ? null : () {
                        rebooter.reboot(currentPlayer);
                      },
                      child: 
                      const Text(
                        "Reboot",
                      ),
                    ),
                    const SizedBox(width:10),
                    OutlinedButton(
                      onPressed: playerControl.isConnectionOpen() || (currentPlayer.powerState != 0 && currentPlayer.powerState != 1) ? null : () {
                        playerControl.togglePlayerPower(currentPlayer);
                        currentPlayer.powerState = -1;
                        update(); // just to update text on the button because power state has changed...
                      },
                      child: 
                      Text(
                        switch (currentPlayer.powerState) {
                          // spaces added just to reduce spacing shift when text changes
                          0 => "Off",
                          1 => "On ",
                          _ => "...  ",
                        }
                      ),
                    ),
                ],),
                if (currentPlayer.powerState == 1 && currentPlayer.currentMode == "play")
                  Row(
                    children: [
                      const SizedBox(width: 20),
                      Text(currentPlayer.getNowPlaying()),
                  ],),
              ],),
              TextField(
                controller: logger.getController(),
                readOnly: true, 
                textAlign: TextAlign.left,
                maxLines: null,
                decoration: const InputDecoration(border:InputBorder.none),
              ),
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    ));
  }

  void _submitServerPlayerQuery() {
    appPrefs.serverIpAddr = _ipAddrController.text;
    appPrefs.serverIpAddrPort = int.parse(_ipAddrPortController.text);

    beginPlayerQuery();

    appPrefs.storeSettings();
  }

  void update() {
    setState(() {});
  }

  Future<void> beginPlayerQuery() async {
    server.beginPlayerQuery();
  }
}
