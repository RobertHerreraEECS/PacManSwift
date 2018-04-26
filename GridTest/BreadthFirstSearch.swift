//
//  BreadthFirstSearch.swift
//  GridTest
//
//  Created by Robert Herrera on 4/22/18.
//  Copyright © 2018 Robert Herrera. All rights reserved.
//
// Basic Implementation of Breadth First Search
// Note: multi agent search perform on a time schedule

import Foundation
import UIKit

class BreadthFirstSearch {
    
    class func BFS (_ location: (Int,Int),pacman:(Int,Int)) -> [(Int,Int)] {
        
        
        var Queue: [GridNode] = [GridNode]()
        var visitedArray: [GridNode] = [GridNode]()
        var Path =  [(Int,Int)]()
        let pacManGoalPoint = pacman
        let ghostStartPoint = location
        var checkGoal: Bool = false
        var visited: [(x: Int, y: Int)] = []

        //set current sprite position as eval node
        var Eval = ghostStartPoint
        // initial evaluation coordianates
        let x = Eval.0
        let y = Eval.1
        // mark coordinate as visited
        visited.append((x: x,y: y))
        visitedArray.append(GridNode(coordinate: Eval, NodeData: "i", parentCoordinate: (-1,-1)))
        // enqueue coordinate
        Queue.append(GridNode(coordinate: Eval, NodeData: "i", parentCoordinate: (-1,-1)))

        // --- start loop
        while !Queue.isEmpty {

            // eval = queue.last.coordinate
            Eval = (Queue[0].coordinate.0, Queue[0].coordinate.1)

            // check for adjacent neighbors ---> cardinal direction : right, up ,left, down
            if Eval.0 < 0 || Eval.0 > 27 || Eval.1 < 0 || Eval.0 > 27 {
                //print("flag")
                return []
            }
            // if walkable store in walkable list
            var Walkable = checkForWalkable(gridFile, EvalNode: Eval)
            // check for duplicates --> if not in visited then walkable append
            var newWalkable = findUniqeTuples(visited, B: Walkable)
            
            if !newWalkable.isEmpty {
                for (_,e) in newWalkable.enumerated() {
                    // add each coordinate to queue
                    Queue.append(GridNode(coordinate: e , NodeData: gridFile[e.0][e.1], parentCoordinate: Eval))
                    // add each walkable as visited
                    visited.append((x:e.0,y:e.1))
                    // set eval as parent coordinate
                    visitedArray.append(GridNode(coordinate: e , NodeData: gridFile[e.0][e.1], parentCoordinate: Eval))
                }
                // check visisted for target coordinate
                for items in visited {
                    if items.x == pacManGoalPoint.0 && items.y == pacManGoalPoint.1 { // goal node would be placed here
                        checkGoal = true
                        break
                    }
                }
                
                if checkGoal == true {
                    var path = Array(traceBack(visitedArray).reversed())
                    path.remove(at: 0)
                    // append goal node
                    path.append(pacManGoalPoint)
                    Path = path
                    return Path
                }

                Walkable.removeAll(keepingCapacity: true)
                newWalkable.removeAll(keepingCapacity: true)
                
            }// end if
            
            // remove queue.last
            Queue.remove(at: 0)
        }
        print("no goal found")
        return Path // return path
    } // end func
    
}// end class



func checkForWalkable(_ sender: [[String]], EvalNode: (Int,Int)) -> [(Int,Int)] {
    
    //intialized variables
    var tempWalk:[(Int, Int)] = []
    let x = EvalNode.0 // row
    let y = EvalNode.1 // col
    
    //directions
    let right = (x,y+1)
    let up  = (x-1,y)
    let down = (x+1,y)
    let left  = (x,y-1)
    
    // look right
    if right.1 < 56 {  // check boundaries
        if sender[right.0][right.1] != "0" {
            //print("Found walkable at \(right.0) \(right.1) at : \(sender[right.0][right.1])\n\n")
            tempWalk.append((right.0,right.1))
        }
    }
    // look up
    if up.0 > 0 {  // check boundaries
        if sender[up.0][up.1] != "0" {
            //print("Found walkable at \(up.0) \(up.1)\n\n")
            tempWalk.append((up.0,up.1))
        }
    }
    // look left
    if left.1 > 0 {  // check boundaries
        if sender[left.0][left.1] != "0" {
            //print("Found walkable at \(left.0) \(left.1)\n\n")
            tempWalk.append((left.0,left.1))
        }
    }
    // look down
    if down.0 < 55 {  // check boundaries
        if sender[down.0][down.1] != "0" {
            //print("Found walkable at \(down.0) \(down.1)\n\n")
            tempWalk.append((down.0,down.1))
        }
    }
    return tempWalk
}


func findUniqeTuples(_ A: [(x:Int,y:Int)], B: [(Int,Int)]) ->  [(Int,Int)] {
    
    var indexArray:[Int] = []
    for (i, e) in B.enumerated() {
        for items in A {
            if e.0 == items.0 && e.1 == items.1 {
                indexArray.append(i)
            }
        }
    }
    var array = B
    for i in Array(indexArray.reversed()) {
        array.remove(at: i)
    }
    return array
}



func traceBack(_ visited: [GridNode]) -> [(Int,Int)] {
    
    var path = [(Int , Int)]()
    var backNode = visited.last!.parentCoordinate
    let tempTup = backNode
    var tempTup1 = (0,0)
    var indexCarry = 0
    var element = (tempTup.0,tempTup.1)
    
    while backNode.0 != -1  && backNode.1 != -1 {
        
        for (i,items) in visited.enumerated() {
            if items.coordinate.0 == backNode.0 && items.coordinate.1 == backNode.1 {
                tempTup1 = items.parentCoordinate
                indexCarry = i
                break
            }
        }
        element = (tempTup1.0 , tempTup1.1)
        path.append(element)
        backNode  = visited[indexCarry].parentCoordinate
    }
    return path
}

