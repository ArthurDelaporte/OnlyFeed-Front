import 'dart:io';

String getPlatformType() {
  if (Platform.isAndroid) return 'android';
  if (Platform.isIOS) return 'ios';
  return 'other';
}