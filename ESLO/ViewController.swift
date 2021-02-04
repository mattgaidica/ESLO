//
//  ViewController.swift
//  ESLO
//
//  Created by Matt Gaidica on 2/3/21.
//

import UIKit
import Charts
import CoreBluetooth

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    @IBOutlet weak var chartViewEEG: LineChartView!
    @IBOutlet weak var chartViewAxy: LineChartView!
    @IBOutlet weak var txtTextBox: UITextField!
    @IBOutlet weak var Header: UIView!
    @IBOutlet weak var ChartButton: UIButton!
    @IBOutlet weak var DeviceLabel: UILabel!
    @IBOutlet weak var batteryPercentLabel: UILabel!
    @IBOutlet weak var DeviceView: UIView!
    @IBOutlet weak var LED0Switch: UISwitch!
    @IBOutlet weak var ConnectBtn: UIButton!
    @IBOutlet weak var RSSILabel: UILabel!
    
    // Characteristics
    private var redChar: CBCharacteristic?
    private var battChar: CBCharacteristic?
    
    var countTime: Int = 0
    var timeoutTimer = Timer()
    var RSSITimer = Timer()
    var RSSI: NSNumber = 0
    
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
        updateGraph()
        centralManager = CBCentralManager(delegate: self, queue: nil)
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
            print("Central scanning for", ESLOPeripheral.LEDServiceUUID);
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
            DeviceView.backgroundColor = UIColor.green
            LED0Switch.isEnabled = true
            ConnectBtn.setTitle("Disconnect", for: .normal)
            self.startReadRSSI()
