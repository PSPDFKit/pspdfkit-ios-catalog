//
//  Copyright © 2023-2026 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI
import SwiftUI

@MainActor class DigitalSignatureConfigurationExample: Example {
    override init() {
        super.init()

        title = "Add Digital Signature (with configuration options)"
        contentDescription = "Shows how to add a digital signature with different customized options"
        category = .forms
        priority = 26
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let signatureSettings = SignatureSettingsView(onSignTapped: { configuration in
            let navigationController = delegate.currentViewController!.navigationController!
            await self.sign(with: configuration, presentSignedDocumentOn: navigationController)
        })

        return UIHostingController(rootView: signatureSettings)
    }

    func sign(with configuration: SigningConfiguration, presentSignedDocumentOn navigationController: UINavigationController) async {
        let unsignedDocument = AssetLoader.document(for: "Form.pdf")
        let signatureFormElement = unsignedDocument.annotations(at: 0, type: SignatureFormElement.self).first!
        let signedDocumentURL = URL(fileURLWithPath: NSTemporaryDirectory().appending("\(UUID().uuidString).pdf"))

        do {
            try await unsignedDocument.sign(formElement: signatureFormElement, configuration: configuration, outputDataProvider: FileDataProvider(fileURL: signedDocumentURL))
            navigationController.pushViewController(PDFViewController(document: Document(url: signedDocumentURL)), animated: true)
        } catch {
            navigationController.showAlert(withTitle: "Couldn't add signature", message: "\(error)")
            print(error)
        }
    }
}

