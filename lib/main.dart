import 'dart:io';

import 'package:f_logs/constants/db_constants.dart';
import 'package:f_logs/model/flog/flog.dart';
import 'package:f_logs/model/flog/flog_config.dart';
import 'package:f_logs/model/flog/log_level.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sembast/sembast.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setPreferredOrientations();
//  await dotenv.load(fileName: ".env");
  setupLogging();
 // await setupSSL();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

void setupLogging() {
  LogsConfig logsConfig = FLog.getDefaultConfigurations();

  bool logAll = dotenv.env["LOG_ALL"] == "true" || dotenv.env["LOG_ALL"] == "1";
  if(! logAll) {
    logsConfig.activeLogLevel = LogLevel.WARNING;
  }

  FLog.applyConfigurations(logsConfig);

  // delete logs older than 48h
  FLog.deleteAllLogsByFilter(filters: [
    Filter.lessThan(DBConstants.FIELD_TIME_IN_MILLIS,
        DateTime.now().millisecondsSinceEpoch - 72 * 60 * 60 * 1000)
  ]);
}

Future<SecurityContext> setupSSL() async {
  ByteData data = await PlatformAssetBundle().load('assets/ca/lets-encrypt-r3.pem');

  SecurityContext securityContext = SecurityContext.defaultContext;
  try {
    securityContext.setTrustedCertificatesBytes(data.buffer.asUint8List());
  } on TlsException catch (e, st) {
    if (e.osError?.message != null &&
        e.osError?.message.contains('CERT_ALREADY_IN_HASH_TABLE') == true) {
      FLog.logThis(
          text: 'createHttpClient() - cert already trusted! Skipping.',
          type: LogLevel.WARNING,
          exception: e,
          stacktrace: st
      );
    } else {
      FLog.logThis(
          text: 'createHttpClient() - exception',
          type: LogLevel.ERROR,
          exception: e,
          stacktrace: st
      );
    }
  }

  return securityContext;

}

Future<void> setPreferredOrientations() {
  return SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeRight,
    DeviceOrientation.landscapeLeft,
  ]);
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
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
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
