//
//  ContentView.swift
//  Magic 8 ball
//
//  Created by Rick Ator on 1/26/25.
//

import SwiftUI

@main
struct Magic8BallApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
}

// Main View with Tabs
struct MainView: View {
    var body: some View {
        TabView {
            Magic8BallView()
                .tabItem {
                   // Label("Dare Game", systemImage: "circle")
                }
        }
    }
}

// Magic 8-Ball View
struct Magic8BallView: View {
    @State private var answer: String = "Do you Dare?"
    @State private var showLoading: Bool = false // Tracks if the loading wheel is visible
    @State private var responses: [String] = Magic8BallDataManager.loadResponses()
    @State private var isConfigPanelOpen = false
    @State private var delayMs: Int = Magic8BallDataManager.loadDelay() // Load saved delay

    var body: some View {
        NavigationView {
            ZStack {
                // Background Emoji
                Text("😈")
                    .font(.system(size: 300))
                    .opacity(0.1) // Make it semi-transparent
                    .scaleEffect(1.2) // Slightly scale it up
                
                VStack {
                    Spacer()
                    
                    // Answer or Loading Indicator
                    if showLoading {
                        ProgressView() // Loading spinner
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(1.5)
                            .padding()
                            .tint(Color.black) // Set the loading icon color to dark
                    } else {
                        Text(answer)
                            .font(.title)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    
                    Spacer() // Add more space above the button
                    
                    // Shake Button
                    Button(action: {
                        generateAnswerWithDelay()
                    }) {
                        Text("Shake or Press if You Dare")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(radius: 4)
                    }
                    .padding()
                }
                .padding()
            }
            .background(LinearGradient(gradient: Gradient(colors: [Color.purple, Color.black]), startPoint: .top, endPoint: .bottom))
           // .navigationTitle("Dare Game")
            .navigationBarItems(trailing: Button(action: {
                isConfigPanelOpen = true
            }) {
                Image(systemName: "gear")
                    .font(.title2)
            })
            .sheet(isPresented: $isConfigPanelOpen) {
                ConfigPanelView(responses: $responses, delayMs: $delayMs)
            }
        }
    }
    
    private func generateAnswerWithDelay() {
        showLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(delayMs) / 1000.0) { // Apply delay
            answer = responses.randomElement() ?? "Error!"
            showLoading = false
        }
    }
}

// Configuration Panel View
struct ConfigPanelView: View {
    @Binding var responses: [String]
    @Binding var delayMs: Int
    @State private var newResponse: String = ""
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Edit Responses")
                    .font(.headline)
                    .padding()
                
                // Display Existing Responses
                List {
                    ForEach(responses, id: \.self) { response in
                        Text(response)
                    }
                    .onDelete(perform: deleteResponse)
                }
                
                // Add New Response
                HStack {
                    TextField("Add a new response", text: $newResponse)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    Button(action: addResponse) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                    }
                }
                .padding(.bottom)
                
                // Configurable Delay
                VStack {
                    Text("Response Delay (ms): \(delayMs)")
                        .font(.subheadline)
                    
                    Slider(value: Binding(
                        get: { Double(delayMs) },
                        set: { delayMs = Int($0) }
                    ), in: 0...5000, step: 100)
                        .padding()
                }
                
                Spacer()
            }
            .navigationBarTitle("Configuration", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        Magic8BallDataManager.saveResponses(responses)
                        Magic8BallDataManager.saveDelay(delayMs)
                        UIApplication.shared.windows.first?.rootViewController?.dismiss(animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
    // Add a new response
    private func addResponse() {
        guard !newResponse.isEmpty else { return }
        responses.append(newResponse)
        Magic8BallDataManager.saveResponses(responses)
        newResponse = ""
    }
    
    // Delete a response
    private func deleteResponse(at offsets: IndexSet) {
        responses.remove(atOffsets: offsets)
        Magic8BallDataManager.saveResponses(responses)
    }
}

// Data Manager for Saving and Loading
struct Magic8BallDataManager {
    private static let responsesKey = "magic8BallResponses"
    private static let delayKey = "magic8BallDelay"

    // Save responses to UserDefaults
    static func saveResponses(_ responses: [String]) {
        UserDefaults.standard.set(responses, forKey: responsesKey)
    }
    
    // Load responses from UserDefaults
    static func loadResponses() -> [String] {
        if let savedResponses = UserDefaults.standard.array(forKey: responsesKey) as? [String] {
            return savedResponses
        } else {
            // Default responses if no saved data exists
            return [
                "It is certain.",
                "Ask again later.",
                "Don't count on it.",
                "Yes, definitely!",
                "No way!",
                "Outlook good.",
                "Very doubtful.",
                "Try again."
            ]
        }
    }
    
    // Save delay to UserDefaults
    static func saveDelay(_ delay: Int) {
        UserDefaults.standard.set(delay, forKey: delayKey)
    }
    
    // Load delay from UserDefaults
    static func loadDelay() -> Int {
        return UserDefaults.standard.integer(forKey: delayKey) == 0 ? 1000 : UserDefaults.standard.integer(forKey: delayKey) // Default delay is 1000ms
    }
}
