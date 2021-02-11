//
//  ViewController.swift
//  ESLO
//
//  Created by Matt Gaidica on 2/3/21.
//
// colors:  http://0xrgb.com/#flat
import UIKit
import Charts
import CoreBluetooth
import Foundation

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    let DEBUG: Bool = true
    
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
    @IBOutlet weak var TxPowerStepper: UIStepper!
    @IBOutlet weak var TxPowerLabel: UILabel!
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
    
    // Characteristics
    private var LEDChar: CBCharacteristic?
    private var battChar: CBCharacteristic?
    private var EEGChar: CBCharacteristic?
    private var AXYChar: CBCharacteristic?
    private var settingsChar: CBCharacteristic?
    
    var timeoutTimer = Timer()
    var RSSITimer = Timer()
    var RSSI: NSNumber = 0
    var terminalCount: Int = 0
    var lastGraphTime: Double = 1000
    
    var EEG1Data: Array<Int32> = Array(repeating: 0, count: 50)
    var EEG2Data: Array<Int32> = Array(repeating: 0, count: 50)
    var EEG3Data: Array<Int32> = Array(repeating: 0, count: 50)
    var EEG4Data: Array<Int32> = Array(repeating: 0, count: 50)
    
    var EEG1Plot: Array<Int32> = Array(repeating: 0, count: 500)
    var EEG2Plot: Array<Int32> = Array(repeating: 0, count: 500)
    var EEG3Plot: Array<Int32> = Array(repeating: 0, count: 500)
    var EEG4Plot: Array<Int32> = Array(repeating: 0, count: 500)
    
    // States
    let txArr = [-20, -10, 0, 5]
    let dutyArr = [0, 1, 2, 4, 8, 12, 24]
    let durationArr = [0, 1, 5, 10, 30, 60]
    var esloType: UInt8 = 0
    
    // Other
    let pasteboard = UIPasteboard.general
    var curSettings: ESLO_Settings! = ESLO_Settings()
    
    // Properties
    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral!
    
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
        if DEBUG == false {
            overlayOn()
        }
        print("View loaded")
        Header.setTwoGradient(colorOne: UIColor.purple, colorTwo: UIColor.blue)
