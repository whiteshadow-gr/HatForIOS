/**
 * Copyright (C) 2018 HAT Data Exchange Ltd
 *
 * SPDX-License-Identifier: MPL2
 *
 * This file is part of the Hub of All Things project (HAT).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/
 */

import Alamofire
import SwiftyJSON

// MARK: Struct

/// A Struct about the methods concerning the user's HAT account
public struct HATAccountService {
    
    // MARK: - Get hat values from a table
    
    /**
     Gets values from a particular table in use with v2 API
     
     - parameter token: The user's token
     - parameter userDomain: The user's domain
     - parameter namespace: The namespace to read from
     - parameter scope: The scope to read from
     - parameter parameters: The parameters to pass to the request, e.g. startime, endtime, limit
     - parameter successCallback: A callback called when successful of type @escaping ([JSON], String?) -> Void
     - parameter errorCallback: A callback called when failed of type @escaping (HATTableError) -> Void)
     */
    public static func getHatTableValues(token: String, userDomain: String, namespace: String, scope: String, parameters: Dictionary<String, Any>, successCallback: @escaping ([JSON], String?) -> Void, errorCallback: @escaping (HATTableError) -> Void) {
        
        // form the url
        let url: String = "https://\(userDomain)/api/v2/data/\(namespace)/\(scope)"
        
        // create parameters and headers
        let headers: [String: String] = [RequestHeaders.xAuthToken: token]
        
        // make the request
        HATNetworkHelper.asynchronousRequest(url, method: .get, encoding: Alamofire.URLEncoding.default, contentType: ContentType.json, parameters: parameters, headers: headers, completion: { (response: HATNetworkHelper.ResultType) -> Void in
            
            switch response {
                
            case .error(let error, let statusCode):
                
                if error.localizedDescription == "The request timed out." || error.localizedDescription == "The Internet connection appears to be offline." {
                    
                    errorCallback(.noInternetConnection)
                } else {
                    
                    let message = NSLocalizedString("Server responded with error", comment: "")
                    errorCallback(.generalError(message, statusCode, error))
                }
            case .isSuccess(let isSuccess, _, let result, let token):
                
                if isSuccess {
                    
                    if let array = result.array {
                        
                        successCallback(array, token)
                    } else {
                        
                        errorCallback(.noValuesFound)
                    }
                }
            }
        })
    }
    
    // MARK: - Create value
    
    /**
     Gets values from a particular table in use with v2 API
     
     - parameter userToken: The user's token
     - parameter userDomain: The user's domain
     - parameter namespace: The namespace to read from
     - parameter scope: The scope to read from
     - parameter parameters: The parameters to pass to the request, e.g. startime, endtime, limit
     - parameter successCallback: A callback called when successful of type @escaping (JSON, String?) -> Void
     - parameter errorCallback: A callback called when failed of type @escaping (HATTableError) -> Void)
     */
    public static func createTableValue(userToken: String, userDomain: String, namespace: String, scope: String, parameters: Dictionary<String, Any>, successCallback: @escaping (JSON, String?) -> Void, errorCallback: @escaping (HATTableError) -> Void) {
        
        // form the url
        let url: String = "https://\(userDomain)/api/v2/data/\(namespace)/\(scope)"
        
        // create parameters and headers
        let headers: [String: String] = [RequestHeaders.xAuthToken: userToken]
        
        // make the request
        HATNetworkHelper.asynchronousRequest(url, method: .post, encoding: Alamofire.JSONEncoding.default, contentType: ContentType.json, parameters: parameters, headers: headers, completion: { (response: HATNetworkHelper.ResultType) -> Void in
            
            switch response {
                
            case .error(let error, let statusCode):
                
                if error.localizedDescription == "The request timed out." || error.localizedDescription == "The Internet connection appears to be offline." {
                    
                    errorCallback(.noInternetConnection)
                } else {
                    
                    let message = NSLocalizedString("Server responded with error", comment: "")
                    errorCallback(.generalError(message, statusCode, error))
                }
            case .isSuccess(let isSuccess, let statusCode, let result, let token):
                
                if isSuccess {
                    
                    successCallback(result, token)
                }
                
                if statusCode == 404 {
                    
                    errorCallback(.tableDoesNotExist)
                }
            }
        })
    }
    
    // MARK: - Delete from hat

