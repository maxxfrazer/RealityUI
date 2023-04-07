//
//  File.swift
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
public struct RUITexture {
    public enum TextureError: Error {
        case cgImageFailed
        case invalidSystemName
    }
    public static func generatePaddedTexture(
        systemName: String, pointSize: CGFloat
    ) async throws -> TextureResource {
        #if canImport(AppKit)
        let config = NSImage.SymbolConfiguration(pointSize: pointSize, weight: .regular)
        #elseif canImport(UIKit)
        let config = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .regular, scale: .default)
        #endif
        return try await self.generatePaddedTexture(systemName: systemName, config: config)
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
    public static func generatePaddedTexture(
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
    public static func generatePaddedTexture(
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
