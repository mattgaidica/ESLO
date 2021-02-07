//
//  UUIDKey.swift
//  ESLO - Matt Gaidica
//

import CoreBluetooth

class ESLOPeripheral: NSObject {
    public static let LEDServiceUUID             = CBUUID.init(string: "f0001110-0451-4000-b000-000000000000")
    public static let redLEDCharacteristicUUID   = CBUUID.init(string: "FFF1")

    public static let streamServiceUUID          = CBUUID.init(string: "FFF0")
    public static let batteryCharacteristicUUID  = CBUUID.init(string: "FFF5")
    public static let EEG1CharacteristicUUID     = CBUUID.init(string: "FFF4")
    public static let EEG2CharacteristicUUID     = CBUUID.init(string: "f0001133-0451-4000-b000-000000000000")
    public static let EEG3CharacteristicUUID     = CBUUID.init(string: "f0001134-0451-4000-b000-000000000000")
    public static let EEG4CharacteristicUUID     = CBUUID.init(string: "f0001135-0451-4000-b000-000000000000")
    
    public static let Axy1CharacteristicUUID     = CBUUID.init(string: "f0001135-0451-4000-b000-000000000000")
    public static let Axy2CharacteristicUUID     = CBUUID.init(string: "f0001135-0451-4000-b000-000000000000")
    public static let Axy3CharacteristicUUID     = CBUUID.init(string: "f0001135-0451-4000-b000-000000000000")
}
