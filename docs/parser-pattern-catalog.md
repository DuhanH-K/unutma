# Parser pattern catalog

UNUTMA uses deterministic, on-device TR/EN rules. This catalog documents pattern
families; it is not a promise that a finite keyword list can understand every
message. Turkish is morphologically rich, and informal mobile text often drops
diacritics or stretches letters. Matching therefore uses a folded copy for rule
checks while the normalized source text remains available for safe extraction.

## Turkish action families

The V4 engine keeps sender/conversation names out of intent text, recognizes
imperatives, polite requests, necessitative forms, and contextual phrases such
as `gelirken`, `çıkmadan`, and `eve varınca`. Contextual phrases are preserved as
review metadata; they do not become fabricated timestamps.

| Intent | Representative families |
|---|---|
| Bill / payment | Open-ended noun + obligation forms such as `ödemesi`, `fatura`, `ücreti`, `bedeli`, `parası`, `borcu`, `taksidi`, `ekstresi`, `aidatı`, `kirası`, `primi`, `harcı`, `cezası`, `masrafı`, `tahsilatı`; actions/states such as `öde`, `yatır`, `havale/EFT/transfer et`, `vadesi`, `var`, `kaldı`, `geldi`, `ödenecek`, `başarısız`, `çekilemedi`; utilities, housing, finance, tax, education, health, shopping and service vocabulary; cheque/promissory-note forms; recurring brands including Spotify, YouTube Premium, Netflix, Disney+, Amazon Prime, BluTV/Max, Exxen, Gain, Apple/iCloud, Google One, Microsoft/Adobe, PlayStation/Xbox and Turkish telecom/TV providers. A merchant or brand alone is insufficient; it needs an obligation/action or a date+amount pair. |
| Appointment | `randevu`, `doktor`, `dişçi`, `muayene`, `kontrol`, `toplantı`, `görüşme`, `mülakat` |
| Delivery | `kargo/paket` with `dağıtımda`, `teslim edilecek`, `gelecek`, `geliyor` |
| Branch pickup | `şubede bekliyor`, `şubede hazır`, `şubesine ulaştı`, `şubeden teslim al`, `kargoyu/paketi al` |
| Subscription | `abonelik/üyelik` with `yenileniyor`, `yenilenecek`, `yenileme tarihi` |
| Return | `iade süresi`, `iade için son gün`, `iade ... kadar`, `iade ... bitiyor` |
| Reservation | `rezervasyon`, confirmed reservation/booking forms |
| Ticket / event | `bilet`, `konser`, `etkinlik`, `sinema`, `tiyatro` |
| Travel | `uçuş`, `sefer`, `otobüs/tren kalkış`, `check-in`, `boarding` |
| Deadline | `son başvuru`, `son gün`, `son tarih`, `süresi doluyor`, `bitiş tarihi` |
| General reminder | `unutma`, `hatırla`, `hatırlat`, `aklında olsun`, `not et/al`, `kaydet`, `takvime ekle`; or a date with `ara`, `yaz`, `gönder`, `götür`, `getir`, `yap`, `git`, `gel`, `uğra`, `başvur`, `teslim et`, `ilacı iç` |

The same families accept common ASCII forms such as `yarin`, `dogalgaz`,
`odemesi`, `subede`, `hatirla`, and repeated-letter noise such as `yarinnn`.
Inflected and colloquial fixtures include `ödemem lazım`, `aramalıyım`,
`yatırmayı unutma`, `ayın 15'inde`, and `8de`.

The automated quality gate contains 341 fixtures across direct reminders,
imperative daily tasks, polite requests, payments, appointments, packages,
calls/messages, bring/take, deadlines, travel, contextual time, noisy Turkish,
marketing, completed actions, OTP/security, summaries, and ordinary non-tasks.

## Date and entity forms

Supported dates include `08.09.2026`, `08/09/2026`, ISO dates, month names,
`bugün`, `yarın`, `öbür gün`, weekdays, `haftaya`, `N gün sonra/içinde/kaldı`,
`N iş günü içinde`, `N hafta sonra`, `ayın 15'inde`, and `gelecek ayın 15'inde`.
Times include `14:30`, AM/PM, `saat 14`, `8'de`, `8de`, `sabah`, `öğlen`,
`akşam`, and `gece`. Relative dates are anchored to notification `postedAt`.
Bare historic phrases such as `10 gün önce` are not converted to future dates.

Amounts accept leading or trailing TRY/TL, USD, EUR and GBP symbols/codes.
Tracking/order/sending/reservation identifiers and explicit `adres/konum/location`
fields are extracted when present. Missing or conflicting dates remain review
items; the parser does not invent a merchant-specific deadline.

## Precision and confirmation policy

Marketing, discounts, OTP/security codes without an actionable intent, weather,
completed payments, delivered/cancelled items, and interpersonal phrases such as
`beni unutma` are rejected. A completed delivery is not turned into a new return
deadline unless the notification itself contains a reliable return deadline.

Structured high-confidence notifications can create an active card. Ambiguous or
incomplete candidates go to Inbox. Messaging-style notifications always require
an explicit decision, even when parsing confidence is high. The local suggestion
notification offers `Ekle`, `İncele`, and `Yoksay` and never displays the source
message text. `Ekle` is available only when a usable due date exists.

## SMS, email and app boundaries

The app does not request `READ_SMS` and does not read SMS or email databases.
It receives only notifications that Android posts after the user grants special
notification access. Consequently, a Gmail message whose Gmail notification is
disabled, suppressed, or redacted is invisible to UNUTMA. Direct mailbox access
would require a separate account/OAuth product and Gmail scopes; it is outside
this local-only version.

For notification-free capture, the user can explicitly choose `Share → UNUTMA`
or select text and choose `UNUTMA’ya ekle`. Plain text is bounded, previewed in
memory, and analyzed locally only after confirmation. Attachments and content
URIs are not opened. A successful parse creates a review card; unmatched text is
passed to the manual form and is not stored until the user saves it.

## Research basis

- [Zemberek NLP](https://github.com/ahmetaa/zemberek-nlp) documents Turkish
  tokenization, morphology, and noisy-text normalization.
- [UD Turkish ATIS verb features](https://universaldependencies.org/treebanks/tr_atis/tr_atis-pos-VERB.html)
  shows the range of imperative, necessitative, optative and future verb forms.
- [Non-canonical Turkish text normalization research](https://aclanthology.org/P19-2037/)
  motivates handling missing diacritics and informal spelling.
- [Android NotificationListenerService](https://developer.android.com/reference/android/service/notification/NotificationListenerService.html)
  defines the posted/removed-notification callback boundary.
- [Android notification permission](https://developer.android.com/develop/ui/compose/notifications/notification-permission)
  explains why Android 13+ posting permission controls UNUTMA's own prompts and
  reminders separately from listener access.
- [Gmail API scopes](https://developers.google.com/workspace/gmail/api/auth/scopes)
  and [message listing](https://developers.google.com/workspace/gmail/api/reference/rest/v1/users.messages/list)
  document the OAuth scopes required for direct mailbox access.
