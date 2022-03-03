//
//  ViewController.swift
//  ESLO
//
//  Created by Matt Gaidica on 2/3/21.
//
// colors:  http://0xrgb.com/#flat
// write to file: https://www.hackingwithswift.com/books/ios-swiftui/writing-data-to-the-documents-directory
import UIKit
@IBDesignable extension UIButton {

    @IBInspectable var borderWidth: CGFloat {
        set {
            layer.borderWidth = newValue
        }
        get {
            return layer.borderWidth
        }
    }

    @IBInspectable var cornerRadius: CGFloat {
        set {
            layer.cornerRadius = newValue
        }
        get {
            return layer.cornerRadius
        }
    }

    @IBInspectable var borderColor: UIColor? {
        set {
            guard let uiColor = newValue else { return }
            layer.borderColor = uiColor.cgColor
        }
        get {
            guard let color = layer.borderColor else { return nil }
            return UIColor(cgColor: color)
        }
    }
}
import Charts
import CoreBluetooth

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    @IBOutlet weak var chartViewEEG: LineChartView!
    @IBOutlet weak var chartViewAxy: LineChartView!
    @IBOutlet weak var Header: UIView!
    @IBOutlet weak var DeviceLabel: UILabel!
    @IBOutlet weak var batteryPercentLabel: UILabel!
    @IBOutlet weak var DeviceView: UIView!
    @IBOutlet weak var ConnectBtn: UIButton!
    @IBOutlet weak var RSSILabel: UILabel!
    @IBOutlet weak var BatteryBar: UIProgressView!
    @IBOutlet weak var ESLOTerminal: UITextView!
    @IBOutlet weak var WriteTimeLabel: UILabel!
    @IBOutlet weak var DurationSlider: UISlider!
    @IBOutlet weak var DurationLabel: UILabel!
    @IBOutlet weak var DutySlider: UISlider!
    @IBOutlet weak var DisconnectOverlay: UIView!
    @IBOutlet weak var DutyLabel: UILabel!
    @IBOutlet weak var SleepWakeSwitch: UISwitch!
    @IBOutlet weak var EEG1Switch: UISwitch!
    @IBOutlet weak var EEG2Switch: UISwitch!
    @IBOutlet weak var EEG3Switch: UISwitch!
    @IBOutlet weak var EEG4Switch: UISwitch!
    @IBOutlet weak var LEDSwitch: UISwitch!
    @IBOutlet weak var AxySwitch: UISegmentedControl!
    @IBOutlet weak var PushActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var PushButton: UIButton!
    @IBOutlet weak var HexTimeLabel: UILabel!
    @IBOutlet weak var RmOffsetSwitch: UISwitch!
    @IBOutlet weak var DataSyncLabel: UILabel!
    @IBOutlet weak var SciUnitsSwitch: UISwitch!
    @IBOutlet weak var AxyUnitsLabel: UILabel!
    @IBOutlet weak var EEGUnitsLabel: UILabel!
    @IBOutlet weak var ThermLabel: UILabel!
    @IBOutlet weak var ThermFLabel: UILabel!
    @IBOutlet weak var AdvLongSwitch: UISwitch!
    @IBOutlet weak var BattMinLabel: UILabel!
    @IBOutlet weak var EsloAddrLabel: UILabel!
    @IBOutlet weak var ResetButton: UIButton!
    @IBOutlet weak var SWASwitch: UISegmentedControl!
    @IBOutlet weak var AxyMoveLabel: UILabel!
    @IBOutlet weak var SWAThreshSlider: UISlider!
    @IBOutlet weak var SWAThreshLabel: UILabel!
    @IBOutlet weak var SWARatioLabel: UILabel!
    @IBOutlet weak var SWARatioSlider: UISlider!
    @IBOutlet weak var RecRatioLabel: UILabel!
    
    // Characteristics
    private var LEDChar: CBCharacteristic?
    private var vitalsChar: CBCharacteristic?
    private var EEGChar: CBCharacteristic?
    private var AXYChar: CBCharacteristic?
    private var settingsChar: CBCharacteristic?
    private var addrChar: CBCharacteristic?
    private var swaChar: CBCharacteristic?
    
    var exportCount: Int = 0
    var esloExportBlock: UInt32 = 0
    var exportUrl: URL = URL("empty")
    var timeoutConnTimer = Timer()
    var RSSITimer = Timer()
    var timeOutSec: Double = 60*2
    var RSSI: NSNumber = 0
    var terminalCount: Int = 1
    var EEGCount: Int = 0
    
    var BOTH_CHARTS: Int = 3
    var AXY_CHART: Int = 1
    var AXY_FS: Double = 1
    var uVFactor: Double = 1000000.0
    // !!was 32
    var AXYXData: Array<Int32> = Array(repeating: 0, count: 4)
    var AXYYData: Array<Int32> = Array(repeating: 0, count: 4)
    var AXYZData: Array<Int32> = Array(repeating: 0, count: 4)
    
    var AXYXPlot: Array<Int32> = Array(repeating: 0, count: 4*10)
    var AXYYPlot: Array<Int32> = Array(repeating: 0, count: 4*10)
    var AXYZPlot: Array<Int32> = Array(repeating: 0, count: 4*10)
    
    var AXYnewX: Bool = false
    var AXYnewY: Bool = false
    var AXYnewZ: Bool = false
    
    var EEG_FS: Double = 125 // divided by 2 from 250
    var EEG_CHART: Int = 2
    // 62*4=248 which is eeg packet size
    var EEG1Data: Array<Int32> = Array(repeating: 0, count: 62)
    var EEG2Data: Array<Int32> = Array(repeating: 0, count: 62)
    var EEG3Data: Array<Int32> = Array(repeating: 0, count: 62)
    var EEG4Data: Array<Int32> = Array(repeating: 0, count: 62)
    // make this a multiple of 248
    var EEG1Plot: Array<Int32> = Array(repeating: 0, count: 512)
    var EEG2Plot: Array<Int32> = Array(repeating: 0, count: 512)
    var EEG3Plot: Array<Int32> = Array(repeating: 0, count: 512)
    var EEG4Plot: Array<Int32> = Array(repeating: 0, count: 512)
    
    var EEGnew1: Bool = false
    var EEGnew2: Bool = false
    var EEGnew3: Bool = false
    var EEGnew4: Bool = false
    
    // States
    let axyArr = [1,10]
    let dutyArr = [0, 1, 5, 10, 30, 60] // minutes
    let durationArr = [0, 1, 5, 10, 30, 60] // minutes
    var esloType: UInt8 = 0
    let resetAlpha: CGFloat = 0.3
    
    // Other
    let pasteboard = UIPasteboard.general
    var iosSettings: ESLO_Settings! = ESLO_Settings()
    var esloSettings: ESLO_Settings! = ESLO_Settings()
    
    // Properties
    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral!
    
    // Graph Vars
    var DCoffset: Double = 0.0
    var data = LineChartData()
    var lineChartEntry = [ChartDataEntry]()
    let textColor = UIColor.white
    // line colors, see: http://0xrgb.com/#material
    let EEG1Color = UIColor(red: 255/255, green: 87/255, blue: 34/255, alpha: 1) // deep orange
    let EEG2Color = UIColor(red: 205/255, green: 220/255, blue: 57/255, alpha: 1) // lime
    let EEG3Color = UIColor(red: 0/255, green: 188/255, blue: 212/255, alpha: 1) // cyan
    let EEG4Color = UIColor(red: 96/255, green: 125/255, blue: 139/255, alpha: 1) // blue grey
    let AXYXColor = UIColor(red: 3/255, green: 169/255, blue: 244/255, alpha: 1) // light blue
    let AXYYColor = UIColor(red: 156/255, green: 39/255, blue: 176/255, alpha: 1) // purple
    let AXYZColor = UIColor(red: 255/255, green: 239/255, blue: 59/255, alpha: 1) // yellow
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func overlayOn() {
        self.view.bringSubviewToFront(DisconnectOverlay)
        DisconnectOverlay.backgroundColor = .black
    }
    
    func overlayOff() {
        self.view.sendSubviewToBack(DisconnectOverlay)
        DisconnectOverlay.backgroundColor = .clear
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overlayOn()
        print("View loaded")
        Header.setTwoGradient(colorOne: UIColor.purple, colorTwo: UIColor.blue)
//        updateChart() // !! init chart?
        centralManager = CBCentralManager(delegate: self, queue: nil)
        WriteTimeLabel.text = getTimeStr()
        ESLOTerminal.text = ""
        updateSWASwitch()
        updateSWAThreshLabel()
    }
    
    @IBAction func LEDChange(_ sender: Any) {
        if settingsChar != nil {
            LEDSwitch.isEnabled = false
            peripheral.writeValue(Data([LEDSwitch.isOn.uint8Value]), for: LEDChar!, type: .withResponse)
            peripheral.readValue(for: LEDChar!)
        }
    }
    
    func printESLO(_ text: String) {
        let formatString = NSLocalizedString("%03i", comment: "terminal")
        ESLOTerminal.text = String(format: formatString, terminalCount) + ">> " + text + "\n" + ESLOTerminal.text
        terminalCount += 1
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // If we're powered on, start scanning
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("Central state update")
        if central.state != .poweredOn {
            print("Central is not powered on")
        } else {
            scanBTE()
            updateChart(BOTH_CHARTS)
        }
    }
    
    func scanBTE() {
        centralManager.scanForPeripherals(withServices: [ESLOPeripheral.ESLOServiceUUID],
                                          options: [CBCentralManagerScanOptionAllowDuplicatesKey : false])
        updateChart(BOTH_CHARTS)
        timeoutConnTimer = Timer.scheduledTimer(withTimeInterval: timeOutSec, repeats: false) { timer in
            self.cancelScan()
        }
    }
    
    // Handles the result of the scan
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // We've found it so stop scan
        self.centralManager.stopScan()
        // Copy the peripheral instance
        self.peripheral = peripheral
        self.peripheral.delegate = self
        self.RSSI = RSSI
        // Connect!
        ESLOTerminal.text = ""
        printESLO("Scanned " + getTimeStr())
        self.centralManager.connect(self.peripheral, options: nil)
    }
    
    func getTimeStr() -> String {
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d HH:mm:ss"
        return dateFormatter.string(from: date)
    }
    
    func hexTime() -> String {
        let seconds =  UInt32(NSDate().timeIntervalSince1970)
        let hexDateString = String(format: "0x%llX", seconds)
        
        // set iosSettings
        iosSettings.Time1 = UInt8(seconds & 0xFF)
        iosSettings.Time2 = UInt8(seconds >> 8 & 0xFF)
        iosSettings.Time3 = UInt8(seconds >> 16 & 0xFF)
        iosSettings.Time4 = UInt8(seconds >> 24 & 0xFF)
        
        return hexDateString
    }
    
    func delegateRSSI() {
        if self.peripheral != nil {
            self.peripheral.delegate = self
            self.peripheral.readRSSI()
        }
    }
    
    func updateRSSI(RSSI: NSNumber!) {
        let str : String = RSSI.stringValue
        RSSILabel.text = str + "dB"
        WriteTimeLabel.text = getTimeStr()
        HexTimeLabel.text = hexTime()
    }
    
    func startReadRSSI() {
        self.RSSITimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            self.delegateRSSI()
        }
    }
    
    func stopReadRSSI() {
        self.RSSITimer.invalidate()
    }
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        updateRSSI(RSSI: RSSI)
    }
    
    // The handler if we do connect succesfully
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if peripheral == self.peripheral {
            timeoutConnTimer.invalidate()
            DeviceLabel.text = peripheral.name
            updateRSSI(RSSI: RSSI)
            DeviceView.backgroundColor = UIColor(hex: "#27ae60ff") // green
            ConnectBtn.setTitle("Disconnect", for: .normal)
            self.startReadRSSI()
            peripheral.discoverServices([ESLOPeripheral.ESLOServiceUUID])
            print("Connected to ESLO")
            printESLO("Connected to ESLO device")
            overlayOff()
            PushButton.isEnabled = true
            PushButton.alpha = 1
        }
    }
    
    // discovery event
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                if service.uuid == ESLOPeripheral.ESLOServiceUUID {
                    print("Service found")
                    peripheral.discoverCharacteristics([ESLOPeripheral.LEDCharacteristicUUID, ESLOPeripheral.vitalsCharacteristicUUID, ESLOPeripheral.settingsCharacteristicUUID, ESLOPeripheral.EEGCharacteristicUUID,
                                                        ESLOPeripheral.AXYCharacteristicUUID,ESLOPeripheral.addrCharacteristicUUID,ESLOPeripheral.swaCharacteristicUUID], for: service)
                }
            }
        }
    }
    
    // Handling discovery of characteristics
    // manually via peripheral.readValueForCharacteristic(characteristic) <- will callback
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if characteristic.uuid == ESLOPeripheral.LEDCharacteristicUUID {
                    print("LED characteristic found")
                    printESLO("Found LED")
                    // Set the characteristic
                    LEDChar = characteristic
                    peripheral.setNotifyValue(true, for: characteristic)
                    if characteristic.value != nil {
                        let data:Data = characteristic.value!
                        let number = data.withUnsafeBytes { pointer in
                            return pointer.load(as: UInt8.self)
                        }
                        LEDSwitch.isOn = number.boolValue
                    }
                }
                if characteristic.uuid == ESLOPeripheral.vitalsCharacteristicUUID {
                    print("Battery characteristic found")
                    printESLO("Found Vitals")
                    vitalsChar = characteristic
                    peripheral.setNotifyValue(true, for: characteristic)
                }
                if characteristic.uuid == ESLOPeripheral.settingsCharacteristicUUID {
                    print("Settings characteristic found")
                    printESLO("Found Settings")
                    settingsChar = characteristic
                    peripheral.setNotifyValue(true, for: characteristic)
                    printESLO("Reading settings")
                    peripheral.readValue(for: settingsChar!) // cue read of esloSettings
                }
                if characteristic.uuid == ESLOPeripheral.EEGCharacteristicUUID {
                    print("EEG characteristic found")
                    printESLO("Found EEG")
                    EEGChar = characteristic
                    peripheral.setNotifyValue(true, for: characteristic)
                }
                if characteristic.uuid == ESLOPeripheral.AXYCharacteristicUUID {
                    print("AXY characteristic found")
                    printESLO("Found AXY")
                    AXYChar = characteristic
                    peripheral.setNotifyValue(true, for: characteristic)
                }
                if characteristic.uuid == ESLOPeripheral.addrCharacteristicUUID {
                    print("Addr characteristic found")
                    printESLO("Found Addr")
                    addrChar = characteristic
                    peripheral.setNotifyValue(true, for: characteristic)
                }
                if characteristic.uuid == ESLOPeripheral.swaCharacteristicUUID {
                    print("SWA characteristic found")
                    printESLO("Found SWA")
                    swaChar = characteristic
                }
            }
        }
    }
    
    // attempt made to notify
    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateNotificationStateFor characteristic: CBCharacteristic,
                    error: Error?) {
        print("Enabling notify ", characteristic.uuid)
        if error != nil {
            print("Enable notify error")
        }
    }
    
    // notification recieved
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        // this is a readValue callback from setting value
        if characteristic == LEDChar {
            let data:UInt8 = characteristic.value![0]
            LEDSwitch.isOn = data.boolValue
            LEDSwitch.isEnabled = true
        }
        if characteristic == vitalsChar {
            let data:Data = characteristic.value! //get a data object from the CBCharacteristic
            // same method call, without type annotations
            let _ = data.withUnsafeBytes { pointer in
                let vBatt = Float(pointer.load(as: Int32.self)) / 1000000
                let minBatt = Float(pointer.load(fromByteOffset:4, as: Int32.self)) / 1000000
                let temp_C = Float(pointer.load(fromByteOffset:8, as: Int32.self)) / 1000000
                let esloAddr = pointer.load(fromByteOffset:12, as: Int32.self)
                let axyMove = pointer.load(fromByteOffset:16, as: UInt8.self)
                
                let formatString = NSLocalizedString("%1.2fV", comment: "vBatt")
                batteryPercentLabel.text = String(format: formatString, vBatt)
                BattMinLabel.text = String(format: formatString, minBatt)
                BatteryBar.progress = vBatt.converting(from: 2.5...3.0, to: 0.0...1.0)
                
                if temp_C < 100 && temp_C > 0 {
                    let formatString = NSLocalizedString("%2.1f°C", comment: "therm")
                    ThermLabel.text = String(format: formatString, temp_C)
                    let formatStringF = NSLocalizedString("%2.1f°F", comment: "therm")
                    ThermFLabel.text = String(format: formatStringF, temp_C * 1.8 + 32)
                } else {
                    ThermLabel.text = "--.-°C"
                    ThermFLabel.text = "--.-°F"
                }
                
                UIView.animate(withDuration: 0.2, animations: { () -> Void in
                    self.EsloAddrLabel.transform = .init(scaleX: 1.25, y: 1.25)
                }) { (finished: Bool) -> Void in
                    self.EsloAddrLabel.text = String(format: "0x%08x", esloAddr)
                    UIView.animate(withDuration: 0.25, animations: { () -> Void in
                        self.EsloAddrLabel.transform = .identity
                    })
                }
                
                let initBits:UInt8 = 0x01
                var labelString = ""
                for n in 0...4 {
                    if axyMove & (initBits<<n) > 0 {
                        labelString = "●" + labelString
                    } else {
                        labelString = "○" + labelString
                    }
                }
                AxyMoveLabel.text = labelString
            }
        }
        if characteristic == settingsChar {
            let initSettings: ESLO_Settings! = ESLO_Settings()
            var rawSettings = encodeESLOSettings(initSettings)
            let data:Data = characteristic.value!
            let _ = data.withUnsafeBytes { pointer in
                for n in 0..<rawSettings.count {
                    rawSettings[n] = pointer.load(fromByteOffset:n, as: UInt8.self)
                }
            }
            iosSettings = decodeESLOSettings(rawSettings)
            esloSettings = iosSettings
            settingsUpdate()
            PushActivityIndicator.stopAnimating()
            PushButton.isEnabled = true
            PushButton.alpha = 1
            dataSynced()
        }
        // https://www.raywenderlich.com/7181017-unsafe-swift-using-pointers-and-interacting-with-c
        if characteristic == EEGChar {
            let data:Data = characteristic.value!
            let _ = data.withUnsafeBytes { pointer in
                for n in 0..<EEG1Data.count {
                    let eegSample = pointer.load(fromByteOffset:n*4, as: UInt32.self)
                    let ESLOpacket = decodeESLOPacket(eegSample)
                    self.esloType = ESLOpacket.eslo_type
                    switch esloType {
                    case 2:
                        EEG1Data[n] = ESLOpacket.eslo_data
                    case 3:
                        EEG2Data[n] = ESLOpacket.eslo_data
                    case 4:
                        EEG3Data[n] = ESLOpacket.eslo_data
                    case 5:
                        EEG4Data[n] = ESLOpacket.eslo_data
                    default:
                        break
                    }
                }
            }
            switch esloType {
            case 2:
                EEG1Plot.replaceSubrange(0..<EEG1Data.count, with: EEG1Data)
                EEG1Plot.rotateLeft(positions: EEG1Data.count)
                EEGnew1 = true
            case 3:
                EEG2Plot.replaceSubrange(0..<EEG2Data.count, with: EEG2Data)
                EEG2Plot.rotateLeft(positions: EEG2Data.count)
                EEGnew2 = true
            case 4:
                EEG3Plot.replaceSubrange(0..<EEG3Data.count, with: EEG3Data)
                EEG3Plot.rotateLeft(positions: EEG3Data.count)
                EEGnew3 = true
            case 5:
                EEG4Plot.replaceSubrange(0..<EEG4Data.count, with: EEG4Data)
                EEG4Plot.rotateLeft(positions: EEG4Data.count)
                EEGnew4 = true
            default:
                break
            }
            updateChart(EEG_CHART)
        }
        if characteristic == AXYChar {
            let data:Data = characteristic.value!
            let _ = data.withUnsafeBytes { pointer in
                for n in 0..<AXYXData.count { // assume count? !!read notif count directly
                    let axySample = pointer.load(fromByteOffset:n*4, as: UInt32.self)
                    let ESLOpacket = decodeESLOPacket(axySample)
                    self.esloType = ESLOpacket.eslo_type
                    switch esloType {
                    case 7:
                        AXYXData[n] = ESLOpacket.eslo_data
                    case 8:
                        AXYYData[n] = ESLOpacket.eslo_data
                    case 9:
                        AXYZData[n] = ESLOpacket.eslo_data
                    default:
                        break
                    }
                }
            }
            switch esloType {
            case 7:
                AXYXPlot.replaceSubrange(0..<AXYXData.count, with: AXYXData)
                AXYXPlot.rotateLeft(positions: AXYXData.count)
                AXYnewX = true
            case 8:
                AXYYPlot.replaceSubrange(0..<AXYYData.count, with: AXYYData)
                AXYYPlot.rotateLeft(positions: AXYYData.count)
                AXYnewY = true
            case 9:
                AXYZPlot.replaceSubrange(0..<AXYZData.count, with: AXYZData)
                AXYZPlot.rotateLeft(positions: AXYZData.count)
                AXYnewZ = true
            default:
                break
            }
            updateChart(AXY_CHART) // best place to call? it's going to update 4 times
        }
        if characteristic == swaChar {
            printESLO("SWA Detected")
        }
    }
    
    // disconnected
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if peripheral == self.peripheral {
            stopReadRSSI()
            DeviceLabel.text = "Disconnected"
            DeviceView.backgroundColor = UIColor(hex: "#c0392bff")
            ConnectBtn.setTitle("Connect", for: .normal)
            PushActivityIndicator.stopAnimating()
            print("Disconnected")
            printESLO("Disconnected")
            printESLO("Copied terminal to clipboard")
            pasteboard.string = ESLOTerminal.text
            overlayOn()
            
            self.peripheral = nil
            LEDChar = nil
            vitalsChar = nil
            EEGChar = nil
            AXYChar = nil
            settingsChar = nil
            addrChar = nil
            swaChar = nil
            terminalCount = 1
        }
    }
    
    func cancelScan() {
        centralManager?.stopScan()
        print("Scan Stopped")
        printESLO("Scan stopped")
        DeviceLabel.text = "Scan Timeout"
    }
    
    func restoreCentralManager() {
        //Restores Central Manager delegate if something went wrong
        centralManager?.delegate = self
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        if error != nil {
            printESLO("Error writing characteristic")
            return
        }
        print("Write characteristic success")
    }
    
    @IBAction func ConnectBtnChange(_ sender: Any) {
        if ConnectBtn.currentTitle == "Connect" {
            DeviceView.backgroundColor = UIColor.lightGray
            DeviceLabel.text = "Connecting..."
            scanBTE()
        } else {
            if peripheral != nil {
                if (DataSyncLabel.text == "Data Stale") {
                    PushSettings(false)
                    printESLO("Pushed disconnect [try again]")
                } else {
                    centralManager?.cancelPeripheralConnection(peripheral)
                }
            }
            ConnectBtn.setTitle("Disconnect", for: .normal)
        }
    }
    
    func updateChart(_ chartNum: Int){
        if chartNum == AXY_CHART || chartNum == BOTH_CHARTS {
            // always plot Axy, always >= 1Hz
            if AXYnewX && AXYnewY && AXYnewZ {
                data = LineChartData()
                lineChartEntry = [ChartDataEntry]()
                
                var multiXl: Double = 1.0
                var divideXl: Double = 1.0
                if SciUnitsSwitch.isOn {
                    multiXl = 0.98
                    divideXl = 16.0
                }
                let Fs = Double(axyArr[AxySwitch.selectedSegmentIndex])
                
                DCoffset = 0
                if RmOffsetSwitch.isOn {
                    DCoffset = (AXYXPlot as NSArray).value(forKeyPath: "@avg.floatValue") as! Double
                }
                for i in 0..<AXYXPlot.count {
                    let value = ChartDataEntry(x: Double(i) / Fs, y: ((Double(AXYXPlot[i])-DCoffset)/divideXl)*multiXl)
                    lineChartEntry.append(value)
                }
                let line1 = LineChartDataSet(entries: lineChartEntry, label: "Axy X")
                line1.colors = [AXYXColor]
                line1.drawCirclesEnabled = false
                line1.drawValuesEnabled = false
                data.addDataSet(line1)

                var lineChartEntry = [ChartDataEntry]()
                DCoffset = 0
                if RmOffsetSwitch.isOn {
                    DCoffset = (AXYYPlot as NSArray).value(forKeyPath: "@avg.floatValue") as! Double
                }
                for i in 0..<AXYYPlot.count {
                    let value = ChartDataEntry(x: Double(i) / Fs, y: ((Double(AXYYPlot[i])-DCoffset)/divideXl)*multiXl)
                    lineChartEntry.append(value)
                }

                let line2 = LineChartDataSet(entries: lineChartEntry, label: "Axy Y")
                line2.colors = [AXYYColor]
                line2.drawCirclesEnabled = false
                line2.drawValuesEnabled = false
                data.addDataSet(line2)

                lineChartEntry = [ChartDataEntry]()
                DCoffset = 0
                if RmOffsetSwitch.isOn {
                    DCoffset = (AXYZPlot as NSArray).value(forKeyPath: "@avg.floatValue") as! Double
                }
                for i in 0..<AXYZPlot.count {
                    let value = ChartDataEntry(x: Double(i) / Fs, y: ((Double(AXYZPlot[i])-DCoffset)/divideXl)*multiXl)
                    lineChartEntry.append(value)
                }

                let line3 = LineChartDataSet(entries: lineChartEntry, label: "Axy Z")
                line3.colors = [AXYZColor]
                line3.drawCirclesEnabled = false
                line3.drawValuesEnabled = false
                data.addDataSet(line3)

                let l = chartViewAxy.legend
                l.form = .line
                l.font = UIFont(name: "HelveticaNeue-Light", size: 11)!
                l.textColor = textColor
                l.horizontalAlignment = .left
                l.verticalAlignment = .bottom
                l.orientation = .horizontal
                l.drawInside = false
                
                let xAxis = chartViewAxy.xAxis
                xAxis.labelFont = .systemFont(ofSize: 11)
                xAxis.labelTextColor = textColor
                xAxis.drawAxisLineEnabled = true
                
                let leftAxis = chartViewAxy.leftAxis
                leftAxis.labelTextColor = textColor
        //        leftAxis.axisMaximum = 55
        //        leftAxis.axisMinimum = -5
                leftAxis.drawGridLinesEnabled = true
                leftAxis.granularityEnabled = false
                
                chartViewAxy.rightAxis.enabled = false
                chartViewAxy.legend.enabled = true
                
                chartViewAxy.chartDescription?.enabled = false
                chartViewAxy.dragEnabled = false
                chartViewAxy.setScaleEnabled(false)
                chartViewAxy.pinchZoomEnabled = false
                chartViewAxy.data = data // add and update
                
                AXYnewX = false
                AXYnewY = false
                AXYnewZ = false
            } else {
                chartViewAxy.data = nil
            }
        }
        
        if chartNum == EEG_CHART || chartNum == BOTH_CHARTS {
            if EEG1Switch.isOn || EEG2Switch.isOn || EEG3Switch.isOn || EEG4Switch.isOn {
                var EEG1gate: Bool = true
                if EEG1Switch.isOn && !EEGnew1 {
                    EEG1gate = false
                }
                var EEG2gate: Bool = true
                if EEG2Switch.isOn && !EEGnew2 {
                    EEG2gate = false
                }
                var EEG3gate: Bool = true
                if EEG3Switch.isOn && !EEGnew3 {
                    EEG3gate = false
                }
                var EEG4gate: Bool = true
                if EEG4Switch.isOn && !EEGnew4 {
                    EEG4gate = false
                }
                
                if EEG1gate && EEG2gate && EEG3gate && EEG4gate {
                    data = LineChartData()

                    // +/-Vref = 3, gain = 12, 24-bit resolution
                    // *5/3 empirically determined from input filters
                    var EEGfactor: Double = 1.0
                    if SciUnitsSwitch.isOn {
                        EEGfactor = ((3/12) / Double(UInt32(0xFFFFFF))) * uVFactor * (5/3)
                    }
                    
                    if EEG1Switch.isOn {
                        lineChartEntry = [ChartDataEntry]()
                        DCoffset = 0
                        if RmOffsetSwitch.isOn {
                            DCoffset = (EEG1Plot as NSArray).value(forKeyPath: "@avg.floatValue") as! Double
                        }
                        for i in 0..<EEG1Plot.count {
                            let value = ChartDataEntry(x: Double(i) / EEG_FS, y: (Double(EEG1Plot[i])-DCoffset) * EEGfactor) //uV
                            lineChartEntry.append(value)
                        }
                        let line1 = LineChartDataSet(entries: lineChartEntry, label: "EEG Ch1")
                        line1.colors = [EEG1Color]
                        line1.drawCirclesEnabled = false
                        line1.drawValuesEnabled = false
                        data.addDataSet(line1)
                    }
                    if EEG2Switch.isOn {
                        lineChartEntry = [ChartDataEntry]()
                        DCoffset = 0
                        if RmOffsetSwitch.isOn {
                            DCoffset = (EEG2Plot as NSArray).value(forKeyPath: "@avg.floatValue") as! Double
                        }
                        for i in 0..<EEG2Plot.count {
                            let value = ChartDataEntry(x: Double(i) / EEG_FS, y: (Double(EEG2Plot[i])-DCoffset) * EEGfactor) //uV
                            lineChartEntry.append(value)
                        }

                        let line2 = LineChartDataSet(entries: lineChartEntry, label: "EEG Ch2")
                        line2.colors = [EEG2Color]
                        line2.drawCirclesEnabled = false
                        line2.drawValuesEnabled = false
                        data.addDataSet(line2)
                    }
                    if EEG3Switch.isOn {
                        lineChartEntry = [ChartDataEntry]()
                        DCoffset = 0
                        if RmOffsetSwitch.isOn {
                            DCoffset = (EEG3Plot as NSArray).value(forKeyPath: "@avg.floatValue") as! Double
                        }
                        for i in 0..<EEG3Plot.count {
                            let value = ChartDataEntry(x: Double(i) / EEG_FS, y: (Double(EEG3Plot[i])-DCoffset) * EEGfactor) //uV
                            lineChartEntry.append(value)
                        }

                        let line3 = LineChartDataSet(entries: lineChartEntry, label: "EEG Ch3")
                        line3.colors = [EEG3Color]
                        line3.drawCirclesEnabled = false
                        line3.drawValuesEnabled = false
                        data.addDataSet(line3)
                    }
                    if EEG4Switch.isOn {
                        lineChartEntry = [ChartDataEntry]()
                        DCoffset = 0
                        if RmOffsetSwitch.isOn {
                            DCoffset = (EEG4Plot as NSArray).value(forKeyPath: "@avg.floatValue") as! Double
                        }
                        for i in 0..<EEG4Plot.count {
                            let value = ChartDataEntry(x: Double(i) / EEG_FS, y: (Double(EEG4Plot[i])-DCoffset) * EEGfactor) //uV
                            lineChartEntry.append(value)
                        }

                        let line4 = LineChartDataSet(entries: lineChartEntry, label: "EEG Ch4")
                        line4.colors = [EEG4Color]
                        line4.drawCirclesEnabled = false
                        line4.drawValuesEnabled = false
                        data.addDataSet(line4)
                    }

                    let l = chartViewEEG.legend
                    l.form = .line
                    l.font = UIFont(name: "HelveticaNeue-Light", size: 11)!
                    l.textColor = textColor
                    l.horizontalAlignment = .left
                    l.verticalAlignment = .bottom
                    l.orientation = .horizontal
                    l.drawInside = false
                    
                    let xAxis = chartViewEEG.xAxis
                    xAxis.labelFont = .systemFont(ofSize: 11)
                    xAxis.labelTextColor = textColor
                    xAxis.drawAxisLineEnabled = true
                    
                    let leftAxis = chartViewEEG.leftAxis
                    leftAxis.labelTextColor = textColor
            //        leftAxis.axisMaximum = 55
            //        leftAxis.axisMinimum = -5
                    leftAxis.drawGridLinesEnabled = true
                    leftAxis.granularityEnabled = false
                    
                    chartViewEEG.rightAxis.enabled = false
                    chartViewEEG.legend.enabled = true
                    
                    chartViewEEG.chartDescription?.enabled = false
                    chartViewEEG.dragEnabled = false
                    chartViewEEG.setScaleEnabled(false)
                    chartViewEEG.pinchZoomEnabled = false
                    chartViewEEG.data = data // add and update
                    
                    EEGnew1 = false
                    EEGnew2 = false
                    EEGnew3 = false
                    EEGnew4 = false
                }
            } else {
                chartViewEEG.data = nil
            }
        }
    }
    @IBAction func SciUnitsChanged(_ sender: Any) {
        if SciUnitsSwitch.isOn {
            EEGUnitsLabel.alpha = 1
            AxyUnitsLabel.alpha = 1
        } else {
            EEGUnitsLabel.alpha = 0
            AxyUnitsLabel.alpha = 0
        }
    }
    
    func settingsUpdate() { // from ESLO
        SleepWakeSwitch.isOn = iosSettings.Record.boolValue
        DutySlider.value = Float(dutyArr.firstIndex(of: Int(iosSettings.RecPeriod))!)
        updateDutyLabel()
        DurationSlider.value = Float(durationArr.firstIndex(of: Int(iosSettings.RecDuration))!)
        updateDurationLabel()
        EEG1Switch.isOn = iosSettings.EEG1.boolValue
        EEG2Switch.isOn = iosSettings.EEG2.boolValue
        EEG3Switch.isOn = iosSettings.EEG3.boolValue
        EEG4Switch.isOn = iosSettings.EEG4.boolValue
        AxySwitch.selectedSegmentIndex = Int(iosSettings.AxyMode)
        SWASwitch.selectedSegmentIndex = Int(iosSettings.SWA)
        SWAThreshSlider.value = Float(iosSettings.SWAThresh);
        SWARatioSlider.value = Float(iosSettings.SWARatio);
        AdvLongSwitch.isOn = iosSettings.AdvLong.boolValue
        
        updateSWAThreshLabel()
        updateSWARatioLabel()
        prependDurationLabel()
        updateSWASwitch()
    }
    @IBAction func SettingsChanged(_ sender: Any) { // triggered by most UI changes
        iosSettings.Record = SleepWakeSwitch.isOn.uint8Value
        iosSettings.RecPeriod = UInt8(dutyArr[Int(DutySlider.value)])
        iosSettings.RecDuration = UInt8(durationArr[Int(DurationSlider.value)])
        iosSettings.EEG1 = EEG1Switch.isOn.uint8Value
        iosSettings.EEG2 = EEG2Switch.isOn.uint8Value
        iosSettings.EEG3 = EEG3Switch.isOn.uint8Value
        iosSettings.EEG4 = EEG4Switch.isOn.uint8Value
        iosSettings.SWA = UInt8(SWASwitch.selectedSegmentIndex)
        if UInt8(SWASwitch.selectedSegmentIndex) > 0 {
            AxySwitch.selectedSegmentIndex = 0 // force Axy 1Hz in SWA
        }
        iosSettings.SWAThresh = UInt8(SWAThreshSlider.value)
        iosSettings.SWARatio = UInt8(SWARatioSlider.value)
        iosSettings.AxyMode = UInt8(AxySwitch.selectedSegmentIndex)
        iosSettings.AdvLong = AdvLongSwitch.isOn.uint8Value
        updateSWASwitch()
        dataSynced()
    }
    func dataSynced() {
        if compareESLOSettings(iosSettings, esloSettings) {
            DataSyncLabel.text = "Data Synced"
            DataSyncLabel.textColor = .black
        } else {
            DataSyncLabel.text = "Data Stale"
            DataSyncLabel.textColor = .red
        }
    }
    @IBAction func PushSettings(_ sender: Any) {
        // https://medium.com/@shoheiyokoyama/manual-memory-management-in-swift-c31eb20ea8f
        ResetButton.alpha = resetAlpha
        if settingsChar != nil {
            PushButton.isEnabled = false
            PushButton.alpha = 0.25
            PushActivityIndicator.startAnimating()
            var uintSettings = encodeESLOSettings(iosSettings)
            let ptr = UnsafeMutablePointer<UInt8>.allocate(capacity: uintSettings.count)
            ptr.initialize(from: &uintSettings, count: uintSettings.count)
            let data = Data(buffer: UnsafeBufferPointer(start: ptr, count: uintSettings.count))
            peripheral.writeValue(data, for: settingsChar!, type: .withResponse)
            printESLO("Settings pushed") // will notify from ESLO
        }
    }
    
    @IBAction func SWAThreshChanged(_ sender: Any, forEvent event: UIEvent) {
        if let touchEvent = event.allTouches?.first {
            switch touchEvent.phase {
                case .moved:
                    updateSWAThreshLabel()
                case .ended:
                    SettingsChanged(sender)
                default:
                    break
            }
        }
    }
    func updateSWAThreshLabel() {
        let sliderIdx = Int(SWAThreshSlider.value)
        SWAThreshLabel.text = String(format: "%1.0fµV", Float(sliderIdx))
        SWAThreshSlider.value = Float(sliderIdx)
    }
    @IBAction func SWARatioChanged(_ sender: Any, forEvent event: UIEvent) {
        if let touchEvent = event.allTouches?.first {
            switch touchEvent.phase {
                case .moved:
                    updateSWARatioLabel()
                case .ended:
                    SettingsChanged(sender)
                default:
                    break
            }
        }
    }
    func updateSWARatioLabel() {
        let sliderIdx = Int(SWARatioSlider.value)
        SWARatioLabel.text = String(format: "%1.0f", Float(sliderIdx))
        SWARatioSlider.value = Float(sliderIdx)
    }
    
    @IBAction func DutyChanged(_ sender: Any, forEvent event: UIEvent) {
        if let touchEvent = event.allTouches?.first {
            switch touchEvent.phase {
                case .moved:
                    updateDutyLabel()
                case .ended:
                    if Int(DutySlider.value) == 0 {
                        DurationSlider.value = 0
                    } else {
                        SleepWakeSwitch.setOn(true, animated:true)
                        if Int(DurationSlider.value) == 0 {
                            DurationSlider.value = 1;
                        } else {
                            if Int(DutySlider.value) < Int(DurationSlider.value) {
                                DurationSlider.value = DutySlider.value
                            }
                        }
                    }
//                    updateDurationLabel()
//                    prependDurationLabel()
                    SettingsChanged(sender)
                default:
                    break
            }
        }
    }
    func updateDutyLabel() {
        let sliderIdx = Int(DutySlider.value)
        DutyLabel.text = String(dutyArr[sliderIdx]) + " min"
        DutySlider.value = Float(sliderIdx)
    }
    
    @IBAction func DurationChanged(_ sender: Any, forEvent event: UIEvent) {
        if let touchEvent = event.allTouches?.first {
            switch touchEvent.phase {
                case .moved:
                    updateDurationLabel()
                case .ended:
                    if Int(DurationSlider.value) == 0 {
                        DutySlider.value = 0
                    } else {
                        SleepWakeSwitch.setOn(true, animated:true)
                    }
                    if Int(DutySlider.value) < Int(DurationSlider.value) {
                        DutySlider.value = DurationSlider.value
                    }
//                    updateDutyLabel()
//                    prependDurationLabel()
                    SettingsChanged(sender)
                default:
                    break
            }
        }
    }
    func updateDurationLabel() {
        let sliderIdx = Int(DurationSlider.value)
        DurationLabel.text = String(durationArr[sliderIdx]) + " min"
        DurationSlider.value = Float(sliderIdx)
    }
    func prependDurationLabel() {
        var preStr = ""
        if Int(DurationSlider.value) == 0 || Int(DutySlider.value) == 0 {
            preStr = "0"
        } else {
            let recRatio = Float(durationArr[Int(DurationSlider.value)]) / Float(dutyArr[Int(DutySlider.value)])
            preStr = String(format: "%1.0f",100*recRatio)
        }
        RecRatioLabel.text = preStr;
    }
    
    @IBAction func ResetVersionButton(_ sender: Any) {
        if ResetButton.alpha == 1 {
            iosSettings.ResetVersion = 0x01
            PushSettings(false)
            printESLO("Version reset")
            ResetButton.alpha = resetAlpha
        } else {
            ResetButton.alpha = 1
        }
    }
    
    func updateSWASwitch() {
        if !EEG1Switch.isOn && SWASwitch.selectedSegmentIndex == 1 {
            SWASwitch.selectedSegmentIndex = 0
        }
        if !EEG2Switch.isOn && SWASwitch.selectedSegmentIndex == 2 {
            SWASwitch.selectedSegmentIndex = 0
        }
        if !EEG3Switch.isOn && SWASwitch.selectedSegmentIndex == 3 {
            SWASwitch.selectedSegmentIndex = 0
        }
        if !EEG4Switch.isOn && SWASwitch.selectedSegmentIndex == 4 {
            SWASwitch.selectedSegmentIndex = 0
        }
        SWASwitch.setEnabled(EEG1Switch.isOn, forSegmentAt: 1)
        SWASwitch.setEnabled(EEG2Switch.isOn, forSegmentAt: 2)
        SWASwitch.setEnabled(EEG3Switch.isOn, forSegmentAt: 3)
        SWASwitch.setEnabled(EEG4Switch.isOn, forSegmentAt: 4)
    }
}
