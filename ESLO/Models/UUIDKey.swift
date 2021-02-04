//
//  UUIDKey.swift
//  ESLO - Matt Gaidica
//

import CoreBluetooth

//let kBLEService_UUID = "F0001110-0451-4000-B000-000000000000"
//let kBLE_Characteristic_uuid_Tx = "F0001131-0451-4000-B000-000000000000"
//let kBLE_Characteristic_uuid_Rx = "F0001131-0451-4000-B000-000000000000"
//let MaxCharacters = 20
//
//let BLEService_UUID = CBUUID(string: kBLEService_UUID)
//let BLE_Characteristic_uuid_Tx = CBUUID(string: kBLE_Characteristic_uuid_Tx)//(Property = Write without response)
//let BLE_Characteristic_uuid_Rx = CBUUID(string: kBLE_Characteristic_uuid_Rx)// (Property = Read/Notify)

//protocol ParticleDelegate {
//}

class ESLOPeripheral: NSObject {
    public static let LEDServiceUUID             = CBUUID.init(string: "f0001110-0451-4000-b000-000000000000")
    public static let redLEDCharacteristicUUID   = CBUUID.init(string: "f0001111-0451-4000-b000-000000000000")
//    public static let greenLEDCharacteristicUUID = CBUUID.init(string: "b4250402-fb4b-4746-b2b0-93f0e61122c6")
//    public static let blueLEDCharacteristicUUID  = CBUUID.init(string: "b4250403-fb4b-4746-b2b0-93f0e61122c6")

    public static let batteryServiceUUID         = CBUUID.init(string: "180f")
    public static let batteryCharacteristicUUID  = CBUUID.init(string: "2a19")

}
