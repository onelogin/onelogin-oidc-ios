//
//  OLOidc.swift
//  ios-oidc
//
//  Created by Dominik Thalmann on 30.12.19.
//  Copyright © 2019 OneLogin. All rights reserved.
//

import Foundation

public class OLOidc: NSObject {
    
    @objc public let oidcConfig: OLOidcConfig
    public var olAuthState: OLOidcAuthState
    public var currentAuthorizationFlow: OIDExternalUserAgentSession?
    
    @objc public init(configuration: OLOidcConfig? = nil, useSecureStorage: Bool = true) throws {
        if let config = configuration {
            oidcConfig = config
        } else {
            // load default
            oidcConfig = try OLOidcConfig.standard()
        }
        olAuthState = OLOidcAuthState(oidcConfig: oidcConfig, useSecureStorage: useSecureStorage)
    }
    
    @objc public func signIn(presenter: UIViewController, callback: @escaping ((Error?) -> Void)) {
        
        let issuer = URL(string: oidcConfig.issuer)!

        // discovers endpoints
        OIDAuthorizationService.discoverConfiguration(forIssuer: issuer) { configuration, error in
            guard configuration != nil else {
            print("Error retrieving discovery document: \(error?.localizedDescription ?? "Unknown error")")
                callback(error)
            return
          }

            // perform the auth request...
            let request = OIDAuthorizationRequest(configuration: configuration!,
                                                  clientId: self.oidcConfig.clientId,
                                                  clientSecret: nil,
                                                  scopes: self.oidcConfig.getScopes(),
                                                  redirectURL: self.oidcConfig.redirectUri,
                                                  responseType: OIDResponseTypeCode,
                                                  additionalParameters: nil)

            let externalUserAgent = OIDExternalUserAgentIOS(presenting: presenter)
            self.currentAuthorizationFlow = OIDAuthState.authState(byPresenting: request, externalUserAgent: externalUserAgent!) { (authState, error) in
                if let authState = authState {
                    self.olAuthState.authState = authState
                    callback(nil)
                } else {
                    self.olAuthState.authState = nil
                    callback(error)
                }
            }
        }
        
        
    }

    @objc public func endLocalSession() {
        olAuthState.authState = nil
    }
    
