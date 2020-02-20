//
//  OLOidcKeychain.swift
//  ios-oidc
//
//  Created by Dominik Thalmann on 30.12.19.
//  Copyright © 2019 OneLogin. All rights reserved.
//

import Foundation

public enum OLKeychainError: Error {
    case wrongFormat
    case failed(String)
    case itemNotFound
}

public class OLOidcKeychain : NSObject {
    
    private class func addItemDict(data: Data, key: String, accessibility: CFString? = nil, accessGroup: String? = nil) -> CFDictionary {
        var query = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecValueData as String: data,
            kSecAttrAccount as String: key,
            kSecAttrAccessible as String: accessibility ?? kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ] as [String : Any]
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        return query as CFDictionary
    }
    
    private class func getItemDict(key: String) -> CFDictionary {
        let query = [
            kSecClass as String: kSecClassGenericPassword,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecAttrAccount as String: key
        ] as CFDictionary
        return query
    }
    
    private class func deleteItemDict(data: Data, key: String) -> CFDictionary {
        let query = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecValueData as String: data,
            kSecAttrAccount as String: key
        ] as CFDictionary
        return query
    }
    
    public class func set(key: String, value: String, accessGroup: String? = nil, accessibility: CFString? = nil) throws {
        guard let objectData = value.data(using: .utf8) else {
            throw OLKeychainError.wrongFormat
        }
        try set(key: key, data: objectData, accessGroup: accessGroup, accessibility: accessibility)
    }
    
    public class func set(key: String, data: Data, accessGroup: String? = nil, accessibility: CFString? = nil) throws {
        
        let queryDict = addItemDict(data: data, key: key, accessibility: accessibility, accessGroup: accessGroup)
        
        // Delete if already exists
        SecItemDelete(queryDict)
        
        let success = SecItemAdd(queryDict, nil)
        if success != noErr {
            throw OLKeychainError.failed(success.description)
        }
    }
    
    public class func get(key: String) throws -> String {
        let data: Data = try get(key: key)
        guard let string = String(data: data, encoding: .utf8) else {
            throw OLKeychainError.wrongFormat
        }
        return string
    }
    
    public class func get(key: String) throws -> Data {
        
        let queryDict = getItemDict(key: key)
        var ref: AnyObject? = nil
        
        let success = SecItemCopyMatching(queryDict, &ref)
        guard success == noErr else {
            if success == errSecItemNotFound {
                throw OLKeychainError.itemNotFound
            } else {
                throw OLKeychainError.failed(success.description)
            }
        }
        guard let data = ref as? Data else {
            throw OLKeychainError.failed("No data found for \(key)")
        }
        return data
    }
    
    public class func remove(key: String) throws {
        let data: Data = try get(key: key)
        let queryDict = deleteItemDict(data: data, key: key)
        
        // Delete item
        let success = SecItemDelete(queryDict)
        guard success == noErr else {
            throw OLKeychainError.failed(success.description)
        }
    }
    
}
