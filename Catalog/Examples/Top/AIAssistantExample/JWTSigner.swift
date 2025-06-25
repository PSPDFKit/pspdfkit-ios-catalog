//
//  Copyright © 2025 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Foundation
import Security

/// A utility class for signing JWTs using RS256 algorithm
/// This is not meant to be used in production code and we don't recommend signing JWTs on client side.
/// Make sure to generate and sign JWTs on the server instead.
/// This is only done since the AI Assistant demo doesn't support providing JWTs.
class AIAssistantExampleJWTSigner {

    // PEM-formatted private key string used to sign the JWT
    private static var privateKeyPEM = """
-----BEGIN RSA PRIVATE KEY-----
MIIEpQIBAAKCAQEA2gzhmJ9TDanEzWdP1WG+0Ecwbe7f3bv6e5UUpvcT5q68IQJK
P47AQdBAnSlFVi4X9SaurbWoXdS6jpmPpk24QvitzLNFphHdwjFBelTAOa6taZrS
usoFvrtK9x5xsW4zzt/bkpUraNx82Z8MwLwrt6HlY7dgO9+xBAabj4t1d2t+0HS8
O/ed3CB6T2lj6S8AbLDSEFc9ScO6Uc1XJlSorgyJJSPCpNhSq3AubEZ1wMS1iEtg
AzTPRDsQv50qWIbn634HLWxTP/UH6YNJBwzt3O6q29kTtjXlMGXCvin37PyX4Jy1
IiPFwJm45aWJGKSfVGMDojTJbuUtM+8P9RrnAwIDAQABAoIBAQDSKxhGw0qKINhQ
IwQP5+bDWdqUG2orjsQf2dHOHNhRwJoUNuDZ4f3tcYzV7rGmH0d4Q5CaXj2qMyCd
0eVjpgW0h3z9kM3RA+d7BX7XKlkdQABliZUT9SUUcfIPvohXPKEzBRHed2kf6WVt
XKAuJTD+Dk3LjzRygWldOAE4mnLeZjU61kxPYriynyre+44Gpsgy37Tj25MAmVCY
Flotr/1WZx6bg3HIyFRGxnoJ1zU1MkGxwS4IsrQwOpWEHBiD5nvo54hF5I00NHj/
ccz+MwpgGdjyl02IGCy1fF+Q5SYyH86DG52Mgn8VI9dseGmanLGcgNvrdJFILoJR
SZW7gQoBAoGBAP+D6ZmRF7EqPNMypEHQ5qHHDMvil3mhNQJyIC5rhhl/nn063wnm
zhg96109hVh4zUAj3Rmjb9WqPiW7KBMJJdnEPjmZ/NOXKmgjs2BF+c8oiLQyTQml
xB7LnptvBDi8MnEd3uemfxNuZc+2siuSzgditshNru8xPG2Sn99JC271AoGBANp2
xj5EfdlqNLd11paLOtJ7dfREgc+8FxQCiKSxbaOlVXNk0DW1w4+zLnFohj2m/wRr
bBIzSL+eufoQ9y4BT/AA+ln4qxOpC0isOGK5SxwIjB6OHhCuP8L3anj1IFYM+NX0
Xr1/qdZHKulgbS49cq+TDpB74WyKLLnsvQFyINMXAoGABR5+cp4ujFUdTNnp4out
4zXasscCY+Rv7HGe5W8wC5i78yRXzZn7LQ8ohQCziDc7XXqadmYI2o4DmrvqLJ91
S6yb1omYQCD6L4XvlREx1Q2p13pegr/4cul/bvvFaOGUXSHNEnUKfLgsgAHYBfl1
+T3oDZFI3O/ulv9mBpIvEXUCgYEApeRnqcUM49o4ac/7wZm8czT5XyHeiUbFJ5a8
+IMbRJc6CkRVr1N1S1u/OrMqrQpwwIRqLm/vIEOB6hiT+sVYVGIJueSQ1H8baHYO
4zjdhk4fSNyWjAgltwF2Qp+xjGaRVrcYckHNUD/+n/VvMxvKSPUcrC7GAUvzpsPU
ypJFxsUCgYEA6GuP6M2zIhCYYeB2iLRD4ZHw92RfjikaYmB0++T0y2TVrStlzXHl
c8H6tJWNchtHH30nfLCj9WIMb/cODpm/DrzlSigHffo3+5XUpD/2nSrcFKESw4Xs
a4GXoAxqU44w4Mckg2E19b2MrcNkV9eWAyTACbEO4oFcZcSZOCKj8Fw=
-----END RSA PRIVATE KEY-----
"""

    enum JWTError: Error {
        case failedToCreatePrivateKey
        case signingFailed
        case algorithmNotSupported
        case invalidPEMKeyFormat
        case invalidPKCS8Format
    }

    /// Creates and signs a JWT with the given claims
    /// - Parameters:
    ///   - claims: Dictionary of claims to include in the JWT
    /// - Returns: Signed JWT string
    /// - Throws: Error if signing fails
    static func createAndSignJWT(claims: [String: Any]) throws -> String {
        // Header for RS256
        let header: [String: Any] = ["alg": "RS256", "typ": "JWT"]

        // Add standard claims
        var finalClaims = claims
        let expirationTime = Int(Date().addingTimeInterval(60 * 60).timeIntervalSince1970) // 1 hour from now
        finalClaims["exp"] = expirationTime

        // Convert header and payload to JSON data
        let headerData = try JSONSerialization.data(withJSONObject: header, options: [])
        let payloadData = try JSONSerialization.data(withJSONObject: finalClaims, options: [])

        // Base64 URL encode header and payload
        let headerEncoded = base64UrlEncode(headerData)
        let payloadEncoded = base64UrlEncode(payloadData)

        // Create the signing input (header.payload)
        let signingInput = "\(headerEncoded).\(payloadEncoded)"

        // Convert the private key PEM string to a SecKey
        let privateKey = try loadPrivateKey(from: privateKeyPEM)

        // Sign the data
        let signature = try sign(data: signingInput.data(using: .utf8)!, with: privateKey)

        // Base64 URL encode the signature
        let signatureEncoded = base64UrlEncode(signature)

        // Final JWT
        return "\(signingInput).\(signatureEncoded)"
    }

