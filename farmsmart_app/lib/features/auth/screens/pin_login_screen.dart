import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/l10n/locale_provider.dart';
import '../providers/auth_provider.dart';

class PinLoginScreen extends ConsumerStatefulWidget {
  const PinLoginScreen({super.key});

  @override
  ConsumerState<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends ConsumerState<PinLoginScreen> {
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  final _phoneFocus = FocusNode();
  final _pinFocus = FocusNode();
  String? _phoneError;
  String? _pinError;
  bool _phoneEntered = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _pinController.dispose();
    _phoneFocus.dispose();
    _pinFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final phone = _phoneController.text.trim();
    final pin = _pinController.text.trim();
    if (phone.length < 10) {
      setState(() => _phoneError = 'Enter your phone number');
      return;
    }
    if (pin.length != 4) {
      setState(() => _pinError = 'PIN must be 4 digits');
      return;
    }
    final ok = await ref.read(authProvider.notifier).loginWithPin(phone: phone, pin: pin);
    if (!mounted) return;
    if (ok) {
      final auth = ref.read(authProvider);
      final completed = await ref.read(authProvider.notifier).hasCompletedOnboarding();
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        completed ? '/home' : '/onboarding',
      );
    } else {
      final err = ref.read(authProvider).error;
      setState(() => _pinError = err ?? 'Wrong PIN');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF1D1B20),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Text(
                t.t('signin_with_pin'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1D1B20),
                ),
              ),
              const SizedBox(height: 32),
              if (!_phoneEntered) ...[
                TextField(
                  controller: _phoneController,
                  focusNode: _phoneFocus,
                  keyboardType: TextInputType.phone,
                  maxLength: 11,
                  decoration: InputDecoration(
                    labelText: t.t('phone_login'),
                    hintText: '08012345678',
                    errorText: _phoneError,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.phone),
                  ),
                  onChanged: (_) {
                    if (_phoneError != null) setState(() => _phoneError = null);
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_phoneController.text.trim().length < 10) {
                        setState(() => _phoneError = 'Enter your phone number');
                      } else {
                        setState(() => _phoneEntered = true);
                        _pinFocus.requestFocus();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(t.t('continue_label')),
                  ),
                ),
              ] else ...[
                Text(
                  '${t.t('phone_login')}: +234${_phoneController.text.trim()}',
                  style: const TextStyle(color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 24),
                Text(
                  t.t('enter_pin'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Color(0xFF374151)),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Pinput(
                    controller: _pinController,
                    focusNode: _pinFocus,
                    length: 4,
                    obscureText: true,
                    obscuringCharacter: '•',
                    keyboardType: TextInputType.number,
                    pinAnimationType: PinAnimationType.fade,
                    decoration: BoxDecoration(
                      color: _pinError != null ? AppColors.red50 : AppColors.green50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _pinError != null ? AppColors.red600 : AppColors.green200,
                      ),
                    ),
                    onChanged: (_) {
                      if (_pinError != null) setState(() => _pinError = null);
                    },
                    onCompleted: (_) => _submit(),
                  ),
                ),
                if (_pinError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _pinError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.red600, fontSize: 14),
                  ),
                ],
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/signup'),
                  child: Text(t.t('forgot_pin')),
                ),
              ],
              const SizedBox(height: 24),
              if (auth.isLoading) const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      ),
    );
  }
}
