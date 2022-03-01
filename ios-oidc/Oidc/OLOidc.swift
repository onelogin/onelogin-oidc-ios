//
//  OLOidc.swift
//  ios-oidc
//
//  Created by Dominik Thalmann on 30.12.19.
//  Copyright © 2019 OneLogin. All rights reserved.
//

import Foundation

@objc public enum TokenType: Int {
    case AccessToken = 0
    case RefreshToken = 1
}

public class OLOidc: NSObject {
    
    @objc public let oidcConfig: OLOidcConfig
    @objc public var olAuthState: OLOidcAuthState
    @objc public var currentAuthorizationFlow: OIDExternalUserAgentSession?
    @objc public var ephemeralSession: Bool = false
        
    @objc public init(configuration: OLOidcConfig? = nil, useSecureStorage: Bool = true) throws {
        if let config = configuration {
            oidcConfig = config
        } else {
            // load default
            oidcConfig = try OLOidcConfig.standard()
        }
        olAuthState = OLOidcAuthState(oidcConfig: oidcConfig, useSecureStorage: useSecureStorage)
    }
    
    @objc public func setEphemeralSession( ephemeral: Bool ) {
        ephemeralSession = ephemeral;
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
                                                  additionalParameters: self.oidcConfig.additionalParameters)

            let externalUserAgent = OIDExternalUserAgentIOS(presenting: presenter)
            externalUserAgent?.setEphemeralBrowsingSession( self.ephemeralSession )
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

    @objc public func deleteTokens() {
        olAuthState.authState = nil
    }
    
    @objc public func signOut(callback: @escaping ((Bool, Error?) -> Void)) {
        guard let signOutEndpoint = self.olAuthState.endSessionEndpoint else {
            callback(false, OLOidcError.endSessionEndpointUndeclared)
            return
        }
        
        self.olAuthState.authState?.performAction() { (accessToken, idToken, error) in

            if error != nil  {
                callback(false, OLOidcError.fetchingFreshTokenError(error?.localizedDescription ?? "Unknown error"))
                return
            }

            guard let idToken = idToken else {
                callback(false, OLOidcError.gettingIdTokenError)
                return
            }
            
            guard let url = URL(string: "\(signOutEndpoint.absoluteString)?id_token_hint=\(idToken)") else {
                callback(false, OLOidcError.generatingSignOutUrlError)
                return
            }

            let urlRequest = URLRequest(url: url)

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

                    if response.statusCode != 302 {
                        guard let data = data else {
                            callback(false, OLOidcError.noResponseData)
                            return
                        }
                        
                        var json: [AnyHashable: Any]?

                        do {
                            json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                        } catch {
                            callback(false, OLOidcError.jsonSerializationError)
                            return
                        }
                        
                        // server replied with an error
                        let responseText: String? = String(data: data, encoding: String.Encoding.utf8)

                        if response.statusCode == 401 {
                            // "401 Unauthorized" generally indicates there is an issue with the authorization
                            // grant. Puts OIDAuthState into an error state.
                            let oauthError = OIDErrorUtilities.resourceServerAuthorizationError(withCode: 0,
                                                                                                errorResponse: json,
                                                                                                underlyingError: error)
                            self.olAuthState.authState?.update(withAuthorizationError: oauthError)
                            callback(false, OLOidcError.authorizationError("(\(oauthError)). Response: \(responseText ?? "RESPONSE_TEXT")"))
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
    }
    
    @objc public func revokeToken(tokenType: TokenType, callback: @escaping ((Error?) -> Void)) {
        guard let tokenEndpoint = self.olAuthState.tokenEndpoint else {
            callback(OLOidcError.tokenEndpointUndeclared)
            return
        }

        var token: String?
        switch(tokenType) {
        case .AccessToken:
            token = olAuthState.accessToken
            break
        case .RefreshToken:
            token = olAuthState.refreshToken
        }
        guard let _ = token else {
            callback(OLOidcError.gettingAccessTokenError)
            return
        }
        
        Router().request(endpoint: .revoke(tokenEndpoint: tokenEndpoint, accessToken: token!, clientId: self.oidcConfig.clientId)) { (data, response, error) in
            DispatchQueue.main.async {
                guard error == nil else {
                    callback(error)
                    return
                }
                callback(nil)
            }
        }
    }
    
    @objc public func introspect(callback: @escaping ((Bool, Error?) -> Void)) {
        guard let tokenEndpoint = self.olAuthState.tokenEndpoint else {
            callback(false, OLOidcError.tokenEndpointUndeclared)
            return
        }

        guard let accessToken = olAuthState.accessToken else {
            callback(false, OLOidcError.gettingAccessTokenError)
            return
        }
        
        Router().request(endpoint: .introspect(tokenEndpoint: tokenEndpoint, accessToken: accessToken, clientId: self.oidcConfig.clientId)) { (data, response, error) in
            DispatchQueue.main.async {
                
                guard error == nil else {
                    callback(false, error)
                    return
                }

                let jsonResponse = (try? JSONSerialization.jsonObject(with: data!, options: .mutableContainers)) as? [String: Any]
                guard let isValid = jsonResponse?["active"] as? Bool else {
                    callback(false, OLOidcError.unknownError)
                    return
                }
                callback(isValid, nil)
            }
        }
    }

    @objc public func getUserInfo(callback: @escaping (([AnyHashable: Any]?, Error?) -> Void)) {
        guard let userinfoEndpoint = self.olAuthState.userInfoEndpoint else {
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
    
    @objc public func refreshAccessToken(callback: @escaping ((Error?) -> Void)) {
        olAuthState.authState?.setNeedsTokenRefresh()
        olAuthState.authState?.performAction(freshTokens: { (freshAccessToken, idToken, error) in
            if error != nil {
                callback(error)
                return
            }
            self.olAuthState.authState = self.olAuthState.authState
            callback(nil)
        })
    }
}
