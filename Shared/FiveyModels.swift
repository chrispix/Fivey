//
//  FiveyModels.swift
//  Fivey
//
//  Created by Joel Bernstein on 8/30/20.
//

import Foundation
import SwiftUI

struct Poll: Codable {
    let state: String
    let candidates: [Candidate]
    let updatedMilliseconds: Double

    var updated: Date {
        Date(timeIntervalSince1970: updatedMilliseconds / 1000)
    }
    
    func candidate(named name: String) -> Candidate? {
        candidates.filter { $0.name == name }.first
    }

    enum CodingKeys : String, CodingKey {
        case state
        case candidates
        case updatedMilliseconds = "updated"
    }
}

struct Candidate: Codable {
    let name: String
    let dataPoints: [DataPoint]
    
    enum CodingKeys : String, CodingKey {
        case name = "candidate"
        case dataPoints = "dates"
    }
    
    var winProbabilities: [Double] {
        dataPoints.map { $0.winProbability }.reversed()
    }

//    var electoralVotes: [StatRange] {
//        dataPoints.compactMap { $0.electoralVote }.reversed()
//    }
//
//    var popularVotes: [StatRange] {
//        dataPoints.map { $0.popularVote }.reversed()
//    }
}

struct DataPoint: Codable {
    let dateString: String
    let winProbability: Double
//    let electoralVote: StatRange?
//    let popularVote: StatRange

    var date: Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.date(from:dateString)
    }
    
    enum CodingKeys : String, CodingKey {
        case dateString = "date"
        case winProbability = "winprob"
//        case electoralVote = "evs"
//        case popularVote = "voteshare"
    }
}

//struct StatRange: Codable {
//    let mean: Double
//    let high: Double
//    let low: Double
//
//    enum CodingKeys : String, CodingKey {
//        case mean
//        case high = "hi"
//        case low = "lo"
//    }
//}

struct SensorResults: Codable {
    let results: [Sensor]
    enum CodingKeys : String, CodingKey {
        case results
    }

    var name: String {
        guard let sensor1 = results[safe: 0] else { return "No Sensor Found" }
        return sensor1.name
    }

    var id: String {
        guard let sensor1 = results[safe: 0] else { return "-" }
        return String(sensor1.id)
    }
    
    var averageAQI: Double {
        guard let sensor1 = results[safe: 0], let sensor2 = results[safe: 1] else { return .nan }
        return (sensor1.aqi + sensor2.aqi) / 2
    }

    var aqi: String {
        let aqiNum = averageAQI
        switch aqiNum {
            case .nan:
                return "-"
            default:
                return String(aqiNum)
        }
    }

    var description: String {
        return getAQIDescription(averageAQI).0
    }

    var color: Color {
        return getAQIDescription(averageAQI).1
    }
}

private extension SensorResults {
    // Function that gets the AQI's description
    func getAQIDescription(_ aqinum: Double) -> (String, Color) {
        switch aqinum {
            case 401..<Double.infinity:
                return ("GTFO", AQIColor.magenta)
            case 301..<401:
                return ("Hazardous", AQIColor.maroon)
            case 201..<301:
                return ("Very Unhealthy", AQIColor.purple)
            case 151..<201:
                return ("Unhealthy", AQIColor.red)
            case 101..<151:
                return ("Unhealthy SG", AQIColor.orange)
            case 51..<101:
                return ("Moderate", AQIColor.yellow)
            case 0..<51:
                return ("Good", AQIColor.green)
            default:
                return ("Unknown", AQIColor.black)
        }
    }

    // Function that checks for the AQI trend
    func getAQItrend(_ average: Double, _ live: Double) -> String {
        if average - live > 9 {
            return "↓"
        } else if average - live < -9 {
            return "↑"
        } else {
            return ""
        }
    }
}

struct Sensor: Codable {
    let pm: String
    let name: String
    let id: Int

    enum CodingKeys : String, CodingKey {
        case pm = "PM2_5Value"
        case name = "Label"
        case id = "ID"
    }

    var aqi: Double {
        return aqiFromPM(pm)
    }
}

