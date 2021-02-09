//
//  ESLO.swift
//  ESLO
//
//  Created by Matt Gaidica on 2/9/21.
//

import Foundation

func decodeESLO(packet: UInt32) -> (eslo_type: UInt8, eslo_data: Int32) {
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
