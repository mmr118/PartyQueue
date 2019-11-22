//
//  Utilities.swift
//  PartyQueue
//
//  Created by Rondon Monica on 19.11.19.
//  Copyright © 2019 NotMoniApps. All rights reserved.
//

import CoreData

let clientID = "ba5c48fcf2424b149d2a5638b7a42374"
let clientSecret = "aced2f1991b94c6fb9bf62010220c153"
let redirectURL = URL(string: "partyqueue://")!

@discardableResult
func didHandleError(_ error: Error?) -> Bool {
    guard let error = error else { return false }
    fatalError(error.localizedDescription)
}

@discardableResult
func didHandleNSError(_ nserror: NSError?) -> Bool {
    guard let nserror = nserror else { return false }
    fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
}

extension NSPersistentContainer {

    static func loaded(named name: String, errorHandler: ((Error) -> Void)? = nil) -> NSPersistentContainer {
        
        let container = NSPersistentContainer(name: name)
        container.loadPersistentStores { (_, error) in
            guard let error = error else { return }
            if let handler = errorHandler {
                handler(error)
            } else {
                didHandleError(error)
            }
        }

        return container
    }

}

extension SPTAppRemotePlaybackOptionsRepeatMode {

    var description: String {
        switch self {
        case .off: return "off"
        case .track: return "track"
        case .context: return "context"
        @unknown default: return "unknown"
        }
    }
}

extension SPTAppRemotePlayerState {

    func info() -> String {
        let output = """
        PLAYER STATE CHANGED
        paused:             \(isPaused)
        track:
            - uri:          \(track.uri)
            - name:         \(track.name)
            - imageId:      \(track.imageIdentifier)
            - artist:
                - name:     \(track.artist.name)
            - album:
                - name:     \(track.album.name)
            - isSaved:      \(track.isSaved)
        playbackSpeed:      \(playbackSpeed)
        playbackOptions:
            - isShuffling:  \(playbackOptions.isShuffling)
            - repeatMode:   \(playbackOptions.repeatMode.description)
        playbackPosition:   \(playbackPosition)

        """
        return output
    }
}
