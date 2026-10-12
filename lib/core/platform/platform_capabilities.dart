import 'package:flutter/foundation.dart';

/// iOS cannot inspect notifications posted by WhatsApp/SMS/other applications.
bool get isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