    /**
     Deletes a record from hat using V2 API
     
     - parameter userDomain: The user's domain
     - parameter userToken: The user's token
     - parameter recordIds: The record id to delete
     - parameter success: A callback called when the request was successful of type @escaping (String) -> Void
     - parameter failed: A callback called when the request failed of type @escaping (HATTableError) -> Void
     */
    public static func deleteHatRecord(userDomain: String, userToken: String, recordIds: [String], success: @escaping (String) -> Void, failed: @ escaping (HATTableError) -> Void) {
        
        // form the url
        var url: String = "https://\(userDomain)/api/v2/data"
        
        let firstRecord: String? = recordIds.first
        url.append("?records=\(firstRecord!)")
        
        for record: String in recordIds where record != firstRecord! {
            
            url.append("&records=\(record)")
        }
        
        let headers: [String: String] = [RequestHeaders.xAuthToken: userToken]
        
        // make the request
        HATNetworkHelper.asynchronousRequest(url, method: .delete, encoding: Alamofire.URLEncoding.default, contentType: ContentType.text, parameters: [:], headers: headers, completion: { (response: HATNetworkHelper.ResultType) -> Void in
            
            // handle result
            switch response {
                
            case .isSuccess(let isSuccess, let statusCode, _, _):
                
                if isSuccess {
                    
                    success(userToken)
                    HATAccountService.triggerHatUpdate(userDomain: userDomain, completion: { () -> Void in return })
                } else {
                    
                    let message: String = NSLocalizedString("The request was unsuccesful", comment: "")
                    failed(.generalError(message, statusCode, nil))
                }
                
            case .error(let error, let statusCode):
                
                if error.localizedDescription == "The request timed out." || error.localizedDescription == "The Internet connection appears to be offline." {
                    
                    failed(.noInternetConnection)
                } else {
                    
                    let message = NSLocalizedString("Server responded with error", comment: "")
                    failed(.generalError(message, statusCode, error))
                }
            }
        })
    }
    
    // MARK: - Edit record
    
    /**
     Edits a record from hat using v2 API's
     
     - parameter userDomain: The user's domain
     - parameter userToken: The user's token
     - parameter parameters: The object to upload formatted as a Dictionary<String, Any>
     - parameter successCallback: A callback called when successful of type @escaping ([JSON], String?) -> Void
     - parameter errorCallback: A callback called when failed of type @escaping (HATTableError) -> Void
     */
    public static func updateHatRecord(userDomain: String, userToken: String, parameters: Dictionary<String, Any>, successCallback: @escaping ([JSON], String?) -> Void, errorCallback: @escaping (HATTableError) -> Void) {
        
        // form the url
        let url: String = "https://\(userDomain)/api/v2/data/"
        
        // create parameters and headers
        let headers: [String: String] = [RequestHeaders.xAuthToken: userToken]
        
        // make the request
        HATNetworkHelper.asynchronousRequest(url, method: .put, encoding: Alamofire.URLEncoding.default, contentType: ContentType.text, parameters: parameters, headers: headers, completion: { (response: HATNetworkHelper.ResultType) -> Void in
            
            // handle result
            switch response {
                
            case .error(let error, let statusCode):
                
                if error.localizedDescription == "The request timed out." || error.localizedDescription == "The Internet connection appears to be offline." {
                    
                    errorCallback(.noInternetConnection)
                } else {
                    
                    let message: String = NSLocalizedString("Server responded with error", comment: "")
                    errorCallback(.generalError(message, statusCode, error))
                }
            case .isSuccess(let isSuccess, _, let result, let token):
                
                if isSuccess {
                    
                    if let array: [JSON] = result.array {
                        
                        successCallback(array, token)
                    } else {
                        
                        errorCallback(.noValuesFound)
                    }
                }
            }
        })
    }
    
    // MARK: - Trigger an update
    
    /**
     Triggers an update to hat servers
     */
    public static func triggerHatUpdate(userDomain: String, completion: @escaping () -> Void) {
        
        // define the url to connect to
        let url: String = "https://notables.hubofallthings.com/api/bulletin/tickle"
        
        // make the request
        Alamofire.request(url, method: .get, parameters: ["phata": userDomain], encoding: Alamofire.URLEncoding.default, headers: nil).responseString { _ in
            
            completion()
        }
    }
    
    // MARK: - Get public key
    
    /**
     Constructs URL to get the public key
     
     - parameter userHATDomain: The user's HAT domain
     
     - returns: An optional String, nil if public key not found
     */
    public static func theUserHATDomainPublicKeyURL(_ userHATDomain: String) -> String? {
        
        if let escapedUserHATDomain: String = userHATDomain.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) {
            
            return "https://\(escapedUserHATDomain)/publickey"
        }
        
