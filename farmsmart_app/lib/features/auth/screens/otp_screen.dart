import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/l10n/locale_provider.dart';
import '../providers/auth_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phone;
  final bool isSignIn;

  const OtpScreen({super.key, this.phone = '', this.isSignIn = false});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _pinController = TextEditingController();
  final _pinFocusNode = FocusNode();

  String get _phone {
    if (widget.phone.isNotEmpty) return widget.phone;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) return args['phone'] as String? ?? '';
    if (args is String) return args;
    return '';
  }

  bool get _isSignIn {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) return args['isSignIn'] as bool? ?? false;
    return widget.isSignIn;
  }

  int _secondsRemaining = 60;
  Timer? _timer;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    setState(() {
      _canResend = false;
      _secondsRemaining = 60;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining == 0) {
        setState(() => _canResend = true);
        timer.cancel();
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocusNode.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _onCompleted(String pin) async {
    final authNotifier = ref.read(authProvider.notifier);
    final success = await authNotifier.verifyOtp(phone: _phone, otp: pin);
    if (!mounted) return;
    if (success) {
      final completed = await authNotifier.hasCompletedOnboarding();
      if (!mounted) return;
      if (completed) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
      } else {
        Navigator.pushNamedAndRemoveUntil(context, '/onboarding', (_) => false);
      }
    } else {
      _pinController.clear();
      _pinFocusNode.requestFocus();
    }
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;
    _pinController.clear();
    final sent = await ref.read(authProvider.notifier).sendOtp(phone: _phone);
    if (!mounted) return;
    if (sent) {
      _startTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);
    final auth = ref.watch(authProvider);
    final isLoading = auth.isLoading;

    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.error != null && !next.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    final defaultPinTheme = PinTheme(
      width: 52,
      height: 60,
      textStyle: const TextStyle(
        fontSize: 22,
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.transparent),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 2),
      ),
    );

    final errorPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade300, width: 2),
      ),
    );

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.green900, AppColors.green800, AppColors.green700],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                ),
                const SizedBox(height: 24),
                Text(
                  t.t('verify'),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.8)),
                    children: [
                      TextSpan(text: '${t.t('otp_sent')} '),
                      TextSpan(
                        text: _phone,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                if (auth.devOtpCode != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade400),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.developer_mode, color: Colors.amber, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Dev mode — code: ${auth.devOtpCode}',
                          style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 40),
                Center(
                  child: isLoading
                      ? const SizedBox(
                          height: 60,
                          child: Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          ),
                        )
                      : Pinput(
                          controller: _pinController,
                          focusNode: _pinFocusNode,
                          length: 6,
                          autofocus: true,
                          defaultPinTheme: defaultPinTheme,
                          focusedPinTheme: focusedPinTheme,
                          errorPinTheme: errorPinTheme,
                          onCompleted: _onCompleted,
                        ),
                ),
                const SizedBox(height: 40),
                Center(
                  child: _canResend
                      ? TextButton.icon(
                          onPressed: _resendOtp,
                          icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
                          label: Text(
                            t.t('resend_otp'),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : Text(
                          '${t.t('resend_in')} $_secondsRemaining s',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.65),
                            fontSize: 15,
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    _isSignIn
                        ? "Signing you in to your account"
                        : "We'll create your account after verification",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
