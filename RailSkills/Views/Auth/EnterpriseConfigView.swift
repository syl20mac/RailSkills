//
//  EnterpriseConfigView.swift
//  RailSkills
//
//  Vue de configuration pour le mode entreprise.
//  Permet de scanner un QR Code ou de saisir manuellement les identifiants.
//

import SwiftUI
import AVFoundation

struct EnterpriseConfigView: View {
    @StateObject private var appConfig = AppConfigurationService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingManualConfig = false
    @State private var errorMessage: String?
    @State private var isScanning = true
    
    var body: some View {
        VStack(spacing: 20) {
            if showingManualConfig {
                ManualConfigForm()
            } else {
                QRScannerView { code in
                    handleScannedCode(code)
                }
                .frame(height: 300)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue, lineWidth: 2)
                )
                .padding()
                
                Text("Scannez le QR Code fourni par votre organisation")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Button(action: {
                    showingManualConfig = true
                }) {
                    HStack {
                        Image(systemName: "keyboard")
                        Text("Configurer manuellement")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal)
            }
            
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding()
            }
        }
        .navigationTitle("Configuration Entreprise")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func handleScannedCode(_ code: String) {
        isScanning = false
        // Format attendu: JSON
        // {
        //   "tenantId": "...",
        //   "clientId": "...",
        //   "backendUrl": "...",
        //   "orgName": "...",
        //   "orgSecret": "..."
        // }
        
        guard let data = code.data(using: .utf8) else {
            errorMessage = "Code invalide"
            isScanning = true
            return
        }
        
        do {
            let config = try JSONDecoder().decode(EnterpriseConfigData.self, from: data)
            appConfig.configure(
                tenantId: config.tenantId,
                clientId: config.clientId,
                backendUrl: config.backendUrl,
                orgName: config.orgName,
                orgSecret: config.orgSecret
            )
            // La navigation va automatiquement changer grâce au changement de mode dans RailSkillsApp
        } catch {
            errorMessage = "Format du QR Code invalide"
            isScanning = true
        }
    }
}

struct EnterpriseConfigData: Codable {
    let tenantId: String
    let clientId: String
    let backendUrl: String
    let orgName: String
    let orgSecret: String?
}

struct ManualConfigForm: View {
    @StateObject private var appConfig = AppConfigurationService.shared
    @State private var tenantId = ""
    @State private var clientId = ""
    @State private var backendUrl = "https://"
    @State private var orgName = ""
    @State private var orgSecret = ""
    
    var body: some View {
        Form {
            Section(header: Text("Identifiants Azure AD")) {
                TextField("Tenant ID", text: $tenantId)
                TextField("Client ID", text: $clientId)
            }
            
            Section(header: Text("Serveur")) {
                TextField("URL Backend", text: $backendUrl)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
            }
            
            Section(header: Text("Organisation")) {
                TextField("Nom de l'organisation", text: $orgName)
                SecureField("Secret (Optionnel)", text: $orgSecret)
            }
            
            Button("Enregistrer") {
                appConfig.configure(
                    tenantId: tenantId,
                    clientId: clientId,
                    backendUrl: backendUrl,
                    orgName: orgName.isEmpty ? "Organisation" : orgName,
                    orgSecret: orgSecret.isEmpty ? nil : orgSecret
                )
            }
            .disabled(tenantId.isEmpty || clientId.isEmpty || backendUrl.isEmpty)
        }
    }
}

// Vue simple pour scanner (Placeholder ou implémentation basique)
// Note: Une vraie implémentation nécessite AVCaptureSession
struct QRScannerView: UIViewControllerRepresentable {
    var onCodeScanned: (String) -> Void
    
    func makeUIViewController(context: Context) -> ScannerViewController {
        let controller = ScannerViewController()
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onCodeScanned: onCodeScanned)
    }
    
    class Coordinator: NSObject, ScannerDelegate {
        var onCodeScanned: (String) -> Void
        
        init(onCodeScanned: @escaping (String) -> Void) {
            self.onCodeScanned = onCodeScanned
        }
        
        func didScanCode(_ code: String) {
            onCodeScanned(code)
        }
    }
}

protocol ScannerDelegate: AnyObject {
    func didScanCode(_ code: String)
}

class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    weak var delegate: ScannerDelegate?
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.black
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }
        
        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        previewLayer?.frame = view.bounds
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if (captureSession?.isRunning == true) {
            captureSession.stopRunning()
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession.stopRunning()
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            delegate?.didScanCode(stringValue)
        }
    }
}
