import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/l10n/locale_provider.dart';
import '../providers/auth_provider.dart';

class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  final _first = TextEditingController();
  final _second = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _first.dispose();
    _second.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_first.text.length != 4 || _second.text.length != 4) {
      setState(() => _error = 'PIN must be 4 digits');
      return;
    }
    if (_first.text != _second.text) {
      setState(() => _error = 'PINs don\'t match');
      _first.clear();
      _second.clear();
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final ok = await ref.read(authProvider.notifier).setPin(_first.text);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Navigator.pushReplacementNamed(context, '/onboarding');
    } else {
      setState(() => _error = ref.read(authProvider).error ?? 'Could not save PIN');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF1D1B20),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Text(
                t.t('set_pin_title'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1D1B20),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                t.t('set_pin_subtitle'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 40),
              Text(
                t.t('set_pin_title'),
                style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
              ),
              const SizedBox(height: 8),
              Pinput(
                controller: _first,
                length: 4,
                obscureText: true,
                obscuringCharacter: '•',
                keyboardType: TextInputType.number,
                pinAnimationType: PinAnimationType.fade,
                decoration: BoxDecoration(
                  color: AppColors.green50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.green200),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                t.t('enter_pin'),
                style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
              ),
              const SizedBox(height: 8),
              Pinput(
                controller: _second,
                length: 4,
                obscureText: true,
                obscuringCharacter: '•',
                keyboardType: TextInputType.number,
                pinAnimationType: PinAnimationType.fade,
                decoration: BoxDecoration(
                  color: _error != null ? AppColors.red50 : AppColors.green50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _error != null ? AppColors.red600 : AppColors.green200,
                  ),
                ),
                onCompleted: (_) => _save(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.red600, fontSize: 14),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(t.t('save')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
