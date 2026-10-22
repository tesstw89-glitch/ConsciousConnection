import SwiftUI
import UIKit
import AVFoundation

// A camera scanner plus a manual fallback. Camera images are never uploaded;
// only the detected barcode is sent to Open Food Facts for a product lookup.
struct MealBarcodeScanner: View {
    @Environment(\.dismiss) private var dismiss
    let onBarcode: (String) -> Void
    @State private var permission = AVCaptureDevice.authorizationStatus(for: .video)
    @State private var manualBarcode = ""
    @State private var validationMessage: String? = nil
    @State private var submitted = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Point your camera at the barcode on a food packet. We'll look up the exact product in Open Food Facts.")
                        .foregroundStyle(.secondary)

                    Group {
                        if permission == .authorized && AVCaptureDevice.default(for: .video) != nil {
                            MealBarcodeCamera { code in
                                accept(code)
                            }
                            .frame(height: 285)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .overlay {
                                RoundedRectangle(cornerRadius: 18)
                                    .strokeBorder(Color.green.opacity(0.55), lineWidth: 2)
                            }
                            Text("Keep the whole barcode visible. The camera reads it automatically.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        } else if permission == .denied || permission == .restricted {
                            ContentUnavailableView("Camera access unavailable", systemImage: "camera.fill",
                                description: Text("Allow camera access in Settings → ConsciousConnection, or type the barcode below."))
                        } else if permission == .authorized {
                            ContentUnavailableView("Camera unavailable", systemImage: "camera.fill",
                                description: Text("Enter the barcode printed beneath the stripes instead."))
                        } else {
                            ProgressView("Preparing camera…")
                                .frame(maxWidth: .infinity, minHeight: 180)
                        }
                    }

                    Divider()
                    Text("Or enter a barcode")
                        .font(.headline)
                    HStack(spacing: 10) {
                        TextField("Numbers beneath the barcode", text: $manualBarcode)
                            .keyboardType(.numberPad)
                            .textContentType(.none)
                            .textFieldStyle(.roundedBorder)
                            .accessibilityLabel("Barcode number")
                        Button("Look up") { accept(manualBarcode) }
                            .buttonStyle(.borderedProminent)
                            .disabled(manualBarcode.isEmpty || submitted)
                    }
                    if let validationMessage {
                        Text(validationMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                    Text("Nothing found? You can still type the ingredient or search by its name. Not all branded products are in the database.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(18)
            }
            .navigationTitle("Scan a barcode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                if AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined {
                    let granted = await AVCaptureDevice.requestAccess(for: .video)
                    permission = granted ? .authorized : .denied
                } else {
                    permission = AVCaptureDevice.authorizationStatus(for: .video)
                }
            }
        }
    }

    private func accept(_ raw: String) {
        guard !submitted else { return }
        let code = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard code.count >= 8, code.count <= 14,
              code.unicodeScalars.allSatisfy({ CharacterSet.decimalDigits.contains($0) }) else {
            validationMessage = "Enter an 8–14 digit product barcode."
            return
        }
        submitted = true
        dismiss()
        onBarcode(code)
    }
}

private struct MealBarcodeCamera: UIViewControllerRepresentable {
    let onBarcode: (String) -> Void

    func makeUIViewController(context: Context) -> MealBarcodeCaptureController {
        let controller = MealBarcodeCaptureController()
        controller.onBarcode = onBarcode
        return controller
    }
    func updateUIViewController(_ uiViewController: MealBarcodeCaptureController, context: Context) { }
}

private final class MealBarcodeCaptureController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onBarcode: ((String) -> Void)?
    private let session = AVCaptureSession()
    private let queue = DispatchQueue(label: "ConsciousConnection.barcodeCapture")
    private let preview = AVCaptureVideoPreviewLayer()
    private var hasDetected = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        preview.session = session
        preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(preview)
        queue.async { [weak self] in self?.configureAndStart() }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        preview.frame = view.bounds
    }

    private func configureAndStart() {
        guard let camera = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: camera) else { return }
        session.beginConfiguration()
        guard session.canAddInput(input) else { session.commitConfiguration(); return }
        session.addInput(input)
        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else { session.commitConfiguration(); return }
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.ean8, .ean13, .upce, .code128]
        session.commitConfiguration()
        session.startRunning() // AVCaptureSession starts off the main thread.
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        queue.async { [weak self] in
            guard let self = self, self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        guard !hasDetected else { return }
        for case let item as AVMetadataMachineReadableCodeObject in metadataObjects {
            guard let code = item.stringValue,
                  (8...14).contains(code.count),
                  code.unicodeScalars.allSatisfy({ CharacterSet.decimalDigits.contains($0) }) else { continue }
            hasDetected = true
            onBarcode?(code)
            return
        }
    }
}

struct MealBarcodeProduct {
    let barcode: String
    let name: String
    let brand: String?
    let nutriments: [String: Any]?
    var rawProduct: [String: Any]? = nil
}

// Barcode lookup hits the canonical product API, not the text-search index.
// A missing product or missing product name is an error, never invented nutrition.
enum MealBarcodeProducts {
    static func lookup(_ barcode: String) async throws -> MealBarcodeProduct {
        guard barcode.unicodeScalars.allSatisfy({ CharacterSet.decimalDigits.contains($0) }),
              (8...14).contains(barcode.count),
              let url = URL(string: "https://world.openfoodfacts.org/api/v2/product/\(barcode).json?fields=code,product_name,product_name_en,brands,nutriments,serving_size,serving_quantity,serving_quantity_unit,product_quantity_unit") else {
            throw BarcodeLookupError.invalidCode
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 18
        request.setValue("ConsciousConnection/1.0 (https://github.com/tesstw89-glitch/ConsciousConnection)", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw BarcodeLookupError.badResponse }
        guard (200...299).contains(http.statusCode) else { throw BarcodeLookupError.http(http.statusCode) }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw BarcodeLookupError.badResponse
        }
        guard (json["status"] as? NSNumber)?.intValue == 1,
              let entry = json["product"] as? [String: Any] else {
            throw BarcodeLookupError.notFound(barcode)
        }
        let name = [entry["product_name_en"] as? String, entry["product_name"] as? String]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty } ?? ""
        guard !name.isEmpty else { throw BarcodeLookupError.missingName }
        let brand = (entry["brands"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        return MealBarcodeProduct(barcode: barcode, name: name,
                                  brand: brand?.isEmpty == true ? nil : brand,
                                  nutriments: entry["nutriments"] as? [String: Any],
                                  rawProduct: entry)
    }
}

private enum BarcodeLookupError: LocalizedError {
    case invalidCode, notFound(String), missingName, badResponse, http(Int)
    var errorDescription: String? {
        switch self {
        case .invalidCode: return "This isn't a valid product barcode. Try entering the number beneath it."
        case .notFound(let code): return "Barcode \(code) isn't listed in Open Food Facts yet. Try searching by name or adding it manually."
        case .missingName: return "The barcode exists, but the product has no usable name. Please add it manually."
        case .badResponse: return "Open Food Facts sent an unexpected response. Please try again."
        case .http(let status): return "Open Food Facts returned HTTP \(status). Please try again later."
        }
    }
}
