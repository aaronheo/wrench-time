import Foundation
import UserNotifications
import SwiftData

class NotificationService {
    // MARK: - Permission

    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    // MARK: - Evaluate All Components

    @MainActor
    func evaluateAllComponents(modelContext: ModelContext) async {
        let descriptor = FetchDescriptor<Component>()

        guard let components = try? modelContext.fetch(descriptor) else { return }

        // Remove all existing maintenance notifications
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        for component in components {
            guard let bike = component.bike else { continue }

            if component.isDue {
                await scheduleNotification(
                    for: component,
                    on: bike,
                    title: "Replacement Due: \(bike.name)",
                    body: "\(component.name) has \(Int(component.currentMiles)) miles — replacement recommended at \(Int(component.replacementThresholdMiles)) miles.",
                    urgent: true
                )
            } else if component.isApproaching {
                await scheduleNotification(
                    for: component,
                    on: bike,
                    title: "Maintenance Soon: \(bike.name)",
                    body: "\(component.name) is at \(Int(component.wearPercentage * 100))% wear. \(Int(component.milesRemaining)) miles remaining.",
                    urgent: false
                )
            }
        }
    }

    // MARK: - Schedule Notification

    private func scheduleNotification(
        for component: Component,
        on bike: Bike,
        title: String,
        body: String,
        urgent: Bool
    ) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = urgent ? .defaultCritical : .default
        content.categoryIdentifier = "MAINTENANCE"
        content.userInfo = [
            "bikeId": bike.id.uuidString,
            "componentId": component.id.uuidString
        ]

        // Fire in 1 second (immediate delivery for already-due items)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(
            identifier: "maintenance-\(component.id.uuidString)",
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            // Silently fail — notifications are best-effort
        }
    }
}
