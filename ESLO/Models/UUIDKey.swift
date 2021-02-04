//
//  UUIDKey.swift
//  ESLO - Matt Gaidica
//

import CoreBluetooth

class ESLOPeripheral: NSObject {
    public static let LEDServiceUUID             = CBUUID.init(string: "f0001110-0451-4000-b000-000000000000")
    public static let redLEDCharacteristicUUID   = CBUUID.init(string: "f0001111-0451-4000-b000-000000000000")

    public static let batteryServiceUUID         = CBUUID.init(string: "f0001130-0451-4000-b000-000000000000")
    public static let batteryCharacteristicUUID  = CBUUID.init(string: "f0001132-0451-4000-b000-000000000000")

}
