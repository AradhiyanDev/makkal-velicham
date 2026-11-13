import 'package:flutter/services.dart';

/// Maps raw Google Sign-In exceptions to actionable messages.
///
/// ApiException: 10 (DEVELOPER_ERROR) is a *configuration* problem, not a
/// network/backend problem: Google Play Services doesn't recognise this
/// app build. It never reaches our backend, so backend logs stay silent.
String friendlyGoogleSignInMessage(Object e) {
  if (e is PlatformException &&
      e.code == 'sign_in_failed' &&
      (e.message ?? '').contains('ApiException: 10')) {
    return 'Google sign-in failed (Error 10): this app build is not '
        'registered in Google Cloud Console. Add an Android OAuth client for '
        'package com.makkal.velicham with this device\'s SHA-1, and make sure '
        'the serverClientId is a *Web application* client ID.';
  }
  return 'Google sign-in error: $e';
}

/// True when the failure happened on-device (no backend call was made).
bool isGoogleConfigError(Object e) {
  return e is PlatformException &&
      e.code == 'sign_in_failed' &&
      (e.message ?? '').contains('ApiException: 10');
}
