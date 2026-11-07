import SwiftUI

/// Root view for the RigAssist AI application.
///
/// During the calculator interface development phase, the calculator is
/// presented directly from the root view. Additional application navigation
/// for Reference and Ask AI features can be added as those modules are built.
struct ContentView: View {
    var body: some View {
        CalculatorView()
    }
}

#Preview {
    ContentView()
}
