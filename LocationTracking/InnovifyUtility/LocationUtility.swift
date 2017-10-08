//
//  LocationUtility.swift
//  LocationTracking
//
//  Created by jetani kalpesh on 08/10/17.
//  Copyright © 2017 sigmacoder. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData

//let NOTIFY_LOCATION_UPDATE = "NOTIFY_LOCATION_UPDATE"

class LocationUtility: NSObject, CLLocationManagerDelegate {
    
    static let shared = LocationUtility()
    var trackedSpeeds : [CLLocationSpeed] = []
    var session_time : Date!
    var isTracking : Bool = false{
        didSet{
            if isTracking == true{
                self.trackedSpeeds.removeAll()
                self.lastCapturedDate = nil
                session_time = Date()
                self.startUpdatingLocation()
            }else{
                locationManager.stopUpdatingLocation()
            }
        }
    }
    var lastCapturedDate : Date!
    
    var locationManager : CLLocationManager = CLLocationManager()
    var initialAuthorizationStatus = CLLocationManager.authorizationStatus()
    
    var systemLoaction : CLLocationCoordinate2D?
    required override init() {
        super.init()
        self.initializeLocationManager()
    }
    
    func initializeLocationManager() {
        
        locationManager.distanceFilter = CLLocationDistance(5)
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.delegate = self
    }
    
    func startUpdatingLocation(){
        if self.isLocationServiceEnabled == true {
            locationManager.startUpdatingLocation()
        }
        else if self.isLocationServiceEnabled == nil {
            //locationManager.requestWhenInUseAuthorization()
            locationManager.requestAlwaysAuthorization()
        }
        else {
            locationManager.startUpdatingLocation()
            print("\n\n")
            print("Location is disabled, Please check location services")
            print("\n\n")
        }
    }
    
    
    var isLocationServiceEnabled : Bool? {
        
        if CLLocationManager.locationServicesEnabled() {
            switch(CLLocationManager.authorizationStatus()) {
            case .notDetermined:
                print("location-authorization : Not Determined")
                return nil
            case .restricted, .denied:
                print("location-authorization : restricted or denied")
                return false
            case .authorizedAlways, .authorizedWhenInUse:
                print("location-authorization : Authorized")
                return true
            }
        }else{
            print("location-authorization : device locationServices disabled")
            return false
        }
    }
    
    //MARK:- CLLocationManager Delegates
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
        //NotificationCenter.default.post(name: Notification.Name(NOTIFY_LOCATION_UPDATE), object: nil)
        //manager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("Locations >> \(locations)")
        if isTracking == false{
            return
        }
        
        if lastCapturedDate == nil {
            lastCapturedDate = Date()
        }
        
        if let speed : CLLocationSpeed = manager.location?.speed{
            //meters per second To KiloMeter per hour
            let KiloMeterPerHour = speed * 3.6
            self.updateSpeed(speed: KiloMeterPerHour)
        }
        
        if let coordinates :CLLocationCoordinate2D = manager.location?.coordinate
        {
            systemLoaction = coordinates
            //NotificationCenter.default.post(name: Notification.Name(NOTIFY_LOCATION_UPDATE), object: coordinates )
        }
        else {
            //NotificationCenter.default.post(name: Notification.Name(NOTIFY_LOCATION_UPDATE), object: nil)
            print("\n\n didUpdateLocations in ERROR \n\n ")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus){
        
        print("\n\n*** didChangeAuthorization status *** \n\n ")
        if initialAuthorizationStatus != status{
            initialAuthorizationStatus = status
            if self.isLocationServiceEnabled == true{
                self.locationManager.startUpdatingLocation()
            }else{
                //NotificationCenter.default.post(name: Notification.Name(NOTIFY_LOCATION_UPDATE), object: nil)
            }
        }
    }
}

extension LocationUtility {
    
    func updateSpeed(speed: CLLocationSpeed){
        
        self.trackedSpeeds.append(speed)
        
        //Senario Speed
        let avgSpeed = (self.trackedSpeeds.reduce(0, +)) / Double(self.trackedSpeeds.count)
        
        //- Location should be captured after every 30 seconds interval,
        if avgSpeed >= 80,
            lastCapturedDate.addingTimeInterval(30).compare(Date()) == .orderedAscending {
            //Save Tracking Speed & Location
            saveTrackInfo(captured_speed: speed, average_speed: avgSpeed)
        }
        //- Location should be captured after every minute
        else if avgSpeed < 80 && avgSpeed > 60,
            lastCapturedDate.addingTimeInterval(60).compare(Date()) == .orderedAscending {

            //Save Tracking Speed & Location
            saveTrackInfo(captured_speed: speed, average_speed: avgSpeed)

        }
        //- Location should be captured after every 2 minutes
        else if avgSpeed < 60 && avgSpeed > 30,
            lastCapturedDate.addingTimeInterval(120).compare(Date()) == .orderedAscending {

            //Save Tracking Speed & Location
            saveTrackInfo(captured_speed: speed, average_speed: avgSpeed)
        }
        //- Location should be captured after every 5 minutes
        else if avgSpeed < 30,
            lastCapturedDate.addingTimeInterval(300).compare(Date()) == .orderedAscending {

            //Save Tracking Speed & Location
            saveTrackInfo(captured_speed: speed, average_speed: avgSpeed)
            
        }
        else {
            print("Wait ...Elapsed : \(Date().timeIntervalSince(lastCapturedDate))", " Speed > \(speed)", " Average Speed > \(avgSpeed)")
        }
    }
}

extension LocationUtility {
    
    func saveTrackInfo(captured_speed : Double, average_speed : Double){
        //session_time
        //captured_time
        //captured_speed
        //average_speed
        
        self.trackedSpeeds.removeAll()
        self.lastCapturedDate = Date()

        let location : EntityLocation = EntityLocation(context: appDelegate.persistentContainer.viewContext)
        location.captured_speed = captured_speed
        location.average_speed = average_speed
        location.captured_time = Date() as NSDate
        location.session_time = session_time as NSDate
        
        appDelegate.saveContext()
        
        logAllEntries()
    }
    
    func logAllEntries(){
        
        let fetchRequest = NSFetchRequest<EntityLocation>(entityName: "EntityLocation")
        do {
            let objects = try appDelegate.persistentContainer.viewContext.fetch(fetchRequest)
            let locations : [EntityLocation] = objects
            for location in locations {
                print("session > \(location.session_time),time > \(location.captured_time), speed > \(location.captured_speed), average > \(location.average_speed)")
            }
        }
        catch {
            assert(false, "please check this")
        }
    
    }
}
