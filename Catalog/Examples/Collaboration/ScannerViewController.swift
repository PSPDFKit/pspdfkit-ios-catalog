//
//  Copyright © 2018-2025 PSPDFKit GmbH. All rights reserved.
//
//  The Nutrient sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import AVFoundation
import PSPDFKitUI

#if !os(visionOS)

/// The possible results of barcode scanning.
enum BarcodeScanResult {
    case success(barcode: String)
    case failure(error: String)
}

@MainActor protocol ScannerViewControllerDelegate: AnyObject {
    /// Notifies the delegate when a scanning result is obtained. This will be called on the main thread.
    func scannerViewController(_ scannerViewController: ScannerViewController, didFinishScanningWith result: BarcodeScanResult)
}

private class BarcodeScannerView: UIView {

    weak var previewLayer: AVCaptureVideoPreviewLayer?

    convenience init(_ previewLayer: AVCaptureVideoPreviewLayer) {
        self.init()

        previewLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(previewLayer)
        self.previewLayer = previewLayer
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let previewLayer else { return }
        previewLayer.frame = self.layer.bounds
        let interfaceOrientation = window?.windowScene?.interfaceOrientation ?? .portrait
        previewLayer.connection?.videoOrientation = interfaceOrientation.convertToAVCaptureVideoOrientation()
    }
}

/// A view controller that shows the device camera and notifies its delegate when a barcode is found.
class ScannerViewController: UIViewController {
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var scannerQueue = DispatchQueue(label: "com.pspdfkit.viewer.scanner-queue", qos: .userInitiated)
    weak var delegate: ScannerViewControllerDelegate?

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Scan QR Code"
        edgesForExtendedLayout = []
        view.backgroundColor = UIColor.black

        let captureSession = AVCaptureSession()
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)

        scannerQueue.async { [weak self] in
            guard let self else { return }
            self.setupScanning(captureSession: captureSession)
        }

        let scannerView = BarcodeScannerView(previewLayer)
        scannerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scannerView)

        NSLayoutConstraint.activate([
            scannerView.topAnchor.constraint(equalTo: view.topAnchor),
            scannerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scannerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scannerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        self.previewLayer = previewLayer
        navigationController?.navigationBar.prefersLargeTitles = true

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closePressed))
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if let captureSession = previewLayer?.session, captureSession.isRunning {
            scannerQueue.async {
                captureSession.stopRunning()
            }
        }
    }

    func setupScanning(captureSession: AVCaptureSession) {
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video),
            let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice) else { return }

        precondition(captureSession.canAddInput(videoInput))
        captureSession.addInput(videoInput)

        // Metadata output is used to get callbacks when camera detects barcode
        let metadataOutput = AVCaptureMetadataOutput()

        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)

            metadataOutput.metadataObjectTypes = [.qr]

            // See explanation at the top of this class to find out why this is necessary.
            metadataOutput.perform(#selector(AVCaptureMetadataOutput.setMetadataObjectsDelegate(_:queue:)), with: self, with: scannerQueue)

            metadataOutput.setMetadataObjectsDelegate(self, queue: scannerQueue)

            // start running the capture session only once the setup is completed
            captureSession.startRunning()
        } else {
            let errorString = "Scanning is not supported on this device."
            self.delegate?.scannerViewController(self, didFinishScanningWith: .failure(error: errorString))
        }
    }

    @objc func closePressed() {
        self.dismiss(animated: true, completion: nil)
    }
}

extension ScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let captureSession = previewLayer?.session, captureSession.isRunning {
            captureSession.stopRunning()
        }

        guard let metadataObject = metadataObjects.first,
            let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
            let stringValue = readableObject.stringValue else {
                DispatchQueue.main.async {
                    self.delegate?.scannerViewController(self, didFinishScanningWith: .failure(error: "Didn’t find anything to scan."))
                }
                return
        }

        DispatchQueue.main.async {
            self.delegate?.scannerViewController(self, didFinishScanningWith: .success(barcode: stringValue))
        }
    }
}

private extension UIInterfaceOrientation {
    func convertToAVCaptureVideoOrientation() -> AVCaptureVideoOrientation {
        switch self {
        case .landscapeLeft:
            return AVCaptureVideoOrientation.landscapeLeft
        case .landscapeRight:
            return AVCaptureVideoOrientation.landscapeRight
        case .portraitUpsideDown:
            return AVCaptureVideoOrientation.portraitUpsideDown
        case .portrait, .unknown:
            return AVCaptureVideoOrientation.portrait
        @unknown default:
            fatalError()
        }
    }
}

#endif
