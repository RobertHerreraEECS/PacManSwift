//
//  Structures.swift
//  GridTest
//
//  Created by Robert Herrera on 4/22/18.
//  Copyright © 2018 Robert Herrera. All rights reserved.
//

import Foundation


struct GridNode {
    var coordinate = (0,0)
    var NodeData = " "
    var parentCoordinate = (0,0)
}

// Array of objects used for search algorithm
var ObjectArray: [GridNode] = [GridNode]()

// Simple 2D array containing map info
var gridFile = [[String]]()

