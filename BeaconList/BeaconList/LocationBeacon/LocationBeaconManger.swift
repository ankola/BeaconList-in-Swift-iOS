//
//  LocationBeaconManger.swift
//  BeaconDemo
//
//  Created by Savan Ankola on 26/04/22.
//

import Foundation
import CoreLocation
import UIKit

final class LocationBeaconManger: NSObject {
    
    // MARK: - Variables
    //Private
    private var locationManager: CLLocationManager!
    static let Shared = LocationBeaconManger()
    fileprivate var timerStart: Timer!
    
    var dictRssi = [String:Any]()
    var dictMajorRssi = [String:Double]()
    var dictAvgRssi = [String:Double]()
    var dictAvgDistance = [String:Double]()
    var dictCount = [String:Int]()
    var dictMajor = [String:String]()
    var dictIdealCount = [String:Int]()
    var staticBeaconIdealCount = 3
    var dicFilteredRssi = [String:Any]()
    var arrMinorIds = [String]()
    var dicFilteredRssiTemp = [String:Any]()
    
    private override init() {}
    
    func setUpLocationManager() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
    }
    
    func stopScanning() {
        self.stopTimer()
        if self.locationManager != nil {
            if #available(iOS 13.0, *) {
                self.locationManager.rangedBeaconConstraints.forEach { beaconIdentityConstraint in
                    self.locationManager.stopRangingBeacons(satisfying: beaconIdentityConstraint)
                }
                self.locationManager.monitoredRegions.forEach { beaconRegion in
                    self.locationManager.stopMonitoring(for: beaconRegion)
                }
            } else {
                // Fallback on earlier versions
                self.locationManager.monitoredRegions.forEach { beaconRegion in
                    self.locationManager.stopMonitoring(for: beaconRegion)
                }
                self.locationManager.rangedRegions.forEach { region in
                    if let reg : CLBeaconRegion = region as? CLBeaconRegion {
                        self.locationManager.stopRangingBeacons(in: reg)
                    }
                }
            }
        }
    }
    
    private func startScanning() {
        let dictResponse = self.readJsonFile(ofName: "BeaconList")
        guard dictResponse.keys.count > 0, let resultFlag = dictResponse["resultFlag"] as? Bool, resultFlag == true, let storedItems = (dictResponse["beacons"] as? [[String: Any]])?.map({ Item(dict: $0) }) else {
            return
        }
        self.startTimer()
        for item in storedItems {
            startMonitoringItem(item)
        }
    }
    
    private func startMonitoringItem(_ item: Item) {
        if #available(iOS 13.0, *) {
            let beaconIdentity = CLBeaconIdentityConstraint(uuid: item.uuid)
            let beaconRegion = CLBeaconRegion(beaconIdentityConstraint: beaconIdentity, identifier: item.name)
            locationManager.startMonitoring(for: beaconRegion)
            locationManager.startRangingBeacons(satisfying: beaconIdentity)
        } else {
            let beaconRegion = CLBeaconRegion(proximityUUID: item.uuid, identifier: item.name)
            locationManager.startMonitoring(for: beaconRegion)
            locationManager.startRangingBeacons(in: beaconRegion)
        }
    }
    
    //MARK: Start Timer
    private func startTimer() {
        if timerStart == nil {
            timerStart = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerActionStart), userInfo: nil, repeats: true)
            RunLoop.current.add(timerStart, forMode: .common)
        }
    }
    
    private func stopTimer() {
        if timerStart != nil {
            timerStart?.invalidate()
            timerStart = nil
        }
    }
    
    private func getProximityString(proximity:CLProximity)->String{
        switch proximity {
        case .unknown:
            return "Unknown"
        case .immediate:
            return "Immediate"
        case .near:
            return "Near"
        case .far:
            return "Far"
        @unknown default:
            return "Unknown Default"
        }
    }
}

