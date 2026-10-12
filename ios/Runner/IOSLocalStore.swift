import Foundation

// Separate Codable records keep the generated Pigeon contract reproducible.
struct IOSCardRecord: Codable {
  var id, category, title, sourceLabel, sourcePackage, status: String
  var dueAt: Int64?
  var amount, currency: String?
  var confidence: Double
  var createdAt: Int64
  var completedAt: Int64?
  var reminderOffsets: [Int64]
  var snoozedUntil: Int64?
  var parserVersion: Int64
  var note, sourceMessage: String?
  var revision: Int64

  init(_ c: CardDto) {
    id = c.id; category = c.category; title = c.title
    sourceLabel = c.sourceLabel; sourcePackage = c.sourcePackage; status = c.status
    dueAt = c.dueAt; amount = c.amount; currency = c.currency; confidence = c.confidence
    createdAt = c.createdAt; completedAt = c.completedAt; reminderOffsets = c.reminderOffsets
    snoozedUntil = c.snoozedUntil; parserVersion = c.parserVersion
    note = c.note; sourceMessage = c.sourceMessage; revision = c.revision
  }

  var dto: CardDto {
    CardDto(id: id, category: category, title: title, sourceLabel: sourceLabel,
      sourcePackage: sourcePackage, dueAt: dueAt, amount: amount, currency: currency,
      status: status, confidence: confidence, createdAt: createdAt, completedAt: completedAt,
      reminderOffsets: reminderOffsets, snoozedUntil: snoozedUntil, parserVersion: parserVersion,
      note: note, sourceMessage: sourceMessage, revision: revision)
  }
}

struct IOSPreferencesRecord: Codable {
  var onboarded = false
  var language = ""
  var theme = "system"
  var reminderMinutes: Int64 = 1440
  var dto: PreferencesDto {
    PreferencesDto(onboarded: onboarded, language: language, theme: theme,
      reminderMinutes: reminderMinutes)
  }
}

struct IOSLocalState: Codable {
  var schema = 1
  var cards: [IOSCardRecord] = []
  var preferences = IOSPreferencesRecord()
}

enum IOSStoreError: Error { case invalidInput, conflict, corruptStore }

/// Access only through NativeUnutmaApi's serial storage queue.
/// Atomic, protected, excluded from iCloud backup; no notification text is logged.
final class IOSLocalStore {
  let url: URL
  init(url: URL) { self.url = url }

