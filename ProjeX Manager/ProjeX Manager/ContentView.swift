//
//  ContentView.swift
//  ProjeX Manager
//
//  Created by Ian Carlson on 11/20/23.
//

import SwiftUI
import CoreData

// TaskStatus enum
enum TaskStatus: Int16, CaseIterable {
    case onTime = 0
    case runningBehind = 1
    case completed = 2

    var description: String {
        switch self {
        case .onTime:
            return "On Time"
        case .runningBehind:
            return "Running Behind"
        case .completed:
            return "Completed"
        }
    }

    var color: Color {
        switch self {
        case .onTime:
            return .yellow
        case .runningBehind:
            return .red
        case .completed:
            return .green
        }
    }
}

// ContentView
struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Project.startTime, ascending: true)],
        animation: .default)
    private var projects: FetchedResults<Project>

    @State private var selectedDate = Date()
    @State private var showingAddProjectView = false

    private var projectsInSelectedRange: [Project] {
        projects.filter { project in
            guard let startDate = project.startTime, let endDate = project.endTime else { return false }
            return (startDate...endDate).contains(selectedDate)
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                DatePicker(
                    "Select Date",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .padding()
                .datePickerStyle(GraphicalDatePickerStyle())
                .onChange(of: selectedDate) { _ in }

                List {
                    ForEach(projectsInSelectedRange, id: \.self) { project in
                        NavigationLink(destination: ProjectDetailView(project: project)) {
                            Text(project.name ?? "Unnamed Project")
                                .foregroundColor(project.taskStatus.color)
                        }
                    }
                    .onDelete(perform: deleteProjects)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: { showingAddProjectView = true }) {
                        Label("Add Project", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddProjectView) {
                AddProjectView(isPresented: $showingAddProjectView)
                    .environment(\.managedObjectContext, self.viewContext)
            }
            Text("Select a project")
        }
        .navigationTitle("Projects")
    }

    private func deleteProjects(offsets: IndexSet) {
        withAnimation {
            offsets.map { projects[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

extension Project {
    var tasksArray: [Tasks] {
        let set = tasks as? Set<Tasks> ?? []
        return set.sorted { $0.name ?? "" < $1.name ?? "" }
    }

    var taskStatus: TaskStatus {
        get {
            TaskStatus(rawValue: status) ?? .onTime
        }
        set {
            status = newValue.rawValue
        }
    }
}

// AddProjectView
struct AddProjectView: View {
    @Environment(\.managedObjectContext) var viewContext
    @Binding var isPresented: Bool

    @State private var name: String = ""
    @State private var startTime = Date()
    @State private var endTime = Date()

    var body: some View {
        NavigationView {
            Form {
                TextField("Project Name", text: $name)
                DatePicker("Start Time", selection: $startTime, displayedComponents: .date)
                DatePicker("End Time", selection: $endTime, displayedComponents: .date)

                Button("Add Project") {
                    let newProject = Project(context: viewContext)
                    newProject.name = name
                    newProject.startTime = startTime
                    newProject.endTime = endTime
                    // Set other properties of Project

                    try? viewContext.save()
                    isPresented = false
                }
            }
            .navigationTitle("New Project")
            .navigationBarItems(leading: Button("Cancel") { isPresented = false })
        }
    }
}

// ProjectDetailView
struct ProjectDetailView: View {
    @ObservedObject var project: Project
    @Environment(\.managedObjectContext) var viewContext
    @State private var showingAddTaskView = false

    var body: some View {
        Form {
            Section(header: Text("Project Details")) {
                TextField("Project Name", text: Binding($project.name, default: ""))
                DatePicker("Start Time", selection: Binding($project.startTime, default: Date()), displayedComponents: .date)
                DatePicker("End Time", selection: Binding($project.endTime, default: Date()), displayedComponents: .date)

                Picker("Status", selection: Binding(
                    get: { TaskStatus(rawValue: project.status) ?? .onTime },
                    set: { project.status = $0.rawValue }
                )) {
                    ForEach(TaskStatus.allCases, id: \.self) { status in
                        Text(status.description).tag(status)
                    }
                }
            }

            Section(header: Text("Tasks")) {
                ForEach(project.tasksArray, id: \.self) { task in
                    NavigationLink(destination: TaskDetailView(task: task)) {
                        VStack(alignment: .leading) {
                            Text(task.name ?? "Unnamed Task")
                                .foregroundColor(task.taskStatus.color)
                            Text("\(task.startDateString) - \(task.endDateString)")
                                .font(.subheadline)
                        }
                    }
                }
                .onDelete(perform: deleteTasks)

                Button("Add Task") {
                    showingAddTaskView = true
                }
            }
        }
        .navigationBarTitle(project.name ?? "Unnamed Project")
        .onDisappear {
            saveContext()
        }
        .sheet(isPresented: $showingAddTaskView) {
            AddTaskView(project: project)
                .environment(\.managedObjectContext, self.viewContext)
        }
    }

    private func deleteTasks(offsets: IndexSet) {
        withAnimation {
            offsets.map { project.tasksArray[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                print("Error deleting task: \(error.localizedDescription)")
            }
        }
    }

    private func saveContext() {
        if viewContext.hasChanges {
            do {
                try viewContext.save()
            } catch {
                print("Error saving context: \(error.localizedDescription)")
            }
        }
    }
}

extension Tasks {
    var startDateString: String {
        guard let startDate = self.startTime else { return "No start date" }
        return itemFormatter.string(from: startDate)
    }

    var endDateString: String {
        guard let endDate = self.endTime else { return "No end date" }
        return itemFormatter.string(from: endDate)
    }

    var taskStatus: TaskStatus {
        get {
            TaskStatus(rawValue: status) ?? .onTime
        }
        set {
            status = newValue.rawValue
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .none
    return formatter
}()



// AddTaskView
struct AddTaskView: View {
    var project: Project
    @Environment(\.managedObjectContext) var viewContext
    @Environment(\.presentationMode) var presentationMode
    @State private var taskName: String = ""
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var status: TaskStatus = .onTime

    var body: some View {
        NavigationView {
            Form {
                TextField("Task Name", text: $taskName)
                DatePicker("Start Time", selection: $startTime, displayedComponents: .date)
                DatePicker("End Time", selection: $endTime, displayedComponents: .date)
                Picker("Status", selection: $status) {
                    ForEach(TaskStatus.allCases, id: \.self) { status in
                        Text(status.description).tag(status)
                    }
                }

                Button("Add Task") {
                    let newTask = Tasks(context: viewContext)
                    newTask.name = taskName
                    newTask.startTime = startTime
                    newTask.endTime = endTime
                    newTask.status = status.rawValue
                    newTask.project = project
                    // Set other properties of Tasks

                    try? viewContext.save()
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .navigationTitle("New Task")
        }
    }
}

// TaskDetailView
struct TaskDetailView: View {
    @ObservedObject var task: Tasks
    @Environment(\.managedObjectContext) var viewContext

    var body: some View {
        Form {
            TextField("Task Name", text: Binding($task.name, default: ""))
            DatePicker("Start Time", selection: Binding($task.startTime, default: Date()), displayedComponents: .date)
            DatePicker("End Time", selection: Binding($task.endTime, default: Date()), displayedComponents: .date)

            Picker("Status", selection: Binding(
                get: { TaskStatus(rawValue: task.status) ?? .onTime },
                set: { task.status = $0.rawValue }
            )) {
                ForEach(TaskStatus.allCases, id: \.self) { status in
                    Text(status.description).tag(status)
                }
            }
        }
        .navigationBarTitle(task.name ?? "Unnamed Task")
        .onDisappear {
            saveContext()
        }
    }

    private func saveContext() {
        if viewContext.hasChanges {
            do {
                try viewContext.save()
            } catch {
                // Handle the error appropriately
                print("Error saving context: \(error.localizedDescription)")
            }
        }
    }
}

// Helper extension for optional binding
extension Binding {
    init(_ source: Binding<Value?>, default: Value) {
        self.init(
            get: { source.wrappedValue ?? `default` },
            set: { source.wrappedValue = $0 }
        )
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
