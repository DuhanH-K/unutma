# Acceptance and validation map

| Contract area | Implementation / evidence |
|---|---|
| Empty repository audit, visual opening | `architecture.md`, `asset-audit.json` |
| Provided icon, adaptive/round/monochrome | `tools/derive_assets.py`, Android mipmap resources |
| Canonical onboarding art | responsive `OnboardingArt`, reproducible PNG exports via `tools/render_assets_test.dart` |
| Native background processing | `notification/UnutmaNotificationListenerService.kt` |
| Eligibility and negative/completed intent | `notification/`, `parser/RuleEngine.kt`, `ParserTest.kt` |
| TR/EN dates, DST, locale, business days | `parser/DateParser.kt`, deterministic parser tests |
| Typed feature and weighted confidence | `parser/Features.kt`, `ParserConfig` |
| Transactional duplicate protection | `NativeRepository.ingest`, Room transaction and hashes |
| Single source of truth | Room V1, checked-in schema, migration helper test |
| Encryption and data deletion | `security/PreviewCipher.kt`, native integration tests |
| Typed bridge and recoverable errors | Pigeon definition + generated Dart/Kotlin, AppFailure |
| UI/closed Flutter independence | Listener has no Flutter imports; native instrumented pipeline |
| Dashboard/Inbox/manual/detail/history | Feature screens, repository/controller and widget tests |
| Permission-free explicit capture | Android Sharesheet + selected-text intent, memory-only preview, local import and manual fallback tests |
| Native reminders/actions/reconciliation | WorkManager + revision/receipt guards; native tests |
| Notification and reminder disclosures | Four-step onboarding and independent settings |
| Settings/source ignore/privacy/delete | Native preferences/source table; delete confirmation test |
| TR/EN/dark/accessibility | ARB gen-l10n, layout matrix 3 widths × 2 scales × 2 languages × 2 themes |
| Visual QA | `test/goldens/`: 12 real Flutter render captures |
| Ads/billing/analytics | AdMob/UMP adapter with native release config, foreground-only manual init, consent gate, persisted caps, exclusions and debug test IDs; billing/analytics remain honest disabled/no-op services |
| App signing and production ID | Environment-based release signing; configurable application ID |
| Distribution readiness | Debug APK + unsigned structural bundle validation, strict signed Play build script, listing/privacy/Data safety drafts; publisher account setup remains external |

No Android device guarantee is inferred merely from compilation. Physical OEM
testing, idle/Doze soak tests and Play Console release setup remain distinct
release gates. See `validation.md` for the actual command/device outcomes.
