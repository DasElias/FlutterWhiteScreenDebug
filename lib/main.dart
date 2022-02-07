import 'dart:io';

import 'package:f_logs/constants/db_constants.dart';
import 'package:f_logs/model/flog/flog.dart';
import 'package:f_logs/model/flog/flog_config.dart';
import 'package:f_logs/model/flog/log_level.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sembast/sembast.dart';

Object? globE;
StackTrace? globStr;
bool wasException = false;

Future main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    await dotenv.load(fileName: ".env");
    setupLogging();
    await setupSSL();

    runApp(MyHomePage());

  } catch(e) {
    wasException = true;
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

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key}) : super(key: key);


  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance!.addPostFrameCallback((_) async {
      try {
        await dialog("here we are " + ( wasException ? "except" : "false"));

        await dialog(globE ?? "");
        await dialog(globStr ?? "");
      } catch(e, str) {
        await dialog(e);
        await dialog(str);
      }
    });
  }

  Future dialog(Object content) async {
    await showDialog(context: context, builder: (context) {
      return AlertDialog(
        title: Text("Hi!"),
        content: Text(
            content.toString()
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Demo App",
      home: Scaffold(
        body: Container(
          color: Colors.redAccent,
          child: Text("Hello World!"),
        ),
      ),
    );
  }
}
