//
//  OLOidcConfig.swift
//  ios-oidc
//
//  Created by Dominik Thalmann on 30.12.19.
//  Copyright © 2019 OneLogin. All rights reserved.
//

import Foundation

public class OLOidcConfig: NSObject, Codable {

    @objc public static let stdConfigName = "OL-Oidc"
    @objc public let clientId: String
    @objc public let issuer: String
    @objc public let redirectUri: URL
    @objc private let scopes: String
    @objc public let loginUrl: URL?

    @objc public static func standard() throws -> OLOidcConfig {
        return try OLOidcConfig(plist: stdConfigName)
    }
    
    @objc public init(dict: [String: String]) throws {
        guard let clientId = dict["clientId"], clientId.count > 0,
              let issuer = dict["issuer"],
              let _ = URL(string: issuer),
              let redirectUriString = dict["redirectUri"],
              let redirectUri = URL(string: redirectUriString),
              let scopes = dict["scopes"], scopes.contains("openid")
               else {
                throw OLOidcError.configInvalid
        }
        
        self.clientId = clientId
        self.issuer = issuer
        self.redirectUri = redirectUri
        self.scopes = scopes
        self.loginUrl = nil
    }
    
    @objc public convenience init(plist: String) throws {
        guard let path = Bundle.main.url(forResource: plist, withExtension: "plist") else {
            throw OLOidcError.configFileNotFound
        }
        
        guard let data = try? Data(contentsOf: path),
            let plistContent = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
            let configDict = plistContent as? [String: String] else {
                throw OLOidcError.configFileParseFailure
        }
        
        try self.init(dict: configDict)
    }
    
    @objc public func getScopes() -> [String] {
        return self.scopes.components(separatedBy: " ")
    }
    
}
