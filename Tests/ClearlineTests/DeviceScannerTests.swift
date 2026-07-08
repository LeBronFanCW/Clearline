import XCTest
@testable import Clearline

final class DeviceScannerTests: XCTestCase {
    func testFindsSamsungByVendorIDInNestedUSBTree() {
        let fixture: [String: Any] = [
            "SPUSBDataType": [[
                "_name": "USB 3.1 Bus",
                "_items": [[
                    "_name": "SAMSUNG Mobile USB Composite Device",
                    "vendor_id": "0x04e8  (Samsung Electronics Co., Ltd.)",
                    "serial_num": "R58N123456A"
                ]]
            ]]
        ]
        let device = DeviceScanner.findSamsung(in: fixture)
        XCTAssertEqual(device?.name, "SAMSUNG Mobile USB Composite Device")
        XCTAssertEqual(device?.serial, "R58N123456A")
        XCTAssertEqual(device?.connection, "USB")
    }

    func testIgnoresUnrelatedUSBDevice() {
        let fixture: [String: Any] = ["_name": "USB Keyboard", "vendor_id": "0x05ac"]
        XCTAssertNil(DeviceScanner.findSamsung(in: fixture))
    }

    func testFindsSamsungFromIOKitNumericVendorID() {
        let fixture: [String: Any] = [
            "idVendor": NSNumber(value: 0x04e8),
            "USB Product Name": "SAMSUNG Android",
            "USB Serial Number": "ABC123"
        ]
        let device = DeviceScanner.findSamsung(in: fixture)
        XCTAssertEqual(device?.name, "SAMSUNG Android")
        XCTAssertEqual(device?.serial, "ABC123")
    }

    func testMapsSamsungSalesCodesToCarrier() {
        XCTAssertEqual(Carrier(salesCode: "ATT"), .att)
        XCTAssertEqual(Carrier(salesCode: "TMB"), .tmobile)
        XCTAssertEqual(Carrier(salesCode: "VZW"), .verizon)
        XCTAssertNil(Carrier(salesCode: "XAA"))
    }

    func testMasksSerialExceptLastFourCharacters() {
        let device = SamsungDevice(name: "Galaxy", model: nil, serial: "R58N123456A", connection: "USB")
        XCTAssertEqual(device.maskedSerial?.suffix(4), "456A")
        XCTAssertFalse(device.maskedSerial?.contains("R58N") == true)
    }
}
