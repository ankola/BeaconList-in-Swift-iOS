//
//  BeaconListViewController.swift
//  NWM
//
//  Created by Dhruv Patel on 30/06/21.
//

import UIKit

//MARK:- NotificationCenter
let K_NC = NotificationCenter.default
var beaconMacAddress = ""
var beaconGroupIds = [String]()
var beaconGroupIdsTemp = [String]()

class BeaconListViewController: UIViewController, TblViewDelegate {
    
    @IBOutlet weak var tblview: UITableView!
    @IBOutlet weak var lblNearestBeacon: UILabel!
    @IBOutlet weak var btnSwitchRSSI: UISwitch!
    @IBOutlet weak var btnSwitch: UISwitch!
    
    fileprivate var delegateDataSource: BeaconTblViewDelegateDataSource!
    private let locationBeaconManager = LocationBeaconManger.Shared
    
    var array : [BeaconListModel] = [] //filtered with selected year and search string
    var arrNo = ["1","2","3","4","5","6","7"]
    var isFlag = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setUpTblView()
        addObserver()
        
        btnSwitch.addTarget(self, action: #selector(self.btnSwitchValueUpdate(sender:)), for: .valueChanged)
        btnSwitch.isOn = UserDefaults.standard.bool(forKey: "BeaconList_SortingOrderListUsingAvg")
        btnSwitch.tintColor = .lightGray
        btnSwitch.layer.cornerRadius = btnSwitch.frame.height / 2.0
        btnSwitch.backgroundColor = .lightGray

        btnSwitchRSSI.addTarget(self, action: #selector(self.btnSwitchValueUpdateForRSSI(sender:)), for: .valueChanged)
        btnSwitchRSSI.isOn = UserDefaults.standard.bool(forKey: "BeaconList_RSSI_List")
        btnSwitchRSSI.tintColor = .lightGray
        btnSwitchRSSI.layer.cornerRadius = btnSwitchRSSI.frame.height / 2.0
        btnSwitchRSSI.backgroundColor = .lightGray
        
        LocationManager.shared.checkForPermission()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.locationBeaconManager.setUpLocationManager()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeObserver()
    }
    
    private func addObserver() {
        K_NC.addObserver(self, selector: #selector(UpdateList(_:)), name: .updateBeaconList, object: nil)
        K_NC.addObserver(self, selector: #selector(BeaconChanged(_:)), name: .updateBeacon, object: nil)
    }
    
    private func removeObserver() {
        K_NC.removeObserver(self, name: .updateBeaconList, object: nil)
        K_NC.removeObserver(self, name: .updateBeacon, object: nil)
    }
    
    @objc func btnSwitchValueUpdate(sender : UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "BeaconList_SortingOrderListUsingAvg")
    }
    
    @objc func btnSwitchValueUpdateForRSSI(sender : UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "BeaconList_RSSI_List")
    }
    
    func setUpTblView() {
        
        let dictavg = LocationBeaconManger.Shared.dictAvgRssi
        let dictMajor = LocationBeaconManger.Shared.dictMajor
        let dictcount = LocationBeaconManger.Shared.dictCount
        let dictMajorRssi = LocationBeaconManger.Shared.dictMajorRssi
        let dicFilteredRssi = LocationBeaconManger.Shared.dicFilteredRssiTemp
        
        var arrData = [[String : Any]]()
        for (key, _) in dicFilteredRssi {
            var dict = [String : Any]()
            dict["mac"] = key
            dict["avg"] = dictavg[key]
            dict["count"] = dictcount[key]
            dict["major"] = dictMajor[key]
            dict["MajorRssi"] = dictMajorRssi[key]
            dict["minor"] = key
            
            if UserDefaults.standard.bool(forKey: "BeaconList_RSSI_List") {
                dict["extraDetails"] = (dicFilteredRssi[key] as? [[String:Any]] ?? [])
            }
            
            arrData.append(dict)
        }
        
        array = arrData.map({BeaconListModel(dict: $0)})
        if UserDefaults.standard.bool(forKey: "BeaconList_SortingOrderListUsingAvg") {
            array.sort { $0.avg > $1.avg }
        } else {
            array.sort { (Int($0.mac) ?? 0) < (Int($1.mac) ?? 0) }
        }

        if (delegateDataSource == nil) {
            delegateDataSource = BeaconTblViewDelegateDataSource(arrData: array, tbl: tblview, delegate: self)
        } else {
            delegateDataSource.reloadData(arrData: array)
        }
    }
    
    @objc private func UpdateList(_ noti: Notification) {
        setUpTblView()
    }
    
    @objc private func BeaconChanged(_ noti: Notification) {
        self.lblNearestBeacon.text = "Nearest Beacon : " + beaconMacAddress
    }
}

@objc protocol TblViewDelegate : NSObjectProtocol {
    @objc optional func didSelect(tbl: UITableView, indexPath: IndexPath)
    @objc optional func willDisplay(tbl: UITableView, atIndexPath: IndexPath)
    @objc optional func tbldidScroll(scrollView:UIScrollView)
    @objc optional func tblViewDidEndDecelerating(scrollView:UIScrollView)
}

extension Notification.Name {
    static let updateBeaconList = Notification.Name(NotificationObserverKeys.updateBeaconList)
    static let updateBeacon = Notification.Name(NotificationObserverKeys.updateBeacon)
}
struct NotificationObserverKeys {
    static let updateBeaconList = "UpdateBeaconList"
    static let updateBeacon = "nearest_beacon"
}
