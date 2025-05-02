// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/


import SwiftUI
import Combine


// MARK: - SummaryService
class SummaryService {
    private let apiURLString = "ADD URL HERE"
    
    func fetchSummary(for text: String, completion: @escaping (Result<SummaryResponse, Error>) -> Void) {
        guard let url = URL(string: apiURLString) else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }

        let request = SummaryRequest(text: text,
                                     summaryType: "any-translate-custom",
                                     customLines: 1,
                                     language: "english")

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data received", code: -2, userInfo: nil)))
                return
            }
            
            do {
                let response = try JSONDecoder().decode(SummaryResponse.self, from: data)
                completion(.success(response))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

// MARK: - SummaryViewModel
class SummaryViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var summary = ""
    @Published var error: String?
    @Published var isTyping = false
    @Published var contentHeight: CGFloat = 250 // Initial height
    
    private let service = SummaryService()
    
    func getSummary(for text: String) {
        isLoading = true
        error = nil
        
        service.fetchSummary(for: text) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let response):
                    self?.summary = response.summary
                    
                    // Estimate content height based on text length
                    let estimatedHeight = min(
                        CGFloat(response.summary.count / 4), // Rough estimate of text height
                        400 // Maximum height
                    )
                    self?.contentHeight = max(estimatedHeight, 150) // Minimum height
                    
                    self?.isTyping = true
                    
                case .failure(let error):
                    self?.error = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - SummaryBottomSheet SwiftUI View
struct SummaryBottomSheet: View {
    @StateObject private var viewModel = SummaryViewModel()
    @Binding var isPresented: Bool
    let text: String
    
    var body: some View {
        VStack(spacing: 16) {
            // Drag indicator
            Capsule()
                .fill(Color(.systemGray4))
                .frame(width: 40, height: 5)
                .padding(.top, 8)
            
            // Header
            HStack {
                Text("Summary")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        isPresented = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)
            
            // Content area
            ZStack {
                if viewModel.isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.blue)
                        
                        Text("Generating summary...")
                            .foregroundColor(.secondary)
                    }
                } else if let error = viewModel.error {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                        
                        Text("Error: \(error)")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else if !viewModel.summary.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            TypewriterText(text: viewModel.summary, isAnimating: $viewModel.isTyping)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                        .padding(.horizontal)
                    }
                    .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom)
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: -5)
        .onAppear {
            viewModel.getSummary(for: text)
        }
    }
}

// MARK: - Bottom Sheet Configuration
struct BottomSheetModifier<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    @Binding var contentHeight: CGFloat
    let sheetContent: SheetContent
    let maxHeightPercentage: CGFloat = 0.7 // Maximum height as percentage of screen
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if isPresented {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        withAnimation(.spring()) {
                            isPresented = false
                        }
                    }
                
                VStack {
                    Spacer()
                    
                    sheetContent
                        .padding(.bottom, 34) // Add extra padding for bottom safe area
                        .transition(.move(edge: .bottom))
                        .animation(.spring(), value: isPresented)
                        .frame(maxWidth: .infinity)
                        .frame(height: min(contentHeight + 150, UIScreen.main.bounds.height * maxHeightPercentage)) // Dynamic height with padding and maximum constraint
                        .background(Color(.systemBackground))
                        .cornerRadius(16, corners: [.topLeft, .topRight])
                }
                .ignoresSafeArea()
                .transition(.identity)
            }
        }
        .animation(.spring(), value: isPresented)
    }
}

// MARK: - UIKit Integration
class SummaryBottomSheetViewController: UIViewController {
    private var hostingController: UIHostingController<AnyView>?
    private var isPresented = false
    private let text: String
    private var contentHeight: CGFloat = 250
    
    init(text: String) {
        self.text = text
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        
        setupHostingController()
    }
    
    private func setupHostingController() {
        var isSheetPresented = true
        
        let viewModel = SummaryViewModel()
        
        let summaryView = SummaryBottomSheet(
            isPresented: Binding<Bool>(
                get: { isSheetPresented },
                set: { newValue in
                    isSheetPresented = newValue
                    if !newValue {
                        self.dismiss(animated: false)
                    }
                }
            ),
            text: text
        )
        
        let rootView = AnyView(
            Color.clear
                .modifier(BottomSheetModifier(
                    isPresented: Binding<Bool>(
                        get: { isSheetPresented },
                        set: { newValue in
                            isSheetPresented = newValue
                            if !newValue {
                                self.dismiss(animated: false)
                            }
                        }
                    ),
                    contentHeight: Binding<CGFloat>(
                        get: { viewModel.contentHeight },
                        set: { viewModel.contentHeight = $0 }
                    ),
                    sheetContent: summaryView
                ))
        )
        
        hostingController = UIHostingController(rootView: rootView)
        hostingController?.view.backgroundColor = .clear
        
        if let hostingView = hostingController?.view {
            hostingView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(hostingView)
            
            NSLayoutConstraint.activate([
                hostingView.topAnchor.constraint(equalTo: view.topAnchor),
                hostingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                hostingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                hostingView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Usage Example
extension UIViewController {
    func presentSummaryBottomSheet(forText text: String) {
        let summaryVC = SummaryBottomSheetViewController(text: text)
        present(summaryVC, animated: true)
    }
}
