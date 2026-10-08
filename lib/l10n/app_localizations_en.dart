// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'UNUTMA';

  @override
  String get tagline => 'A little less on your mind.';

  @override
  String get home => 'Home';

  @override
  String get inbox => 'Review';

  @override
  String get history => 'History';

  @override
  String get settings => 'Settings';

  @override
  String get today => 'TODAY';

  @override
  String get tomorrow => 'TOMORROW';

  @override
  String get week => 'THIS WEEK';

  @override
  String get later => 'LATER';

  @override
  String get overdue => 'PAST DUE';

  @override
  String get morning => 'Good morning';

  @override
  String get afternoon => 'Good afternoon';

  @override
  String get evening => 'Good evening';

  @override
  String get allClear => 'You’re all caught up.';

  @override
  String get emptyBody =>
      'When an important notification arrives, you’ll find it here.';

  @override
  String get localBadge => 'Only on your phone';

  @override
  String get autoOff => 'Automatic capture is not running';

  @override
  String get autoOffBody =>
      'Notification access may be off, or Android may have detached it. Turn UNUTMA access off and on again in system settings.';

  @override
  String get openAccess => 'Manage access';

  @override
  String get add => 'Add new';

  @override
  String get manual => 'Add manually';

  @override
  String get done => 'Done';

  @override
  String get paid => 'Paid';

  @override
  String get snooze => 'Remind tomorrow';

  @override
  String get archive => 'Archive';

  @override
  String get confirm => 'Confirm';

  @override
  String get edit => 'Edit';

  @override
  String get ignore => 'Ignore';

  @override
  String get reviewLabel => 'Needs your review';

  @override
  String get emptyInbox => 'Nothing to review.';

  @override
  String get emptyInboxBody =>
      'If a date or notification is uncertain, I’ll ask you to check it.';

  @override
  String get emptyHistory => 'Your completed items will appear here.';

  @override
  String get historyBody => 'A little more peace of mind with every item done.';

  @override
  String get search => 'Search history';

  @override
  String get all => 'All';

  @override
  String get archived => 'Archived';

  @override
  String get completed => 'Completed';

  @override
  String get newCard => 'Get it off your mind.';

  @override
  String get editCard => 'Edit card';

  @override
  String get what => 'What should I remember?';

  @override
  String get titleHint => 'e.g. Internet bill';

  @override
  String get category => 'Category';

  @override
  String get when => 'When?';

  @override
  String get date => 'Date';

  @override
  String get time => 'Time';

  @override
  String get dueToday => 'Payment due today';

  @override
  String tomorrowAt(String time) {
    return 'Tomorrow • $time';
  }

  @override
  String pickupDaysLeft(int count) {
    return 'Pick up at branch • $count days left';
  }

  @override
  String get chooseDate => 'Choose a date';

  @override
  String get reminder => 'Reminder';

  @override
  String get atTime => 'At the time';

  @override
  String get oneHour => '1 hour before';

  @override
  String get oneDay => '1 day before';

  @override
  String get threeDays => '3 days before';

  @override
  String get noReminder => 'No reminder';

  @override
  String get customReminder => 'Custom (minutes before)';

  @override
  String get optional => 'More details';

  @override
  String get amount => 'Amount';

  @override
  String get currency => 'Currency';

  @override
  String get note => 'Note';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get requiredTitle => 'Enter a short title.';

  @override
  String get requiredDate => 'Choose a date to continue.';

  @override
  String get invalidAmount => 'Enter a valid amount.';

  @override
  String get source => 'Source';

  @override
  String get sourceMessage => 'Source message';

  @override
  String get sourceMessageStored =>
      'This message is encrypted and stored only on your phone.';

  @override
  String get deleteSourceMessage => 'Delete message';

  @override
  String get deleteSourceMessageTitle => 'Delete source message?';

  @override
  String get deleteSourceMessageBody =>
      'The message text will be permanently removed from this card. The reminder card will be kept.';

  @override
  String get sourceMessageDeleted => 'Source message deleted.';

  @override
  String get manualSource => 'Added by you';

  @override
  String get unknownSource => 'Unknown app';

  @override
  String get noDate => 'Check the date';

  @override
  String get detail => 'Action card';

  @override
  String get dueDate => 'Scheduled for';

  @override
  String get reviewBefore =>
      'This notification needs a second look. Check the date before confirming.';

  @override
  String get approximate =>
      'Reminders may be delayed by battery optimization. Exact delivery time is not guaranteed.';

  @override
  String get pastReminder =>
      'Reminders scheduled in the past will not be sent.';

  @override
  String get notificationAccess => 'Notification access';

  @override
  String get enabled => 'On';

  @override
  String get disabled => 'Off';

  @override
  String get reminderPermission => 'Reminder notifications';

  @override
  String get reminderOff =>
      'Reminder notifications are off. Your cards are saved; allow notifications to be reminded.';

  @override
  String get reminderDefaults => 'Default reminder';

  @override
  String get privacy => 'Privacy';

  @override
  String get localData => 'Local data';

  @override
  String get deleteAll => 'Delete all local data';

  @override
  String get deleteTitle => 'Delete local data?';

  @override
  String get deleteBody =>
      'All cards, encrypted previews, reminders and ignored sources will be permanently deleted. Language and appearance reset. Onboarding completion is kept. Notification access can be revoked separately in Android settings.';

  @override
  String get deleteConfirm => 'Yes, delete everything';

  @override
  String get deleted => 'Local data deleted.';

  @override
  String get preferences => 'PREFERENCES';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Appearance';

  @override
  String get system => 'System';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get ignoredSources => 'Ignored sources';

  @override
  String get sourcesBody =>
      'Ignore a source to stop processing its new notifications. Existing cards are kept.';

  @override
  String get noSources => 'No sources yet.';

  @override
  String get about => 'ABOUT';

  @override
  String get version => 'Version';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get terms => 'Terms of use';

  @override
  String get privacyTitle => 'Your notifications\nstay on your phone.';

  @override
  String get privacyLocalAnalysis => 'On-device analysis';

  @override
  String get privacyNoCloud => 'Notification text is not sent to the cloud';

  @override
  String get privacyDeleteAnytime => 'Delete all local data whenever you want';

  @override
  String get privacyBody =>
      'Notification titles and necessary text fields are analyzed only on your device. Notification text is never sent to a server, advertising or analytics service. SMS and email inboxes are not read directly; if the source app\'s notification is off, UNUTMA cannot see that content.';

  @override
  String get privacyStorage =>
      'Necessary card information is stored in a local database. Source messages are encrypted using Android Keystore and removed when the card is completed, archived, or when you delete the message. History is kept for 90 days. Cloud backup is disabled.';

  @override
  String get termsBody =>
      'UNUTMA is a reminder aid. Review extracted information. Notification access, device restrictions and battery settings can affect operation. Do not rely on it as your only safeguard for critical payments or appointments. Advertising, purchases and cloud services are disabled in this build.';

  @override
  String get termsBodyWithAds =>
      'UNUTMA is a reminder aid. Review extracted information. Notification access, device restrictions and battery settings can affect operation. Do not rely on it as your only safeguard for critical payments or appointments. This build may show occasional ads through Google AdMob; purchases and cloud services are disabled.';

  @override
  String get adPrivacyTitle => 'Advertising and privacy';

  @override
  String get adPrivacyBody =>
      'The Google Mobile Ads SDK may automatically collect and share IP address (for an approximate general location), app interactions, diagnostic information, and device or account identifiers with Google for advertising, measurement, and fraud prevention. Data is encrypted in transit using TLS. Notification text, card titles, amounts, notes, and source apps are never added to an ad request.';

  @override
  String get manageAdPrivacy => 'Ad privacy options';

  @override
  String get manageAdPrivacyBody =>
      'Review or change applicable regional advertising choices.';

  @override
  String get pro => 'UNUTMA Pro';

  @override
  String get proTitle => 'The essentials come first.';

  @override
  String get proBody =>
      'Purchases are not enabled in this build. Notification capture, cards and basic reminders are available free.';

  @override
  String get billingDisabled => 'Purchases are not configured';

  @override
  String get restore => 'Restore purchases';

  @override
  String get onboardValue => 'Remembers what\nmatters to you.';

  @override
  String get onboardValueBody =>
      'Quietly catches bills, appointments, deliveries and time-sensitive notifications.';

  @override
  String get onboardTransform =>
      'A notification arrives.\nThe next step is clear.';

  @override
  String get onboardTransformBody =>
      'UNUTMA pulls out what matters, so you know when it needs your attention.';

  @override
  String get onboardAccess => 'You’re always in control.';

  @override
  String get accessWhat => 'What is accessed?';

  @override
  String get accessWhatBody => 'Notification titles and necessary text fields.';

  @override
  String get accessWhy => 'Why?';

  @override
  String get accessWhyBody =>
      'To identify important bills, appointments, deliveries and dates.';

  @override
  String get accessWhere => 'Where does it go?';

  @override
  String get accessWhereBody =>
      'Content never leaves your device. Permission is managed in Android settings.';

  @override
  String get continueLabel => 'Continue';

  @override
  String get skip => 'Not now';

  @override
  String get getStarted => 'Get started';

  @override
  String get enableNotificationAccess => 'Enable notification access';

  @override
  String get exampleNotification => 'Your internet bill is due September 8.';

  @override
  String get exampleBill => 'Internet bill';

  @override
  String get exampleDate => 'September 8';

  @override
  String get exampleLabel => 'HOW IT WORKS';

  @override
  String get retry => 'Try again';

  @override
  String get errorTitle => 'Couldn’t finish that.';

  @override
  String get errorBody => 'Local data couldn’t be accessed. Please try again.';

  @override
  String get saved => 'Card saved.';

  @override
  String get updated => 'Card updated.';

  @override
  String get shareTitle => 'Add to UNUTMA';

  @override
  String get shareBody =>
      'The text you shared is analyzed only on this device. Nothing is saved until you continue.';

  @override
  String get sharePreview => 'SHARED TEXT';

  @override
  String get shareAnalyze => 'Analyze';

  @override
  String get shareNoMatch =>
      'No clear action or date was found. You can finish it manually.';

  @override
  String get shareEmpty => 'There is no text to share.';

  @override
  String get notFound => 'This card is no longer available.';

  @override
  String get filter => 'Filter';

  @override
  String get dateRange => 'Date range';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get bill => 'Bill';

  @override
  String get paymentDue => 'Payment';

  @override
  String get packageDelivery => 'Delivery';

  @override
  String get packagePickup => 'Pickup';

  @override
  String get appointment => 'Appointment';

  @override
  String get reservation => 'Reservation';

  @override
  String get subscriptionRenewal => 'Subscription';

  @override
  String get returnWindow => 'Return window';

  @override
  String get ticketEvent => 'Ticket / event';

  @override
  String get travel => 'Travel';

  @override
  String get deadline => 'Deadline';

  @override
  String get other => 'Other';

  @override
  String attentionCount(int count) {
    return '$count things need your attention.';
  }

  @override
  String reviewCount(int count) {
    return '$count notifications are waiting for your review.';
  }
}
