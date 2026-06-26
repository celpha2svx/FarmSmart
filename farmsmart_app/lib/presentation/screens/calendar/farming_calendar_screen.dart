import 'package:flutter/material.dart';
import 'package:farmsmart_app/core/theme/colors.dart';
import 'package:farmsmart_app/domain/entities/farm.dart';

/// Farming Calendar — Chinese "农事日历" concept.
/// Shows what to do each day based on crop, weather, and growth stage.
class FarmingCalendarScreen extends StatefulWidget {
  const FarmingCalendarScreen({super.key});

  @override
  State<FarmingCalendarScreen> createState() => _FarmingCalendarScreenState();
}

class _FarmingCalendarScreenState extends State<FarmingCalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    _weekStart = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Farming Calendar'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Week selector
          _buildWeekBar(),
          // Selected date header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppColors.primaryLight.withOpacity(0.05),
            child: Text(
              _formattedSelectedDate(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          // Tasks for selected date
          Expanded(child: _buildTasksForDate()),
        ],
      ),
    );
  }

  Widget _buildWeekBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(7, (i) {
          final day = _weekStart.add(Duration(days: i));
          final isSelected = day.day == _selectedDate.day &&
              day.month == _selectedDate.month &&
              day.year == _selectedDate.year;
          final isToday = day.day == DateTime.now().day &&
              day.month == DateTime.now().month &&
              day.year == DateTime.now().year;

          return GestureDetector(
            onTap: () => setState(() => _selectedDate = day),
            child: Container(
              width: 44,
              height: 64,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : isToday
                        ? AppColors.primaryLight.withOpacity(0.1)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _dayAbbr(day.weekday),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    day.day.toString(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTasksForDate() {
    // Sample tasks based on crop and season
    final tasks = _getSampleTasks();

    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('📋', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              'No tasks for this day',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _taskColor(task.taskType).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(task.taskEmoji, style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      task.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Task marked as done!')),
                  );
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: task.done ? AppColors.success : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: task.done ? AppColors.success : AppColors.divider,
                    ),
                  ),
                  child: task.done
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : null,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<FarmingTask> _getSampleTasks() {
    // In production, these come from the backend AI model
    // based on crop type, growth stage, and weather forecast
    final dayOfMonth = _selectedDate.day;

    return [
      FarmingTask(
        id: '1',
        farmId: 'farm_001',
        taskDate: _selectedDate.toIso8601String(),
        taskType: 'irrigate',
        title: 'Irrigate maize field',
        description: 'Soil moisture is 18%. Apply 20L/m². Best before 10 AM.',
        done: dayOfMonth % 3 == 0,
      ),
      if (dayOfMonth % 7 == 0)
        FarmingTask(
          id: '2',
          farmId: 'farm_001',
          taskDate: _selectedDate.toIso8601String(),
          taskType: 'spray',
          title: 'Apply pest control',
          description: 'Fall armyworm risk is HIGH. Use neem extract or recommended pesticide.',
          done: false,
        ),
      if (dayOfMonth % 14 == 0)
        FarmingTask(
          id: '3',
          farmId: 'farm_001',
          taskDate: _selectedDate.toIso8601String(),
          taskType: 'fertilize',
          title: 'Fertilize — NPK 15:15:15',
          description: 'Apply 50kg per hectare. Rain expected on Thursday.',
          done: false,
        ),
      FarmingTask(
        id: '4',
        farmId: 'farm_001',
        taskDate: _selectedDate.toIso8601String(),
        taskType: 'scout',
        title: 'Scout for pests',
        description: 'Check underside of leaves for eggs/larvae. Focus on field edges.',
        done: dayOfMonth % 2 == 0,
      ),
      if (dayOfMonth == 28)
        FarmingTask(
          id: '5',
          farmId: 'farm_001',
          taskDate: _selectedDate.toIso8601String(),
          taskType: 'harvest',
          title: 'Prepare for harvest',
          description: 'Maize cobs are 85% dry. Harvest within 1 week.',
          done: false,
        ),
    ];
  }

  Color _taskColor(String type) {
    switch (type) {
      case 'plant': return AppColors.primary;
      case 'fertilize': return AppColors.accent;
      case 'irrigate': return AppColors.info;
      case 'spray': return AppColors.error;
      case 'harvest': return AppColors.success;
      case 'scout': return AppColors.warning;
      default: return AppColors.textSecondary;
    }
  }

  String _formattedSelectedDate() {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return '${days[_selectedDate.weekday - 1]}, ${_selectedDate.day} ${months[_selectedDate.month - 1]} ${_selectedDate.year}';
  }

  String _dayAbbr(int weekday) {
    const abbrs = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return abbrs[weekday - 1];
  }
}
