//
//  Copyright © 2021-2025 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI

/// List of the known document identifiers hosted on the Instant Web Examples Server.
public struct InstantExampleDocumentIdentifier: RawRepresentable, Codable, Hashable, Sendable {

    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// The document used by the `BoardMeetingExample`.
    static let boardMeeting = Self(rawValue: "board-meeting")

    /// The document used by the basic Instant Demo.
    static let demoDocument = Self(rawValue: "instant-landing-page")

    /// The document used by the `Multi-User Instant Example`.
    static let marketingDepartmentSchedule = Self(rawValue: "marketing-department-schedule")

    /// The document used by the `Instant Layers Example`.
    static let constructionPlan = Self(rawValue: "construction-plan")

    /// The document used by the `Collaboration Permissions Example`.
    static let collaborationPermissions = Self(rawValue: "collaboration-permissions")

}
