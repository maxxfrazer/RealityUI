//
//  RUIConversions.swift
//  Methods for converting SceneKit scenes to USDZ, or downloading remote
//  Image or USDZ files to be converted a TextureResource or Entity.
//
//  Created by Max Cobb on 24/04/2021.
//

import Foundation
import RealityKit
import SceneKit
import Combine

public struct RUIConversions {
    /// Errors for when an external failed to load
    public enum LoadRemoteError: Error {
        /// Cannot override local file of the same name
        case cannotDelete
        /// File could not be downloaded
        case downloadError
    }

}

// MARK: TextureResource
public extension RUIConversions {
    /// Load texture from Remote URL and return as a TextureResource in the completion
    /// - Parameters:
    ///   - url: URL for remote file, including file name and extension
    ///   - useCache: Whether any previously downloaded version should be used
    ///   - completion: Result type callback to either get the TextureResource or an Error
    static func loadRemoteTexture(
        contentsOf url: URL, useCache: Bool = true,
        completion: @escaping (Result<TextureResource, Error>) -> Void
    ) {
        RUIConversions.downloadRemoteFile(contentsOf: url, useCache: useCache) { result in
            switch result {
            case .failure(let err):
                completion(.failure(err))
            case .success(let endURL):
                self.loadResourceCompletion(contentsOf: endURL, completion: completion)
            }
        }
    }
    static func loadResourceCompletion(
        contentsOf url: URL,
        completion: @escaping (Result<TextureResource, Error>
    ) -> Void) {
        var canc: Cancellable?
        canc = TextureResource.loadAsync(contentsOf: url).sink(
            receiveCompletion: { loadCompletion in
                // Added this switch just as an example
                switch loadCompletion {
                case .failure(let loadErr):
                    completion(.failure(loadErr))
                    canc?.cancel()
                case .finished: break
                }
            }, receiveValue: { textureResource in
                completion(.success(textureResource))
            }
        )
    }
}

// MARK: Entities
public extension RUIConversions {
    /// Load model from Remote URL of a USDZ file and return as an Entity in the completion
    /// - Parameters:
    ///   - url: A file URL representing the file to load.
    ///   - resourceName: A unique name to assign to the loaded resource, for use in network synchronization.
    ///   - useCache: Whether the file should be overridden if previously downloaded
    ///   - loadMethod: Method that takes the file URL and filename, and returns a LoadRequest of the entity.
    ///   - completion: Result type callback to either get the Entity or an Error
    static func loadEntityAsync(
        contentsOf url: URL, withName resourceName: String? = nil, useCache: Bool = true,
        using loadMethod: @escaping ((_ contentsOf: URL, _: String?) -> LoadRequest<Entity>) = Entity.loadAsync,
        completion: @escaping (Result<Entity, Error>) -> Void
    ) {
        RUIConversions.downloadRemoteFile(contentsOf: url, useCache: useCache) { result in
            switch result {
            case .success(let endURL):
                RUIConversions.loadModelCompletion(
                    contentsOf: endURL, withName: resourceName, using: loadMethod, completion: completion
                )
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }

    /// Load a model with a given local URL
    /// - Parameters:
    ///   - url: local URL of a USDZ resource
    ///   - resourceName: Name of the resource
    ///   - loadMethod: Method that takes the file URL and filename, and returns a LoadRequest of the entity.
    ///   - completion: Completion callback giving the Entity or error message.
    static func loadModelCompletion(
        contentsOf url: URL, withName resourceName: String?,
        using loadMethod: ((_ contentsOf: URL, _: String?) -> LoadRequest<Entity>),
        completion: @escaping (Result<Entity, Error>) -> Void
    ) {
        var canc: Cancellable?
        canc = loadMethod(url, resourceName).sink(
            receiveCompletion: { loadCompletion in
                // Added this switch just as an example
                switch loadCompletion {
                case .failure(let loadErr):
                    completion(.failure(loadErr))
                    canc?.cancel()
                case .finished: break
                }
            }, receiveValue: { entity in
                completion(.success(entity))
            }
        )
    }

    /// Error type that is returned on failing to load a SCNScene into RealityKit
    enum SceneKitConversionError: Error {
        case writeSceneFailed
    }
    /// Convert an SCNScene to a RealityKit Entity
    /// - Parameters:
    ///   - scene: Scene containing all the SCNNodes to be converted to a RealityKit Entity.
    ///   - loadMethod: Method used to load the Entity from disk. Default is Entity.loadAsync
    ///   - delegate: A delegate object to customize export of external resources used by the scene.
    ///   Pass nil for default export of external resources.
    ///   - completion: Result type callback to either get the Entity or an Error
    static func loadSCNScene(
        _ scene: SCNScene,
        using loadMethod: ((_ contentsOf: URL, _: String?) -> LoadRequest<Entity>) = Entity.loadAsync,
        delegate: SCNSceneExportDelegate,
        completion: @escaping (Result<Entity, Error>) -> Void
    ) {
        let destinationURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(UUID().uuidString).usdz")
        if !scene.write(to: destinationURL, delegate: delegate) {
            // If we cannot export the scene, return failure
            return completion(.failure(SceneKitConversionError.writeSceneFailed))
        }
        self.loadModelCompletion(
            contentsOf: destinationURL, withName: nil,
            using: loadMethod, completion: completion
        )
    }
}

// MARK: Helper Methods
private extension RUIConversions {
    private static func downloadRemoteFile(
        contentsOf url: URL, useCache: Bool = true,
        completion: @escaping ((Result<URL, Error>) -> Void)
    ) {
        var request = URLRequest(url: url, timeoutInterval: 10)
        let endLocation = FileManager.default.temporaryDirectory
            .appendingPathComponent(url.lastPathComponent)
        if FileManager.default.fileExists(atPath: endLocation.path) {
            if useCache {
                RealityUI.RUIPrint("Item was cached")
                return completion(.success(endLocation))
            }
            do {
                try FileManager.default.removeItem(atPath: endLocation.path)
            } catch let err {
                RealityUI.RUIPrint("Could not remove item: \(err)")
                return completion(.failure(LoadRemoteError.cannotDelete))
            }
        }
        request.httpMethod = "GET"
        let task = URLSession.shared.downloadTask(
            with: request
        ) { location, _, error in
            if let error = error {
                return completion(.failure(error))
            }
            guard let location = location else {
                return completion(.failure(LoadRemoteError.downloadError))
            }
            do {
                try FileManager.default.moveItem(
                    atPath: location.path, toPath: endLocation.path
                )
            } catch let err {
                RealityUI.RUIPrint("Could not move item")
                return completion(.failure(err))
            }
            return completion(.success(endLocation))
        }
        task.resume()
    }
}
