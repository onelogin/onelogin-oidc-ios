//
//  ViewController.swift
//  ios-oidc-tester
//
//  Created by Dominik Thalmann on 30.12.19.
//  Copyright © 2019 OneLogin. All rights reserved.
//

import UIKit
import OLOidc

class ViewController: UIViewController {

    @IBOutlet weak var infoText: UITextView!
    private var olOidc: OLOidc?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        olOidc = try? OLOidc(configuration: nil)
        AppDelegate.shared.olOidc = olOidc
    }
    
    func setInfoText(text: String) {
        DispatchQueue.main.async { self.infoText.text = text }
    }

    @IBAction func btnSignInClicked(_ sender: Any) {
        olOidc?.signIn(presenter: self) { error
            in
            if let error = error {
                self.setInfoText(text: "Error: \(error)")
                return
            }
            if let accessToken = self.olOidc?.olAuthState.accessToken {
                self.setInfoText(text: "Received access token: \(accessToken)")
            }
        }
    }
    
    @IBAction func btnSignOutClicked(_ sender: Any) {
        olOidc?.signOut(presenter: self) { error in
            if let error = error {
                self.setInfoText(text: error.localizedDescription)
                return
            }
            self.setInfoText(text: "Sign out is successful")
        }
    }
    
    @IBAction func btnIntrospectClicked(_ sender: Any) {
        olOidc?.introspect(callback: { (tokenValid, error) in
            if let error = error {
                self.setInfoText(text: error.localizedDescription)
                return
            }
            let status = tokenValid ? "The token is valid" : "The token is not valid"
            self.setInfoText(text: status)
        })
    }
    
    @IBAction func btnGetUserInfoClicked(_ sender: Any) {
        olOidc?.getUserInfo(callback: { (userInfo, error) in
            if let error = error {
                self.setInfoText(text: error.localizedDescription)
                return
            }
            self.setInfoText(text: "\(String(describing: userInfo))")
        })
    }
    
    @IBAction func btnDeleteTokensClicked(_ sender: Any) {
        olOidc?.deleteTokens()
        self.setInfoText(text: "Successfully removed local tokens from the keychain")
    }
    
    @IBAction func btnRevokeAccessTokenClicked(_ sender: Any) {
        olOidc?.revokeToken(tokenType: .AccessToken, callback: { (error) in
            if let error = error {
                self.setInfoText(text: error.localizedDescription)
                return
            }
            self.setInfoText(text: "Successfully revoked Access-Token")
        })
    }
    
    @IBAction func btnRevokeRefreshTokenClicked(_ sender: Any) {
        olOidc?.revokeToken(tokenType: .RefreshToken, callback: { (error) in
            if let error = error {
                self.setInfoText(text: error.localizedDescription)
                return
            }
            self.setInfoText(text: "Successfully revoked Refresh-Token")
        })
    }
    
    @IBAction func btnRefreshAccessTokenClicked(_ sender: Any) {
        olOidc?.refreshAccessToken(callback: { (error) in
            if let error = error {
                self.setInfoText(text: error.localizedDescription)
                return
            }
            self.setInfoText(text: "Successfully refreshed access token")
        })
    }
    
}

