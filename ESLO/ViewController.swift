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
    @IBOutlet weak var RndNumLabel: UILabel!
    @IBOutlet weak var LEDButton: UIButton!
    @IBOutlet weak var TxPowerStepper: UIStepper!
    @IBOutlet weak var TxPowerLabel: UILabel!
    @IBOutlet weak var DurationSlider: UISlider!
    @IBOutlet weak var DurationLabel: UILabel!
    @IBOutlet weak var DutySlider: UISlider!
    @IBOutlet weak var DutyLabel: UILabel!
    
    // Characteristics
    private var ledChar: CBCharacteristic?
    private var battChar: CBCharacteristic?
    private var eeg1Char: CBCharacteristic?
    
    var countTime: Int = 0
    var timeoutTimer = Timer()
    var RSSITimer = Timer()
    var RSSI: NSNumber = 0
    var terminalCount: Int = 0
    
    var EEG1Data: Array<Int32> = Array(repeating: 0, count: 50)
    var EEG2Data: Array<Int32> = Array(repeating: 0, count: 50)
    var EEG3Data: Array<Int32> = Array(repeating: 0, count: 50)
    var EEG4Data: Array<Int32> = Array(repeating: 0, count: 50)
    
    var EEG1Plot: Array<Int32> = Array(repeating: 0, count: 500)
    
    // States
    var LED0State: Bool = false
    
    // Properties
    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral!
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("View loaded")
        // Do any additional setup after loading the view, typically from a nib.
        Header.setTwoGradient(colorOne: UIColor.purple, colorTwo: UIColor.blue)
