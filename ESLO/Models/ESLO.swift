//
//  ESLO.swift
//  ESLO
//
//  Created by Matt Gaidica on 2/9/21.
//

import Foundation

struct ESLO_Settings {
    var SleepWake   = UInt8(0)
    var EEGDuty     = UInt8(0)
    var EEGDuration = UInt8(0)
    var EEG1        = UInt8(0)
    var EEG2        = UInt8(0)
    var EEG3        = UInt8(0)
    var EEG4        = UInt8(0)
    var AxyMode     = UInt8(0)
    var TxPower     = UInt8(0)
    var Time1       = UInt8(0)
    var Time2       = UInt8(0)
    var Time3       = UInt8(0)
    var Time4       = UInt8(0)
};

func encodeESLOSettings(_ settings: ESLO_Settings) -> [UInt8] {
    var rawSettings: Array<UInt8> = Array(repeating: 0, count: 16)
    rawSettings[0]  = settings.SleepWake
    rawSettings[1]  = settings.EEGDuty
    rawSettings[2]  = settings.EEGDuration
    rawSettings[3]  = settings.EEG1
    rawSettings[4]  = settings.EEG2
    rawSettings[5]  = settings.EEG3
    rawSettings[6]  = settings.EEG4
    rawSettings[7]  = settings.AxyMode
    rawSettings[8]  = settings.TxPower
    rawSettings[9]  = settings.Time1
    rawSettings[10] = settings.Time2
    rawSettings[11] = settings.Time3
    rawSettings[12] = settings.Time4
    return rawSettings
}

func decodeESLOSettings(_ settings: [UInt8]) -> ESLO_Settings {
    var newSettings: ESLO_Settings! = ESLO_Settings()
    newSettings.SleepWake       = settings[0]
    newSettings.EEGDuty         = settings[1]
    newSettings.EEGDuration     = settings[2]
    newSettings.EEG1            = settings[3]
    newSettings.EEG2            = settings[4]
    newSettings.EEG3            = settings[5]
    newSettings.EEG4            = settings[6]
    newSettings.AxyMode         = settings[7]
    newSettings.TxPower         = settings[8]
    newSettings.Time1           = settings[9]
    newSettings.Time2           = settings[10]
    newSettings.Time3           = settings[11]
    newSettings.Time4           = settings[12]
    
    return newSettings
}

func decodeESLOPacket(_ packet: UInt32) -> (eslo_type: UInt8, eslo_data: Int32) {
    var thisType: UInt8
    var thisData: UInt32
    thisType = UInt8(packet >> 24)
    if ((packet & 0x00800000) != 0) {
        thisData = packet | 0xFF000000; // 0xFF000000
    } else {
        thisData = packet & 0x00FFFFFF;
    }
    if thisData > UInt32(Int32.max) {
        
    }
    let thisData_trun = Int32(truncatingIfNeeded: thisData)
    return (thisType, thisData_trun)
}
