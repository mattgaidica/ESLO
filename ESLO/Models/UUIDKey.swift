//
//  UUIDKey.swift
//  ESLO - Matt Gaidica
//

import CoreBluetooth

// remember to whitelist chars in didDiscoverServices
class ESLOPeripheral: NSObject {
    public static let ESLOServiceUUID            = CBUUID.init(string: "E000")
    public static let LEDCharacteristicUUID      = CBUUID.init(string: "E001")
    public static let vitalsCharacteristicUUID   = CBUUID.init(string: "E002")
    public static let settingsCharacteristicUUID = CBUUID.init(string: "E003")
    public static let EEGCharacteristicUUID      = CBUUID.init(string: "E004")
    public static let AXYCharacteristicUUID      = CBUUID.init(string: "E005")
    public static let addrCharacteristicUUID     = CBUUID.init(string: "E006")
    public static let swaCharacteristicUUID      = CBUUID.init(string: "E007")
}
