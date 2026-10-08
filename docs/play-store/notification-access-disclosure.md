# Notification Access disclosure

UNUTMA's primary purpose is to identify actionable information in notifications
locally. The four-step onboarding and Settings → Notification access explain
what is read (title and necessary text), why (bills, appointments, delivery and
deadlines), and that content does not leave the device. The user explicitly opens
Android's listener settings; the application cannot grant this access itself.
Skipping is supported. Manual cards and history remain usable without access.

Android settings are authoritative; returning to the app refreshes permission
state. Reminder posting permission is separate and requested only from the
corresponding setting. Revocation does not delete existing cards automatically.
Delete local data is independently available behind a confirmation dialog.

No AccessibilityService, SMS, call log, location, calendar, contact or broad
package visibility permission is used. Notifications restricted or redacted by
Android are not bypassed. Android force-stop, work profiles and vendor battery
restrictions may limit notification delivery. Do not claim universal capture.
The app does not open SMS or email inboxes. When a source application's
notification is disabled, suppressed or redacted, UNUTMA cannot inspect the
underlying message.
As a permission-free fallback, users may explicitly share plain text from Gmail,
Messages, browsers or other apps to UNUTMA. Shared text is previewed before local
analysis; the app does not open attachments or source-app databases.

This is implementation documentation, not legal advice. The developer must
review current Play policies and provide their own publisher details and public
privacy-policy URL before publication.
