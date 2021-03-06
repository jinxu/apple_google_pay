import Flutter
import UIKit
import Foundation
import PassKit
//import Cloudipsp


//SwiftPaymentprocessingPlugin

typealias AuthorizationCompletion = (_ payment: String) -> Void
typealias AuthorizationViewControllerDidFinish = (_ error : NSDictionary) -> Void
@available(iOS 11.0, *)
typealias CompletionHandler = (PKPaymentAuthorizationResult) -> Void


@available(iOS 11.0, *)

@available(iOS 11.0, *)
public class SwiftApplegooglepayPlugin: NSObject, FlutterPlugin, PKPaymentAuthorizationViewControllerDelegate {
    var authorizationCompletion : AuthorizationCompletion!
        var authorizationViewControllerDidFinish : AuthorizationViewControllerDidFinish!
        var pkrequest = PKPaymentRequest()
        var flutterResult: FlutterResult!;
        var completionHandler: CompletionHandler!
        
        
    

    
    private func setUpWebView() {
        guard let currentViewController = UIApplication.shared.keyWindow?.topMostViewController() else {
            return
        }
        
        let webViewFrame = CGRect(x: 0, y: 64, width: currentViewController.view.bounds.size.width, height: currentViewController.view.bounds.size.height - 66)
        
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        
        let channel = FlutterMethodChannel(name: "apple_google_pay", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(SwiftApplegooglepayPlugin(), channel: channel)
    }
    
    @available(iOS 11.0, *)
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        flutterResult = result;
        if call.method == "authorizePayment" {
            
            let parameters = NSMutableDictionary()
            var payments: [PKPaymentNetwork] = []
            var items = [PKPaymentSummaryItem]()
            var totalPrice:Double = 0.0
            let arguments = call.arguments as! NSDictionary
            
            guard let paymentNeworks = arguments["paymentNetworks"] as? [String] else {return}
            guard let countryCode = arguments["countryCode"] as? String else {return}
            guard let currencyCode = arguments["currencyCode"] as? String else {return}
            guard let paymentItems = arguments["paymentItems"] as? [NSDictionary] else {return}
            guard let merchantIdentifier = arguments["merchantIdentifier"] as? String else {return}
            guard let merchantName = arguments["merchantName"] as? String else {return}
            guard let isPending = arguments["isPending"] as? Bool else {return}
            
            
            let type = isPending ? PKPaymentSummaryItemType.pending : PKPaymentSummaryItemType.final;
            
            for dictionary in paymentItems {
                guard let label = dictionary["label"] as? String else {return}
                guard let price = dictionary["amount"] as? Double else {return}

                totalPrice += price
                items.append(PKPaymentSummaryItem(label: label, amount: NSDecimalNumber(floatLiteral: price), type: type))
            }
                        
            let total = PKPaymentSummaryItem(label: merchantName, amount: NSDecimalNumber(floatLiteral:totalPrice), type: type)
            items.append(total)
            
            paymentNeworks.forEach {
                
                guard let paymentType = PaymentSystem(rawValue: $0) else {
                    assertionFailure("No payment type found")
                    return
                }
                payments.append(paymentType.paymentNetwork)
            }
            
            parameters["paymentNetworks"] = payments
            parameters["requiredShippingContactFields"] = [PKContactField.name, PKContactField.postalAddress] as Set
            parameters["merchantCapabilities"] = PKMerchantCapability.capability3DS // optional
            
            parameters["merchantIdentifier"] = merchantIdentifier
            parameters["countryCode"] = countryCode
            parameters["currencyCode"] = currencyCode
            
            parameters["paymentSummaryItems"] = items
            
            makePaymentRequest(parameters: parameters,  authCompletion: authorizationCompletion, authControllerCompletion: authorizationViewControllerDidFinish)
        }
        else if call.method == "closeApplePaySheetWithSuccess" {
            closeApplePaySheetWithSuccess()
        }
        else if call.method == "closeApplePaySheetWithError" {
            closeApplePaySheetWithError()
        }
        
        else {
            result("Flutter method not implemented on iOS")
        }
    }

    
    func authorizationCompletion(_ payment: String) {
        print(payment)
        flutterResult(payment)
    }
    
    func authorizationViewControllerDidFinish(_ error : NSDictionary) {
        flutterResult(error)
    }
    
    enum PaymentSystem: String {
        case visa
        case mastercard
        case amex
        case quicPay
        case chinaUnionPay
        case discover
        case interac
        case privateLabel
        
        var paymentNetwork: PKPaymentNetwork {
            
            switch self {
                case .mastercard: return PKPaymentNetwork.masterCard
                case .visa: return PKPaymentNetwork.visa
                case .amex: return PKPaymentNetwork.amex
                case .quicPay: return PKPaymentNetwork.quicPay
                case .chinaUnionPay: return PKPaymentNetwork.chinaUnionPay
                case .discover: return PKPaymentNetwork.discover
                case .interac: return PKPaymentNetwork.interac
                case .privateLabel: return PKPaymentNetwork.privateLabel
            }
        }
    }
    
