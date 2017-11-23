/**
 * Copyright (C) 2017 HAT Data Exchange Ltd
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

/// The location data plug service class
public struct HATLocationService {
    
    // MARK: - Create location plug URL
    
    /**
     Register with HAT url
     
     - parameter userHATDomain: The user's hat domain
     - returns: HATRegistrationURLAlias, can return empty string
     */
    public static func locationDataPlugURL(_ userHATDomain: String, dataPlugID: String) -> String {
        
        if let escapedUserHATDomain: String = userHATDomain.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) {
            
            return "https://dex.hubofallthings.com/api/dataplugs/\(dataPlugID)/connect?hat=\(escapedUserHATDomain)"
        }
        
        return ""
    }
    
    // MARK: - Enable locations
    
    /**
     Registers app to write on HAT
     
     - parameter userDomain: The user's domain
     - parameter HATDomainFromToken: The HAT domain from token
     - parameter viewController: The UIViewController that calls this method
     */
    public static func enableLocationDataPlug(_ userDomain: String, _ HATDomainFromToken: String, success: @escaping (Bool) -> Void, failed: @escaping (JSONParsingError) -> Void) {
        
        // parameters..
        let parameters: Dictionary<String, String> = [:]
        
        // auth header
        let headers: [String : String] = ["Accept": ContentType.JSON,
                                          "Content-Type": ContentType.JSON,
                                          RequestHeaders.xAuthToken: HATDataPlugCredentials.locationDataPlugToken]
        // construct url
        let url = HATLocationService.locationDataPlugURL(userDomain, dataPlugID: HATDataPlugCredentials.dataPlugID)
        
        // make asynchronous call
        HATNetworkHelper.asynchronousRequest(url, method: HTTPMethod.get, encoding: Alamofire.URLEncoding.default, contentType: "application/json", parameters: parameters, headers: headers) { (response: HATNetworkHelper.ResultType) -> Void in
            
            switch response {
            case .isSuccess(let isSuccess, let statusCode, let result, _):
                
                if isSuccess {
                    
                    // belt and braces.. check we have a message in the returned JSON
                    if result["message"].exists() {
                        
                        // save the hatdomain from the token to the device Keychain
                        success(true)
                        // No message field in JSON file
                    } else {
                        
                        failed(.expectedFieldNotFound)
                    }
                    // general error
                } else {
                    
                    failed(.generalError(isSuccess.description, statusCode, nil))
                }
                
            case .error(let error, let statusCode):
                
                //show error
                if error.localizedDescription == "The request timed out." {
                    
                    failed(.noInternetConnection)
                } else {
                    
                    let message = NSLocalizedString("Server responded with error", comment: "")
                    failed(.generalError(message, statusCode, error))
                }
            }
        }
    }
    
    // MARK: - Get Locations
    
    public static func getLocationsV2(userDomain: String, userToken: String, fromDate: Date, toDate: Date, successCallback: @escaping ([HATLocationsV2Object], String?) -> Void, errorCallback: @escaping (HATTableError) -> Void ) {
        
        func receivedLocations(json: [JSON], newUserToken: String?) {
            
            // if we have values return them
            if !json.isEmpty {
                
                var arrayToReturn: [HATLocationsV2Object] = []
                
                for item in json {
                    
                    if let object: HATLocationsV2Object = HATLocationsV2Object.decode(from: item.dictionaryValue) {
                        
                        arrayToReturn.append(object)
                    } else {
                        
                        print("error parsing json")
                    }
                }
                
                successCallback(arrayToReturn, newUserToken)
            } else {
                
                errorCallback(.noValuesFound)
            }
        }
        
        func locationsReceived(error: HATTableError) {
            
            errorCallback(error)
        }
        
        HATAccountService.getHatTableValuesv2(
            token: userToken,
            userDomain: userDomain,
            namespace: "rumpel",
            scope: "locations/ios",
            parameters: [:],
            successCallback: receivedLocations,
            errorCallback: locationsReceived)
    }
    
    public static func pushLocationsV2(userDomain: String, userToken: String, locations: [HATLocationsV2DataObject], successCallback: @escaping ([HATLocationsV2Object], String?) -> Void, errorCallback: @escaping (HATTableError) -> Void ) {
        
        //        guard let json = HATLocationsV2DataObject.encode(from: locations) else {
        //
        //            return
        //        }
        //
        //        HATAccountService.createTableValuev2(
        //            token: userToken,
        //            userDomain: userDomain,
        //            source: "rumpel",
        //            dataPath: "ios/locations",
        //            parameters: json,
        //            successCallback: { (json, newToken) in
        //
        //                guard let locations: HATLocationsV2Object = HATLocationsV2Object.decode(from: json.dictionaryValue) else {
        //
        //                    errorCallback(.noValuesFound)
        //                    return
        //                }
        //                successCallback([locations], newToken)
        //        },
        //            errorCallback: errorCallback
        //        )
    }
}
