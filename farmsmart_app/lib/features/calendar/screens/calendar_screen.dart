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

  void _onDaySelected(DateTime selected, DateTime focused) {
    setState(() {
      _selectedDay = selected;
      _focusedDay = focused;
    });
  }

  void _showAddTaskSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddTaskSheet(
        onAdd: (title, type) {
          ref.read(customTasksProvider.notifier).add(title, type);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksProvider);
    final customTasks = ref.watch(customTasksProvider);
    final completions = ref.watch(taskCompletionProvider);
    final t = ref.watch(translationsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: const OfflineBanner()),
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
                titleTextStyle: TextStyle(
                    color: AppColors.green800,
                    fontSize: 18,
                    fontWeight: FontWeight.w600),
                leftChevronIcon:
                    Icon(Icons.chevron_left, color: AppColors.green700),
                rightChevronIcon:
                    Icon(Icons.chevron_right, color: AppColors.green700),
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                    color: AppColors.green100, shape: BoxShape.circle),
                selectedDecoration: BoxDecoration(
                    color: AppColors.green600, shape: BoxShape.circle),
                todayTextStyle: TextStyle(
                    color: AppColors.green800, fontWeight: FontWeight.bold),
                selectedTextStyle: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SliverToBoxAdapter(child: const SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    '${t.t('tasks')} — ${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: AppColors.ink),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          if (customTasks.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final task = customTasks[index];
                  final isComplete = completions.contains(task.id);
                  return _CustomTaskItem(
                    task: task,
                    isComplete: isComplete,
                    onToggle: () => ref.read(taskCompletionProvider.notifier).toggle(task.id),
                    onDelete: () => ref.read(customTasksProvider.notifier).remove(task.id),
                  );
                },
                childCount: customTasks.length,
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
              if (tasks.isEmpty && customTasks.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: true,
                  child: EmptyState(title: t.t('no_tasks')),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final task = tasks[index];
                    final isComplete = completions.contains(task.id);
                    return _TaskItem(
                      task: task,
                      isComplete: isComplete,
                      onToggle: () =>
                          ref.read(taskCompletionProvider.notifier).toggle(task.id),
                    );
                  },
                  childCount: tasks.length,
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
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

class _TaskItem extends StatelessWidget {
  final FarmTask task;
  final bool isComplete;
  final VoidCallback onToggle;
  const _TaskItem({required this.task, required this.isComplete, required this.onToggle});

  @override
  Widget build(BuildContext context) {
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
              onTap: onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isComplete ? AppColors.green500 : AppColors.inkMuted,
                    width: 2,
                  ),
                  color: isComplete ? AppColors.green500 : Colors.transparent,
                ),
                child: isComplete
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          decoration: isComplete ? TextDecoration.lineThrough : null,
                          color: isComplete ? AppColors.inkMuted : AppColors.ink,
                        ),
                  ),
                  if (task.note != null && task.note!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      task.note!,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.inkMuted),
                    ),
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

class _CustomTaskItem extends StatelessWidget {
  final CustomTask task;
  final bool isComplete;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _CustomTaskItem({
    required this.task,
    required this.isComplete,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.green200),
          boxShadow: [AppShadows.sm],
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isComplete ? AppColors.green500 : AppColors.inkMuted,
                    width: 2,
                  ),
                  color: isComplete ? AppColors.green500 : Colors.transparent,
                ),
                child: isComplete
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                task.title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      decoration: isComplete ? TextDecoration.lineThrough : null,
                      color: isComplete ? AppColors.inkMuted : AppColors.ink,
                    ),
              ),
            ),
            const SizedBox(width: 4),
            const AppChip(label: 'custom', variant: ChipVariant.green),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onDelete,
              child: const Icon(Icons.close, size: 18, color: AppColors.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddTaskSheet extends StatefulWidget {
  final void Function(String title, String type) onAdd;
  const _AddTaskSheet({required this.onAdd});

  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  final _controller = TextEditingController();
  String _selectedType = 'general';
  final _types = ['general', 'water', 'fertilizer', 'pest', 'harvest'];

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
      padding: EdgeInsets.fromLTRB(
          16, 24, 16, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(t.t('add_task'),
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'e.g. Apply fertilizer to field 2',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _types.map((type) {
                final selected = _selectedType == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(type),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedType = type),
                    selectedColor: AppColors.green100,
                    checkmarkColor: AppColors.green700,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              final title = _controller.text.trim();
              if (title.isEmpty) return;
              widget.onAdd(title, _selectedType);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green600,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm)),
            ),
            child: Text(t.t('add_task'),
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
