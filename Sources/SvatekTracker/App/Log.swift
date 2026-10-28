import os

/// Centralized `os.Logger` categories. View live:
///   log stream --predicate 'subsystem == "com.hermanik.svatektracker"'
/// or browse history in Console.app filtered by that subsystem.
enum Log {
    private static let subsystem = "com.hermanik.svatektracker"
    static let app = Logger(subsystem: subsystem, category: "app")
    static let reminders = Logger(subsystem: subsystem, category: "reminders")
}
