import SwiftUI

struct RootView: View {
    @AppStorage("acceptedOwnershipNotice") private var acceptedNotice = false

    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor).ignoresSafeArea()
            if acceptedNotice {
                MainView(onShowNotice: { acceptedNotice = false })
                    .transition(.opacity.combined(with: .scale(scale: 0.985)))
            } else {
                OwnershipNotice(onContinue: { withAnimation(.easeOut(duration: 0.22)) { acceptedNotice = true } })
                    .transition(.opacity)
            }
        }
    }
}

private struct OwnershipNotice: View {
    @State private var ownsPhone = false
    @State private var paidOff = false
    @State private var notStolen = false
    let onContinue: () -> Void

    private var canContinue: Bool { ownsPhone && paidOff && notStolen }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 34)
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.accentColor.opacity(0.10))
                    .frame(width: 78, height: 78)
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
            }
            .accessibilityHidden(true)

            Text("Start with rightful ownership")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .padding(.top, 24)
            Text("Clearline only helps owners use the carrier’s official unlock process. It cannot bypass a carrier lock, blacklist, payment balance, or theft report.")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .frame(maxWidth: 570)
                .padding(.top, 10)

            VStack(spacing: 10) {
                ConfirmationRow(isOn: $ownsPhone, title: "I own this phone or have the owner’s permission", icon: "person.crop.circle.badge.checkmark")
                ConfirmationRow(isOn: $paidOff, title: "The phone is paid off and the account is in good standing", icon: "creditcard.and.123")
                ConfirmationRow(isOn: $notStolen, title: "The phone is not lost, stolen, or involved in fraud", icon: "hand.raised")
            }
            .frame(maxWidth: 610)
            .padding(.top, 28)

            Button(action: onContinue) {
                Text("I understand — find my phone")
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!canContinue)
            .frame(maxWidth: 610)
            .padding(.top, 22)

            Text("No account credentials or phone data are collected.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.top, 12)
            Spacer(minLength: 34)
        }
        .padding(.horizontal, 48)
    }
}

private struct ConfirmationRow: View {
    @Binding var isOn: Bool
    let title: String
    let icon: String

    var body: some View {
        Button { isOn.toggle() } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(isOn ? Color.accentColor : .secondary)
                    .frame(width: 24)
                Text(title)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(isOn ? Color.accentColor : Color.secondary.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .frame(height: 54)
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isOn ? Color.accentColor.opacity(0.45) : Color.primary.opacity(0.10), lineWidth: 1)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityValue(isOn ? "Confirmed" : "Not confirmed")
    }
}

struct SettingsView: View {
    @AppStorage("acceptedOwnershipNotice") private var acceptedNotice = false
    @EnvironmentObject private var updates: UpdateController
    var body: some View {
        Form {
            Section("Updates") {
                LabeledContent("Version", value: updates.currentVersion)
                Toggle("Automatically check for updates", isOn: $updates.automaticallyChecks)
                    .disabled(!updates.isConfigured)
                Toggle("Download and install updates automatically", isOn: $updates.automaticallyDownloads)
                    .disabled(!updates.isConfigured)
                HStack {
                    Text(updates.statusText)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Check Now") { updates.checkForUpdates() }
                        .disabled(!updates.isConfigured || !updates.canCheckForUpdates)
                }
            }
            LabeledContent("Safety notice") {
                Button("Show again next launch") { acceptedNotice = false }
            }
            Text("Clearline scans local USB device information only. It does not transmit device identifiers or store account details.")
                .foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
        .frame(width: 520, height: 390)
    }
}
