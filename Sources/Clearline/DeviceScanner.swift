import Foundation

@MainActor
final class DeviceScanner: ObservableObject {
    enum Status: Equatable {
        case searching
        case connected(SamsungDevice)
        case unavailable(String)
    }

    @Published private(set) var status: Status = .searching
    @Published private(set) var lastChecked = Date()
    private var scanTask: Task<Void, Never>?

    deinit { scanTask?.cancel() }

    func start() {
        guard scanTask == nil else { return }
        scanTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.scan()
                try? await Task.sleep(for: .seconds(3))
            }
        }
    }

    func refresh() {
        status = .searching
        Task { await scan() }
    }

    private func scan() async {
        if case .connected = status { } else { status = .searching }
        let result = await Task.detached(priority: .utility) {
            Self.detectDevice()
        }.value
        lastChecked = Date()
        status = result.map(Status.connected) ?? .unavailable("No Samsung phone found")
    }

    nonisolated static func detectDevice() -> SamsungDevice? {
        if ProcessInfo.processInfo.environment["CLEARLINE_DEMO_DEVICE"] == "1" {
            return SamsungDevice(
                name: "Samsung Galaxy S25 Ultra",
                model: "SM-S938U",
                serial: "R5CX10DEMO1",
                connection: "USB · preview device"
            )
        }
        if let adb = adbDevice() { return adb }
        guard let data = run("/usr/sbin/system_profiler", ["SPUSBDataType", "-json"]),
              let object = try? JSONSerialization.jsonObject(with: data) else { return ioregDevice() }
        return findSamsung(in: object) ?? ioregDevice()
    }

    nonisolated static func findSamsung(in value: Any) -> SamsungDevice? {
        if let dictionary = value as? [String: Any] {
            let values = dictionary.values.compactMap { $0 as? String }.joined(separator: " ").lowercased()
            let vendor = (dictionary["vendor_id"] as? String)?.lowercased() ?? ""
            let numericVendor = (dictionary["idVendor"] as? NSNumber)?.intValue
            if values.contains("samsung") || vendor.contains("0x04e8") || numericVendor == 0x04e8 {
                let name = (dictionary["_name"] as? String)
                    ?? (dictionary["USB Product Name"] as? String)
                    ?? (dictionary["kUSBProductString"] as? String)
                    ?? "Samsung Galaxy"
                let serial = (dictionary["serial_num"] as? String)
                    ?? (dictionary["USB Serial Number"] as? String)
                    ?? (dictionary["kUSBSerialNumberString"] as? String)
                return SamsungDevice(name: name, model: nil, serial: serial, connection: "USB")
            }
            for child in dictionary.values {
                if let result = findSamsung(in: child) { return result }
            }
        } else if let array = value as? [Any] {
            for child in array {
                if let result = findSamsung(in: child) { return result }
            }
        }
        return nil
    }

    nonisolated private static func adbDevice() -> SamsungDevice? {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let possiblePaths = [
            "/opt/homebrew/bin/adb",
            "/usr/local/bin/adb",
            "\(home)/Library/Android/sdk/platform-tools/adb"
        ]
        guard let path = possiblePaths.first(where: { FileManager.default.isExecutableFile(atPath: $0) }),
              let devicesData = run(path, ["devices"]),
              let devices = String(data: devicesData, encoding: .utf8),
              devices.split(separator: "\n").dropFirst().contains(where: { $0.hasSuffix("\tdevice") }) else { return nil }

        func property(_ key: String) -> String? {
            guard let data = run(path, ["shell", "getprop", key]),
                  let value = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !value.isEmpty else { return nil }
            return value
        }
        guard property("ro.product.manufacturer")?.localizedCaseInsensitiveContains("samsung") == true else { return nil }
        let model = property("ro.product.model")
        let name = property("ro.product.marketname") ?? model ?? "Samsung Galaxy"
        let serial = property("ro.serialno")
        let salesCode = property("ro.csc.sales_code") ?? property("ro.boot.carrierid")
        return SamsungDevice(
            name: name,
            model: model,
            serial: serial,
            connection: "USB · debugging enabled",
            carrierHint: salesCode.flatMap(Carrier.init(salesCode:))
        )
    }

    nonisolated private static func ioregDevice() -> SamsungDevice? {
        guard let data = run("/usr/sbin/ioreg", ["-a", "-p", "IOUSB", "-l", "-w", "0"]),
              let object = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil)
        else { return nil }
        return findSamsung(in: object)
    }

    nonisolated private static func run(_ executable: String, _ arguments: [String]) -> Data? {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else { return nil }
            return pipe.fileHandleForReading.readDataToEndOfFile()
        } catch { return nil }
    }
}
