import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/l10n/locale_provider.dart';
import '../../../core/providers/core_providers.dart';

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _controller = TextEditingController();
  String _category = 'feedback';
  bool _sending = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final message = _controller.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      final storage = FlutterSecureStorage();
      final phone = await storage.read(key: 'phone') ?? '';
      final token = await storage.read(key: 'auth_token') ?? '';
      final api = ref.read(apiClientProvider);
      await api.post('/api/feedback', data: {
        'phone': phone,
        'token': token,
        'message': message,
        'category': _category,
      });
      if (!mounted) return;
      setState(() {
        _sending = false;
        _sent = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = 'Could not send. Try again?';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.t('send_feedback')),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1D1B20),
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(),
            if (_sent) ...[
              const Icon(Icons.check_circle, size: 80, color: AppColors.green600),
              const SizedBox(height: 24),
              Text(
                t.t('feedback_sent'),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1D1B20)),
                textAlign: TextAlign.center,
              ),
            ] else ...[
              const Icon(Icons.feedback_outlined, size: 60, color: AppColors.green600),
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                children: [
                  _CategoryChip(label: 'Feedback', value: 'feedback', selected: _category == 'feedback', onTap: () => setState(() => _category = 'feedback')),
                  _CategoryChip(label: 'Bug', value: 'bug', selected: _category == 'bug', onTap: () => setState(() => _category = 'bug')),
                  _CategoryChip(label: 'Idea', value: 'feature', selected: _category == 'feature', onTap: () => setState(() => _category = 'feature')),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                maxLines: 6,
                maxLength: 2000,
                decoration: InputDecoration(
                  hintText: t.t('feedback_hint'),
                  filled: true,
                  fillColor: AppColors.green50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: AppColors.red600, fontSize: 14)),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _sending ? null : _submit,
                  icon: _sending
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send),
                  label: Text(_sending ? t.t('loading') : t.t('submit')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryChip({required this.label, required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.green600,
      labelStyle: TextStyle(
        color: selected ? Colors.white : const Color(0xFF374151),
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
