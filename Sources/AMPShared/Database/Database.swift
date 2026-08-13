import Foundation
import SQLite

public final class Database {
    public static let shared = Database()

    private var db: Connection?
    private var dbPath: String = ""

    // Table definitions
    private let tasks = Table("tasks")
    private let sessions = Table("sessions")
    private let settings = Table("settings")

    // Task columns
    private let tId = Expression<Int64>("id")
    private let tTitle = Expression<String>("title")
    private let tStatus = Expression<String>("status")
    private let tPriority = Expression<String>("priority")
    private let tCreatedAt = Expression<String>("created_at")
    private let tCompletedAt = Expression<String?>("completed_at")

    // Session columns
    private let sId = Expression<Int64>("id")
    private let sTaskId = Expression<Int64>("task_id")
    private let sPhase = Expression<String>("phase")
    private let sPlannedMinutes = Expression<Double>("planned_minutes")
    private let sStartedAt = Expression<String>("started_at")
    private let sCompleted = Expression<Bool>("completed")
    private let sEndedAt = Expression<String?>("ended_at")
    private let sWindowLog = Expression<String?>("active_window_log")

    // Settings columns
    private let setSprintMinutes = Expression<Int64>("sprint_minutes")
    private let setSyncMinutes = Expression<Int64>("sync_minutes")
    private let setResetMinutes = Expression<Int64>("reset_minutes")
    private let setRestMinutes = Expression<Int64>("rest_minutes")
    private let setRestAfterCycles = Expression<Int64>("rest_after_cycles")
    private let setNotificationsEnabled = Expression<Bool>("notifications_enabled")
    private let setTrackingEnabled = Expression<Bool>("tracking_enabled")
    private let setFloatingTimerEnabled = Expression<Bool>("floating_timer_enabled")
    private let setFocusColor = Expression<String>("focus_color")

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first?.path ?? "/tmp"
        let dbDir = "\(appSupport)/AMP"
        try? FileManager.default.createDirectory(atPath: dbDir, withIntermediateDirectories: true)
        dbPath = "\(dbDir)/amp.db"
        connect()
        createTables()
        migrateSettingsSchema()
        seedSettings()
    }

    private func postChange() {
        NotificationCenter.default.post(name: .databaseDidChange, object: nil)
    }

    private func connect() {
        let docURL = try! FileManager.default
            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("AMP", isDirectory: true)
            .appendingPathComponent("amp.db")
        try! FileManager.default.createDirectory(at: docURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        db = try? Connection(docURL.path)
    }

    private func createTables() {
        guard let db else { return }
        try? db.run(tasks.create(ifNotExists: true) { t in
            t.column(tId, primaryKey: .autoincrement)
            t.column(tTitle)
            t.column(tStatus)
            t.column(tPriority)
            t.column(tCreatedAt)
            t.column(tCompletedAt)
        })

        try? db.run(sessions.create(ifNotExists: true) { s in
            s.column(sId, primaryKey: .autoincrement)
            s.column(sTaskId)
            s.column(sPhase)
            s.column(sPlannedMinutes)
            s.column(sStartedAt)
            s.column(sCompleted)
            s.column(sEndedAt)
            s.column(sWindowLog)
        })

        try? db.run(settings.create(ifNotExists: true) { s in
            s.column(Expression<Int64>("id"), primaryKey: true)
            s.column(setSprintMinutes)
            s.column(setSyncMinutes)
            s.column(setResetMinutes)
            s.column(setRestMinutes)
            s.column(setRestAfterCycles)
            s.column(setNotificationsEnabled)
            s.column(setTrackingEnabled)
            s.column(setFloatingTimerEnabled, defaultValue: true)
            s.column(setFocusColor, defaultValue: FocusColor.blue.rawValue)
        })
    }

    private func migrateSettingsSchema() {
        guard let db else { return }
        let stmt = try? db.prepare("PRAGMA table_info(settings)")
        let names = stmt?.compactMap { row -> String? in
            guard row.count > 1, let name = row[1] as? String else { return nil }
            return name
        } ?? []
        if !names.contains("floating_timer_enabled") {
            try? db.run("ALTER TABLE settings ADD COLUMN floating_timer_enabled INTEGER NOT NULL DEFAULT 1")
        }
        if !names.contains("focus_color") {
            try? db.run("ALTER TABLE settings ADD COLUMN focus_color TEXT NOT NULL DEFAULT '\(FocusColor.blue.rawValue)'")
        }
    }

    private func seedSettings() {
        guard let db else { return }
        let count = try? db.scalar(settings.filter(Expression<Int64>("id") == 1).count) ?? 0
        if count == 0 {
            let defaults = AppSettings()
            try? db.run(settings.insert(
                Expression<Int64>("id") <- 1,
                setSprintMinutes <- Int64(defaults.sprintMinutes),
                setSyncMinutes <- Int64(defaults.syncMinutes),
                setResetMinutes <- Int64(defaults.resetMinutes),
                setRestMinutes <- Int64(defaults.restMinutes),
                setRestAfterCycles <- Int64(defaults.restAfterCycles),
                setNotificationsEnabled <- defaults.notificationsEnabled,
                setTrackingEnabled <- defaults.trackingEnabled,
                setFloatingTimerEnabled <- defaults.floatingTimerEnabled,
                setFocusColor <- defaults.focusColor.rawValue
            ))
        }
    }

    // MARK: - Settings

    public func getSettings() -> AppSettings {
        guard let db else { return AppSettings() }
        if let row = try? db.pluck(settings) {
            return AppSettings(
                sprintMinutes: Int(row[setSprintMinutes]),
                syncMinutes: Int(row[setSyncMinutes]),
                resetMinutes: Int(row[setResetMinutes]),
                restMinutes: Int(row[setRestMinutes]),
                restAfterCycles: Int(row[setRestAfterCycles]),
                notificationsEnabled: row[setNotificationsEnabled],
                trackingEnabled: row[setTrackingEnabled],
                floatingTimerEnabled: row[setFloatingTimerEnabled],
                focusColor: FocusColor(rawValue: row[setFocusColor]) ?? .blue
            )
        }
        return AppSettings()
    }

    public func updateSettings(_ s: AppSettings) {
        guard let db else { return }
        try? db.run(settings.insert(or: .replace,
            Expression<Int64>("id") <- 1,
            setSprintMinutes <- Int64(s.sprintMinutes),
            setSyncMinutes <- Int64(s.syncMinutes),
            setResetMinutes <- Int64(s.resetMinutes),
            setRestMinutes <- Int64(s.restMinutes),
            setRestAfterCycles <- Int64(s.restAfterCycles),
            setNotificationsEnabled <- s.notificationsEnabled,
            setTrackingEnabled <- s.trackingEnabled,
            setFloatingTimerEnabled <- s.floatingTimerEnabled,
            setFocusColor <- s.focusColor.rawValue
        ))
        postChange()
    }

    // MARK: - Tasks

    private func rowToTask(_ row: Row) -> Task {
        Task(
            id: Int(row[tId]),
            title: row[tTitle],
            status: TaskStatus(rawValue: row[tStatus]) ?? .pending,
            priority: TaskPriority(rawValue: row[tPriority]) ?? .medium,
            createdAt: row[tCreatedAt],
            completedAt: row[tCompletedAt]
        )
    }

    public func addTask(_ task: Task) -> Int {
        guard let db else { return 0 }
        let id = try! db.run(tasks.insert(
            tTitle <- task.title,
            tStatus <- task.status.rawValue,
            tPriority <- task.priority.rawValue,
            tCreatedAt <- task.createdAt,
            tCompletedAt <- task.completedAt
        ))
        postChange()
        return Int(id)
    }

    public func updateTask(_ task: Task) {
        guard let db, let id = task.id else { return }
        let row = tasks.filter(tId == Int64(id))
        try? db.run(row.update(
            tTitle <- task.title,
            tStatus <- task.status.rawValue,
            tPriority <- task.priority.rawValue,
            tCreatedAt <- task.createdAt,
            tCompletedAt <- task.completedAt
        ))
        postChange()
    }

    public func deleteTask(taskId: Int) {
        guard let db else { return }
        try? db.run(sessions.filter(sTaskId == Int64(taskId)).delete())
        try? db.run(tasks.filter(tId == Int64(taskId)).delete())
        postChange()
    }

    public func getTasks(status: TaskStatus? = nil) -> [Task] {
        guard let db else { return [] }
        if let status {
            let rows = try? db.prepare(tasks.filter(tStatus == status.rawValue).order(tCreatedAt.desc))
            return rows?.compactMap { rowToTask($0) } ?? []
        }
        let rows = try? db.prepare(tasks.order(tCreatedAt.desc))
        return rows?.compactMap { rowToTask($0) } ?? []
    }

    public func getTask(taskId: Int) -> Task? {
        guard let db else { return nil }
        if let row = try? db.pluck(tasks.filter(tId == Int64(taskId))) {
            return rowToTask(row)
        }
        return nil
    }

    // MARK: - Sessions

    private func rowToSession(_ row: Row) -> Session {
        Session(
            id: Int(row[sId]),
            taskId: Int(row[sTaskId]),
            phase: Phase(rawValue: row[sPhase]) ?? .idle,
            plannedMinutes: row[sPlannedMinutes],
            startedAt: row[sStartedAt],
            completed: row[sCompleted],
            endedAt: row[sEndedAt],
            activeWindowLog: row[sWindowLog]
        )
    }

    public func addSession(_ session: Session) -> Int {
        guard let db else { return 0 }
        let id = try! db.run(sessions.insert(
            sTaskId <- Int64(session.taskId),
            sPhase <- session.phase.rawValue,
            sPlannedMinutes <- session.plannedMinutes,
            sStartedAt <- session.startedAt,
            sCompleted <- session.completed,
            sEndedAt <- session.endedAt,
            sWindowLog <- session.activeWindowLog
        ))
        postChange()
        return Int(id)
    }

    public func updateSession(_ session: Session) {
        guard let db, let id = session.id else { return }
        let row = sessions.filter(sId == Int64(id))
        try? db.run(row.update(
            sCompleted <- session.completed,
            sEndedAt <- session.endedAt,
            sWindowLog <- session.activeWindowLog
        ))
        postChange()
    }

    public func getSessions(taskId: Int? = nil, limit: Int = 100) -> [Session] {
        guard let db else { return [] }
        if let taskId {
            let rows = try? db.prepare(sessions.filter(sTaskId == Int64(taskId)).order(sStartedAt.desc).limit(limit))
            return rows?.compactMap { rowToSession($0) } ?? []
        }
        let rows = try? db.prepare(sessions.order(sStartedAt.desc).limit(limit))
        return rows?.compactMap { rowToSession($0) } ?? []
    }

    // MARK: - Analytics

    public func getTotalFocusMinutes(taskId: Int? = nil) -> Double {
        guard let db else { return 0 }
        let pred = taskId != nil
            ? sessions.filter(sTaskId == Int64(taskId!)).filter(sPhase == Phase.sprint.rawValue).filter(sCompleted == true)
            : sessions.filter(sPhase == Phase.sprint.rawValue).filter(sCompleted == true)
        return (try? db.scalar(pred.select(sPlannedMinutes.sum))) ?? 0
    }

    public func getFocusByDay(days: Int = 7) -> [(day: String, total: Double)] {
        guard let db else { return [] }
        let query = """
        SELECT DATE(started_at) as day, SUM(planned_minutes) as total
        FROM sessions
        WHERE phase = 'sprint' AND completed = 1
        GROUP BY day
        ORDER BY day DESC
        LIMIT \(days)
        """
        guard let statement = try? db.prepare(query) else { return [] }
        return statement.compactMap { values in
            let day = values[0] as? String ?? ""
            let total = values[1] as? Double ?? 0
            return (day: day, total: total)
        }
    }
}
