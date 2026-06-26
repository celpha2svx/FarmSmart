import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmsmart_app/core/theme/colors.dart';
import 'package:farmsmart_app/core/network/api_client.dart';
import 'package:farmsmart_app/core/constants/api_constants.dart';
import 'package:farmsmart_app/presentation/providers/auth_provider.dart';

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _msgCtrl = TextEditingController();
  String _category = 'bug';
  bool _sending = false;
  String? _result;

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback & Support'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Category selector
          const Text('Category', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _categoryChip('bug', '🐛 Bug Report'),
              _categoryChip('feature', '💡 Feature Request'),
              _categoryChip('question', '❓ Question'),
              _categoryChip('other', '📝 Other'),
            ],
          ),
          const SizedBox(height: 24),

          // Message
          const Text('Your message', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 8),
          TextField(
            controller: _msgCtrl,
            maxLines: 6,
            maxLength: 2000,
            decoration: InputDecoration(
              hintText: 'Describe your issue, suggestion, or question...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 24),

          // Submit
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _sending || _msgCtrl.text.trim().isEmpty ? null : _submit,
              child: _sending
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Submit Feedback'),
            ),
          ),

          // Result
          if (_result != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_result!, style: const TextStyle(fontSize: 13))),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),
          // Support info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📬 How it works', style: TextStyle(fontWeight: FontWeight.w600)),
                SizedBox(height: 8),
                Text(
                  'Your feedback is sent to our GitHub Issues where we track and respond to every report. '
                  'You can check the status of your issue on our GitHub repository.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryChip(String value, String label) {
    final isSelected = _category == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 13)),
      selected: isSelected,
      onSelected: (_) => setState(() => _category = value),
      selectedColor: AppColors.primaryLight.withOpacity(0.2),
    );
  }

  Future<void> _submit() async {
    setState(() {
      _sending = true;
      _result = null;
    });

    final auth = ref.read(authProvider);
    final client = FarmSmartApiClient();

    try {
      final resp = await client.post('/api/feedback', data: {
        'phone': auth.phone ?? '',
        'token': auth.token ?? '',
        'message': _msgCtrl.text.trim(),
        'category': _category,
        'app_version': '1.0.0',
        'device_info': 'Flutter Android',
      });
      final data = resp.data as Map;
      setState(() {
        _sending = false;
        _result = data['message']?.toString() ?? 'Thank you for your feedback!';
      });
      _msgCtrl.clear();
    } catch (e) {
      setState(() {
        _sending = false;
        _result = 'Failed to send. Please try again later.';
      });
    }
  }
}