fileprivate struct SignatureSettingsView: View {

    struct Certificates: Hashable, CaseIterable {
        static let goodSigner = Certificates(title: "Good Signer", signingCertificatesName: "GoodSigner.cert", privateKeyName: "GoodSigner.key", caCertificatesName: "ca_chain.pem")
        static let badSigner = Certificates(title: "Bad Signer", signingCertificatesName: "BadSigner.cert", privateKeyName: "BadSigner.key", caCertificatesName: "ca_chain.pem")
        static let goodSignerFromGoodCA = Certificates(title: "Good Signer from Good CA", signingCertificatesName: "GoodSignerFromGoodCA.cert", privateKeyName: "GoodSignerFromGoodCA.key", caCertificatesName: "GoodSignerFromGoodCA_ca_chain.pem")
        static let goodSignerFromBadCA = Certificates(title: "Good Signer from Bad CA", signingCertificatesName: "GoodSignerFromBadCA.cert", privateKeyName: "GoodSignerFromBadCA.key", caCertificatesName: "GoodSignerFromBadCA_ca_chain.pem")
        static let simpleSigner = Certificates(title: "Simple Signer", signingCertificatesName: "SimpleSigner.cert", privateKeyName: "SimpleSigner.key", caCertificatesName: "ca_root.cert")

        static let allCases: [Self] = [.goodSigner, .badSigner, .goodSignerFromGoodCA, .goodSignerFromBadCA, .simpleSigner]

        let title: String

        private let signingCertificatesName: String
        private let privateKeyName: String
        private let caCertificatesName: String

        init(title: String, signingCertificatesName: String, privateKeyName: String, caCertificatesName: String) {
            self.title = title
            self.signingCertificatesName = signingCertificatesName
            self.privateKeyName = privateKeyName
            self.caCertificatesName = caCertificatesName
        }

        var signingCertificates: [X509] {
            try! X509.certificates(fromPKCS7Data: Data(contentsOf: AssetLoader.assetURL(for: AssetName(rawValue: signingCertificatesName))))
        }

        var caCertificates: [X509] {
            try! X509.certificates(fromPKCS7Data: Data(contentsOf: AssetLoader.assetURL(for: AssetName(rawValue: caCertificatesName))))
        }

        var privateKey: PrivateKey {
            let pkcs8FileURL = AssetLoader.assetURL(for: AssetName(rawValue: privateKeyName))
            let pkcs8Data = try! Data(contentsOf: pkcs8FileURL)
            return PrivateKey.create(fromRawPrivateKey: pkcs8Data, encoding: .PKCS8)!
        }
    }

    enum TimeStampConfiguration: CaseIterable {
        case none
        case nutrient
        case freetsa
        case custom

        var title: String {
            switch self {
            case .none:
                return "None"
            case .nutrient:
                return "Nutrient Demo TSA"
            case .freetsa:
                return "FreeTSA"
            case .custom:
                return "Custom"
            }
        }
    }

    @State private var type: PDFSignatureType = .pades
    @State private var certificates: Certificates = .goodSigner
    @State private var isLongTermValidationEnabled = true
    @State private var customTimestampURL = ""
    @State private var timeStampConfiguration: TimeStampConfiguration = .none
    @State private var hashAlgorithm: PDFSignatureHashAlgorithm = .SHA256
    @State private var reason = ""
    @State private var location = ""
    @State private var useCustomEstimatedSize = false
    @State private var estimatedSize: Int32 = 32_768
    @State private var useCustomSignatureAppearance = false
    @State private var addBiometricData = false

    @State private var isSigningInProgress = false

    let onSignTapped: (SigningConfiguration) async -> Void

    var body: some View {
        Form {
            Section("Type") {
                Picker("Signature Type", selection: $type) {
                    ForEach(PDFSignatureType.allCases, id: \.self) {
                        Text($0.title)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section {
                Picker("Certificate", selection: $certificates) {
                    ForEach(Certificates.allCases, id: \.self) {
                        Text($0.title)
                    }
                }
                .pickerStyle(.menu)
            }

            Section {
                Toggle("Enable Long-Term Validation", isOn: $isLongTermValidationEnabled)
            }

            Section {
                Picker("Timestamp", selection: $timeStampConfiguration) {
                    ForEach(TimeStampConfiguration.allCases, id: \.self) {
                        Text($0.title)
                    }
                }
                .pickerStyle(.menu)

                if timeStampConfiguration == .custom {
                    TextField("Custom Timestamp URL", text: $customTimestampURL)
                        .autocapitalization(.none)
                        .keyboardType(.URL)
                        .textContentType(.URL)
                }
            }

            Section {
                Picker("Hash Algorithm", selection: $hashAlgorithm) {
                    ForEach(PDFSignatureHashAlgorithm.allCases, id: \.self) {
                        Text($0.title)
                    }
                }
                .pickerStyle(.menu)
            }

            Section {
                TextField("Enter Reason", text: $reason)
                    .autocapitalization(.sentences)

                TextField("Enter Location", text: $location)
                    .autocapitalization(.words)
            }

            Section {
                Toggle("Set Estimated Size", isOn: $useCustomEstimatedSize)

                if useCustomEstimatedSize {
                    Stepper(value: $estimatedSize, in: 0...262_144, step: 1_024) {
                        Text("Estimated Size: \(estimatedSize) Byte")
                    }
                }
            }

            Section {
                Toggle("Use Custom Signature Appearance", isOn: $useCustomSignatureAppearance)
            }

            Section {
                Toggle("Add Biometric Data", isOn: $addBiometricData)
            }

            Section {
                Button(action: {
                    isSigningInProgress = true

                    let configuration = SigningConfiguration(
                        type: type,
                        dataSigner: certificates.privateKey,
                        certificates: certificates.signingCertificates,
                        isLongTermValidationEnabled: isLongTermValidationEnabled,
                        hashAlgorithm: hashAlgorithm,
                        appearance: useCustomSignatureAppearance ? .customAppearance : nil,
                        estimatedSize: useCustomEstimatedSize ? estimatedSize : nil,
                        reason: reason,
                        location: location,
                        timestampSource: timestampURL,
                        biometricData: addBiometricData ? .init(pressureList: [1, 1, 0.5], timePointsList: [0, 10, 14], touchRadius: 2, inputMethod: .finger) : nil)

                    // In the example we do this here, but in your app you can set this early
                    // in the app lifecycle and don't need to clear them.
                    let signatureManager = SDK.shared.signatureManager
                    signatureManager.clearTrustedCertificates()
                    for cert in certificates.caCertificates {
                        signatureManager.addTrustedCertificate(cert)
                    }

                    Task {
                        await onSignTapped(configuration)
                        isSigningInProgress = false
                    }
                }, label: {
                    HStack {
                        Text("Sign")
                        if isSigningInProgress {
                            Spacer()
                            ProgressView()
                        }
                    }
                })
                .disabled(isSigningInProgress)
            }
        }
        .navigationBarTitle("Customize Signature Options")
    }

    private var timestampURL: URL? {
        switch timeStampConfiguration {
        case .none:
            return nil
        case .nutrient:
            return URL(string: "https://tsa.our.services.nutrient-powered.io/")!
        case .freetsa:
            return URL(string: "https://freetsa.org/tsr")!
        case .custom:
            return URL(string: customTimestampURL)
        }
    }
}

fileprivate extension PDFSignatureType {
    static let allCases: [Self] = [.CMS, .pades]

    var title: String {
        switch self {
        case .CMS:
            return "CMS"
        case .pades:
            return "PAdES"
        default:
            fatalError()
        }
    }
}

fileprivate extension PDFSignatureHashAlgorithm {
    static let allCases: [Self] = [.MD5, .SHA160, .SHA224, .SHA256, .SHA384, .SHA512]

    var title: String {
        switch self {
        case .MD5:
            return "MD5"
        case .SHA160:
            return "SHA160"
        case .SHA224:
            return "SHA224"
        case .SHA256:
            return "SHA256"
        case .SHA384:
            return "SHA384"
        case .SHA512:
            return "SHA512"
        case .unknown:
            fatalError()
        }
    }
}

fileprivate extension PDFSignatureAppearance {
    static var customAppearance: PDFSignatureAppearance {
        let tempPDF = FileHelper.temporaryPDFFileURL(prefix: "appearance")
        let format = UIGraphicsPDFRendererFormat()
        let pageRect = CGRect(x: 0, y: 0, width: 300, height: 50)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        try? renderer.writePDF(to: tempPDF, withActions: { context in
            context.beginPage()

            // draw a gradient
            let colors = [UIColor.systemBlue.cgColor, UIColor.systemTeal.cgColor]
            let colorLocations: [CGFloat] = [0.0, 1.0]
            guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                            colors: colors as CFArray,
                                            locations: colorLocations) else { return }
            context.cgContext.drawLinearGradient(gradient, start: CGPoint.zero,
                                                 end: CGPoint(x: pageRect.size.width, y: pageRect.size.height),
                                                 options: [])

            // draw text
            let text = "This is a custom signature appearance"
            text.draw(at: CGPoint(x: 3, y: 3), withAttributes: [
                NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 12)
            ])
        })
        // Create a `PDFSignatureAppearance` that will be used for the signature appearance while signing.
        let appearanceStream = Annotation.AppearanceStream(fileURL: tempPDF)
        let signatureAppearance = PDFSignatureAppearance { builder in
            builder.appearanceMode = .signatureOnly
            builder.signatureWatermark = appearanceStream
        }
        return signatureAppearance
    }
}
