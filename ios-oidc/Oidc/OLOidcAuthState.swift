//
//  OLOidcAuthState.swift
//  ios-oidc
//
//  Created by Dominik Thalmann on 30.12.19.
//  Copyright © 2019 OneLogin. All rights reserved.
//

import Foundation

open class OLOidcAuthState: NSObject {
    
    private let useSecureStorage: Bool
    private static let storagePrefix = "ol-oidc-authState-"
    @objc open var authState: OIDAuthState? {
        didSet {
            if (useSecureStorage) {writeToKeychain()}
        }
    }
    @objc open var configuration: OIDServiceDiscovery?
    private let clientId: String
    @objc open var accessibility : CFString
    @objc open var accessToken: String? {
        get {return authState?.lastTokenResponse?.accessToken}
    }
    @objc open var idToken: String? {
        get {return authState?.lastTokenResponse?.idToken}
    }
    @objc open var idTokenParsed: OIDIDToken? {
        get {return OIDIDToken(idTokenString: authState?.lastTokenResponse?.idToken ?? "")}
    }
    @objc open var refreshToken: String? {
        get {return authState?.lastTokenResponse?.refreshToken}
    }
    @objc open var endSessionEndpoint: URL? {
        get {return authState?.lastAuthorizationResponse.request.configuration.discoveryDocument?.endSessionEndpoint}
    }
    @objc open var tokenEndpoint: URL? {
        get {return authState?.lastAuthorizationResponse.request.configuration.discoveryDocument?.tokenEndpoint}
    }
    @objc open var userInfoEndpoint: URL? {
        get {return authState?.lastAuthorizationResponse.request.configuration.discoveryDocument?.userinfoEndpoint}
    }
    
    @objc public init(oidcConfig: OLOidcConfig, useSecureStorage: Bool = true, accessibility: CFString = kSecAttrAccessibleWhenUnlockedThisDeviceOnly) {
        self.accessibility = accessibility
        self.clientId = oidcConfig.clientId
        self.useSecureStorage = useSecureStorage
        self.authState = useSecureStorage ? OLOidcAuthState.readFromKeychain(key: OLOidcAuthState.getStorageKey(clientId: clientId)) : nil
    }
    
    private static func getStorageKey(clientId: String) -> String {
        return storagePrefix + clientId
    }
    
    @objc public func readFromKeychain() -> OIDAuthState? {
        return OLOidcAuthState.readFromKeychain(key: OLOidcAuthState.getStorageKey(clientId: clientId))
    }
    
    private class func readFromKeychain(key: String) -> OIDAuthState? {
        guard let encodedState: Data = try? OLOidcKeychain.get(key: key) else {
            return nil
        }

        // Deserialize
        guard let savedState = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(encodedState) as? OIDAuthState
         else {
            return nil
        }

        return savedState
    }
    
    @objc public func writeToKeychain() {
        if let authState = authState {
            // Serialize
            let authStateData = try! NSKeyedArchiver.archivedData(withRootObject: authState, requiringSecureCoding: false)
            do {
                try OLOidcKeychain.set(
                    key: OLOidcAuthState.getStorageKey(clientId: clientId),
                    data: authStateData,
                    accessibility: self.accessibility
                )
            } catch let error {
                print("Error: \(error)")
            }
        } else {
            deleteFromKeychain()
        }
    }
    
    @objc public func deleteFromKeychain() {
        try? OLOidcKeychain.remove(key: OLOidcAuthState.getStorageKey(clientId: clientId))
    }
}