private extension Sensor {
    // Function to get AQI number from PPM reading
    func aqiFromPM(_ pm: String) -> Double {
        guard let reading = Double(pm) else { return .nan }
        switch reading {
            case ..<0:
                return .nan
            case 35.5..<1000:
                return calcAQI(reading, 500.0, 401.0, 500.0, 350.5)
            case 250.5..<350.5:
                return calcAQI(reading, 400.0, 301.0, 350.4, 250.5)
            case 150.5..<250.5:
                return calcAQI(reading, 300.0, 201.0, 250.4, 150.5)
            case 55.5..<150.5:
                return calcAQI(reading, 200.0, 151.0, 150.4, 55.5)
            case 35.5..<55.5:
                return calcAQI(reading, 150.0, 101.0, 55.4, 35.5)
            case 12.1..<35.5:
                return calcAQI(reading, 100.0, 51.0, 35.4, 12.1)
            case 0..<12.1:
                return calcAQI(reading, 50.0, 0.0, 12.0, 0.0)
            default:
                return .nan
        }
    }

    // Function that actually calculates the AQI number
    func calcAQI(_ Cp: Double, _ Ih: Double, _ Il: Double, _ BPh: Double, _ BPl: Double) -> Double {
        let a = Ih - Il
        let b = BPh - BPl
        let c = Cp - BPl
        return round( ( a / b ) * c + Il )
    }
}

struct AQIColor {
    static let magenta: Color = Color(red: 255.0, green: 0.0, blue: 255.0)
    static let maroon: Color = Color(red: 126.0, green: 0.0, blue: 35.0)
    static let purple: Color = Color(red: 143.0, green: 63.0, blue: 151.0)
    static let red: Color = Color(red: 255.0, green: 0.0, blue: 0.0)
    static let orange: Color = Color(red: 207.0, green: 115.0, blue: 50.0)
    static let yellow: Color = Color(red: 255.0, green: 255.0, blue: 0.0)
    static let green: Color = Color(red: 0.0, green: 228.0, blue: 0.0)
    static let black: Color = Color.black
}

extension Collection {
    subscript (safe index: Index) -> Iterator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}


