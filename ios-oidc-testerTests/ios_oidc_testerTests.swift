//
//  ios_oidc_testerTests.swift
//  ios-oidc-testerTests
//
//  Created by Dominik Thalmann on 30.12.19.
//  Copyright © 2019 OneLogin. All rights reserved.
//

import XCTest
import OLOidc
@testable import ios_oidc_swift_tester

class ios_oidc_testerTests: XCTestCase {

    var olOidc : OLOidc?
    var olOidcConfigValid: Dictionary<String, String>?
    var olOidcConfigValidAdditionalParam: Dictionary<String, String>?
    var olOidcConfigScopesMissing: Dictionary<String, String>?
    var olOidcConfigWrongScopes: Dictionary<String, String>?
    var olOidcConfig: OLOidcConfig?
    let testIssuer = "testIssuer"
    let testId = "123"
    let redirectUri = "com.test://callback"
    let scopes = "openid, profile"
    var oidAuthStateTest: OIDAuthState?
    
    override func setUp() {
        olOidcConfigValid = [
            "issuer": testIssuer,
            "clientId": testId,
            "redirectUri": redirectUri,
            "scopes": scopes,
        ]
        olOidcConfigValidAdditionalParam = [
            "issuer": testIssuer,
            "clientId": testId,
            "redirectUri": redirectUri,
            "scopes": scopes,
            "myAdditionalParam": "testParam"
        ]
        olOidcConfigScopesMissing = [
            "issuer": testIssuer,
            "clientId": testId,
            "redirectUri": redirectUri,
        ]
        olOidcConfigWrongScopes = [
            "issuer": testIssuer,
            "clientId": testId,
            "redirectUri": redirectUri,
            "scopes": "opend"
        ]
        
        oidAuthStateTest = OIDAuthState(registrationResponse: OIDRegistrationResponse.init(request: OIDRegistrationRequest(configuration: OIDServiceConfiguration(authorizationEndpoint: URL(string: "https://test")!, tokenEndpoint: URL(string: "https://test")!), redirectURIs: [URL(string: "https://test")!], responseTypes: nil, grantTypes: nil, subjectType: nil, tokenEndpointAuthMethod: nil, additionalParameters: nil), parameters: ["test": NSDictionary()]))
    }

    override func tearDown() {
    }

    func testOLOidcConfig() {
        do {
            try olOidcConfig = OLOidcConfig(dict: olOidcConfigValid!)
        } catch {
            XCTFail()
        }
        
        XCTAssert(olOidcConfig != nil)
        XCTAssert(olOidcConfig?.issuer == testIssuer)
        XCTAssert(olOidcConfig?.clientId == testId)
        XCTAssert(olOidcConfig?.redirectUri.absoluteString == redirectUri)
        XCTAssert(olOidcConfig?.getScopes().count == 2)
    }
    
    func testOLoidcInitialization() {
        do {
            try olOidcConfig = OLOidcConfig(dict: olOidcConfigValid!)
        } catch {
            XCTFail()
        }
        
        olOidc = try! OLOidc(configuration: olOidcConfig, useSecureStorage: false)
        XCTAssert(olOidc?.oidcConfig.issuer == testIssuer)
    }
    
    func testAdditionalParameters() {
        do {
            try olOidcConfig = OLOidcConfig(dict: olOidcConfigValidAdditionalParam!)
        } catch {
            XCTFail()
        }
        
        olOidc = try! OLOidc(configuration: olOidcConfig, useSecureStorage: false)
        XCTAssert(olOidc?.oidcConfig.additionalParameters?.count == 1)
        let param = olOidc?.oidcConfig.additionalParameters?.first
        XCTAssert(param?.key == "myAdditionalParam")
        XCTAssert(param?.value == "testParam")
    }
    
    func testScopesMissing() {
        XCTAssertThrowsError(try olOidcConfig = OLOidcConfig(dict: olOidcConfigScopesMissing!)) { error in
            XCTAssertEqual(error as! OLOidcError, OLOidcError.configInvalid)
        }
        
    }
    
    func testWrongScopes() {
        XCTAssertThrowsError(try olOidcConfig = OLOidcConfig(dict: olOidcConfigWrongScopes!)) { error in
            XCTAssertEqual(error as! OLOidcError, OLOidcError.configInvalid)
        }
    }
    
    func testKeychain() {
        do {
            try olOidcConfig = OLOidcConfig(dict: olOidcConfigValid!)
        } catch {
            XCTFail()
        }
        olOidc = try! OLOidc(configuration: olOidcConfig, useSecureStorage: false)
        olOidc?.olAuthState.authState = oidAuthStateTest
        olOidc?.olAuthState.writeToKeychain()
        
        let authState = olOidc?.olAuthState.readFromKeychain()
        XCTAssert(authState != nil)
        
    }
}