//            RSSITimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
//                peripheral.readRSSI();
//            }
            peripheral.discoverServices([ESLOPeripheral.LEDServiceUUID,ESLOPeripheral.batteryServiceUUID]);
            print("Connected to ESLO")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if peripheral == self.peripheral {
            stopReadRSSI()
            DeviceLabel.text = "Disconnected"
            DeviceView.backgroundColor = UIColor.red
            ConnectBtn.setTitle("Connect", for: .normal)
            LED0Switch.isEnabled = false
            self.peripheral = nil
            print("Disconnected")
        }
    }
    
    // Handles discovery event
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                if service.uuid == ESLOPeripheral.LEDServiceUUID {
                    print("LED service found")
                    //Now kick off discovery of characteristics
                    peripheral.discoverCharacteristics([ESLOPeripheral.redLEDCharacteristicUUID], for: service)
                }
                if( service.uuid == ESLOPeripheral.batteryServiceUUID ) {
                    print("Battery service found")
                    peripheral.discoverCharacteristics([ESLOPeripheral.batteryCharacteristicUUID], for: service)
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
    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        if( characteristic == battChar ) {
            print("Battery:", characteristic.value![0])
            batteryPercentLabel.text = "\(characteristic.value![0])%"
        }
    }
    
    // Handling discovery of characteristics
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if characteristic.uuid == ESLOPeripheral.redLEDCharacteristicUUID {
                    print("Red LED characteristic found")
                    // Set the characteristic
                    redChar = characteristic
                } else if characteristic.uuid == ESLOPeripheral.batteryCharacteristicUUID {
                    print("Battery characteristic found");
                    // Set the char
                    battChar = characteristic
                    // Subscribe to the char.
                    peripheral.setNotifyValue(true, for: characteristic)
                }
            }
        }
    }
    
    func scanBTE() {
        timeoutTimer.invalidate()
        centralManager.scanForPeripherals(withServices: [ESLOPeripheral.LEDServiceUUID],
                                          options: [CBCentralManagerScanOptionAllowDuplicatesKey : false])
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { timer in
            self.cancelScan();
        }
    }
    
    func cancelScan() {
        centralManager?.stopScan()
        print("Scan Stopped")
        DeviceLabel.text = "Scan Timeout"
    }
    
    func restoreCentralManager() {
        //Restores Central Manager delegate if something went wrong
        centralManager?.delegate = self
    }
    
    // see Write functions in UART module for reference
    private func writeValueToChar( withCharacteristic characteristic: CBCharacteristic, withValue value: Data) {
        // Check if it has the write property
        if characteristic.properties.contains(.writeWithoutResponse) && peripheral != nil {
            peripheral.writeValue(value, for: characteristic, type: .withoutResponse)
        }
    }
    
    @IBAction func LED0Change(_ sender: Any) {
        print("red:",LED0Switch.isOn);
        var switchState:UInt8 = 0
        if LED0Switch.isOn {
            switchState = 1
        }
        writeValueToChar( withCharacteristic: redChar!, withValue: Data([switchState]))
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
    
    func updateGraph(){
        var lineChartEntry = [ChartDataEntry]() //this is the Array that will eventually be displayed on the graph.
        //here is the for loop
        for i in 0..<200 {
            let value = ChartDataEntry(x: Double(i), y: Double.random(in: -100..<100))
            lineChartEntry.append(value)
        }
        
        let line1 = LineChartDataSet(entries: lineChartEntry, label: "EEG Data ch1") //Here we convert lineChartEntry to a LineChartDataSet
        line1.colors = [.red]
        line1.axisDependency = .left
        line1.drawCirclesEnabled = false
        line1.drawValuesEnabled = false
        line1.lineWidth = 1
        line1.highlightColor = UIColor.black
        line1.drawCircleHoleEnabled = false
        line1.mode = .cubicBezier
        
        lineChartEntry = []
        for i in 0..<200 {
            let value = ChartDataEntry(x: Double(i), y: Double.random(in: -100..<100))
            lineChartEntry.append(value)
        }
        
        let line2 = LineChartDataSet(entries: lineChartEntry, label: "EEG Data ch2") //Here we convert lineChartEntry to a LineChartDataSet
        line2.colors = [.systemIndigo]
        line2.axisDependency = .left
        line2.drawCirclesEnabled = false
        line2.drawValuesEnabled = false
        line2.lineWidth = 1
        line2.highlightColor = UIColor.black
        line2.drawCircleHoleEnabled = false
        
        let data = LineChartData() //This is the object that will be added to the chart
        data.addDataSet(line1)
        data.addDataSet(line2)
        
        let l = chartViewEEG.legend
        l.form = .line
        l.font = UIFont(name: "HelveticaNeue-Light", size: 11)!
        l.textColor = .black
        l.horizontalAlignment = .left
        l.verticalAlignment = .bottom
        l.orientation = .horizontal
        l.drawInside = false
        
        let xAxis = chartViewEEG.xAxis
        xAxis.labelFont = .systemFont(ofSize: 11)
        xAxis.labelTextColor = .black
        xAxis.drawAxisLineEnabled = true
        
        let leftAxis = chartViewEEG.leftAxis
        leftAxis.labelTextColor = UIColor.black
        leftAxis.axisMaximum = 250
        leftAxis.axisMinimum = -250
        leftAxis.drawGridLinesEnabled = true
        leftAxis.granularityEnabled = false
        
        chartViewEEG.rightAxis.enabled = false
        chartViewEEG.legend.enabled = true
        
        chartViewEEG.data = data //finally - it adds the chart data to the chart and causes an update
        chartViewEEG.chartDescription?.enabled = false
        chartViewEEG.dragEnabled = false
        chartViewEEG.setScaleEnabled(false)
        chartViewEEG.pinchZoomEnabled = false
        
        
        let lAxy = chartViewAxy.legend
        lAxy.form = .line
        lAxy.font = UIFont(name: "HelveticaNeue-Light", size: 11)!
        lAxy.textColor = .black
        lAxy.horizontalAlignment = .left
        lAxy.verticalAlignment = .bottom
        lAxy.orientation = .horizontal
        lAxy.drawInside = false
        
        let xAxyAxis = chartViewAxy.xAxis
        xAxyAxis.labelFont = .systemFont(ofSize: 11)
        xAxyAxis.labelTextColor = .black
        xAxyAxis.drawAxisLineEnabled = true
        
        let leftAxyAxis = chartViewAxy.leftAxis
        leftAxyAxis.labelTextColor = UIColor.black
        leftAxyAxis.axisMaximum = 250
        leftAxyAxis.axisMinimum = -250
        leftAxyAxis.drawGridLinesEnabled = true
        leftAxyAxis.granularityEnabled = false
        
        chartViewAxy.rightAxis.enabled = false
        chartViewAxy.legend.enabled = true
        
        chartViewAxy.data = data //finally - it adds the chart data to the chart and causes an update
        chartViewAxy.chartDescription?.enabled = false
        chartViewAxy.dragEnabled = false
        chartViewAxy.setScaleEnabled(false)
        chartViewAxy.pinchZoomEnabled = false
    }
    
}

