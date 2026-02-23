import SwiftUI

struct ReminderView: View {
    @ObservedObject var timerManager: TimerManager
    
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
            
            Text("Time to rest your eyes!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Look at something 20 feet away for \(Int(timerManager.timeRemaining)) seconds.")
                .font(.title3)
                .foregroundColor(.white.opacity(0.8))
            
            Button("Skip") {
                timerManager.resetTimer()
            }
            .buttonStyle(.borderedProminent)
            .tint(.white.opacity(0.3))
            .foregroundColor(.white)
            .padding(.top, 20)
        }
        .padding(50)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color.black.opacity(0.7))
                .shadow(radius: 20)
        )
        // Blur background to make the pop-up stand out
        .background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow).clipShape(RoundedRectangle(cornerRadius: 30)))
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
