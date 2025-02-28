import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    func requestPermissions(completion: @escaping (Bool) -> Void) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            completion(granted)
        }
    }
    
    func scheduleMorningNotification() {
        // Schedule the initial 8 AM notification
        let morningDate = createDateForHour(8, minute: 0)
        scheduleNotification(at: morningDate, with: "Time to journal! What do you desire today?", identifier: "morning")
        
        // Schedule follow-up notifications every 30 minutes until 10 PM if the user hasn't journaled
        for hour in 8...21 {
            for minute in stride(from: 30, to: 60, by: 30) {
                if hour == 21 && minute > 30 { continue } // Don't schedule after 9:30 PM
                
                let followUpDate = createDateForHour(hour, minute: minute)
                let identifier = "followup-\(hour)-\(minute)"
                scheduleNotification(at: followUpDate, with: "Don't forget to journal today!", identifier: identifier)
            }
        }
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    private func scheduleNotification(at date: Date, with message: String, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = "Trinity Journal"
        content.body = message
        content.sound = .default
        
        // Create a calendar-based trigger
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        // Create the request
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Add the request to the notification center
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification scheduling error: \(error.localizedDescription)")
            }
        }
    }
    
    private func createDateForHour(_ hour: Int, minute: Int) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute
        components.second = 0
        
        // If the time has already passed today, schedule for tomorrow
        let targetDate = Calendar.current.date(from: components)!
        if targetDate < Date() {
            return Calendar.current.date(byAdding: .day, value: 1, to: targetDate)!
        }
        
        return targetDate
    }
} 