import SwiftUI

struct ReminderView: View {
    @ObservedObject var timerManager: TimerManager
    @AppStorage("isStrictMode") private var isStrictMode: Bool = false
    
    @State private var opac: Double = 0.0
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "eye.slash.fill")
                .font(.system(size: 80))
                .foregroundColor(.white)
                .opacity(opac)
                .animation(Animation.easeInOut(duration: 2).repeatForever(autoreverses: true), value: opac)
                .onAppear {
                    opac = 1.0
                }
            
            Text(timerManager.customReminderMessage)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Text("Look at something 20 feet away for \(Int(timerManager.timeRemaining)) seconds.")
                .font(.title3)
                .foregroundColor(.white.opacity(0.8))
            
            if !isStrictMode {
                HStack(spacing: 20) {
                    Button("Snooze (5m)") {
                        timerManager.snoozeBreak()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.white.opacity(0.3))
                    
                    Button("Skip Break") {
                        timerManager.skipBreak()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.white.opacity(0.3))
                }
                .foregroundColor(.white)
                .padding(.top, 20)
            }
        }
        .padding(.vertical, 60)
        .padding(.horizontal, 40)
        .frame(minWidth: 450)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color.black.opacity(0.6))
                .shadow(color: .black.opacity(0.3), radius: 30, x: 0, y: 15)
        )
        // Blur background to make the pop-up stand out
        .background(VisualEffectView(material: .popover, blendingMode: .behindWindow).clipShape(RoundedRectangle(cornerRadius: 30)))
    }
}

// Helper to access NSVisualEffectView in SwiftUI
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
        visualEffectView.state = .active
        return visualEffectView
    }
    
    func updateNSView(_ visualEffectView: NSVisualEffectView, context: Context) {
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
    }
}