  static func applicationURL() throws -> URL {
    try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask,
      appropriateFor: nil, create: true).appendingPathComponent("UNUTMA/state-v1.json")
  }

  func read() throws -> IOSLocalState {
    guard FileManager.default.fileExists(atPath: url.path) else { return IOSLocalState() }
    let data = try Data(contentsOf: url)
    guard data.count <= 16 * 1024 * 1024 else { throw IOSStoreError.corruptStore }
    let state = try JSONDecoder().decode(IOSLocalState.self, from: data)
    guard state.schema == 1 else { throw IOSStoreError.corruptStore }
    return state
  }

  func write(_ state: IOSLocalState) throws {
    let directory = url.deletingLastPathComponent()
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true,
      attributes: [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication])
    let data = try JSONEncoder().encode(state)
    guard data.count <= 16 * 1024 * 1024 else { throw IOSStoreError.invalidInput }
    var excluded = URLResourceValues()
    excluded.isExcludedFromBackup = true
    var protectedDirectory = directory
    try protectedDirectory.setResourceValues(excluded)
    try data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
  }

  func save(_ dto: CardDto, now: Int64) throws -> CardDto {
    var state = try read()
    let title = dto.title.trimmingCharacters(in: .whitespacesAndNewlines)
    let categories = ["BILL", "PAYMENT_DUE", "PACKAGE_DELIVERY", "PACKAGE_PICKUP",
      "APPOINTMENT", "RESERVATION", "SUBSCRIPTION_RENEWAL", "RETURN_WINDOW",
      "TICKET_EVENT", "TRAVEL", "DEADLINE", "OTHER"]
    guard !title.isEmpty, title.count <= 120, (dto.note?.count ?? 0) <= 500,
      (dto.sourceMessage?.count ?? 0) <= 4000, categories.contains(dto.category), dto.dueAt != nil,
      dto.reminderOffsets.count <= 5, dto.reminderOffsets.allSatisfy({ (0...525600).contains($0) }),
      dto.currency == nil || ["TRY", "USD", "EUR", "GBP"].contains(dto.currency!),
      dto.amount == nil || (dto.amount!.count <= 24 && dto.amount!.range(
        of: "^[0-9]+([.,][0-9]{1,2})?$", options: .regularExpression) != nil)
    else { throw IOSStoreError.invalidInput }
    let index = state.cards.firstIndex { $0.id == dto.id }
    guard dto.id.isEmpty || index != nil else { throw IOSStoreError.invalidInput }
    let old = index.map { state.cards[$0] }
    if let old = old {
      guard old.revision == dto.revision else { throw IOSStoreError.conflict }
      guard ["ACTIVE", "REVIEW", "SNOOZED"].contains(old.status) else { throw IOSStoreError.invalidInput }
    }
    var card = IOSCardRecord(dto)
    card.id = old?.id ?? UUID().uuidString
    card.title = title
    card.sourceLabel = old?.sourceLabel ?? ""
    card.sourcePackage = old?.sourcePackage ?? ""
    card.sourceMessage = old?.sourceMessage
    card.createdAt = old?.createdAt ?? now
    card.status = old?.status == "REVIEW" ? "REVIEW" : "ACTIVE"
    card.snoozedUntil = nil; card.completedAt = nil
    card.confidence = old?.confidence ?? 1
    card.revision = (old?.revision ?? 0) + 1
    card.reminderOffsets = Array(Set(dto.reminderOffsets)).sorted()
    if let index = index { state.cards[index] = card } else { state.cards.append(card) }
    try write(state)
    return card.dto
  }

  func transition(id: String, action: String, revision: Int64, now: Int64) throws {
    var state = try read()
    guard let index = state.cards.firstIndex(where: { $0.id == id }) else { return }
    var card = state.cards[index]
    guard card.revision == revision else { throw IOSStoreError.conflict }
    if action == "delete" {
      state.cards.remove(at: index)
      try write(state)
      return
    }
    let active = ["ACTIVE", "SNOOZED"].contains(card.status)
    switch action {
    case "confirm":
      guard card.status == "REVIEW", card.dueAt != nil else { throw IOSStoreError.invalidInput }
      card.status = "ACTIVE"
    case "done", "archive", "ignore":
      guard action == "ignore" ? card.status == "REVIEW" : active else { throw IOSStoreError.invalidInput }
      card.status = action == "done" ? "DONE" : "ARCHIVED"
      card.completedAt = now; card.sourceMessage = nil; card.snoozedUntil = nil
    case "snooze":
      guard active else { throw IOSStoreError.invalidInput }
      card.status = "SNOOZED"; card.snoozedUntil = now + 86_400_000
    default: throw IOSStoreError.invalidInput
    }
    card.revision += 1
    state.cards[index] = card
    try write(state)
  }

  func setPreferences(_ p: PreferencesDto) throws {
    guard ["", "tr", "en"].contains(p.language), ["system", "light", "dark"].contains(p.theme),
      (0...525600).contains(p.reminderMinutes) else { throw IOSStoreError.invalidInput }
    var state = try read()
    state.preferences = IOSPreferencesRecord(onboarded: p.onboarded, language: p.language,
      theme: p.theme, reminderMinutes: p.reminderMinutes)
    try write(state)
  }

  func clearSourceMessage(_ id: String) throws {
    var state = try read()
    if let index = state.cards.firstIndex(where: { $0.id == id }) {
      state.cards[index].sourceMessage = nil
      try write(state)
    }
  }

  func deleteAll() throws {
    // Explicit deletion is also allowed for an unreadable/corrupt store.
    let onboarded = (try? read().preferences.onboarded) ?? false
    if FileManager.default.fileExists(atPath: url.path) { try FileManager.default.removeItem(at: url) }
    if onboarded {
      var state = IOSLocalState()
      state.preferences.onboarded = true
      try write(state)
    }
  }
}