    @objc public func signOut(callback: @escaping ((Error?) -> Void)) {
        guard let tokenEndpoint = self.olAuthState.authState?.lastAuthorizationResponse.request.configuration.discoveryDocument?.tokenEndpoint else {
            callback(OLOidcError.tokenEndpointUndeclared)
            return
        }

        self.olAuthState.authState?.performAction() { (accessToken, idToken, error) in

            if error != nil  {
                callback(OLOidcError.fetchingFreshTokenError(error?.localizedDescription ?? "Unknown error"))
                return
            }

            guard let accessToken = accessToken else {
                callback(OLOidcError.gettingAccessTokenError)
                return
            }
            
            let body: [String: Any] = ["token": accessToken,
                                       "token_type_hint": "access_token"]
            let bodyData = try? JSONSerialization.data(withJSONObject: body)
            
            let revocationEndpoint = tokenEndpoint.appendingPathComponent("revocation")
            var urlRequest = URLRequest(url: revocationEndpoint)
            urlRequest.allHTTPHeaderFields = ["Content-Type": "application/x-www-form-urlencoded"
                                                ,"Authorization":"none"
                                             ]
            urlRequest.httpMethod = "post"
            urlRequest.httpBody = bodyData
            let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in

                DispatchQueue.main.async {
                    
                    guard error == nil else {
                        callback(OLOidcError.httpRequestFailed(error?.localizedDescription ?? "Unknown error"))
                        return
                    }

                    guard let response = response as? HTTPURLResponse else {
                        callback(OLOidcError.nonHttpResponse)
                        return
                    }

                    guard let data = data else {
                        callback(OLOidcError.noResponseData)
                        return
                    }

                    if response.statusCode != 200 {
                        // server replied with an error
                        let responseText: String? = String(data: data, encoding: String.Encoding.utf8)
                        if response.statusCode == 401 {
                            callback(OLOidcError.authorizationError("(Response: \(responseText ?? "RESPONSE_TEXT")"))
                        } else {
                            callback(OLOidcError.authorizationError("(\(response.statusCode)). Response: \(responseText ?? "RESPONSE_TEXT")"))
                        }

                        return
                    }

                    callback(nil)
                }
            }

            task.resume()
        }
    }
    
    @objc public func introspect(callback: @escaping ((Bool, Error?) -> Void)) {
        guard let tokenEndpoint = self.olAuthState.authState?.lastAuthorizationResponse.request.configuration.discoveryDocument?.tokenEndpoint else {
            callback(false, OLOidcError.tokenEndpointUndeclared)
            return
        }

        guard let accessToken = olAuthState.accessToken else {
            callback(false, OLOidcError.gettingAccessTokenError)
            return
        }
        
        let body: [String: Any] = ["token": accessToken,
                                   "token_type_hint": "access_token",
                                   "client_id": oidcConfig.clientId]
        let bodyData = try? JSONSerialization.data(withJSONObject: body)
        
        let introspectionEndpoint = tokenEndpoint.appendingPathComponent("introspection")
        var urlRequest = URLRequest(url: introspectionEndpoint)
        urlRequest.allHTTPHeaderFields = ["Content-Type": "application/x-www-form-urlencoded"
                                            ,"Authorization":"none"
                                         ]
        urlRequest.httpMethod = "post"
        urlRequest.httpBody = bodyData
        let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in

            DispatchQueue.main.async {
                
                guard error == nil else {
                    callback(false, OLOidcError.httpRequestFailed(error?.localizedDescription ?? "Unknown error"))
                    return
                }

                guard let response = response as? HTTPURLResponse else {
                    callback(false, OLOidcError.nonHttpResponse)
                    return
                }

                guard let data = data else {
                    callback(false, OLOidcError.noResponseData)
                    return
                }

                if response.statusCode != 200 {
                    // server replied with an error
                    let responseText: String? = String(data: data, encoding: String.Encoding.utf8)
                    if response.statusCode == 401 {
                        callback(false, OLOidcError.authorizationError("(Response: \(responseText ?? "RESPONSE_TEXT")"))
                    } else {
                        callback(false, OLOidcError.authorizationError("(\(response.statusCode)). Response: \(responseText ?? "RESPONSE_TEXT")"))
                    }

                    return
                }

                callback(true, nil)
            }
        }

        task.resume()
    }

    @objc public func getUserInfo(callback: @escaping (([AnyHashable: Any]?, Error?) -> Void)) {
        guard let userinfoEndpoint = self.olAuthState.authState?.lastAuthorizationResponse.request.configuration.discoveryDocument?.userinfoEndpoint else {
            callback(nil, OLOidcError.userEndpointUndeclared)
            return
        }

        self.olAuthState.authState?.performAction() { (accessToken, idToken, error) in

            if error != nil  {
                callback(nil, OLOidcError.fetchingFreshTokenError(error?.localizedDescription ?? "Unknown error"))
                return
            }

            guard let accessToken = accessToken else {
                callback(nil, OLOidcError.gettingAccessTokenError)
                return
            }

            var urlRequest = URLRequest(url: userinfoEndpoint)
            urlRequest.allHTTPHeaderFields = ["Authorization":"Bearer \(accessToken)"]

            let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in

                DispatchQueue.main.async {
                    
                    guard error == nil else {
                        callback(nil, OLOidcError.httpRequestFailed(error?.localizedDescription ?? "Unknown error"))
                        return
                    }

                    guard let response = response as? HTTPURLResponse else {
                        callback(nil, OLOidcError.nonHttpResponse)
                        return
                    }

                    guard let data = data else {
                        callback(nil, OLOidcError.noResponseData)
                        return
                    }

                    var json: [AnyHashable: Any]?

                    do {
                        json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    } catch {
                        callback(nil, OLOidcError.jsonSerializationError)
                        return
                    }

                    if response.statusCode != 200 {
                        // server replied with an error
                        let responseText: String? = String(data: data, encoding: String.Encoding.utf8)

                        if response.statusCode == 401 {
                            // "401 Unauthorized" generally indicates there is an issue with the authorization
                            // grant. Puts OIDAuthState into an error state.
                            let oauthError = OIDErrorUtilities.resourceServerAuthorizationError(withCode: 0,
                                                                                                errorResponse: json,
                                                                                                underlyingError: error)
                            self.olAuthState.authState?.update(withAuthorizationError: oauthError)
                            callback(nil, OLOidcError.authorizationError("(\(oauthError)). Response: \(responseText ?? "RESPONSE_TEXT")"))
                        } else {
                            callback(nil, OLOidcError.authorizationError("(\(response.statusCode)). Response: \(responseText ?? "RESPONSE_TEXT")"))
                        }

                        return
                    }

                    if let json = json {
                        callback(json, nil)
                    }
                }
            }

            task.resume()
        }
    }
    
    func toBase64(text: String) -> String? {
        guard let data = text.data(using: String.Encoding.utf8) else {
            return nil
        }
        return data.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
    }
}
