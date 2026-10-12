import Foundation
import UserNotifications
import UIKit

struct IOSReminderSlot: Equatable {
  let id: String
  let at: Int64
}

enum IOSReminderPlan {
  static func slots(_ c: CardDto, now: Int64) -> [IOSReminderSlot] {
    let prefix = "unutma.\(c.id).\(c.revision)."
    if c.status == "SNOOZED" {
      guard let at = c.snoozedUntil, at > now else { return [] }
      return [IOSReminderSlot(id: prefix + "snooze", at: at)]
    }
    guard c.status == "ACTIVE", let due = c.dueAt, due > now else { return [] }
    let offsets = Set(c.reminderOffsets.filter { (0...525600).contains($0) })
    var result = offsets.filter { due - $0 * 60000 > now }.map {
      IOSReminderSlot(id: prefix + String($0), at: due - $0 * 60000)
    }
    if let missed = offsets.filter({ due - $0 * 60000 <= now }).min() {
      result.append(IOSReminderSlot(id: prefix + String(missed), at: now + 5000))
    }
    return result.sorted { $0.at < $1.at }
  }
}

final class IOSReminders: NSObject, UNUserNotificationCenterDelegate {
  private let center: UNUserNotificationCenter
  private let defaults: UserDefaults
  private let ledgerKey = "unutma.ios.scheduledReminders.v1"
  private(set) var openedCard: String?
  var onOpen: (() -> Void)?
  var onPermissionChanged: (() -> Void)?

  init(center: UNUserNotificationCenter = .current(), defaults: UserDefaults = .standard) {
    self.center = center; self.defaults = defaults
    super.init()
  }

  func isEnabled() async -> Bool {
    let settings = await center.notificationSettings()
    return settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
  }

  func requestPermission() {
    center.getNotificationSettings { settings in
      if settings.authorizationStatus == .denied {
        DispatchQueue.main.async {
          UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
        }
      } else {
        self.center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in
          DispatchQueue.main.async { self.onPermissionChanged?() }
        }
      }
    }
  }

  /// Serialized by NativeUnutmaApi. iOS keeps at most 64 pending requests;
  /// reserve four slots and refill the earliest 60 on every change/foreground.
  func synchronize(cards: [CardDto], language: String, now: Int64) async throws {
    let pending = await center.pendingNotificationRequests()
    let own = pending.filter { $0.identifier.hasPrefix("unutma.") }.map(\.identifier)
    let delivered = await center.deliveredNotifications()
    let activeIds = Set(cards.filter { ["ACTIVE", "SNOOZED"].contains($0.status) }.map(\.id))
    let staleDelivered = delivered.filter {
      $0.request.identifier.hasPrefix("unutma.") &&
        !activeIds.contains($0.request.content.userInfo["cardId"] as? String ?? "")
    }.map { $0.request.identifier }
    center.removeDeliveredNotifications(withIdentifiers: staleDelivered)
    guard await isEnabled() else {
      center.removePendingNotificationRequests(withIdentifiers: own)
      return
    }
    let oldLedger = defaults.dictionary(forKey: ledgerKey) as? [String: Double] ?? [:]
    let plan = cards.flatMap { card in IOSReminderPlan.slots(card, now: now).map { (card, $0) } }
      .filter { pair in oldLedger[pair.1.id].map { $0 > Double(now) } ?? true }
      .sorted { $0.1.at < $1.1.at }
    let selected = Array(plan.prefix(60))
    let selectedIds = Set(selected.map { $0.1.id })
    center.removePendingNotificationRequests(withIdentifiers: own.filter { !selectedIds.contains($0) })
    // Retain elapsed receipts for the current card revision, even after the user
    // clears Notification Center, so a foreground catch-up cannot repeat.
    let prefixes = cards.map { "unutma.\($0.id).\($0.revision)." }
    var ledger = oldLedger.filter { key, _ in prefixes.contains { key.hasPrefix($0) } }
    let english = language == "en" || (language.isEmpty && Locale.current.languageCode == "en")
    for (card, slot) in selected {
      let content = UNMutableNotificationContent()
      content.title = english ? "UNUTMA · Time to remember" : "UNUTMA · Hatırlatma zamanı"
      content.subtitle = card.title
      var body: [String] = []
      if let due = card.dueAt {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: english ? "en_GB" : "tr_TR")
        formatter.dateStyle = .medium; formatter.timeStyle = .short
        body.append(formatter.string(from: Date(timeIntervalSince1970: Double(due) / 1000)))
      }
      if let amount = card.amount { body.append("\(amount) \(card.currency ?? "TRY")") }
      content.body = body.joined(separator: " · ")
      content.sound = .default
      content.threadIdentifier = "unutma.reminders"
      content.userInfo = ["cardId": card.id]
      let date = Date(timeIntervalSince1970: Double(slot.at) / 1000)
      // Absolute date components: this is an instant, not a floating local time.
      var calendar = Calendar(identifier: .gregorian)
      calendar.timeZone = TimeZone(secondsFromGMT: 0)!
      var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
      components.timeZone = calendar.timeZone
      let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
      try await center.add(UNNotificationRequest(identifier: slot.id, content: content, trigger: trigger))
      ledger[slot.id] = Double(slot.at)
      // Persist each successful request; a partial OS failure stays recoverable.
      defaults.set(ledger, forKey: ledgerKey)
    }
    defaults.set(ledger, forKey: ledgerKey)
  }

  func deleteAll() async {
    let pending = await center.pendingNotificationRequests()
    center.removePendingNotificationRequests(withIdentifiers:
      pending.filter { $0.identifier.hasPrefix("unutma.") }.map(\.identifier))
    let delivered = await center.deliveredNotifications()
    center.removeDeliveredNotifications(withIdentifiers:
      delivered.filter { $0.request.identifier.hasPrefix("unutma.") }.map { $0.request.identifier })
    defaults.removeObject(forKey: ledgerKey)
    await MainActor.run { self.openedCard = nil }
  }

  func takeOpenedCard() -> String? {
    defer { openedCard = nil }
    return openedCard
  }

  func userNotificationCenter(_ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    if #available(iOS 14.0, *) { completionHandler([.banner, .list, .sound]) }
    else { completionHandler([.alert, .sound]) }
  }

  func userNotificationCenter(_ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
    DispatchQueue.main.async {
      self.openedCard = response.notification.request.content.userInfo["cardId"] as? String
      self.onOpen?()
      completionHandler()
    }
  }
}