    // MARK: - Private Helpers

    /// Utility function for Base64 URL encoding
    private static func base64UrlEncode(_ data: Data) -> String {
        return data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    /// Load RSA private key from PEM string
    private static func loadPrivateKey(from pemString: String) throws -> SecKey {
        // Remove PEM headers and whitespace
        let keyString = pemString
            .replacingOccurrences(of: "-----BEGIN RSA PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END RSA PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----BEGIN PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")
            .trimmingCharacters(in: .whitespaces)

        guard let keyData = Data(base64Encoded: keyString) else {
            throw JWTError.invalidPEMKeyFormat
        }

        // Dictionary to specify attributes for the key
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate
        ]

        // Create the private key
        var error: Unmanaged<CFError>?
        guard let secKey = SecKeyCreateWithData(keyData as CFData, attributes as CFDictionary, &error) else {
            if let error = error?.takeRetainedValue() {
                throw error as Error
            }
            // If direct creation fails, try to strip PKCS#8 wrapper
            let pkcs1Key = try stripPKCS8Header(from: keyData)
            guard let secKey = SecKeyCreateWithData(pkcs1Key as CFData, attributes as CFDictionary, &error) else {
                throw error?.takeRetainedValue() ?? JWTError.failedToCreatePrivateKey
            }
            return secKey
        }

        return secKey
    }

    /// Strips PKCS#8 header from private key data to get PKCS#1 format
    private static func stripPKCS8Header(from data: Data) throws -> Data {
        let asn1Parser = ASN1Parser(data: data)
        guard case .sequence(let objects) = try asn1Parser.parse(),
              objects.count >= 3,
              case .sequence = objects[0],
              case .octetString(let keyData) = objects[2] else {
            throw JWTError.invalidPKCS8Format
        }
        return keyData
    }

    /// Sign data using RSA with SHA-256
    private static func sign(data: Data, with privateKey: SecKey) throws -> Data {
        var error: Unmanaged<CFError>?
        let algorithm: SecKeyAlgorithm = .rsaSignatureMessagePKCS1v15SHA256

        // Ensure the key supports the signing algorithm
        guard SecKeyIsAlgorithmSupported(privateKey, .sign, algorithm) else {
            throw JWTError.algorithmNotSupported
        }

        // Perform the signing
        guard let signature = SecKeyCreateSignature(privateKey, algorithm, data as CFData, &error) else {
            throw error!.takeRetainedValue() as Error
        }

        return signature as Data
    }
}

/// Simple ASN.1 parser for handling PKCS#8 private keys
class ASN1Parser {
    enum ASN1Object {
        case sequence([ASN1Object])
        case integer(Data)
        case octetString(Data)
        case objectIdentifier(String)
        case null
        case bitString(Data)
        indirect case constructed(UInt8, [ASN1Object])
    }

    enum ASN1Error: Error {
        case unexpectedEndOfData
        case unsupportedTag(UInt8)
    }

    private let data: Data
    private var index: Int = 0

    init(data: Data) {
        self.data = data
    }

    func parse() throws -> ASN1Object {
        guard index < data.count else {
            throw ASN1Error.unexpectedEndOfData
        }

        let tag = data[index]
        index += 1

        let length = try readLength()
        let content = try readContent(length: length)

        switch tag {
        case 0x30: // Sequence
            let parser = ASN1Parser(data: content)
            var objects: [ASN1Object] = []
            while parser.index < content.count {
                objects.append(try parser.parse())
            }
            return .sequence(objects)
        case 0x02: // Integer
            return .integer(content)
        case 0x04: // Octet String
            return .octetString(content)
        case 0x06: // Object Identifier
            return .objectIdentifier(content.map { String(format: "%02x", $0) }.joined())
        case 0x05: // Null
            return .null
        case 0x03: // Bit String
            return .bitString(content)
        default:
            if tag & 0x20 == 0x20 {
                let parser = ASN1Parser(data: content)
                var objects: [ASN1Object] = []
                while parser.index < content.count {
                    objects.append(try parser.parse())
                }
                return .constructed(tag, objects)
            }
            throw ASN1Error.unsupportedTag(tag)
        }
    }

    private func readLength() throws -> Int {
        guard index < data.count else {
            throw ASN1Error.unexpectedEndOfData
        }

        let firstByte = data[index]
        index += 1

        if firstByte & 0x80 == 0 {
            return Int(firstByte)
        }

        let numBytes = Int(firstByte & 0x7f)
        var length = 0

        for _ in 0..<numBytes {
            guard index < data.count else {
                throw ASN1Error.unexpectedEndOfData
            }
            length = length * 256 + Int(data[index])
            index += 1
        }

        return length
    }

    private func readContent(length: Int) throws -> Data {
        guard index + length <= data.count else {
            throw NSError(domain: "ASN1Error", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Content length exceeds data bounds"])
        }

        let content = data.subdata(in: index..<(index + length))
        index += length
        return content
    }
}
