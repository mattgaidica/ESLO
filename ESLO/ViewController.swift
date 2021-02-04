//
//  ViewController.swift
//  ESLO
//
//  Created by Matt Gaidica on 2/3/21.
//

import UIKit
import Charts
import CoreBluetooth

class ViewController: UIViewController, UITextFieldDelegate, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    @IBOutlet weak var chartView: LineChartView!
    @IBOutlet weak var txtTextBox: UITextField!
    @IBOutlet weak var Header: UIView!
    @IBOutlet weak var ChartButton: UIButton!
    @IBOutlet weak var DeviceLabel: UILabel!
    @IBOutlet weak var batteryPercentLabel: UILabel!
    @IBOutlet weak var DeviceView: UIView!
    @IBOutlet weak var LED0Switch: UISwitch!
    @IBOutlet weak var ConnectBtn: UIButton!
    
    // Characteristics
    private var redChar: CBCharacteristic?
    private var battChar: CBCharacteristic?
    
    var countTime: Int = 0
    var numbers: [Double] = [] // stores input
    var timer = Timer()
    
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
        ChartButton.setTwoGradient(colorOne: UIColor.purple, colorTwo: UIColor.blue)
        self.txtTextBox.delegate = self
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
            print("Central scanning for", ParticlePeripheral.particleLEDServiceUUID);
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
        
        // Connect!
        self.centralManager.connect(self.peripheral, options: nil)
    }
    
    // The handler if we do connect succesfully
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if peripheral == self.peripheral {
            timer.invalidate()
            print("Connected to ESLO")
            DeviceLabel.text = peripheral.name
            DeviceView.backgroundColor = UIColor.green
            LED0Switch.isEnabled = true
            ConnectBtn.setTitle("Disconnect", for: .normal)
            peripheral.discoverServices([ParticlePeripheral.particleLEDServiceUUID,ParticlePeripheral.batteryServiceUUID]);
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if peripheral == self.peripheral {
            print("Disconnected")
            
            DeviceLabel.text = "Disconnected"
            DeviceView.backgroundColor = UIColor.red
            ConnectBtn.setTitle("Connect", for: .normal)
            LED0Switch.isEnabled = false
            self.peripheral = nil
        }
    }
    
    // Handles discovery event
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                if service.uuid == ParticlePeripheral.particleLEDServiceUUID {
                    print("LED service found")
                    //Now kick off discovery of characteristics
                    peripheral.discoverCharacteristics([ParticlePeripheral.redLEDCharacteristicUUID], for: service)
                }
                if( service.uuid == ParticlePeripheral.batteryServiceUUID ) {
                    print("Battery service found")
                    peripheral.discoverCharacteristics([ParticlePeripheral.batteryCharacteristicUUID], for: service)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateNotificationStateFor characteristic: CBCharacteristic,
                    error: Error?) {
        print("Enabling notify ", characteristic.uuid)
        
        if error != nil {
            print("Enable notify error")
        }
    }
    
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
                if characteristic.uuid == ParticlePeripheral.redLEDCharacteristicUUID {
                    print("Red LED characteristic found")
                    // Set the characteristic
                    redChar = characteristic
                } else if characteristic.uuid == ParticlePeripheral.batteryCharacteristicUUID {
                    print("Battery characteristic found");
                    
                    // Set the char
                    battChar = characteristic
                    
                    // Subscribe to the char.
                    peripheral.setNotifyValue(true, for: characteristic)
                }
            }
        }
    }
    
    private func writeLEDValueToChar( withCharacteristic characteristic: CBCharacteristic, withValue value: Data) {
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
        writeLEDValueToChar( withCharacteristic: redChar!, withValue: Data([switchState]))
    }
    
    func scanBTE() {
        timer.invalidate()
        centralManager.scanForPeripherals(withServices: [ParticlePeripheral.particleLEDServiceUUID],
                                          options: [CBCentralManagerScanOptionAllowDuplicatesKey : false])
        timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { timer in
            self.cancelScan();
        }
    }
    
    func cancelScan() {
        centralManager?.stopScan()
        print("Scan Stopped")
        DeviceLabel.text = "Scan Timeout"
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
    
    @IBAction func btnbutton(_ sender: Any) {
        let input  = Double(txtTextBox.text!) //gets input from the textbox - expects input as double/int
        numbers.append(input!) //here we add the data to the array.
        updateGraph()
        self.view.endEditing(true)
    }
    
    func updateGraph(){
        var lineChartEntry = [ChartDataEntry]() //this is the Array that will eventually be displayed on the graph.
        lineChartEntry.append(ChartDataEntry(x: 1, y: 20));
        lineChartEntry.append(ChartDataEntry(x: 2, y: 40));
        lineChartEntry.append(ChartDataEntry(x: 3, y: 100));
        //here is the for loop
        for i in 0..<numbers.count {
            let value = ChartDataEntry(x: Double(i), y: numbers[i])
            lineChartEntry.append(value)
        }
        
        let line1 = LineChartDataSet(entries: lineChartEntry, label: "Number") //Here we convert lineChartEntry to a LineChartDataSet
        line1.colors = [UIColor.black]
        line1.axisDependency = .left
        line1.setColor(UIColor(red: 51/255, green: 181/255, blue: 229/255, alpha: 1))
        line1.setCircleColor(.white)
        line1.lineWidth = 2
        line1.circleRadius = 3
        line1.fillAlpha = 65/255
        line1.fillColor = UIColor(red: 51/255, green: 181/255, blue: 229/255, alpha: 1)
        line1.highlightColor = UIColor(red: 244/255, green: 117/255, blue: 117/255, alpha: 1)
        line1.drawCircleHoleEnabled = false
        
        let data = LineChartData() //This is the object that will be added to the chart
        data.addDataSet(line1)
        
        let l = chartView.legend
        l.form = .line
        l.font = UIFont(name: "HelveticaNeue-Light", size: 11)!
        l.textColor = .white
        l.horizontalAlignment = .left
        l.verticalAlignment = .bottom
        l.orientation = .horizontal
        l.drawInside = false
        
        let xAxis = chartView.xAxis
        xAxis.labelFont = .systemFont(ofSize: 11)
        xAxis.labelTextColor = .white
        xAxis.drawAxisLineEnabled = false
        
        let leftAxis = chartView.leftAxis
        leftAxis.labelTextColor = UIColor(red: 51/255, green: 181/255, blue: 229/255, alpha: 1)
        leftAxis.axisMaximum = 200
        leftAxis.axisMinimum = 0
        leftAxis.drawGridLinesEnabled = true
        leftAxis.granularityEnabled = true
        
        let rightAxis = chartView.rightAxis
        rightAxis.labelTextColor = .red
        rightAxis.axisMaximum = 900
        rightAxis.axisMinimum = -200
        rightAxis.granularityEnabled = false
        
        chartView.rightAxis.enabled = false
        
        //        chartView.backgroundColor = UIColor.white
        //        line1.circleHoleColor = UIColor.black
        //        line1.circleColors = [UIColor.black]
        //        line1.colors = [UIColor.black]
        //        line1.circleRadius = 0
        //        chartView.chartDescription?.textColor = UIColor.black
        //        chartView.legend.textColor = UIColor.black
        
        chartView.legend.enabled = false
        
        chartView.data = data //finally - it adds the chart data to the chart and causes an update
        chartView.chartDescription?.enabled = false
        chartView.dragEnabled = true
        chartView.setScaleEnabled(true)
        chartView.pinchZoomEnabled = true
        
        // Text
        //        chartView.xAxis.labelTextColor = UIColor.black
        //        chartView.xAxis.axisLineColor = UIColor.black
        //        chartView.legend.font = UIFont(name: "Futura", size: 10)!
        //        chartView.chartDescription?.textColor = UIColor.black
        //        chartView.chartDescription?.font = UIFont(name: "Futura", size: 12)!
        //        chartView.chartDescription?.xOffset = chartView.frame.width
        //        chartView.chartDescription?.yOffset = chartView.frame.height * (2/3)
        //        chartView.chartDescription?.textAlign = NSTextAlignment.left
    }
    
}

