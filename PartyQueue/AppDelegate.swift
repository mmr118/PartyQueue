//
//  AppDelegate.swift
//  PartyQueue
//
//  Created by Rondon Monica on 02.11.19.
//  Copyright © 2019 NotMoniApps. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var shouldReconnectSPTRemote = false

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        setupSpotify()
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        sessionManager.application(app, open: url, options: options)
        return true
    }

    // MARK: UISceneSession Lifecycle
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }


    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state.
        // This can occur for certain types of temporary interruptions (
        // such as an incoming phone call or SMS message) or when the user quits
        // the application and it begins the transition to the background state.

        // Use this method to pause ongoing tasks, disable timers, and i
        // nvalidate graphics rendering callbacks. Games should use this method
        // to pause the game.
        handleApplicationWillEnterState(.inactive)
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the
        // application was inactive. If the application was previously in the
        // background, optionally refresh the user interface.
        handleApplicationWillEnterState(.active)
    }

    // MARK: - Core Data stack
    lazy var persistentContainer = NSPersistentContainer.loaded(named: "PartyQueue")

    func saveContext () {
        let context = persistentContainer.viewContext
        guard context.hasChanges else { print("context.hasChanges == false"); return }
        do {
            try context.save()
        } catch let nserror as NSError {
            didHandleNSError(nserror)
        }
    }

    // MARK: - Spotify App Remote
    lazy var configuration = SPTConfiguration(clientID: clientID, redirectURL: redirectURL)

    lazy var sessionManager: SPTSessionManager = {
        setupTokensIfAble()
        return SPTSessionManager(configuration: configuration, delegate: self)
    }()

    lazy var appRemote: SPTAppRemote = {
        let remote = SPTAppRemote(configuration: configuration, logLevel: .debug)
        remote.delegate = self
        return remote
    }()

}

// MARK: - SPTAppRemoteDelegate
extension AppDelegate: SPTAppRemoteDelegate {

    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        print("connected")
        handleAppRemoteConnection(appRemote)
    }

    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        print("disconnected")
        didHandleError(error)
    }

    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        print("failed")
        didHandleError(error)
    }

}

// MARK: - SPTAppRemotePlayerStateDelegate
extension AppDelegate: SPTAppRemotePlayerStateDelegate {

    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        print("player state changed")
    }

}


// MARK: - SPTSessionManagerDelegate
extension AppDelegate: SPTSessionManagerDelegate {

    func sessionManager(manager: SPTSessionManager, didInitiate session: SPTSession) {
//        appRemote.delegate = self
        appRemote.connectionParameters.accessToken = session.accessToken
        appRemote.connect()
    }

    func sessionManager(manager: SPTSessionManager, didFailWith error: Error) {
        didHandleError(error)
    }

    func sessionManager(manager: SPTSessionManager, didRenew session: SPTSession) {
        print("Session renewed: \(session)")
    }

}

// MARK: - Spotify Helpers
extension AppDelegate {

    enum AppState {
        case active
        case inactive
    }

    func setupSpotify() {
        let requestScopes: SPTScope = [.appRemoteControl]
        sessionManager.initiateSession(with: requestScopes, options: .default)
    }

    func setupTokensIfAble(playURI: String? = nil) {
        guard configuration.tokenSwapURL == nil && configuration.tokenRefreshURL == nil else { return }
        guard let tokenSwapURL = URL(string: "https://[your token swap app domain here]/api/token") else { return }
        guard let tokenRefreshURL = URL(string: "https://[your token swap app domain here]/api/refresh_token") else { return }
        configuration.tokenRefreshURL = tokenRefreshURL
        configuration.tokenSwapURL = tokenSwapURL
        configuration.playURI = playURI ?? ""
    }

    func handleAppRemoteConnection(_ appRemote: SPTAppRemote) {
        self.appRemote.playerAPI?.delegate = self
        self.appRemote.playerAPI?.subscribe(toPlayerState: { (result, error) in
            didHandleError(error)
        })

        // Want to play a new track?
//        self.appRemote.playerAPI?.play("spotify:track:13WO20hoD72L0J13WTQWlT", callback: { (result, error) in
//            didHandleError(error)
//        })

    }

    func handlePlayerStateChange(_ playerState: SPTAppRemotePlayerState) {
        print(playerState.info())
    }

    func handleApplicationWillEnterState(_ state: AppState) {

        switch state {

        case .active:
            if appRemote.connectionParameters.accessToken != nil {
                appRemote.connect()
            }

        case .inactive:
            if appRemote.isConnected {
                appRemote.disconnect()
            }
        }

    }

}

