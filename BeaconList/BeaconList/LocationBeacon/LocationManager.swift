//
//  LocationManager.swift
//  Vidyanjali
//
//  Created by Vikram Jagad on 10/11/20.
//  Copyright © 2020 Vikram Jagad. All rights reserved.
//

import UIKit
import CoreLocation

fileprivate var sharedOrivteLocationManger: LocationManager!

class LocationManager: NSObject {
    //MARK:- Variables
    //Public
    var currentLocation: CLLocation?
    var getLocationPermission : ((Bool) -> Void)?
    
    //Private
    fileprivate var locationManager = CLLocationManager()
    
    var topVC = UIApplication.shared.keyWindow?.rootViewController
    
    class var shared : LocationManager {
        if sharedOrivteLocationManger == nil {
            sharedOrivteLocationManger = LocationManager()
            sharedOrivteLocationManger?.setupLocation()
        }
        return sharedOrivteLocationManger
    }
    
    override private init() {
        super.init()
    }
    
    fileprivate func setupLocation() {
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        self.locationManager.distanceFilter = kCLLocationAccuracyBestForNavigation
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
    }
    
    @discardableResult
    func checkForPermission(onVC: UIViewController? = nil) -> Bool {
        
        if !(CLLocationManager.locationServicesEnabled()) {
            let alert = UIAlertController(title: LocationMessages.enable_location_services_description, message: "", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .destructive) { (action:UIAlertAction!) in
            })
            alert.addAction(UIAlertAction(title: LocationMessages.go_to_settings, style: .default) { (action:UIAlertAction!) in
                let settingsUrl = URL(string: "App-Prefs:root=LOCATION_SERVICES")
                if let url = settingsUrl {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                 }
            })
            getLocationPermission?(false)
            
        } else if (CLLocationManager.authorizationStatus() == .notDetermined) {
            locationManager.requestWhenInUseAuthorization()
            
        } else if ((CLLocationManager.authorizationStatus() == .denied) || (CLLocationManager.authorizationStatus() == .restricted)) {
            getLocationPermission?(false)
            
            let alert = UIAlertController(title: LocationMessages.enable_location_services_description, message: "", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .destructive) { (action:UIAlertAction!) in
            })
            alert.addAction(UIAlertAction(title: LocationMessages.go_to_settings, style: .default) { (action:UIAlertAction!) in
                let settingsUrl = URL(string: UIApplication.openSettingsURLString)
                if let url = settingsUrl {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            })
            
        } else {
            getLocation()
            return true
        }
        return false
    }
    
    fileprivate func getLocation() {
        locationManager.requestLocation()
        locationManager.startUpdatingLocation()
    }
    
}

extension LocationManager: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .denied:
            getLocationPermission?(false)
            print("Location Access denied.")
            
        case .authorizedAlways, .authorizedWhenInUse:
            getLocation()
            getLocationPermission?(true)
            
        case .restricted:
            print("Location Access restricted.")
            
        case .notDetermined:
            print("Location Not Determined.")
            locationManager.requestWhenInUseAuthorization()
            
        @unknown default:
            print("Unknown error.")
        }
        
        if !CLLocationManager.locationServicesEnabled() && status != .denied {
            getLocationPermission?(false)
        }
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let last = locations.last {
            currentLocation = last
            getLocationPermission?(true)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
        self.locationManager.stopUpdatingLocation()
        debugPrint(error.localizedDescription)
    }
    
}

struct LocationMessages {
    static var enable_location_services_description: String { return "Please enable  Location services to allow application to find  your current location to get Nearby Places." }
    static var go_to_settings: String { return "Go to settings" }
    static var give_permission_description: String { return "Please allow location access for better application experience." }
}
