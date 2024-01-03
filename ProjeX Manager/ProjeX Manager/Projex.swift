//
//  Projex.swift
//  ProjeX Manager
//
//  Created by Ian Carlson on 11/20/23.
//

import Foundation
import UIKit



struct Task: Identifiable{
    var id: UUID = UUID()
    var startTime: DateComponents
    var endTime: DateComponents
    var name: String
    var status : TaskStatus = .onTime
    var subTasks: [Task]
}

class Projex: Identifiable {
    var id: UUID
    var startTime: DateComponents
    var endTime: DateComponents
    var name: String
    var status: TaskStatus
    var subTasks: [Task]

    // Designated initializer
    init(id: UUID = UUID(), startTime: DateComponents, endTime: DateComponents, name: String, status: TaskStatus = .onTime, subTasks: [Task] = []) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.name = name
        self.status = status
        self.subTasks = subTasks
    }

    // Convenience initializer
    convenience init(name: String, startTime: DateComponents, endTime: DateComponents) {
        self.init(startTime: startTime, endTime: endTime, name: name)
    }

    // Method to add a task
    func addTask(_ task: Task) {
        subTasks.append(task)
    }
}



