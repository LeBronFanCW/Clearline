import SwiftUI

struct MainView: View {
    @EnvironmentObject private var scanner: DeviceScanner
    @Environment(\.openURL) private var openURL
    @State private var carrier: Carrier = .att
    @State private var paidOff = false
    @State private var accountCurrent = false
    @State private var clearStatus = false
    let onShowNotice: () -> Void

    private var eligible: Bool { paidOff && accountCurrent && clearStatus }

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 220, ideal: 240, max: 270)
        } detail: {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header
                    devicePanel
                    if case .connected = scanner.status {
                        carrierSection
                        eligibilitySection
                    }
                }
                .frame(maxWidth: 760, alignment: .leading)
                .padding(.horizontal, 46)
                .padding(.vertical, 38)
            }
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.45))
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if isConnected {
                    VStack(spacing: 0) {
                        Divider()
                        actionSection
                            .frame(maxWidth: 760)
                            .padding(.horizontal, 46)
                            .padding(.vertical, 14)
                    }
                    .frame(maxWidth: .infinity)
                    .background(.bar)
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
        .onChange(of: scanner.status) { _, status in
            if case let .connected(device) = status, let hint = device.carrierHint {
                carrier = hint
            }
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "link.badge.plus")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                Text("Clearline")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
            }
            .padding(.horizontal, 18)
            .padding(.top, 20)
            .padding(.bottom, 26)

            StepLabel(number: 1, title: "Connect phone", complete: isConnected)
            StepLabel(number: 2, title: "Choose carrier", complete: isConnected)
            StepLabel(number: 3, title: "Confirm eligibility", complete: eligible)
            StepLabel(number: 4, title: "Continue officially", complete: false)

            Spacer()
            Button(action: onShowNotice) {
                Label("Safety & ownership", systemImage: "checkmark.shield")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .padding(18)
        }
        .background(.bar)
    }

    private var isConnected: Bool {
        if case .connected = scanner.status { true } else { false }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Carrier unlock guide")
                .font(.system(size: 30, weight: .bold, design: .rounded))
            Text("Connect your Samsung with a USB cable. Clearline will identify it and take you to the carrier that controls its unlock.")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder private var devicePanel: some View {
        HStack(spacing: 22) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(statusTint.opacity(0.11))
                    .frame(width: 92, height: 108)
                Image(systemName: deviceIcon)
                    .font(.system(size: 39, weight: .medium))
                    .foregroundStyle(statusTint)
                    .symbolEffect(.pulse, options: .repeating.speed(0.55), isActive: isSearching)
            }

            VStack(alignment: .leading, spacing: 7) {
                Text(deviceTitle)
                    .font(.system(size: 20, weight: .semibold))
                Text(deviceSubtitle)
                    .foregroundStyle(.secondary)
                if case let .connected(device) = scanner.status {
                    HStack(spacing: 14) {
                        Label(device.connection, systemImage: "cable.connector")
                        if let model = device.model, model != device.name {
                            Label(model, systemImage: "tag")
                        }
                        if let serial = device.maskedSerial {
                            Label(serial, systemImage: "number")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
                }
            }
            Spacer()
            Button { scanner.refresh() } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            .help("Scan again")
            .disabled(isSearching)
        }
        .padding(22)
        .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.primary.opacity(0.09), lineWidth: 1)
        }
    }

    private var carrierSection: some View {
        VStack(alignment: .leading, spacing: 13) {
            SectionTitle(kicker: "STEP 2", title: "Who originally sold the phone?")
            Picker("Original carrier", selection: $carrier) {
                ForEach(Carrier.allCases) { carrier in Text(carrier.rawValue).tag(carrier) }
            }
            .pickerStyle(.segmented)
            Text(carrier.guidance)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineSpacing(2)
                .padding(.top, 2)
        }
    }

    private var eligibilitySection: some View {
        VStack(alignment: .leading, spacing: 13) {
            SectionTitle(kicker: "STEP 3", title: "Confirm the carrier can approve it")
            VStack(spacing: 0) {
                EligibilityToggle(isOn: $paidOff, title: "Device balance is paid in full", detail: "No remaining installment or lease balance")
                Divider().padding(.leading, 48)
                EligibilityToggle(isOn: $accountCurrent, title: "Account requirements are met", detail: "Service period and account standing vary by carrier")
                Divider().padding(.leading, 48)
                EligibilityToggle(isOn: $clearStatus, title: "Not reported lost, stolen, or fraudulent", detail: "The carrier checks its own records")
            }
            .background(.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            }
        }
    }

    private var actionSection: some View {
        HStack(spacing: 18) {
            Image(systemName: eligible ? "arrow.up.right.square.fill" : "lock.fill")
                .font(.system(size: 25, weight: .semibold))
                .foregroundStyle(eligible ? Color.accentColor : .secondary)
            VStack(alignment: .leading, spacing: 3) {
                Text(eligible ? "Ready for the carrier check" : "Complete the eligibility checks")
                    .font(.headline)
                Text("The carrier—not this Mac—makes the final decision.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(carrier.actionTitle) { openURL(carrier.officialURL) }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!eligible)
        }
        .padding(20)
        .background(Color.accentColor.opacity(eligible ? 0.085 : 0.035), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var isSearching: Bool { if case .searching = scanner.status { true } else { false } }
    private var statusTint: Color { isConnected ? .green : (isSearching ? .accentColor : .secondary) }
    private var deviceIcon: String { isConnected ? "smartphone" : (isSearching ? "cable.connector" : "cable.connector.slash") }
    private var deviceTitle: String {
        switch scanner.status {
        case .searching: "Looking for a Samsung…"
        case let .connected(device): device.displayModel
        case .unavailable: "Connect your Samsung"
        }
    }
    private var deviceSubtitle: String {
        switch scanner.status {
        case .searching: "Checking USB devices"
        case .connected: "Samsung phone found and ready"
        case let .unavailable(message): "\(message). Unlock the phone and try another data cable or USB port."
        }
    }
}

private struct StepLabel: View {
    let number: Int
    let title: String
    let complete: Bool
    var body: some View {
        HStack(spacing: 11) {
            ZStack {
                Circle().fill(complete ? Color.green.opacity(0.16) : Color.primary.opacity(0.06)).frame(width: 28, height: 28)
                Image(systemName: complete ? "checkmark" : "\(number)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(complete ? .green : .secondary)
            }
            Text(title).font(.callout.weight(.medium)).foregroundStyle(number == 1 || complete ? .primary : .secondary)
            Spacer()
        }
        .padding(.horizontal, 18)
        .frame(height: 44)
    }
}

private struct SectionTitle: View {
    let kicker: String
    let title: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(kicker).font(.caption2.weight(.bold)).tracking(1.2).foregroundStyle(Color.accentColor)
            Text(title).font(.system(size: 18, weight: .semibold))
        }
    }
}

private struct EligibilityToggle: View {
    @Binding var isOn: Bool
    let title: String
    let detail: String
    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.callout.weight(.medium))
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
        }
        .toggleStyle(.checkbox)
        .padding(.horizontal, 16)
        .frame(minHeight: 61)
    }
}
