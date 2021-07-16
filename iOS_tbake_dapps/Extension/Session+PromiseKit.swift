// Copyright © 2020 Stormbird PTE. LTD.

import Foundation
import APIKit
import JSONRPCKit
import PromiseKit

extension Session {
    private class func sendImpl<Request: APIKit.Request>(_ request: Request, callbackQueue: CallbackQueue? = nil) -> Promise<Request.Response> {
        Promise { seal in
            Session.send(request, callbackQueue: callbackQueue) { result in
                switch result {
                case .success(let result):
                    seal.fulfill(result)
                case .failure(let error):
                    if let e = convertToUSerFriendlyError(error: error, baseUrl: request.baseURL) {
                        seal.reject(e)
                    } else {
                        seal.reject(error)
                    }
                }
            }
        }
    }

    class func send<Request: APIKit.Request>(_ request: Request, callbackQueue: CallbackQueue? = nil) -> Promise<Request.Response> {
        let promise = sendImpl(request, callbackQueue: callbackQueue)
        return firstly {
            promise
        }.recover { error -> Promise<Request.Response> in
            if error is SendTransactionRetryableError {
                return sendImpl(request, callbackQueue: callbackQueue)
            } else {
                return promise
            }
        }
    }

    private static func convertToUSerFriendlyError(error: SessionTaskError, baseUrl: URL) -> Error? {
        switch error {
        case .connectionError(let e):
            let message = e.localizedDescription
            if message.hasPrefix("The network connection was lost") {
                RemoteLogger.instance.logRpcOrOtherWebError("Connection Error | \(e.localizedDescription) | as: NetworkConnectionWasLostError()", url: baseUrl.absoluteString)
                return SendTransactionRetryableError.networkConnectionWasLost
            } else if message.hasPrefix("The certificate for this server is invalid") {
                RemoteLogger.instance.logRpcOrOtherWebError("Connection Error | \(e.localizedDescription) | as: InvalidCertificateError()", url: baseUrl.absoluteString)
                return SendTransactionRetryableError.invalidCertificate
            } else if message.hasPrefix("The request timed out") {
                RemoteLogger.instance.logRpcOrOtherWebError("Connection Error | \(e.localizedDescription) | as: RequestTimedOutError()", url: baseUrl.absoluteString)
                return SendTransactionRetryableError.requestTimedOut
            }
            RemoteLogger.instance.logRpcOrOtherWebError("Connection Error | \(e.localizedDescription)", url: baseUrl.absoluteString)
            return nil
        case .requestError(let e):
            RemoteLogger.instance.logRpcOrOtherWebError("Request Error | \(e.localizedDescription)", url: baseUrl.absoluteString)
            return nil
        case .responseError(let e):
            if let jsonRpcError = e as? JSONRPCError {
                switch jsonRpcError {
                case .responseError(let code, let message, _):
                    //Lowercased as RPC nodes implementation differ
                    if message.lowercased().hasPrefix("insufficient funds") {
                        return SendTransactionNotRetryableError.insufficientFunds(message: message)
                    } else if message.lowercased().hasPrefix("execution reverted") || message.lowercased().hasPrefix("vm execution error") || message.lowercased().hasPrefix("revert") {
                        return SendTransactionNotRetryableError.executionReverted(message: message)
                    } else if message.lowercased().hasPrefix("nonce too low") || message.lowercased().hasPrefix("nonce is too low") {
                        return SendTransactionNotRetryableError.nonceTooLow(message: message)
                    } else if message.lowercased().hasPrefix("transaction underpriced") {
                        return SendTransactionNotRetryableError.gasPriceTooLow(message: message)
                    } else if message.lowercased().hasPrefix("intrinsic gas too low") || message.lowercased().hasPrefix("Transaction gas is too low") {
                        return SendTransactionNotRetryableError.gasLimitTooLow(message: message)
                    } else if message.lowercased().hasPrefix("intrinsic gas exceeds gas limit") {
                        return SendTransactionNotRetryableError.gasLimitTooHigh(message: message)
                    } else if message.lowercased().hasPrefix("invalid sender") {
                        return SendTransactionNotRetryableError.possibleChainIdMismatch(message: message)
                    } else {
                        RemoteLogger.instance.logRpcOrOtherWebError("JSONRPCError.responseError | code: \(code) | message: \(message)", url: baseUrl.absoluteString)
                    }
                case .responseNotFound(_, let object):
                    RemoteLogger.instance.logRpcOrOtherWebError("JSONRPCError.responseNotFound | object: \(object)", url: baseUrl.absoluteString)
                case .resultObjectParseError(let e):
                    RemoteLogger.instance.logRpcOrOtherWebError("JSONRPCError.resultObjectParseError | error: \(e.localizedDescription)", url: baseUrl.absoluteString)
                case .errorObjectParseError(let e):
                    RemoteLogger.instance.logRpcOrOtherWebError("JSONRPCError.errorObjectParseError | error: \(e.localizedDescription)", url: baseUrl.absoluteString)
                case .unsupportedVersion(let str):
                    RemoteLogger.instance.logRpcOrOtherWebError("JSONRPCError.unsupportedVersion | str: \(String(describing: str))", url: baseUrl.absoluteString)
                case .unexpectedTypeObject(let obj):
                    RemoteLogger.instance.logRpcOrOtherWebError("JSONRPCError.unexpectedTypeObject | obj: \(obj)", url: baseUrl.absoluteString)
                case .missingBothResultAndError(let obj):
                    RemoteLogger.instance.logRpcOrOtherWebError("JSONRPCError.missingBothResultAndError | obj: \(obj)", url: baseUrl.absoluteString)
                case .nonArrayResponse(let obj):
                    RemoteLogger.instance.logRpcOrOtherWebError("JSONRPCError.nonArrayResponse | obj: \(obj)", url: baseUrl.absoluteString)
                }
                return nil
            }

            if let apiKitError = e as? APIKit.ResponseError {
                switch apiKitError {
                case .nonHTTPURLResponse:
                    RemoteLogger.instance.logRpcOrOtherWebError("APIKit.ResponseError.nonHTTPURLResponse", url: baseUrl.absoluteString)
                case .unacceptableStatusCode(let statusCode):
                    if statusCode == 429 {
                        return SendTransactionRetryableError.rateLimited
                    } else {
                        RemoteLogger.instance.logRpcOrOtherWebError("APIKit.ResponseError.unacceptableStatusCode | status: \(statusCode)", url: baseUrl.absoluteString)
                    }
                case .unexpectedObject(let obj):
                    RemoteLogger.instance.logRpcOrOtherWebError("APIKit.ResponseError.unexpectedObject | obj: \(obj)", url: baseUrl.absoluteString)
                }
                return nil
            }

            if RPCServer.binance_smart_chain_testnet.rpcURL.absoluteString == baseUrl.absoluteString, e.localizedDescription == "The data couldn’t be read because it isn’t in the correct format." {
                RemoteLogger.instance.logRpcOrOtherWebError("\(e.localizedDescription) -> PossibleBinanceTestnetTimeoutError()", url: baseUrl.absoluteString)
                //This is potentially Binance testnet timing out
                return SendTransactionRetryableError.possibleBinanceTestnetTimeout
            }

            RemoteLogger.instance.logRpcOrOtherWebError("Other Error: \(e) | \(e.localizedDescription)", url: baseUrl.absoluteString)
            return nil
        }
    }
}

extension RPCServer {
    static func serverWithRpcURL(_ string: String) -> RPCServer? {
        RPCServer.allCases.first { $0.rpcURL.absoluteString == string }
    }
}