import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../cubit/auth_cubit.dart';

class OtpVerificationView extends StatefulWidget {
  const OtpVerificationView({super.key, required this.state});

  final AuthOtpState state;

  @override
  State<OtpVerificationView> createState() => _OtpVerificationViewState();
}

class _OtpVerificationViewState extends State<OtpVerificationView> {
  final _otpCtrl = TextEditingController();
  Timer? _timer;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _restartTimer();
  }

  @override
  void didUpdateWidget(covariant OtpVerificationView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.nonce != widget.state.nonce) {
      _otpCtrl.clear();
      _restartTimer();
    }
  }

  void _restartTimer() {
    _timer?.cancel();
    _secondsLeft = widget.state.resendIn;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft -= 1);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpCtrl.dispose();
    super.dispose();
  }

  void _changeEmail() {
    context.read<AuthCubit>().changeEmail();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColors = theme.extension<AppCardColors>()!;
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final state = widget.state;

    return Scaffold(
      backgroundColor: primaryColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 18),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _changeEmail,
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    tooltip: 'Change email',
                  ),
                  const Spacer(),
                  const Text(
                    'Verify email',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: isDark ? 0.18 : 0.10),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.mark_email_read_outlined, color: primaryColor, size: 34),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Check your email',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: cardColors.titleColor,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Enter the 6-digit code we sent to\n${state.maskedEmail}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.45,
                              color: cardColors.descriptionColor,
                            ),
                          ),
                          const SizedBox(height: 28),
                          Center(
                            child: SizedBox(
                              width: 300,
                              child: TextField(
                                controller: _otpCtrl,
                                autofocus: true,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.done,
                                textAlign: TextAlign.center,
                                maxLength: 6,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 12,
                                  color: cardColors.titleColor,
                                ),
                                onChanged: (_) => setState(() {}),
                                onSubmitted: (value) {
                                  if (value.length == 6 && !state.isVerifying) {
                                    context.read<AuthCubit>().verifyOtp(value);
                                  }
                                },
                                decoration: InputDecoration(
                                  counterText: '',
                                  hintText: '••••••',
                                  hintStyle: TextStyle(
                                    fontSize: 28,
                                    letterSpacing: 10,
                                    color: cardColors.descriptionColor.withValues(alpha: 0.35),
                                  ),
                                  filled: true,
                                  fillColor: isDark
                                      ? theme.colorScheme.surface
                                      : cardColors.descriptionColor.withValues(alpha: 0.06),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(18),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(18),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(18),
                                    borderSide: BorderSide(color: primaryColor, width: 1.5),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (state.error != null) ...[
                            const SizedBox(height: 16),
                            _OtpMessage(
                              message: state.error!,
                              color: Colors.redAccent,
                              icon: Icons.error_outline_rounded,
                            ),
                          ],
                          if (state.notice != null) ...[
                            const SizedBox(height: 16),
                            _OtpMessage(
                              message: state.notice!,
                              color: primaryColor,
                              icon: Icons.check_circle_outline_rounded,
                            ),
                          ],
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 54,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? primaryColor : Colors.black,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: const StadiumBorder(),
                              ),
                              onPressed: state.isVerifying || _otpCtrl.text.length != 6
                                  ? null
                                  : () {
                                      FocusScope.of(context).unfocus();
                                      context.read<AuthCubit>().verifyOtp(_otpCtrl.text);
                                    },
                              child: state.isVerifying
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                    )
                                  : const Text(
                                      'Verify & Create Account',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Center(
                            child: state.isResending
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
                                  )
                                : TextButton(
                                    onPressed: _secondsLeft > 0
                                        ? null
                                        : () {
                                            FocusScope.of(context).unfocus();
                                            context.read<AuthCubit>().resendOtp();
                                          },
                                    child: Text(
                                      _secondsLeft > 0
                                          ? 'Resend code in ${_secondsLeft}s'
                                          : 'Resend code',
                                      style: TextStyle(
                                        color: _secondsLeft > 0 ? cardColors.descriptionColor : primaryColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                          ),
                          Center(
                            child: TextButton(
                              onPressed: state.isVerifying ? null : _changeEmail,
                              child: Text(
                                'Change email address',
                                style: TextStyle(
                                  color: cardColors.descriptionColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'The code expires in ${(state.expiresIn / 60).ceil()} minutes. '
                            'Your account is created only after it is verified.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.5,
                              color: cardColors.descriptionColor.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OtpMessage extends StatelessWidget {
  const _OtpMessage({required this.message, required this.color, required this.icon});

  final String message;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontSize: 13, height: 1.4, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
