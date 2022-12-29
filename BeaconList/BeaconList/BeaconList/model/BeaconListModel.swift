//
//  BeaconListModel.swift
//  NWM
//
//  Created by Dhruv Patel on 30/06/21.
//

import Foundation


class BeaconListModel: NSObject {

    var mac: String
    var avg: Double
    var count: String
    var major: String
    var minor: String
    var MajorRssi: String
    var details : [[String:Any]]
    
    enum Keys: String {
        case mac = "mac"
        case avg = "avg"
        case count = "count"
        case major = "major"
        case minor = "minor"
        case MajorRssi = "MajorRssi"
        case details = "extraDetails"
    }

    init(dict: [String : Any]) {
        mac = getString(anything: dict[Keys.mac.rawValue])
        avg = getDouble(anything: dict[Keys.avg.rawValue])
        count = getString(anything: dict[Keys.count.rawValue])
        major = getString(anything: dict[Keys.major.rawValue])
        minor = getString(anything: dict[Keys.minor.rawValue])
        MajorRssi = getString(anything: dict[Keys.MajorRssi.rawValue])
        details = dict[Keys.details.rawValue] as? [[String:Any]] ?? [[String:Any]]()
        super.init()
    }
}

