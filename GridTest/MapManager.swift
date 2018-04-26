//
//  MapManager.swift
//  GridTest
//
//  Created by Robert Herrera on 4/22/18.
//  Copyright © 2018 Robert Herrera. All rights reserved.
//

import Foundation
import SpriteKit

fileprivate var mapSize:(Int, Int) = (0,0)
fileprivate var mrow: Int = 0
fileprivate var mcol: Int = 0

class MapManager {
    
    class func generateMapFromText(file: String) {
        // intialize array based on max size
        for _ in 0 ..< 56 {
            var subList: [String] = []
            for _ in 0 ..< 56 {
                subList.append(" ")
            }
            gridFile.append(subList)
        }
        
        if let levelPath = Bundle.main.path(forResource: file, ofType: "txt") {
            
            if let levelString = try? NSString(contentsOfFile: levelPath, usedEncoding: nil) {
                
                let lines = levelString.components(separatedBy: "\n")
                
                mrow = lines.count
                
                mcol = lines[0].count
                mapSize = (mrow, mcol)
                for (row,line) in Array(lines).enumerated() {
                    for (column, letter) in line.enumerated() {
                        let position = CGPoint(x: column ,y: row)
                        if letter == "0" {
                            let posX = Int(position.x)
                            let posY = Int(position.y)
                            let conversion = String(letter)
                            gridFile[posY][posX] = conversion
                            let tempTup = (posY,posX)
                            ObjectArray.append(GridNode(coordinate: tempTup, NodeData: conversion,parentCoordinate: (0,0)))
                            
                        } else {
                            let posX = Int(position.x)
                            let posY = Int(position.y)
                            let conversion = String(letter)
                            gridFile[posY][posX] = conversion
                            let tempTup = (posY,posX)
                            ObjectArray.append(GridNode(coordinate: tempTup, NodeData: conversion, parentCoordinate: (0,0)))
                            
                        }
                        
                    }
                }
                
            }
        }
        
    }
    
    class func getMapSize() -> (Int, Int){
        return mapSize
    }
    
    
}
