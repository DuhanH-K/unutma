# UNUTMA Play Store assets

`tr-TR/` contains the production Turkish listing artwork. All artwork uses
privacy-safe demo data and contains no personal device data. Curated phone
artwork supplied for screenshots 02–04 is retained under `sources/tr-TR/` so
regeneration does not overwrite the approved designs.

## Play Console upload map

Upload these files under **Grow > Store presence > Main store listing**:

| File | Play Console field / order | Purpose |
|---|---|---|
| `tr-TR/app_icon_512.png` | App icon | 512×512 listing icon. |
| `tr-TR/feature_graphic_1024x500.png` | Feature graphic | Main promotional banner. |
| `tr-TR/phone_01_dashboard_1080x1920.png` | Phone screenshot 1 | Dashboard and product value. |
| `tr-TR/phone_02_inbox_1080x1920.png` | Phone screenshot 2 | Message notification converted into a reminder candidate. |
| `tr-TR/phone_03_action_card_1080x1920.png` | Phone screenshot 3 | Due date, amount, reminder and source details. |
| `tr-TR/phone_04_privacy_1080x1920.png` | Phone screenshot 4 | On-device processing and local-data privacy. |

Keep this order when uploading the phone screenshots. The first screenshot is
the existing dashboard design; the three supplied images replace screenshots
02, 03 and 04 respectively.

Regenerate and validate from the repository root:

```powershell
flutter test --update-goldens test/visual_qa_test.dart
python tools/generate_store_assets.py --locale tr-TR
python tools/validate_store_assets.py
```

The generator keeps localized copy in a locale map and accepts `--locale`.
Before producing `en-US`, add matching English app goldens so the in-app UI and
the promotional headline use the same language.
