import "dart:async";
import 'dart:convert';
import "dart:io";
import 'package:applegooglepay/googlePay.dart' as google;
import 'package:applegooglepay/applePay.dart' as apple;
import 'package:flutter/foundation.dart';
import "package:flutter/services.dart";

Future<void> makeGooglePayment({
  double amount,
  String merchantID,
  String gateway,
  String orderId,
  String currency = 'UAH',
  bool isTest = true,
  Future<void> onSuccess(String msg),
  Future<void> onError(String msg),
  Future<bool> proccessing(String data, String orderId),
}) async {
  if (Platform.isAndroid) {
    var environment = isTest ? 'test' : 'production';
    if (!(await google.GooglePay.isAvailable(environment))) {
      onError('Google pay not available');
    } else {
      ///docs https://developers.google.com/pay/api/android/guides/tutorial
      google.PaymentBuilder pb = google.PaymentBuilder()
        ..addGateway(gateway, merchantID)
        ..addTransactionInfo(amount.toString(), currency)
        ..addAllowedCardAuthMethods(["PAN_ONLY", "CRYPTOGRAM_3DS"])
        ..addAllowedCardNetworks(["MASTERCARD", "VISA"])
        ..addPhoneNumberRequired(false)
        ..addShippingAddressRequired(false);

//      {apiVersionMinor: 0, apiVersion: 2, paymentMethodData: {description: Mastercard •••• 3114, tokenizationData: {type: PAYMENT_GATEWAY, token: {"signature":"MEYCIQDUuydG/LCRcx0Q7wHkBk3oUizILq7GUp0Y1ixiZpCSdgIhAIL3FrG/abgXQv1dkbf6KneSRYjS/bUmlcjIAgLDp6VT","intermediateSigningKey":{"signedKey":"{\"keyValue\":\"MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEpVN2MldstOzObzAt152Qe6dLh5B5Z62Dr6IihJJ/c3NDa2P9c6Tjd7PkmDw9dDcBB4IE9SCCuSSqPGqUKNQywg\\u003d\\u003d\",\"keyExpiration\":\"1589000899946\"}","signatures":["MEUCIHtWcoM31dOWtcGWS+11n4dVR2m/eHI1iSZRD+cAmBxPAiEAitoJROGhqVZErlzLbfjI7spV5RVG7UgXcgSuqE/2mDA\u003d"]},"protocolVersion":"ECv2","signedMessage":"{\"encryptedMessage\":\"0mZ6t+4tn9y8v11n2EqmIljoLzP5aGVUeHPz/o4VM8UGAZjeSoJ4QrN/KlnSNanNLdTnUNVhkW5QrOSrAIkQLgzAGdU7q8QtacgMOkHvwHS+Sauf5w/gA1ux5wbxlZSF2Vj4zggtJQZlZxnvNTbnW3tX4g1w0TUG/grA1nfWqXKxBm0I73yeC+jY1inNkuV++W6cJ/oMp1nX5qxdaustSNszDWAGTSWZX4S2rPhg3jPA5cR93mbKmEmegkr7B4/D2u4iLhrsp9f50u3KQ7UL+mLct2pY2GuvjMa28Y42KrN9ETPiseFqb4pTTUycnbL2IuTPYzQqWe86QADVbVL2g
      google.GooglePay.makePayment(pb.build())
          .then((google.Result result) async {
        if (result.status == google.ResultStatus.SUCCESS) {
          bool request = await proccessing(result.data.toString(), orderId);
          if (request)
            onSuccess('Success');
          else
            onError('Something wrong'); //todo proceed client response
        } else if (result.error != null) {
          onError(result.error);
        }
      }).catchError((error) {
        //TODO
      });
    }
  }
}

Future<void> makeApplePayment({
  String appleMerchantID,
  String merchantName,
  String countryCode = 'UA',
  String currencyCode = 'UAH',
  String orderId,
  List<Map> items,
  Future<bool> proccessing(String data,String orderId),
}) async {
  if (Platform.isIOS) {
    bool paymentResult = false;
    apple.ApplePay p = apple.ApplePay();

    try {
      paymentResult = await p.makePayment(
          orderId: orderId,
          countryCode: countryCode,
          currencyCode: currencyCode,
          paymentNetworks: [
            apple.PaymentNetwork.visa,
            apple.PaymentNetwork.mastercard
          ],
          merchantIdentifier: appleMerchantID,
          merchantName: merchantName,
          paymentItems: items
              .map<apple.PaymentItem>((item) => apple.PaymentItem(
                  label: item['label'], amount: item['amount']))
              .toList(),
          proceedPayment: proccessing);
      return paymentResult;
    } on PlatformException {
      print('Failed to get platform version.');
    }
  }
}
