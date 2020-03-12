//
//  OLOidcConfig.swift
//  ios-oidc
//
//  Created by Dominik Thalmann on 30.12.19.
//  Copyright © 2019 OneLogin. All rights reserved.
//

import Foundation

public class OLOidcConfig: NSObject, Codable {

    private static let Issuer = "issuer"
    private static let ClientId = "clientId"
    private static let RedirectUri = "redirectUri"
    private static let Scopes = "scopes"
    private static let ScopeOpenId = "openid"
    private static let requiredParams = [Issuer, ClientId, RedirectUri, Scopes]
    
    @objc public static let stdConfigName = "OL-Oidc"
    @objc public let clientId: String
    @objc public let issuer: String
    @objc public let redirectUri: URL
    @objc private let scopes: String
    @objc public let loginUrl: URL?
    @objc public let additionalParameters: [String:String]?

    @objc public static func standard() throws -> OLOidcConfig {
        return try OLOidcConfig(plist: stdConfigName)
    }
    
    @objc public init(dict: [String: String]) throws {
        guard let clientId = dict[OLOidcConfig.ClientId], clientId.count > 0,
            let issuer = dict[OLOidcConfig.Issuer],
              let _ = URL(string: issuer),
              let redirectUriString = dict[OLOidcConfig.RedirectUri],
              let redirectUri = URL(string: redirectUriString),
              let scopes = dict[OLOidcConfig.Scopes], scopes.contains(OLOidcConfig.ScopeOpenId)
               else {
                throw OLOidcError.configInvalid
        }
        
        self.clientId = clientId
        self.issuer = issuer
        self.redirectUri = redirectUri
        self.scopes = scopes
        self.loginUrl = nil
        self.additionalParameters = OLOidcConfig.getAdditionalParameters(dict: dict)
    }
    
    private static func getAdditionalParameters(dict: [String: String]) -> [String: String]? {
        // cut out required parameters
        var additionalParams = dict
        for param in requiredParams {
            additionalParams.removeValue(forKey: param)
        }
        return additionalParams.count > 0 ? additionalParams : nil
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
