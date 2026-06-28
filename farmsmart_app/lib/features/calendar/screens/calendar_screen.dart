import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../core/widgets/shimmer_loader.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/l10n/locale_provider.dart';
import '../providers/tasks_provider.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  void _onDaySelected(DateTime selected, DateTime focused) {
    setState(() {
      _selectedDay = selected;
      _focusedDay = focused;
    });
  }

  void _showAddTaskSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => const _AddTaskSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksProvider(_formatDate(_selectedDay)));
    final t = ref.watch(translationsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: OfflineBanner()),
          SliverToBoxAdapter(
            child: TableCalendar(
              focusedDay: _focusedDay,
              firstDay: DateTime(2020),
              lastDay: DateTime(2030),
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: _onDaySelected,
              headerStyle: HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
                titleTextStyle: TextStyle(color: AppColors.green800, fontSize: 18, fontWeight: FontWeight.w600),
                leftChevronIcon: Icon(Icons.chevron_left, color: AppColors.green700),
                rightChevronIcon: Icon(Icons.chevron_right, color: AppColors.green700),
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(color: AppColors.green100, shape: BoxShape.circle),
                selectedDecoration: BoxDecoration(color: AppColors.green600, shape: BoxShape.circle),
                todayTextStyle: TextStyle(color: AppColors.green800, fontWeight: FontWeight.bold),
                selectedTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '${t.t('tasks')} for ${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.ink),
              ),
            ),
          ),
          tasksAsync.when(
            loading: () => const SliverFillRemaining(
              hasScrollBody: true,
              child: ShimmerLoader(),
            ),
            error: (e, _) => SliverFillRemaining(
              hasScrollBody: true,
              child: ErrorCard(message: e.toString()),
            ),
            data: (tasks) {
              if (tasks.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: true,
                  child: EmptyState(title: t.t('no_tasks')),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _TaskItem(task: tasks[index]),
                  childCount: tasks.length,
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskSheet,
        backgroundColor: AppColors.green600,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _TaskItem extends ConsumerWidget {
  final FarmTask task;
  const _TaskItem({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (Color bg, Color fg) = switch (task.type) {
      'fertilizer' => (AppColors.earth100, AppColors.earth700),
      'pest' => (AppColors.red100, AppColors.red500),
      'water' => (const Color(0xFFE1F5FE), const Color(0xFF0288D1)),
      _ => (AppColors.green100, AppColors.green700),
    };
    final chipVariant = switch (task.type) {
      'fertilizer' => ChipVariant.earth,
      'pest' => ChipVariant.red,
      'water' => ChipVariant.blue,
      _ => ChipVariant.green,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          boxShadow: [AppShadows.sm],
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {},
              child: Container(
                width: 24, height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: task.completed ? AppColors.green500 : AppColors.inkMuted, width: 2),
                  color: task.completed ? AppColors.green500 : Colors.transparent,
                ),
                child: task.completed ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      decoration: task.completed ? TextDecoration.lineThrough : null,
                      color: task.completed ? AppColors.inkMuted : AppColors.ink,
                    ),
                  ),
                  if (task.note != null) ...[
                    const SizedBox(height: 2),
                    Text(task.note!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.inkMuted)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            AppChip(label: task.type, variant: chipVariant),
          ],
        ),
      ),
    );
  }
}

class _AddTaskSheet extends StatefulWidget {
  const _AddTaskSheet();

  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final container = ProviderScope.containerOf(context);
    final t = container.read(translationsProvider);

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 24, 16, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.t('add_task'), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: t.t('add_task'),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green600,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
            ),
            child: Text(t.t('add_task'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