/*
 #!/usr/bin/env php
 <?php
 error_reporting( 0 );

 // find a PurpleAir sensor ID on the PurpleAir map and put that ID in $show
 $show = '55075'; // Alhambra near Blue Ridge

 $url = ( 'https://www.purpleair.com/json?show=' . $show );

 // Get the sensor data via JSON
 $json  = @file_get_contents( $url );
 $array = json_decode( $json, true );
 for ( $i = 0; $i < sizeof( $array['results'] ); $i++ ) {
 $array['results'][ $i ]['Stats'] = json_decode( $array['results'][ $i ]['Stats'], true );
 }
 $pm25a     = $array['results'][0]['Stats']['v1'];
 $pm25b     = $array['results'][1]['Stats']['v1'];
 $pm25livea = $array['results'][0]['Stats']['v'];
 $pm25liveb = $array['results'][1]['Stats']['v'];

 $location = $array['results'][0]['Label'];
 $lat      = $array['results'][1]['Lat'];
 $lon      = $array['results'][1]['Lon'];

 $aqia     = aqiFromPM( $pm25a );
 $aqib     = aqiFromPM( $pm25b );
 $aqilivea = aqiFromPM( $pm25livea );
 $aqiliveb = aqiFromPM( $pm25liveb );

 settype( $aqia, 'integer' );
 settype( $aqib, 'integer' );
 settype( $aqilivea, 'integer' );
 settype( $aqiliveb, 'integer' );

 $AQI     = round( ( $aqia + $aqib ) / 2 );
 $AQIlive = round( ( $aqilivea + $aqiliveb ) / 2 );

 echo ( $output . getAQIDescription( $AQIlive ) . ' (' . $AQI . getAQItrend( $AQI, $AQIlive ) . ')|color=' . getAQIcolor( $AQI ) . '
 ---
 ' . $location . '|href=https://www.purpleair.com/map?opt=1/i/mAQI/a10/cC0&select=' . $show . '#11/' . $lat . '/' . $lon );

 // Function to get AQI number from PPM reading
 function aqiFromPM( $pm ) {
 if ( is_nan( $pm ) ) {
 return '-';
 }
 if ( isset( $pm ) == false ) {
 return 'Error: No value';
 }
 if ( $pm < 0.0 ) {
 return $pm;
 }
 if ( $pm > 1000.0 ) {
 return '-';
 }
 if ( $pm > 350.5 ) {
 return calcAQI( $pm, 500.0, 401.0, 500.0, 350.5 );
 } elseif ( $pm > 250.5 ) {
 return calcAQI( $pm, 400.0, 301.0, 350.4, 250.5 );
 } elseif ( $pm > 150.5 ) {
 return calcAQI( $pm, 300.0, 201.0, 250.4, 150.5 );
 } elseif ( $pm > 55.5 ) {
 return calcAQI( $pm, 200.0, 151.0, 150.4, 55.5 );
 } elseif ( $pm > 35.5 ) {
 return calcAQI( $pm, 150.0, 101.0, 55.4, 35.5 );
 } elseif ( $pm > 12.1 ) {
 return calcAQI( $pm, 100.0, 51.0, 35.4, 12.1 );
 } elseif ( $pm >= 0.0 ) {
 return calcAQI( $pm, 50.0, 0.0, 12.0, 0.0 );
 } else {
 return '-';
 }
 }

 // Function that actually calculates the AQI number
 function calcAQI( $Cp, $Ih, $Il, $BPh, $BPl ) {
 $a = ( $Ih - $Il );
 $b = ( $BPh - $BPl );
 $c = ( $Cp - $BPl );
 return round( ( $a / $b ) * $c + $Il );
 }

 // Function that gets the AQI's description
 function getAQIDescription( $aqinum ) {
 if ( $aqinum >= 401 ) {
 return 'Hazardous';
 } elseif ( $aqinum >= 301 ) {
 return 'Hazardous';
 } elseif ( $aqinum >= 201 ) {
 return 'Very Unhealthy';
 } elseif ( $aqinum >= 151 ) {
 return 'Unhealthy';
 } elseif ( $aqinum >= 101 ) {
 return 'Unhealthy SG';
 } elseif ( $aqinum >= 51 ) {
 return 'Moderate';
 } elseif ( $aqinum >= 0 ) {
 return 'Good';
 } else {
 return 'Unknown';
 }
 }

 // Function that gets the AQI's color code
 function getAQIColor( $aqinum ) {


 $darkmode = shell_exec('osascript <<EOF
 tell application "System Events"
 tell appearance preferences
 set theMode to dark mode
 end tell
 end tell
 return theMode
 EOF
 ');
 $darkmodestate = filter_var($darkmode, FILTER_VALIDATE_BOOLEAN);


 if ( $darkmodestate ) {
 // we are in dark mode
 if ( $aqinum >= 301 ) {
 return '#7e0023';
 } elseif ( $aqinum >= 201 ) {
 return '#8f3f97';
 } elseif ( $aqinum >= 151 ) {
 return '#ff0000';
 } elseif ( $aqinum >= 101 ) {
 return 'Orange';
 } elseif ( $aqinum >= 51 ) {
 return '#ffff00';
 } elseif ( $aqinum >= 0 ) {
 return '#00e400';
 } else {
 return '#ffffff';
 }
 } else {
 // we are in light mode
 if ( $aqinum >= 301 ) {
 return '#7e0023';
 } elseif ( $aqinum >= 201 ) {
 return '#8f3f97';
 } elseif ( $aqinum >= 151 ) {
 return '#ff0000';
 } elseif ( $aqinum >= 101 ) {
 return '#cf7332';
 } elseif ( $aqinum >= 51 ) {
 return '#333333';
 } elseif ( $aqinum >= 0 ) {
 return '#0c990c';
 } else {
 return '#000000';
 }
 }
 }


 // Function that checks for the AQI trend
 function getAQItrend( $average, $live ) {
 if ( ( $average - $live ) > 9 ) {
 return '↓';
 } elseif ( ( $average - $live ) < -9 ) {
 return '↑';
 } else {
 return '';
 }
 }

 ?>`


 */