//        updateChart() // !! init chart?
        LEDButton.setImage(UIImage(systemName: "sun.max.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 23, weight: .regular, scale: .medium)), for: .normal)
        LEDButton.tintColor = UIColor.red
        printESLO(text: "Init " + getDataStr())
        centralManager = CBCentralManager(delegate: self, queue: nil)
        ESLOTerminal.text = ""
        WriteTimeLabel.text = getDataStr()
        updateRandomNumber()
    }
    @IBAction func DutySliderDone(_ sender: Any) {
        print("dutyDone")
    }
    
    @IBAction func DutyStep(_ sender: Any) {
        let dutyArr = [0, 1, 2, 4, 8, 12, 24]
        let sliderIdx = Int(DutySlider.value)
        DutyLabel.text = String(dutyArr[sliderIdx]) + " hr"
        DutySlider.value = Float(sliderIdx)
    }
    
    @IBAction func DurationStep(_ sender: Any) {
        let durationArr = [0, 1, 5, 10, 30, 60]
        let sliderIdx = Int(DurationSlider.value)
        DurationLabel.text = String(durationArr[sliderIdx]) + " min"
        DurationSlider.value = Float(sliderIdx)
    }
    
    @IBAction func WriteTime(_ sender: Any) {
        printESLO(text: "Wrote " + getDataStr())
    }
    @IBAction func WriteUniq(_ sender: Any) {
        printESLO(text: String(RndNumLabel.text!) + " (" + getDataStr() + ")")
        updateRandomNumber()
    }
    
    @IBAction func TxStepper(_ sender: Any) {
        TxPowerLabel.text = String(Int8(TxPowerStepper.value))
    }
    
    func updateRandomNumber() {
        RndNumLabel.text = String(format: NSLocalizedString("0x%06X", comment: "rn"), Int32.random(in: 0..<0xFFFFFF))
    }
    
    func getDataStr() -> String {
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, YY HH:mm:ss"
        return dateFormatter.string(from: date)
    }
    
    func printESLO(text: String) {
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
            printESLO(text: "Scanning for services")
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
        WriteTimeLabel.text = getDataStr()
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
            peripheral.discoverServices([ESLOPeripheral.ESLOServiceUUID, ESLOPeripheral.ESLOServiceUUID]);
            print("Connected to ESLO")
            printESLO(text: "Connected to ESLO device")
        }
    }
    
    // disconnected
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if peripheral == self.peripheral {
            stopReadRSSI()
            DeviceLabel.text = "Disconnected"
            DeviceView.backgroundColor = UIColor(hex: "#c0392bff")
            ConnectBtn.setTitle("Connect", for: .normal)
            self.peripheral = nil
            print("Disconnected")
            printESLO(text: "Disconnected")
            
            ledChar = nil
            battChar = nil
        }
    }
    
    // discovery event
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                if service.uuid == ESLOPeripheral.ESLOServiceUUID {
                    print("LED service found")
                    peripheral.discoverCharacteristics([ESLOPeripheral.LEDCharacteristicUUID], for: service)
                }
                if( service.uuid == ESLOPeripheral.ESLOServiceUUID ) {
                    print("Stream found")
                    peripheral.discoverCharacteristics([ESLOPeripheral.vitalsCharacteristicUUID, ESLOPeripheral.EEGCharacteristicUUID], for: service)
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
        if characteristic == eeg1Char {
            let data:Data = characteristic.value!
            let _ = data.withUnsafeBytes { pointer in
                for n in 0..<EEG1Data.count {
                    let eegSample = pointer.load(fromByteOffset:n*4, as: UInt32.self)
                    let ESLOpacket = decodeESLO(packet: eegSample)
                    EEG1Data[n] = ESLOpacket.eslo_data
                }
            }
            updateChart() // best place to call? Seems like it should be queue after all EEG data is collected
        }
        
        // this is a callback from setting value
        if characteristic == ledChar {
            let data:UInt8 = characteristic.value![0]
            LED0State = data.boolValue
            setLEDState()
        }
        
        if characteristic == battChar {
            let data:Data = characteristic.value! //get a data object from the CBCharacteristic
            // same method call, without type annotations
            let _ = data.withUnsafeBytes { pointer in
                let vBatt = Float(pointer.load(as: Int32.self)) / 1000000
                let formatString = NSLocalizedString("%1.2fV", comment: "vBatt")
//                if vBatt > 2.0 && vBatt < 4.0 {
                    batteryPercentLabel.text = String(format: formatString, vBatt)
                    BatteryBar.progress = vBatt.converting(from: 2.5...3.0, to: 0.0...1.0) // 350
//                }
            }
        }
    }
    
    // Handling discovery of characteristics
    // manually via peripheral.readValueForCharacteristic(characteristic) <- will callback
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if characteristic.uuid == ESLOPeripheral.EEGCharacteristicUUID {
                    print("EEG1 characteristic found")
                    printESLO(text: "Found EEG1")
                    eeg1Char = characteristic
                    peripheral.setNotifyValue(true, for: characteristic)
                }
                if characteristic.uuid == ESLOPeripheral.LEDCharacteristicUUID {
                    print("LED_0 characteristic found")
                    printESLO(text: "Found LED_0")
                    // Set the characteristic
                    ledChar = characteristic
                    if characteristic.value != nil {
                        let data:UInt8 = characteristic.value![0]
                        LED0State = data.boolValue
                    } else {
                        LED0State = false
                    }
                    setLEDState()
                }
                if characteristic.uuid == ESLOPeripheral.vitalsCharacteristicUUID {
                    print("Battery characteristic found");
                    printESLO(text: "Found vBatt")
                    battChar = characteristic
                    peripheral.setNotifyValue(true, for: characteristic)
                }
            }
        }
    }
    
    func scanBTE() {
        timeoutTimer.invalidate()
        centralManager.scanForPeripherals(withServices: [ESLOPeripheral.ESLOServiceUUID],
                                          options: [CBCentralManagerScanOptionAllowDuplicatesKey : false])
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { timer in
            self.cancelScan();
        }
    }
    
    func cancelScan() {
        centralManager?.stopScan()
        print("Scan Stopped")
        printESLO(text: "Scan stopped")
        DeviceLabel.text = "Scan Timeout"
    }
    
    func restoreCentralManager() {
        //Restores Central Manager delegate if something went wrong
        centralManager?.delegate = self
    }
    
    // see Write functions in UART module for reference
    private func writeValueToChar( withCharacteristic characteristic: CBCharacteristic, withValue value: Data) {
        // Check if it has the write property
        // characteristic.properties.contains(.writeWithoutResponse) &&
        if peripheral != nil {
            peripheral.writeValue(value, for: characteristic, type: .withResponse) //CBCharacteristicWriteType.WithResponse
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        if error != nil {
            // not sure what to do here: Discover Services -> Discover Characteristics -> Updates GUI
            //            peripheral.discoverServices([ESLOPeripheral.LEDServiceUUID,ESLOPeripheral.ESLOServiceUUID]);
            return
        }
        print("Write characteristic success")
    }
    
    func setLEDState() {
        if LED0State {
            LEDButton.alpha = 1.0
        } else {
            LEDButton.alpha = 0.25
        }
    }
    
    @IBAction func LED0Change(_ sender: Any) {
        if ledChar != nil {
            print("red:", LED0State);
            printESLO(text: "LED_0 toggled")
            LED0State = !LED0State
            writeValueToChar(withCharacteristic: ledChar!, withValue: Data([LED0State.uint8Value]))
            peripheral.readValue(for: ledChar!)
        }
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
        EEG1Plot.replaceSubrange(0..<EEG1Data.count, with: EEG1Data)
        EEG1Plot.rotateLeft(positions: EEG1Data.count)
        
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
}
