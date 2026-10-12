import Flutter
import XCTest
@testable import Runner

final class RunnerTests: XCTestCase {
  private var directory: URL!
  private var store: IOSLocalStore!
  private let now: Int64 = 1_800_000_000_000

  override func setUpWithError() throws {
    directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    store = IOSLocalStore(url: directory.appendingPathComponent("state-v1.json"))
  }

  override func tearDownWithError() throws {
    if FileManager.default.fileExists(atPath: directory.path) {
      try FileManager.default.removeItem(at: directory)
    }
  }

  private func card() -> CardDto {
    CardDto(id: "", category: "BILL", title: "Doğalgaz faturası", sourceLabel: "",
      sourcePackage: "", dueAt: now + 172_800_000, amount: "500", currency: "TRY",
      status: "ACTIVE", confidence: 1, createdAt: now, reminderOffsets: [1440, 0],
      parserVersion: 1, note: "Yerel not", revision: 0)
  }

  func testCRUDSurvivesRepositoryRestartAndRejectsStaleEdit() throws {
    let saved = try store.save(card(), now: now)
    XCTAssertFalse(saved.id.isEmpty)
    XCTAssertEqual(saved.revision, 1)
    let restarted = IOSLocalStore(url: store.url)
    XCTAssertEqual(try restarted.read().cards.first?.dto, saved)
    var edit = saved; edit.title = "Güncellenen fatura"; edit.note = "Yeni not"
    let updated = try restarted.save(edit, now: now + 1)
    XCTAssertEqual(updated.revision, 2)
    XCTAssertThrowsError(try restarted.save(edit, now: now + 2))
    try restarted.transition(id: updated.id, action: "done", revision: 2, now: now + 3)
    XCTAssertEqual(try store.read().cards.first?.status, "DONE")
    let another = try store.save(card(), now: now + 4)
    try store.transition(id: another.id, action: "delete", revision: another.revision, now: now + 5)
    XCTAssertEqual(try store.read().cards.count, 1)
    try store.deleteAll()
    XCTAssertTrue(try store.read().cards.isEmpty)
  }

  func testPreferencesSurviveRestart() throws {
    let preferences = PreferencesDto(onboarded: true, language: "en", theme: "dark", reminderMinutes: 60)
    try store.setPreferences(preferences)
    XCTAssertEqual(try IOSLocalStore(url: store.url).read().preferences.dto, preferences)
  }

  func testCorruptFileIsNotSilentlyResetOrOverwritten() throws {
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let bytes = Data("broken data".utf8)
    try bytes.write(to: store.url)
    XCTAssertThrowsError(try store.read())
    XCTAssertThrowsError(try store.save(card(), now: now))
    XCTAssertEqual(try Data(contentsOf: store.url), bytes)
  }

  func testReminderOffsetsDueDateAndSnooze() throws {
    let saved = try store.save(card(), now: now)
    let slots = IOSReminderPlan.slots(saved, now: now)
    XCTAssertEqual(slots.map(\.at), [now + 86_400_000, now + 172_800_000])
    XCTAssertEqual(saved.dueAt, now + 172_800_000)
    let late = IOSReminderPlan.slots(saved, now: now + 86_400_001)
    XCTAssertEqual(late.first?.at, now + 86_405_001)
    try store.transition(id: saved.id, action: "snooze", revision: 1, now: now)
    let snoozed = try store.read().cards[0].dto
    XCTAssertEqual(IOSReminderPlan.slots(snoozed, now: now).map(\.at), [now + 86_400_000])
    var done = saved; done.status = "DONE"
    XCTAssertTrue(IOSReminderPlan.slots(done, now: now).isEmpty)
  }
}
