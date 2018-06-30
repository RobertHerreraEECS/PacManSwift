//
//  PathFinder.swift
//  A*
//
//  Created by Robert Herrera on 6/26/18.
//  Copyright © 2018 Robert Herrera. All rights reserved.
//
// Modified from: https://github.com/davecom/SwiftPriorityQueue/blob/master/SwiftPriorityQueue/AppDelegate.swift

import Foundation

// Slightly augmented size of map
let NUM_ROWS = 30
let NUM_COLS = 30

// A point is a way to refer to the row and column of a cell
struct Point: Hashable {
    let x: Int
    let y: Int
    var hashValue: Int { return (Int) (x.hashValue * 31 + y.hashValue) }
}

class PathFinder {
    
    // intialize start and goal parameters
    var start: Point = Point(x: 0, y: 0)
    var goal: Point = Point(x: 0, y: 0)
    
    init (from: (Int,Int), to: (Int,Int)) {
        self.start = Point(x: from.0, y: from.1)
        self.goal = Point(x: to.0, y: to.1)
    }
    
    // check to see if arrived at goal using hashable
    func goalTest(_ x: Point) -> Bool {
        if x == goal {
            return true
        }
        return false
    }
    
    // adjacent directions
    func successors(_ p: Point) -> [Point] { //can't go on diagonals
        var ar: [Point] = [Point]()
        if (p.x + 1 < NUM_ROWS) && (gridFile[p.x + 1][p.y] != WALL) {
            ar.append(Point(x: p.x + 1, y: p.y))
        }
        if (p.x - 1 >= 0) && (gridFile[p.x - 1][p.y] != WALL) {
            ar.append(Point(x: p.x - 1, y: p.y))
        }
        if (p.y + 1 < NUM_COLS) && (gridFile[p.x][p.y + 1] != WALL) {
            ar.append(Point(x: p.x, y: p.y + 1))
        }
        if (p.y - 1 >= 0) && (gridFile[p.x][p.y - 1] != WALL) {
            ar.append(Point(x: p.x, y: p.y - 1))
        }
        
        return ar
    }
    
    // heurisitic using manhattan distance
    func heuristic(_ p: Point) -> Float {
        let xdist = abs(p.x - goal.x)
        let ydist = abs(p.y - goal.y)
        return Float(xdist + ydist)
    }
    
    func search() -> [(Int, Int)]{
        let pathresult:[Point] = (AStar(self.start, goalTestFn: goalTest, successorFn: successors, heuristicFn: heuristic) as [Point]?)!
        
        var path: [(Int,Int)] = [(Int,Int)]()
        for item in pathresult {
            path.append((item.x, item.y))
        }
        return path.reversed()
    }
    
    
    
}
