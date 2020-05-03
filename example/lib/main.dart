import 'dart:io';

import 'package:flutter/material.dart';
import 'package:applegooglepay/applegooglepay.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  BuildContext scaffoldContext;

  @override
  void initState() {
    super.initState();
  }

  makeCustomPayment() async {
    if (Platform.isAndroid)
      makeGooglePayment(
        amount: 1,
        merchantID: '1443682',
        gateway: 'fondyeu',
        onError: (String msg) {
          _showToast(scaffoldContext, msg);
        },
        onSuccess: (String msg) {
          _showToast(scaffoldContext, msg);
        },
        proccessing: (String data) async {
          return true;
        },
      );

    if (Platform.isIOS)
      makeApplePayment(
        appleMerchantID: "merchant.io.datawiz.dwshopping",
        merchantName: "Uchoose",
        items: [
          {'label': 'Bred', 'amount': 10.0},
          {'label': 'Mill', 'amount': 20.0}
        ],
        proccessing: (String data) async {
          return true;
        },
      );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: const Text('Plugin example app'),
          ),
          body: Builder(builder: (context) {
            scaffoldContext = context;
            return Center(
                child: RaisedButton(
              onPressed: makeCustomPayment,
              child: Text('Custom pay'),
            ));
          })),
    );
  }

  void _showToast(BuildContext context, String message) {
    final scaffold = Scaffold.of(context);
    scaffold.showSnackBar(SnackBar(
      content: Text(message),
      action: SnackBarAction(
        label: 'UNDO',
        onPressed: () {},
      ),
    ));
  }
}