    func makePaymentRequest(parameters: NSDictionary, authCompletion: @escaping AuthorizationCompletion, authControllerCompletion: @escaping AuthorizationViewControllerDidFinish) {
        guard let paymentNetworks               = parameters["paymentNetworks"]                 as? [PKPaymentNetwork] else {return}
        let merchantCapabilities : PKMerchantCapability = parameters["merchantCapabilities"]    as? PKMerchantCapability ?? .capability3DS
        guard let merchantIdentifier            = parameters["merchantIdentifier"]              as? String else {return}
        guard let countryCode                   = parameters["countryCode"]                     as? String else {return}
        guard let currencyCode                  = parameters["currencyCode"]                    as? String else {return}
        guard let paymentSummaryItems           = parameters["paymentSummaryItems"]             as? [PKPaymentSummaryItem] else {return}
        
        authorizationCompletion = authCompletion
        authorizationViewControllerDidFinish = authControllerCompletion

        if PKPaymentAuthorizationViewController.canMakePayments(usingNetworks: paymentNetworks) {
            pkrequest.merchantIdentifier = merchantIdentifier
            pkrequest.countryCode = countryCode
            pkrequest.currencyCode = currencyCode
            pkrequest.supportedNetworks = paymentNetworks
            pkrequest.merchantCapabilities = merchantCapabilities
            pkrequest.paymentSummaryItems = paymentSummaryItems
            
            let authorizationViewController = PKPaymentAuthorizationViewController(paymentRequest: pkrequest)
            
            if let viewController = authorizationViewController {
                viewController.delegate = self
                guard let currentViewController = UIApplication.shared.keyWindow?.topMostViewController() else {
                    return
                }
                currentViewController.present(viewController, animated: true)
            }
        } else {
            let error: NSDictionary = ["message": "User not added some cards", "code": "404"]
            
            
            let jsonData = try? JSONSerialization.data(withJSONObject: error, options: [])
            let jsonString = String(data: jsonData!, encoding: .utf8) ?? "{status:error}"
            
            self.authorizationCompletion(jsonString)
//            authControllerCompletion(error)
         }

        return
    }
    
    public func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
                
        let data: NSDictionary = ["data":  payment.token.paymentData.base64EncodedString(),
                                  "token": payment.token.transactionIdentifier,
                                  "displayName": payment.token.paymentMethod.displayName,
                                  "type":payment.token.paymentMethod.type.rawValue,
                                  "network":payment.token.paymentMethod.network?.rawValue,

                                  "status":"ok"]
        let jsonData = try? JSONSerialization.data(withJSONObject: data, options: [])
        let jsonString = String(data: jsonData!, encoding: .utf8) ?? "{status:error}"
        
        self.authorizationCompletion(jsonString)
        self.completionHandler = completion
    }
    @objc func base64forData(_ theData: Data) -> String {
        let charSet = CharacterSet.urlQueryAllowed

        let paymentString = NSString(data: theData, encoding: String.Encoding.utf8.rawValue)!.addingPercentEncoding(withAllowedCharacters: charSet)
        
        return paymentString!
    }
    
    
    public func closeApplePaySheetWithSuccess() {
        if (self.completionHandler != nil) {
            self.completionHandler(PKPaymentAuthorizationResult(status: .success, errors: nil))
        }
    }

    public func closeApplePaySheetWithError() {
        if (self.completionHandler != nil) {
            self.completionHandler(PKPaymentAuthorizationResult(status: .failure, errors: nil))
        }
    }
    
    public func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        // Dismiss the Apple Pay UI
        guard let currentViewController = UIApplication.shared.keyWindow?.topMostViewController() else {
            return
        }
        currentViewController.dismiss(animated: true, completion: nil)
        let error: NSDictionary = ["message": "User closed apple pay", "code": "400"]
        let jsonData = try? JSONSerialization.data(withJSONObject: error, options: [])
        let jsonString = String(data: jsonData!, encoding: .utf8) ?? "{status:error}"
        
        self.authorizationCompletion(jsonString)
//        authorizationViewControllerDidFinish(error)
    }
    
    func makePaymentSummaryItems(itemsParameters: Array<Dictionary <String, Any>>) -> [PKPaymentSummaryItem]? {
        var items = [PKPaymentSummaryItem]()
        var totalPrice:Decimal = 0.0
        
        for dictionary in itemsParameters {
            
            guard let label = dictionary["label"] as? String else {return nil}
            guard let amount = dictionary["amount"] as? NSDecimalNumber else {return nil}
            guard let type = dictionary["type"] as? PKPaymentSummaryItemType else {return nil}
            
            totalPrice += amount.decimalValue
            items.append(PKPaymentSummaryItem(label: label, amount: amount, type: type))
        }
        
        let total = PKPaymentSummaryItem(label: "Total", amount: NSDecimalNumber(decimal:totalPrice), type: .final)
        items.append(total)
        return items
    }
    
}

extension UIWindow {

    
    func topMostViewController() -> UIViewController? {
        guard let rootViewController = self.rootViewController else {
            return nil
        }
        return topViewController(for: rootViewController)
    }
    
    func topViewController(for rootViewController: UIViewController?) -> UIViewController? {
        guard let rootViewController = rootViewController else {
            return nil
        }
        guard let presentedViewController = rootViewController.presentedViewController else {
            return rootViewController
        }
        switch presentedViewController {
        case is UINavigationController:
            let navigationController = presentedViewController as! UINavigationController
            return topViewController(for: navigationController.viewControllers.last)
        case is UITabBarController:
            let tabBarController = presentedViewController as! UITabBarController
            return topViewController(for: tabBarController.selectedViewController)
        default:
            return topViewController(for: presentedViewController)
        }
    }
}
