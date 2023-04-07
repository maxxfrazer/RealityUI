//
//  RUITexture.swift
//  
//
//  Created by Max Cobb on 11/03/2023.
//

import RealityKit
import CoreGraphics
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
public typealias UIImage = NSImage
#endif

@available(iOS 15.0, macOS 12, *)
/// Class for creating `TextureResources`. For now the main use-case is creating SF Symbol images.
public struct RUITexture {
    /// Erorr that can be thrown while generating a texture
    public enum TextureError: Error {
        /// Could not convert UIImage/NSImage to CGImage
        case cgImageFailed
        /// System image with this name does not exist
        case invalidSystemName
    }
    /// Create a `TextureResource` with a system image name and point size.
    /// - Parameters:
    ///   - systemName: Name of the SF Symbol Image.
    ///   - pointSize: Point size the symbol will be drawn with.
    /// - Returns: A new `TextureResource`.
    public static func generateTexture(
        systemName: String, pointSize: CGFloat
    ) async throws -> TextureResource {
        #if canImport(AppKit)
        let config = NSImage.SymbolConfiguration(pointSize: pointSize, weight: .regular)
        #elseif canImport(UIKit)
        let config = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .regular, scale: .default)
        #endif
        return try await self.generateTexture(systemName: systemName, config: config)
    }
    fileprivate static func generateCGImage(
        systemName: String, config: UIImage.SymbolConfiguration
    ) throws -> CGImage {
        #if canImport(UIKit)
        guard let symbolImage = UIImage(
            systemName: systemName, withConfiguration: config
        ) else { throw TextureError.invalidSystemName }
        guard let cgImage = symbolImage.cgImage else {
            throw TextureError.cgImageFailed
        }
        #else
        guard let symbolImage = UIImage(
            systemSymbolName: systemName, accessibilityDescription: nil
        )?.withSymbolConfiguration(config) else { throw TextureError.invalidSystemName }
        guard let cgImage = symbolImage.cgImage(
            forProposedRect: nil, context: nil, hints: nil
        ) else { throw TextureError.cgImageFailed }
        #endif
        return cgImage
    }
    /// Create a `TextureResource` with a system image name and point size.
    /// - Parameters:
    ///   - systemName: Name of the SF Symbol Image.
    ///   - config: Image SymbolConfiguration for the SF Symbol Image.
    /// - Returns: A new `TextureResource`.
    public static func generateTexture(
        systemName: String, config: UIImage.SymbolConfiguration
    ) async throws -> TextureResource {
        let cgImage = try self.generateCGImage(systemName: systemName, config: config)
        #if canImport(AppKit)
        return try await TextureResource.generate(from: cgImage, options: .init(semantic: nil, mipmapsMode: TextureResource.MipmapsMode.allocateAndGenerateAll))
        #else
        return try await withCheckedThrowingContinuation { continuation in
            let generateTexture: @Sendable () -> Void = {
                do {
                    let texture = try TextureResource.generate(from: cgImage, withName: nil, options: .init(semantic: nil, mipmapsMode: TextureResource.MipmapsMode.allocateAndGenerateAll))
                    continuation.resume(returning: texture)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
            DispatchQueue.main.async(execute: generateTexture)
        }
        #endif
    }

#if canImport(UIKit)
    /// Create a `TextureResource` with a system image name and point size.
    /// - Parameters:
    ///   - systemName: Name of the SF Symbol Image.
    ///   - config: Image SymbolConfiguration for the SF Symbol Image.
    ///   - completion: Completion result for creating the `TextureResource`.
    public static func generateTexture(
        systemName: String, config: UIImage.SymbolConfiguration,
        completion: @escaping (Result<TextureResource, Error>) -> Void
    ) {
        do {
            let cgImage = try self.generateCGImage(systemName: systemName, config: config)
            let generateTexture: @Sendable () -> Void = {
                do {
                    let texture = try TextureResource.generate(from: cgImage, withName: nil, options: .init(semantic: nil, mipmapsMode: TextureResource.MipmapsMode.allocateAndGenerateAll))
                    completion(.success(texture))
                } catch {
                    completion(.failure(error))
                }
            }
            DispatchQueue.main.async(execute: generateTexture)
        } catch {
            completion(.failure(error))
        }
    }
    #endif
}
