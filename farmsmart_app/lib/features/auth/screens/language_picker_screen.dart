import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/l10n/locale_provider.dart';
import '../../settings/providers/settings_provider.dart';

class LanguagePickerScreen extends ConsumerStatefulWidget {
  const LanguagePickerScreen({super.key});

  @override
  ConsumerState<LanguagePickerScreen> createState() => _LanguagePickerScreenState();
}

class _LanguagePickerScreenState extends ConsumerState<LanguagePickerScreen> {
  String? _selected;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final saved = await FlutterSecureStorage().read(key: 'locale');
    if (saved != null && mounted) setState(() => _selected = saved);
  }

  Future<void> _save(String code) async {
    setState(() => _selected = code);
    await FlutterSecureStorage().write(key: 'locale', value: code);
    // Update the runtime locale so subsequent screens render in the new language
    ref.read(settingsProvider.notifier).setLocale(code);
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);
    final canContinue = _selected != null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Text(
                '🌱',
                style: const TextStyle(fontSize: 56),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                t.t('choose_language'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1D1B20),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                t.t('language_picker_subtitle'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView(
                  children: [
                    _LanguageOption(
                      code: 'en',
                      label: 'English',
                      flagEmoji: '🇬🇧',
                      selected: _selected == 'en',
                      onTap: () => _save('en'),
                    ),
                    _LanguageOption(
                      code: 'ha',
                      label: 'Hausa',
                      flagEmoji: '🇳🇬',
                      selected: _selected == 'ha',
                      onTap: () => _save('ha'),
                    ),
                    _LanguageOption(
                      code: 'yo',
                      label: 'Yoruba',
                      flagEmoji: '🇳🇬',
                      selected: _selected == 'yo',
                      onTap: () => _save('yo'),
                    ),
                    _LanguageOption(
                      code: 'ig',
                      label: 'Igbo',
                      flagEmoji: '🇳🇬',
                      selected: _selected == 'ig',
                      onTap: () => _save('ig'),
                    ),
                    _LanguageOption(
                      code: 'pcm',
                      label: 'Pidgin',
                      flagEmoji: '🇳🇬',
                      selected: _selected == 'pcm',
                      onTap: () => _save('pcm'),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: canContinue
                      ? () => Navigator.pushReplacementNamed(context, '/auth')
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green700,
                    disabledBackgroundColor: AppColors.green200,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  child: Text(t.t('continue_label')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String code;
  final String label;
  final String flagEmoji;
  final bool selected;
  final VoidCallback onTap;
  const _LanguageOption({
    required this.code,
    required this.label,
    required this.flagEmoji,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: selected ? AppColors.green50 : Colors.white,
            border: Border.all(
              color: selected ? AppColors.green600 : const Color(0xFFE5E7EB),
              width: selected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Text(flagEmoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
              ),
              if (selected) const Icon(Icons.check_circle, color: AppColors.green700),
            ],
          ),
        ),
      ),
    );
  }
}
