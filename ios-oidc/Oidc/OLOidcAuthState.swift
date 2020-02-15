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
    private let storagePrefix = "ol-oidc-authState-"
    @objc open var authState: OIDAuthState? {
        didSet {
            if (useSecureStorage) {writeToKeychain()}
        }
    }
    @objc open var configuration: OIDServiceDiscovery?
    private let clientId: String
    open var accessibility : CFString
    open var accessToken: String? {
        get {return authState?.lastTokenResponse?.accessToken}
    }
    open var idToken: String? {
        get {return authState?.lastTokenResponse?.idToken}
    }
    open var refreshToken: String? {
        get {return authState?.lastTokenResponse?.refreshToken}
    }
    
    public init(oidcConfig: OLOidcConfig, useSecureStorage: Bool = true, accessibility: CFString = kSecAttrAccessibleWhenUnlockedThisDeviceOnly) {
        self.accessibility = accessibility
        self.clientId = oidcConfig.clientId
        self.useSecureStorage = useSecureStorage
        self.authState = useSecureStorage ? OLOidcAuthState.readFromKeychain(key: clientId) : nil
    }
    
    private func getStorageKey() -> String {
        return storagePrefix + clientId
    }
    
    public func readFromKeychain() -> OIDAuthState? {
        return OLOidcAuthState.readFromKeychain(key: getStorageKey())
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
    
    public func writeToKeychain() {
        if let authState = authState {
            // Serialize
            let authStateData = try! NSKeyedArchiver.archivedData(withRootObject: authState, requiringSecureCoding: false)
            do {
                try OLOidcKeychain.set(
                    key: getStorageKey(),
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
    
    public func deleteFromKeychain() {
        try? OLOidcKeychain.remove(key: getStorageKey())
    }
}