extension LocationBeaconManger : CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("Failed monitoring region: \(String(describing: region)) \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            if CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self) && CLLocationManager.isRangingAvailable() {
                self.startScanning()
            }
        }
    }
    
    @available(iOS 13.0, *)
    func locationManager(_ manager: CLLocationManager, didRange beacons: [CLBeacon], satisfying beaconConstraint: CLBeaconIdentityConstraint) {
//        print("didRange ", Date())
//        print("didRangeBeacons region satisfying beaconConstraint ", Date())
        self.manageBeacons(beacons: beacons)
    }
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
//        print("didRangeBeacons ", Date())
//        print("didRangeBeacons region ", Date())
        self.manageBeacons(beacons: beacons)
    }
        
    func manageBeacons(beacons: [CLBeacon]) {
        
        print(beacons)
        for beacon in beacons {

            var str_Major_Rssi = Double("\(beacon.major)".prefix(2)) ?? 96
            str_Major_Rssi = (str_Major_Rssi > 1) ? str_Major_Rssi : 96
            
            let dic = ["Time" : Date().timeIntervalSince1970, "RSSI" : beacon.rssi] as [String : Any]
            var dicBeacon = self.dicFilteredRssi["\(beacon.minor)"] as? [[String : Any]] ?? []
            dicBeacon.insert(dic, at: 0)
            self.dicFilteredRssi["\(beacon.minor)"] = dicBeacon
            
//            if beacon.rssi == 0 {
//                print("minor new - ", beacon.minor, " rssi - ", beacon.rssi, "proximity - ", beacon.proximity)
////                continue
//            } else {
//                print("minor new - ", beacon.minor, " rssi - ", beacon.rssi, "proximity - ", beacon.proximity)
//            }
                     
//            if Double(abs(beacon.rssi)) <= str_Major_Rssi {
                let str_Minor = "\(beacon.minor)"
                var idealCount = Int("\(beacon.major)".suffix(1)) ?? self.staticBeaconIdealCount
                idealCount = (idealCount > 0) ? idealCount : self.staticBeaconIdealCount
                self.setDictWithRSSI(Minor: str_Minor, Rssi: Double(beacon.rssi), Distance: beacon.accuracy, majorRssi: str_Major_Rssi, idealCount: idealCount, major: "\(beacon.major)")
//            }
            
            
//            str = str + "Total Beacons - \(beacons.count) \nRssi - \(beacon.rssi) \nMajor - \(beacon.major) \nMionr - \(beacon.minor) \nDistance - \(self.getProximityString(proximity: beacon.proximity)) - \(Double(beacon.accuracy)) \n\n\n"
            
//            print("majorRssi - ", str_Major_Rssi)
//            print("idealCount - ", Int(idealCount) ?? 4)
//            print("minor - ", beacon.minor)
//            print("idealCount - ", idealCount)
//            print("rssiUFO - ", Double(beacon.rssi))
//            print("Distance - ", beacon.accuracy)
//            print("major - ", beacon.major)
//            print("idealCount - ", idealCount)
        }
//        print(beacons.count, Date())
//        print("\n")
    }
}

//MARK RSSI
extension LocationBeaconManger {
    //MARK: Set Dictionary RSSI
    private func setDictWithRSSI(Minor: String, Rssi: Double, Distance:Double, majorRssi:Double, idealCount: Int, major:String) {
                
        if var tempArray = dictRssi[Minor] as? [[String : Any]] {
            if Rssi != 0 {
//            if Double(abs(Rssi)) <= majorRssi && Rssi != 0 {
                let currentDate = Date().timeIntervalSince1970
                var tempdata = [String: Any]()
                tempdata["RSSI"] = Rssi
                tempdata["Time"] = currentDate
                tempdata["Distance"] = Distance
                tempArray.append(tempdata)
                dictRssi[Minor] = tempArray
            }
            dictMajorRssi[Minor] = majorRssi
            dictMajor[Minor] = major
            dictIdealCount[Minor] = idealCount
            
        } else {
            if Rssi != 0 {
//            if Double(abs(Rssi)) <= majorRssi && Rssi != 0 {
                var tempdata = [String: Any]()
                tempdata["RSSI"] = Rssi
                tempdata["Time"] = Date().timeIntervalSince1970
                tempdata["Distance"] = Distance
                var temparray = [Any]()
                temparray.append(tempdata)
                dictRssi[Minor] = temparray
            }
            dictMajorRssi[Minor] = majorRssi
            dictMajor[Minor] = major
            dictIdealCount[Minor] = idealCount
        }
    }
    
    @objc func timerActionStart() {
//        BeaconList Update
        self.setupDictFilterData()
        NotificationCenter.default.post(name: .updateBeaconList, object: nil)
        
        if !dictRssi.isEmpty {
            if dictAvgRssi.keys.count > 0 {
                let tempNearest = findNearest(dict: dictAvgRssi)
                beaconMacAddress = tempNearest
                K_NC.post(name: .updateBeacon, object: tempNearest)
//                print("beacon found - ", tempNearest)
//                if beaconMacAddress != tempNearest {
//                    if let beaconMajor = dictMajorRssi[tempNearest] {
//                        if let tempAvgRssi = dictAvgRssi[tempNearest] {
//                            if abs(tempAvgRssi) <= beaconMajor {
//                                beaconMacAddress = tempNearest
//                                let res = beaconGroupIds.contains(tempNearest)
//                            }
//                        }
//                    }
//                }
            } else {
                beaconMacAddress = ""
                print("beacon not found")
                K_NC.post(name: .updateBeacon, object: "")
//                Constants.currentVirtualTourContentSelectedIndex = 0
//                Constants.currentVirtualTourSelectedIndex = 0
//                Constants.currentVirtualTourSubSelectedIndex = 0
            }
        }
    }
            
