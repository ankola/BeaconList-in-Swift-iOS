//
//  beaconListTableViewCell.swift
//  NWM
//
//  Created by Dhruv Patel on 30/06/21.
//

import UIKit

class beaconListTableViewCell: UITableViewCell {
    
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblAvg: UILabel!
    @IBOutlet weak var lblMajor: UILabel!
    @IBOutlet weak var lblDetails: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        setUpLbls()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    //Labels set up
    fileprivate func setUpLbls() {
        lblName.textColor = .darkGray
        lblAvg.textColor = .darkGray
        lblMajor.textColor = .darkGray
        lblDetails.textColor = .darkGray

        let font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        lblName.font = font
        lblAvg.font = font
        lblMajor.font = font
        lblDetails.font = font
    }
    
    func configureCell(data: BeaconListModel) {

        if UserDefaults.standard.bool(forKey: "BeaconList_RSSI_List") && data.details.count > 0 {
            
            var str = "Rssi: \n"
            var str2 = "\n\nIgnored Rssi: \n"
            let dateFormatter = DateFormatter()
            dateFormatter.timeStyle = DateFormatter.Style.medium //Set time style
            dateFormatter.timeZone = .current
            
            for index in 1...data.details.count {
                
                let date = Date(timeIntervalSince1970: getDouble(anything: data.details[index - 1]["Time"]))
                
                let localDate = dateFormatter.string(from: date)
                let rssi = getDouble(anything: data.details[index - 1]["RSSI"])
//                let MajorRssi = getDouble(anything: data.MajorRssi)
                
                if rssi != 0 {
//                if rssi != 0 && Double(abs(rssi)) <= MajorRssi {
                    str += " Time: " + localDate + "  " + getString(anything: data.details[index - 1]["RSSI"]) + (index == data.details.count ? "" : ", \n")
                } else {
                    str2 += " Time: " + localDate + "  " + getString(anything: data.details[index - 1]["RSSI"]) + (index == data.details.count ? "" : ", \n")
                }
            }
            
            self.lblDetails.text = str + str2
            self.lblDetails.isHidden = false
            
        } else {
            self.lblDetails.isHidden = true
        }
        
        self.lblName.text = data.mac
        self.lblAvg.text = "Avg: \(String(format: "%.2f", data.avg))  Count: \(data.count)"
        self.lblMajor.text = "Major: \(data.major)  Minor: \(data.minor)  MajorRssi \(data.MajorRssi)"
    }
}

func getDouble(anything: Any?) -> Double
{
    if let any:Any = anything
    {
        if let num = any as? NSNumber
        {
            return num.doubleValue
        }
        else if let str = any as? NSString
        {
            return str.doubleValue
        }
    }
    return 0
}

func getString(anything: Any?) -> String
{
    if let any:Any = anything
    {
        if let num = any as? NSNumber
        {
            return num.stringValue
        }
        else if let str = any as? String
        {
            return str
        }
        else if let char = any as? Character
        {
            return "\(char)"
        }
    }
    return ""
}