//        updateChart() // !! init chart?
        printESLO("Init " + getTimeStr())
        centralManager = CBCentralManager(delegate: self, queue: nil)
        ESLOTerminal.text = ""
        WriteTimeLabel.text = getTimeStr()
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
            printESLO("Scanning for services")
            scanBTE()
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
        self.centralManager.connect(self.peripheral, options: nil)
    }
    
    func scanBTE() {
        centralManager.scanForPeripherals(withServices: [ESLOPeripheral.ESLOServiceUUID],
                                          options: [CBCentralManagerScanOptionAllowDuplicatesKey : false])
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { timer in
            self.cancelScan()
        }
    }
    
    func getTimeStr() -> String {
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d HH:mm:ss"
        return dateFormatter.string(from: date)
    }
    
    func hexTime() -> String {
        var components = DateComponents()
        components.day = 1
        components.month = 1
        components.year = 2021
        components.hour = 0
        components.minute = 0
        components.second = 0
        let startDate = Calendar.current.date(from: components) ?? Date()
        
        let diffComponents = Calendar.current.dateComponents([.second], from: startDate, to: Date())
        let seconds = UInt32(diffComponents.second!)
        let hexDateString = String(format: "0x%llX", seconds)
        
        // set curSettings
        curSettings.Time1 = UInt8(seconds & 0xFF)
        curSettings.Time2 = UInt8(seconds >> 8 & 0xFF)
        curSettings.Time3 = UInt8(seconds >> 16 & 0xFF)
        curSettings.Time4 = UInt8(seconds >> 24 & 0xFF)
        
        return hexDateString
    }
    
    func delegateRSSI() {
        if (self.peripheral != nil){
            self.peripheral.delegate = self
            self.peripheral.readRSSI()
        } else {
            print("peripheral = nil")
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
            timeoutTimer.invalidate()
            DeviceLabel.text = peripheral.name
            updateRSSI(RSSI: RSSI)
            DeviceView.backgroundColor = UIColor(hex: "#27ae60ff") // green
            ConnectBtn.setTitle("Disconnect", for: .normal)
            self.startReadRSSI()
            peripheral.discoverServices([ESLOPeripheral.ESLOServiceUUID]);
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
                    print("LED service found")
                    peripheral.discoverCharacteristics([ESLOPeripheral.LEDCharacteristicUUID, ESLOPeripheral.vitalsCharacteristicUUID, ESLOPeripheral.settingsCharacteristicUUID, ESLOPeripheral.EEGCharacteristicUUID,
                                                        ESLOPeripheral.AXYCharacteristicUUID], for: service)
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
                    print("LED_0 characteristic found")
                    printESLO("Found LED")
                    // Set the characteristic
                    LEDChar = characteristic
                    if characteristic.value != nil {
                        let data:UInt8 = characteristic.value![0]
                        LEDSwitch.isOn = data.boolValue
                    } else {
                        LEDSwitch.isOn = false
                    }
                }
                if characteristic.uuid == ESLOPeripheral.vitalsCharacteristicUUID {
                    print("Battery characteristic found")
                    printESLO("Found vBatt")
                    battChar = characteristic
                    peripheral.setNotifyValue(true, for: characteristic)
                }
                if characteristic.uuid == ESLOPeripheral.settingsCharacteristicUUID {
                    print("Settings characteristic found")
                    printESLO("Found Settings")
                    settingsChar = characteristic
                    peripheral.setNotifyValue(true, for: characteristic)
                    printESLO("Reading settings")
                    peripheral.readValue(for: settingsChar!)
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
        // https://www.raywenderlich.com/7181017-unsafe-swift-using-pointers-and-interacting-with-c
        if characteristic == EEGChar {
            let data:Data = characteristic.value!
            let _ = data.withUnsafeBytes { pointer in
                for n in 0..<EEG1Data.count { // assume count? !!read notif count directly
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
            case 3:
                EEG2Plot.replaceSubrange(0..<EEG2Data.count, with: EEG2Data)
                EEG2Plot.rotateLeft(positions: EEG2Data.count)
            case 4:
                EEG3Plot.replaceSubrange(0..<EEG3Data.count, with: EEG3Data)
                EEG3Plot.rotateLeft(positions: EEG3Data.count)
            case 5:
                EEG4Plot.replaceSubrange(0..<EEG4Data.count, with: EEG4Data)
                EEG4Plot.rotateLeft(positions: EEG4Data.count)
            default:
                break
            }
            updateChart() // best place to call? it's going to update 4 times
        }
        // this is a readValue callback from setting value
        if characteristic == LEDChar {
            let data:UInt8 = characteristic.value![0]
            LEDSwitch.isOn = data.boolValue
            LEDSwitch.isEnabled = true
        }
        if characteristic == battChar {
            let data:Data = characteristic.value! //get a data object from the CBCharacteristic
            // same method call, without type annotations
            let _ = data.withUnsafeBytes { pointer in
                let vBatt = Float(pointer.load(as: Int32.self)) / 1000000
                let formatString = NSLocalizedString("%1.2fV", comment: "vBatt")
                batteryPercentLabel.text = String(format: formatString, vBatt)
                BatteryBar.progress = vBatt.converting(from: 2.5...3.0, to: 0.0...1.0)
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
            curSettings = decodeESLOSettings(rawSettings)
            settingsUpdate()
            PushActivityIndicator.stopAnimating()
            PushButton.isEnabled = true
            PushButton.alpha = 1
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
            battChar = nil
            EEGChar = nil
            AXYChar = nil
            settingsChar = nil
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
                centralManager?.cancelPeripheralConnection(peripheral)
            }
            ConnectBtn.setTitle("Disconnect", for: .normal)
        }
    }
    
    func updateChart(){
        if CACurrentMediaTime() - lastGraphTime < 100 {
            return
        }
        
        var lineChartEntry = [ChartDataEntry]()
        for i in 0..<EEG1Plot.count {
            let value = ChartDataEntry(x: Double(i), y: Double(EEG1Plot[i]))
            lineChartEntry.append(value)
        }
        
        // Vars
        let textColor = UIColor.white
        
        // line colors, see: http://0xrgb.com/#material
        let EEG1Color = UIColor(red: 229/255, green: 28/255, blue: 35/255, alpha: 1)//UIColor(hex: "#e51c23ff") // red
        let EEG2Color = UIColor(hex: "#03a9f4ff") // light blue
        let EEG3Color = UIColor(hex: "#ffc107ff") // amber
        let EEG4Color = UIColor(hex: "#607D8Bff") // blue grey
        
        let AxyXColor = UIColor(hex: "#5677fcff") // blue
        let AxyYColor = UIColor(hex: "#cddc39ff") // lime
        let AxyZColor = UIColor(hex: "#ff5722ff") // deep orange
        
        let line1 = LineChartDataSet(entries: lineChartEntry, label: "EEG Data ch1")
        line1.colors = [EEG1Color]
        line1.axisDependency = .left
        line1.drawCirclesEnabled = false
        line1.drawValuesEnabled = false
        line1.lineWidth = 1
        line1.highlightColor = textColor
        line1.drawCircleHoleEnabled = false
//        line1.mode = .cubicBezier
        
        lineChartEntry = []
        for i in 0..<200 {
            let value = ChartDataEntry(x: Double(i), y: Double.random(in: -100..<100))
            lineChartEntry.append(value)
        }
        
        let line2 = LineChartDataSet(entries: lineChartEntry, label: "EEG Data ch2") //Here we convert lineChartEntry to a LineChartDataSet
        line2.colors = []
        line2.axisDependency = .left
        line2.drawCirclesEnabled = false
        line2.drawValuesEnabled = false
        line2.lineWidth = 1
        line2.highlightColor = textColor
        line2.drawCircleHoleEnabled = false
        
        let data = LineChartData() //This is the object that will be added to the chart
        
        data.addDataSet(line1)
//        data.addDataSet(line2)
        
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
        
        
        
        // ----- AXY CHART -----
//        let lAxy = chartViewAxy.legend
//        lAxy.form = .line
//        lAxy.font = UIFont(name: "HelveticaNeue-Light", size: 11)!
//        lAxy.textColor = textColor
//        lAxy.horizontalAlignment = .left
//        lAxy.verticalAlignment = .bottom
//        lAxy.orientation = .horizontal
//        lAxy.drawInside = false
//
//        let xAxyAxis = chartViewAxy.xAxis
//        xAxyAxis.labelFont = .systemFont(ofSize: 11)
//        xAxyAxis.labelTextColor = textColor
//        xAxyAxis.drawAxisLineEnabled = true
//
//        let leftAxyAxis = chartViewAxy.leftAxis
//        leftAxyAxis.labelTextColor = textColor
////        leftAxyAxis.axisMaximum = 250
////        leftAxyAxis.axisMinimum = -250
//        leftAxyAxis.drawGridLinesEnabled = true
//        leftAxyAxis.granularityEnabled = false
//
//        chartViewAxy.rightAxis.enabled = false
//        chartViewAxy.legend.enabled = true
//
//        chartViewAxy.chartDescription?.enabled = false
//        chartViewAxy.dragEnabled = false
//        chartViewAxy.setScaleEnabled(false)
//        chartViewAxy.pinchZoomEnabled = false
//        chartViewAxy.data = data // add and update
    }
    
    func settingsUpdate() {
        SleepWakeSwitch.isOn = curSettings.SleepWake.boolValue
        DutySlider.value = Float(dutyArr.firstIndex(of: Int(curSettings.EEGDuty))!)
        updateDutyLabel()
        DurationSlider.value = Float(durationArr.firstIndex(of: Int(curSettings.EEGDuration))!)
        updateDurationLabel()
        EEG1Switch.isOn = curSettings.EEG1.boolValue
        EEG2Switch.isOn = curSettings.EEG2.boolValue
        EEG3Switch.isOn = curSettings.EEG3.boolValue
        EEG4Switch.isOn = curSettings.EEG4.boolValue
        AxySwitch.selectedSegmentIndex = Int(curSettings.AxyMode)
        TxPowerStepper.value = Double(Int(curSettings.TxPower))
        updateTxLabel()
    }
    @IBAction func SettingsChanged(_ sender: Any) {
        curSettings.SleepWake = SleepWakeSwitch.isOn.uint8Value
        curSettings.EEGDuty = UInt8(dutyArr[Int(DutySlider.value)])
        curSettings.EEGDuration = UInt8(durationArr[Int(DurationSlider.value)])
        curSettings.EEG1 = EEG1Switch.isOn.uint8Value
        curSettings.EEG2 = EEG2Switch.isOn.uint8Value
        curSettings.EEG3 = EEG3Switch.isOn.uint8Value
        curSettings.EEG4 = EEG4Switch.isOn.uint8Value
        curSettings.AxyMode = UInt8(AxySwitch.selectedSegmentIndex)
        curSettings.TxPower = UInt8(TxPowerStepper.value)
    }
    @IBAction func PushSettings(_ sender: Any) {
        // https://medium.com/@shoheiyokoyama/manual-memory-management-in-swift-c31eb20ea8f
        if settingsChar != nil {
            PushButton.isEnabled = false
            PushButton.alpha = 0.25
            PushActivityIndicator.startAnimating()
            var uintSettings = encodeESLOSettings(curSettings)
            let ptr = UnsafeMutablePointer<UInt8>.allocate(capacity: uintSettings.count)
            ptr.initialize(from: &uintSettings, count: uintSettings.count)
            let data = Data(buffer: UnsafeBufferPointer(start: ptr, count: uintSettings.count))
            peripheral.writeValue(data, for: settingsChar!, type: .withResponse)
            printESLO("Settings pushed")
            peripheral.readValue(for: settingsChar!) // force readValue callback
        }
    }
    
    @IBAction func TxStepper(_ sender: Any) {
        SettingsChanged(sender)
        updateTxLabel()
    }
    func updateTxLabel()  {
        TxPowerLabel.text = String(txArr[Int(TxPowerStepper.value)])
    }
    
    @IBAction func DutyChanged(_ sender: Any, forEvent event: UIEvent) {
        if let touchEvent = event.allTouches?.first {
            switch touchEvent.phase {
                case .moved:
                    updateDutyLabel()
                case .ended:
                    SettingsChanged(sender)
                default:
                    break
            }
        }
    }
    func updateDutyLabel() {
        let sliderIdx = Int(DutySlider.value)
        DutyLabel.text = String(dutyArr[sliderIdx]) + " hr"
        DutySlider.value = Float(sliderIdx)
    }
    
    @IBAction func DurationChanged(_ sender: Any, forEvent event: UIEvent) {
        if let touchEvent = event.allTouches?.first {
            switch touchEvent.phase {
                case .moved:
                    updateDurationLabel()
                case .ended:
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
}