    //MARK: Set Avarage Dictionary RSSI
    private func setupDictFilterData() {
        dictAvgRssi.removeAll()
        var tempdicFilteredRssi = [String:Any]()
        
        let newDic = self.dicFilteredRssi
        self.dicFilteredRssi.removeAll()
        let currentDate = Date().timeIntervalSince1970
        var tempDictRssi = [String:Any]()
        
        for (key, value) in newDic {

            if let tempArray2 = value as? [[String : Any]] {
                
                let tempArray = dictRssi[key] as? [[String : Any]] ?? []
                var tempNewArray = [[String : Any]]()
                guard let idealCount = dictIdealCount[key] else { return }

                if tempArray.count >= idealCount {
                    tempNewArray = tempArray.filter({ (currentDate - ($0["Time"] as! TimeInterval)) < 5 })
                    let list = tempArray2.filter({ (currentDate - ($0["Time"] as! TimeInterval)) < 5 })
                    if list.count > 0 {
                        tempdicFilteredRssi[key] = list
                    }

                } else {
//                    tempNewArray = tempArray.filter({ (currentDate - ($0["Time"] as! TimeInterval)) < 12 })
//                    tempdicFilteredRssi[key] = tempArray2.filter({ (currentDate - ($0["Time"] as! TimeInterval)) < 12 })
                    tempNewArray = tempArray.filter({ (currentDate - ($0["Time"] as! TimeInterval)) < 5 })
                    let list = tempArray2.filter({ (currentDate - ($0["Time"] as! TimeInterval)) < 5 })
                    if list.count > 0 {
                        tempdicFilteredRssi[key] = list
                    }
                }
                
                dictCount[key] = tempNewArray.count
                if tempNewArray.count != 0 {
                    tempDictRssi[key] = tempNewArray
                    setupAvarage(mac: key, array: tempNewArray)
                }
            }
        }
        dictRssi = tempDictRssi
        self.dicFilteredRssi = tempdicFilteredRssi
        self.dicFilteredRssiTemp = tempdicFilteredRssi
    }

    private func setupAvarage(mac: String, array:[[String:Any]]) {
        let avrRSSI = array.map({ $0["RSSI"] as! Double }).reduce(0, +) / Double(array.count)
        dictAvgRssi[mac] = avrRSSI
        let avgDistance = array.map({ $0["Distance"] as! Double }).reduce(0, +)/Double(array.count)
        dictAvgDistance[mac] = avgDistance
        
        /*  if array.count <= 5{
         let avrRSSI = array.map({ $0["RSSI"] as! Double }).reduce(0, +)/Double(array.count)
         dictAvgRssi[mac] = avrRSSI
         let avgDistance = array.map({ $0["Distance"] as! Double }).reduce(0, +)/Double(array.count)
         dictAvgDistance[mac] = avgDistance
         }else{
         var arrReverse = array
         arrReverse.reverse()
         let arrRssi = arrReverse.prefix(5)
         
         let avrRSSI = arrRssi.map({ $0["RSSI"] as! Double }).reduce(0, +)/Double(array.count)
         dictAvgRssi[mac] = avrRSSI
         let avgDistance = arrRssi.map({ $0["Distance"] as! Double }).reduce(0, +)/Double(array.count)
         dictAvgDistance[mac] = avgDistance
         }*/
    }
        
    //MARK: Find Nearest Device With AvarageRSSI
    private func findNearest(dict: [String:Double]) -> String{
        var smallest = -1000000.0
        var smallestkey = ""
//        var tempstring = ""
        for (key, value) in dict {
            let idealCount = dictIdealCount[key] ?? staticBeaconIdealCount
            if let keycount =  dictCount[key], keycount >= idealCount {
                if value > smallest {
                    smallest = value
                    smallestkey = key
                }
            }
//            if let temparry = dictRssi[key] as? [[String : Any]]{
//                tempstring = tempstring + "\(key) \(value), count:- \(temparry.count)\n"
//            }
        }
        return smallestkey
    }
    
    //Read Json file
    func readJsonFile(ofName: String) -> [String : Any] {
        guard let strPath = Bundle.main.path(forResource: ofName, ofType: ".json") else {
            return [:]
        }
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: strPath), options: .alwaysMapped)
            let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
            if let dictJson = jsonResult as? [String : Any] {
                return dictJson
            }
        } catch {
            print("Error!! Unable to parse ")
        }
        return [:]
    }
}