        return nil
    }
    
    // MARK: - Change Password
    
    /**
     Changes the user's password
     
     - parameter userDomain: The user's domain
     - parameter userToken: The user's authentication token
     - parameter oldPassword: The old password the user entered
     - parameter newPassword: The new password to change to
     - parameter successCallback: A function of type (String, String?) to call on success
     - parameter failCallback: A fuction of type (HATError) to call on fail
     */
    public static func changePassword(userDomain: String, userToken: String, oldPassword: String, newPassword: String, successCallback: @escaping (String, String?) -> Void, failCallback: @escaping (HATError) -> Void) {
        
        let url: String = "https://\(userDomain)/control/v2/auth/password"
        
        let parameters: Dictionary<String, Any> = ["password": oldPassword, "newPassword": newPassword]
        let headers: [String: String] = [RequestHeaders.xAuthToken: userToken]
        
        HATNetworkHelper.asynchronousRequest(url, method: .post, encoding: Alamofire.JSONEncoding.default, contentType: ContentType.json, parameters: parameters, headers: headers, completion: {(response: HATNetworkHelper.ResultType) -> Void in
            
            switch response {
                
            case .error(let error, let statusCode):
                
                if error.localizedDescription == "The request timed out." || error.localizedDescription == "The Internet connection appears to be offline." {
                    
                    failCallback(.noInternetConnection)
                } else {
                    
                    let message: String = NSLocalizedString("Server responded with error", comment: "")
                    failCallback(.generalError(message, statusCode, error))
                }
            case .isSuccess(let isSuccess, _, let result, let token):
                
                if isSuccess, let message = result.dictionaryValue["message"]?.stringValue {
                    
                    successCallback(message, token)
                }
            }
        })
    }
    
    // MARK: - Create Combinator
    
    /**
     Creates combinator
     
     - parameter userDomain: The user's domain
     - parameter userToken: The user's authentication token
     - parameter combinatorName: The desired combinator name
     - parameter fieldToFilter: The field to filter with
     - parameter lowerValue: The lower value of the filter
     - parameter upperValue: The upper value of the filter
     - parameter successCallback: A function of type (Bool, String?) to call on success
     - parameter failCallback: A fuction of type (HATError) to call on fail
     */
    public static func createCombinator(userDomain: String, userToken: String, combinatorName: String, fieldToFilter: String, lowerValue: Int, upperValue: Int, successCallback: @escaping (Bool, String?) -> Void, failCallback: @escaping (HATError) -> Void) {
        
        let url: String = "https://\(userDomain)/api/v2/combinator/\(combinatorName)"
        
        let bodyRequest: [BodyRequest] = [BodyRequest()]
        bodyRequest[0].filters[0].field = fieldToFilter
        bodyRequest[0].filters[0].`operator`.lower = lowerValue
        bodyRequest[0].filters[0].`operator`.upper = upperValue
        
        var urlRequest: URLRequest = URLRequest.init(url: URL(string: url)!)
        urlRequest.httpBody = BodyRequest.encode(from: bodyRequest)
        urlRequest.httpMethod = HTTPMethod.post.rawValue
        urlRequest.addValue(userToken, forHTTPHeaderField: RequestHeaders.xAuthToken)
        if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
            
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        Alamofire.request(urlRequest).responseJSON(completionHandler: { response in
            
            switch response.result {
            case .success:
                
                successCallback(true, nil)
            // in case of failure return the error but check for internet connection or unauthorised status and let the user know
            case .failure(let error):
                
                failCallback(HATError.generalError("", nil, error))
            }
        })
    }
    
    /**
     Gets the combinator data from HAT
     
     - parameter userDomain: The user's domain
     - parameter userToken: The user's authentication token
     - parameter combinatorName: The combinator name to search for
     - parameter successCallback: A function of type ([HATLocationsV2Object], String?) to call on success
     - parameter failCallback: A fuction of type (HATError) to call on fail
     */
    public static func getCombinator(userDomain: String, userToken: String, combinatorName: String, successCallback: @escaping ([JSON], String?) -> Void, failCallback: @escaping (HATError) -> Void) {
        
        let url: String = "https://\(userDomain)/api/v2/combinator/\(combinatorName)"
        
        let headers: [String: String] = [RequestHeaders.xAuthToken: userToken]
        
        HATNetworkHelper.asynchronousRequest(
            url,
            method: .get,
            encoding: Alamofire.JSONEncoding.default,
            contentType: ContentType.json,
            parameters: [:],
            headers: headers,
            completion: {(response: HATNetworkHelper.ResultType) -> Void in
                
                switch response {
                    
                case .error(let error, let statusCode):
                    
                    if error.localizedDescription == "The request timed out." || error.localizedDescription == "The Internet connection appears to be offline." {
                        
                        failCallback(.noInternetConnection)
                    } else {
                        
                        let message: String = NSLocalizedString("Server responded with error", comment: "")
                        failCallback(.generalError(message, statusCode, error))
                    }
                case .isSuccess(let isSuccess, _, let result, let token):
                    
                    if isSuccess, let array: [JSON] = result.array {
                        
                        var arrayToReturn: [HATLocationsObject] = []
                        for item: JSON in array {
                            
                            if let object: HATLocationsObject = HATLocationsObject.decode(from: item.dictionaryValue) {
                                
                                arrayToReturn.append(object)
                            }
                        }
                        
                        successCallback(array, token)
                    }
                }
            }
        )
    }
}

/// The operator JSON format
private class Operator: HATObject {
    
    var `operator`: String = "between"
    var lower: Int = 0
    var upper: Int = 0
}
/// The filter JSON format
private class Filter: HATObject {
    
    var field: String = ""
    var `operator`: Operator = Operator()
}
/// The combinator JSON format
private class BodyRequest: HATObject {
    
    var endpoint: String = "rumpel/locations/ios"
    var filters: [Filter] = [Filter()]
}
