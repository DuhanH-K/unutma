import Flutter
import Foundation
import os

final class NativeUnutmaApi: UnutmaApi {
  private let storageQueue = DispatchQueue(label: "app.unutma.local-store", qos: .userInitiated)
  private let store: IOSLocalStore
  private let reminders: IOSReminders
  private let events: UnutmaEvents
  private var synchronization: Task<Void, Error>?
  private let log = Logger(subsystem: "app.unutma.mobile", category: "NativeBridge")

  init(binaryMessenger: FlutterBinaryMessenger, reminders: IOSReminders) throws {
    self.store = IOSLocalStore(url: try IOSLocalStore.applicationURL())
    self.reminders = reminders
    self.events = UnutmaEvents(binaryMessenger: binaryMessenger)
    reminders.onOpen = { [weak self] in
      Task { @MainActor in try? await self?.events.sharedTextReceived() }
    }
    reminders.onPermissionChanged = { [weak self] in
      Task { try? await self?.reconcile() }
    }
    log.notice("Native UnutmaApi registered")
  }

  private func failure(_ error: Error) -> PigeonError {
    let code: String
    switch error {
    case IOSStoreError.invalidInput: code = "invalid_input"
    case IOSStoreError.conflict: code = "revision_conflict"
    default: code = "storage_failure"
    }
    log.error("Local operation failed: \(code, privacy: .public)")
    return PigeonError(code: code, message: "Local operation could not be completed", details: nil)
  }

  private func read<T>(_ body: @escaping (IOSLocalStore) throws -> T) async throws -> T {
    try await withCheckedThrowingContinuation { continuation in
      storageQueue.async {
        do { continuation.resume(returning: try body(self.store)) }
        catch { continuation.resume(throwing: self.failure(error)) }
      }
    }
  }

  private func sync<T>(_ body: (IOSLocalStore) throws -> T) throws -> T {
    do { return try storageQueue.sync { try body(store) } }
    catch { throw failure(error) }
  }

  private func changed() {
    Task { @MainActor in try? await events.cardsChanged() }
  }

  func getCards() async throws -> [CardDto] { try await read { try $0.read().cards.map(\.dto) } }

  func saveCard(card: CardDto) async throws -> CardDto {
    let result = try await read { try $0.save(card, now: Self.now()) }
    changed()
    Task { await self.reconcileAfterMutation() }
    return result
  }

  func transition(id: String, action: String, revision: Int64) async throws {
    try await read { try $0.transition(id: id, action: action, revision: revision, now: Self.now()) }
    changed()
    Task { await self.reconcileAfterMutation() }
  }

  func clearSourceMessage(id: String) async throws {
    try await read { try $0.clearSourceMessage(id) }
    changed()
    Task { await self.reconcileAfterMutation() }
  }

  func deleteAllData() async throws {
    // Serialize with pending reconciliation to prevent old notifications from
    // being re-created after the user explicitly deletes all local data.
    let task: Task<Void, Error> = await MainActor.run {
      let previous = self.synchronization
      let next = Task {
        _ = try? await previous?.value
        try await self.read { try $0.deleteAll() }
        await self.reminders.deleteAll()
      }
      self.synchronization = next
      return next
    }
    try await task.value
    changed()
  }

  // iOS has no Android NotificationListener. Do not claim access to other apps.
  func getSources() async throws -> [SourceDto] { [] }
  func setSourceIgnored(packageName: String, ignored: Bool) async throws {
    throw PigeonError(code: "unsupported_platform", message: "No notification listener on iOS", details: nil)
  }
  func getAccess() async throws -> AccessDto {
    AccessDto(listenerEnabled: false, remindersEnabled: await reminders.isEnabled())
  }
  func openNotificationAccess() throws {
    throw PigeonError(code: "unsupported_platform", message: "Use manual reminders on iOS", details: nil)
  }
  func requestReminderPermission() throws { reminders.requestPermission() }
  func getPreferences() throws -> PreferencesDto { try sync { try $0.read().preferences.dto } }
  func setPreferences(preferences: PreferencesDto) throws {
    try sync { try $0.setPreferences(preferences) }
  }

  func reconcile() async throws {
    let task: Task<Void, Error> = await MainActor.run {
      let previous = self.synchronization
      let next = Task {
        _ = try? await previous?.value
        let state = try await self.read { try $0.read() }
        try await self.reminders.synchronize(cards: state.cards.map(\.dto),
          language: state.preferences.language, now: Self.now())
      }
      self.synchronization = next
      return next
    }
    do { try await task.value }
    catch { throw failure(error) }
  }
  private func reconcileAfterMutation() async {
    // The card is already durable. Never report a failed save and encourage
    // duplicate creation because the OS notification service had a transient error.
    do { try await reconcile() }
    catch {
      log.error("Reminder scheduling failed; retrying once, and on next foreground")
      Task { [weak self] in
        try? await Task.sleep(nanoseconds: 5_000_000_000)
        try? await self?.reconcile()
      }
    }
  }
  func takeOpenedCard() throws -> String? { reminders.takeOpenedCard() }
  func takeSharedText() throws -> String? { nil }

  func importSharedText(text: String) async throws -> String? {
    let preview = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !preview.isEmpty, preview.count <= 4000 else { throw failure(IOSStoreError.invalidInput) }
    // Explicit paste creates a REVIEW draft, not a pretend Android parser result.
    // A date must be supplied by the user before it can become a reminder.
    let card = CardDto(id: UUID().uuidString, category: "OTHER", title: String(preview.prefix(120)),
      sourceLabel: "", sourcePackage: "app.unutma.paste", status: "REVIEW", confidence: 0,
      createdAt: Self.now(), reminderOffsets: [1440], parserVersion: 1,
      sourceMessage: preview, revision: 1)
    try await read { store in
      var state = try store.read()
      state.cards.append(IOSCardRecord(card))
      try store.write(state)
    }
    changed()
    return card.id
  }

  private static func now() -> Int64 { Int64(Date().timeIntervalSince1970 * 1000) }
}
