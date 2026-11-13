import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/notifications/push_notification_service.dart';
import '../../../../core/storage/token_storage.dart';

class NotificationPermissionDialog extends StatelessWidget {
  const NotificationPermissionDialog({super.key});

  static const String _prefKey = 'notification_permission_prompt_shown';

  /// Checks if user is logged in and hasn't been prompted yet, then displays the dialog.
  static Future<bool?> checkAndShow(BuildContext context) async {
    try {
      final hasToken = await TokenStorage().hasToken();
      if (!hasToken) return false;

      final prefs = await SharedPreferences.getInstance();
      final alreadyShown = prefs.getBool(_prefKey) ?? false;
      if (alreadyShown) return false;

      // Check system permission status
      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        await prefs.setBool(_prefKey, true);
        return false;
      }

      if (!context.mounted) return false;

      return await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.75),
        builder: (_) => const NotificationPermissionDialog(),
      );
    } catch (_) {
      return false;
    }
  }

  static Future<void> _markDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, true);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 390),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF22163E),
              Color(0xFF150D27),
              Color(0xFF0F081D),
            ],
          ),
          border: Border.all(
            color: const Color(0xFF4C2F7D).withValues(alpha: 0.6),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B2DE2).withValues(alpha: 0.25),
              blurRadius: 32,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              // Subtle ambient glow behind the bell
              Positioned(
                top: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF9333EA).withValues(alpha: 0.35),
                          const Color(0xFF6B11A8).withValues(alpha: 0.12),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.55, 1.0],
                      ),
                    ),
                  ),
                ),
              ),

              SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Close (X) button
                      Align(
                        alignment: Alignment.topRight,
                        child: GestureDetector(
                          onTap: () {
                            _markDismissed();
                            Navigator.of(context).pop(false);
                          },
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.08),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.14),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              color: Colors.white.withValues(alpha: 0.8),
                              size: 18,
                            ),
                          ),
                        ),
                      ),

                      // Bell Illustration
                      Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 14),
                        child: Image.asset(
                          'assets/images/bell.png',
                          height: 125,
                          fit: BoxFit.contain,
                        ),
                      ),

                      // Title
                      RichText(
                        textAlign: TextAlign.center,
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            height: 1.3,
                          ),
                          children: [
                            TextSpan(
                              text: 'முக்கிய செய்திகளை\n',
                              style: TextStyle(color: Colors.white),
                            ),
                            TextSpan(
                              text: 'உடனுக்குடன் பெறுங்கள்',
                              style: TextStyle(color: Color(0xFFCB75FB)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Description
                      const Text(
                        'உங்களுக்கு தேவையான முக்கிய செய்திகளையும்\nஅப்டேட்களையும் நேரடியாக அறிவிக்க\nநோட்டிபிகேஷன் அனுமதி தேவை.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.5,
                          color: Color(0xFFB5AFCD),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Feature Cards
                      const _FeatureItem(
                        icon: Icons.bolt_rounded,
                        iconGradient: LinearGradient(
                          colors: [Color(0xFFF43F5E), Color(0xFFE11D48)],
                        ),
                        title: 'பிரேக்கிங் செய்திகள்',
                        subtitle: 'முக்கிய நிகழ்வுகளை உடனுக்குடன் பெறுங்கள்',
                      ),
                      const SizedBox(height: 10),
                      const _FeatureItem(
                        icon: Icons.calendar_today_rounded,
                        iconGradient: LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                        ),
                        title: 'முக்கிய அப்டேட்கள்',
                        subtitle: 'அரசியல், விளையாட்டு, வானிலை மற்றும் பல',
                      ),
                      const SizedBox(height: 10),
                      const _FeatureItem(
                        icon: Icons.star_rounded,
                        iconGradient: LinearGradient(
                          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                        ),
                        title: 'உங்களுக்கு பொருத்தமான செய்திகள்',
                        subtitle: 'நீங்கள் விரும்பும் தலைப்புகளில் புதிய செய்திகள்',
                      ),
                      const SizedBox(height: 22),

                      // Allow Button
                      Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(26),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF842FD6), Color(0xFF9E42EC)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8B36E2).withValues(alpha: 0.45),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(26),
                            onTap: () async {
                              await _markDismissed();
                              if (context.mounted) {
                                Navigator.of(context).pop(true);
                              }
                              await PushService.requestPermission();
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 14),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.notifications_active_outlined,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        'நோட்டிபிகேஷனை அனுமதிக்கவும்',
                                        maxLines: 1,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Remind Later Button
                      GestureDetector(
                        onTap: () {
                          _markDismissed();
                          Navigator.of(context).pop(false);
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          child: Text(
                            'பிறகு நினைவூட்டவும்',
                            style: TextStyle(
                              color: Color(0xFFA59FB9),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final Gradient iconGradient;
  final String title;
  final String subtitle;

  const _FeatureItem({
    required this.icon,
    required this.iconGradient,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFF231840).withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF3B2564).withValues(alpha: 0.7),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: iconGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFFA59FB9),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

