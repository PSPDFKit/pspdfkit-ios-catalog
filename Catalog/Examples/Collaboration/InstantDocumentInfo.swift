//
//  InstantDocumentInfo.swift
//  PSPDFKit
//
//  Copyright © 2017-2024 PSPDFKit GmbH. All rights reserved.
//
//  THIS SOURCE CODE AND ANY ACCOMPANYING DOCUMENTATION ARE PROTECTED BY INTERNATIONAL COPYRIGHT LAW
//  AND MAY NOT BE RESOLD OR REDISTRIBUTED. USAGE IS BOUND TO THE PSPDFKIT LICENSE AGREEMENT.
//  UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS SUBJECT TO CIVIL AND CRIMINAL PENALTIES.
//  This notice may not be removed from this file.
//

/// The response from the PSPDFKit for Web examples server API that may be used to load a document layer with Instant.
public struct InstantDocumentInfo: Codable {
    let serverURL: URL
    let url: URL
    let jwt: String
    let documentId: InstantExampleDocumentIdentifier
    let encodedDocumentId: String

    enum CodingKeys: String, CodingKey {
        case serverURL = "serverUrl"
        case url, jwt, documentId, encodedDocumentId
    }
}

extension InstantDocumentInfo {
    func toDictionary() -> [String: String] {
        [
            CodingKeys.serverURL.rawValue: serverURL.absoluteString,
            CodingKeys.url.rawValue: url.absoluteString,
            CodingKeys.jwt.rawValue: jwt,
            CodingKeys.documentId.rawValue: documentId.rawValue,
            CodingKeys.encodedDocumentId.rawValue: encodedDocumentId
        ]
    }

    init?(from dictionary: [String: String]) {
        guard
            let serverURLString = dictionary[CodingKeys.serverURL.rawValue],
            let serverURL = URL(string: serverURLString),
            let docURLString = dictionary[CodingKeys.url.rawValue],
            let url = URL(string: docURLString),
            let jwt = dictionary[CodingKeys.jwt.rawValue],
            let documentId = dictionary[CodingKeys.documentId.rawValue].map({ InstantExampleDocumentIdentifier(rawValue: $0) }),
            let encodedDocumentId = dictionary[CodingKeys.encodedDocumentId.rawValue]
        else {
            return nil
        }

        self.serverURL = serverURL
        self.url = url
        self.jwt = jwt
        self.documentId = documentId
        self.encodedDocumentId = encodedDocumentId
    }
}

extension InstantDocumentInfo: Equatable {
    public static func == (lhs: InstantDocumentInfo, rhs: InstantDocumentInfo) -> Bool {
        return lhs.serverURL == rhs.serverURL && lhs.url == rhs.url && lhs.jwt == rhs.jwt
    }
}

/// URL of the server used by the Instant Examples to create new document sessions or join existing ones.
/// Same as that of the Web Examples (PSPDFKit for Web Catalog).
public let InstantWebExamplesServerURL = URL(string: "https://web-examples.services.demo.pspdfkit.com/")!

/// String used as key to store the `InstantDocumentInfo` of the last viewed document of the PSPDFKit Instant Example.
let InstantExampleLastViewedDocumentInfoKey = "InstantExampleLastViewedDocumentInfoKey"

/// String used as key to store the `InstantDocumentInfo` of the last viewed document of the Multi-User Instant Example.
let MultiUserInstantExampleLastViewedDocumentInfoKey = "MultiUserInstantExampleLastViewedDocumentInfoKey"
