import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models/todo_task_model.dart';
import '../services/todo_service.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen>
    with SingleTickerProviderStateMixin {
  // StudySync Home screen palette sampled from the supplied screenshot.
  static const Color purple = Color(0xFFA855E8);
  static const Color pink = Color(0xFFEB4FB5);
  static const Color bg = Color(0xFF0D0D1A);
  static const Color panel = Color(0xFF191926);
  static const Color border = Color(0xFF292938);
  static const LinearGradient accentGradient = LinearGradient(
    colors: [purple, pink],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  List<TodoTask> _todos = [];
  bool _loading = true;
  String _filter = 'All';
  String _search = '';
  late final AnimationController _pageController;
  late final Animation<double> _pageFade;
  late final Animation<Offset> _pageSlide;

  @override
  void initState() {
    super.initState();
    _pageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _pageFade = CurvedAnimation(parent: _pageController, curve: Curves.easeOut);
    _pageSlide = Tween<Offset>(begin: const Offset(0, .035), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _pageController, curve: Curves.easeOutCubic),
        );
    _pageController.forward();
    _loadTodos();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadTodos() async {
    final items = await TodoService.loadTodos();
    if (!mounted) {
      return;
    }
    setState(() {
      _todos = items;
      _loading = false;
    });
  }

  Future<void> _save() => TodoService.saveTodos(_todos);

  List<TodoTask> get _visibleTodos {
    Iterable<TodoTask> items = _todos;
    if (_filter == 'Pending') {
      items = items.where((item) => !item.isCompleted);
    } else if (_filter == 'Completed') {
      items = items.where((item) => item.isCompleted);
    }
    final query = _search.trim().toLowerCase();
    if (query.isNotEmpty) {
      items = items.where(
        (item) =>
            item.title.toLowerCase().contains(query) ||
            item.description.toLowerCase().contains(query),
      );
    }
    return items.toList();
  }

  Color _priorityColor(TodoPriority priority) {
    switch (priority) {
      case TodoPriority.high:
        return pink;
      case TodoPriority.medium:
        return purple;
      case TodoPriority.low:
        return const Color(0xFFB58AEF);
    }
  }

  String _dateLabel(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today';
    }
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    if (date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day) {
      return 'Tomorrow';
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _editTask({TodoTask? existing}) async {
    final title = TextEditingController(text: existing?.title ?? '');
    final description = TextEditingController(
      text: existing?.description ?? '',
    );
    DateTime dueDate = existing?.dueDate ?? DateTime.now();
    TodoPriority priority = existing?.priority ?? TodoPriority.medium;

    final result = await showModalBottomSheet<TodoTask>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: EdgeInsets.fromLTRB(
            22,
            14,
            22,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: panel,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  existing == null ? 'Create a task' : 'Edit task',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                _textField(title, 'Task name', 'What do you need to do?'),
                const SizedBox(height: 13),
                _textField(
                  description,
                  'Add a note',
                  'Add more details',
                  maxLines: 3,
                ),
                const SizedBox(height: 18),
                const Text(
                  'PRIORITY',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 8,
                  children: TodoPriority.values.map((item) {
                    final color = _priorityColor(item);
                    return ChoiceChip(
                      label: Text(item.name.toUpperCase()),
                      selected: priority == item,
                      onSelected: (_) => setSheetState(() => priority = item),
                      selectedColor: color,
                      backgroundColor: color.withValues(alpha: .12),
                      labelStyle: TextStyle(
                        color: priority == item ? bg : color,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                      showCheckmark: false,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 17),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: sheetContext,
                      initialDate: dueDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setSheetState(() => dueDate = picked);
                  },
                  icon: const Icon(Icons.calendar_month_rounded),
                  label: Text('Due ${_dateLabel(dueDate)}'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withValues(alpha: .2)),
                    minimumSize: const Size(double.infinity, 48),
                    alignment: Alignment.centerLeft,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      final name = title.text.trim();
                      if (name.isEmpty) return;
                      Navigator.pop(
                        sheetContext,
                        TodoTask(
                          id:
                              existing?.id ??
                              DateTime.now().microsecondsSinceEpoch.toString(),
                          title: name,
                          description: description.text.trim(),
                          dueDate: dueDate,
                          priority: priority,
                          isCompleted: existing?.isCompleted ?? false,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: purple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text(existing == null ? 'Add task' : 'Save changes'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    title.dispose();
    description.dispose();
    if (result == null || !mounted) return;
    setState(() {
      final index = _todos.indexWhere((item) => item.id == result.id);
      if (index < 0) {
        _todos.insert(0, result);
      } else {
        _todos[index] = result;
      }
    });
    await _save();
  }

  Widget _textField(
    TextEditingController controller,
    String label,
    String hint, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white30),
        filled: true,
        fillColor: Colors.white.withValues(alpha: .045),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: .1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: .1)),
        ),
      ),
    );
  }

  Future<void> _toggle(TodoTask todo) async {
    setState(() {
      final index = _todos.indexWhere((item) => item.id == todo.id);
      if (index >= 0) {
        _todos[index] = todo.copyWith(isCompleted: !todo.isCompleted);
      }
    });
    await _save();
  }

  Future<void> _delete(TodoTask todo) async {
    setState(() => _todos.removeWhere((item) => item.id == todo.id));
    await _save();
  }

  void _showDetails(TodoTask todo) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 30),
        decoration: const BoxDecoration(
          color: panel,
          borderRadius: BorderRadius.vertical(top: Radius.circular(27)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    todo.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white70),
                ),
              ],
            ),
            if (todo.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                todo.description,
                style: const TextStyle(color: Colors.white70, height: 1.5),
              ),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 16, color: purple),
                const SizedBox(width: 8),
                Text(
                  _dateLabel(todo.dueDate),
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(width: 18),
                Icon(
                  Icons.flag_rounded,
                  size: 16,
                  color: _priorityColor(todo.priority),
                ),
                const SizedBox(width: 6),
                Text(
                  todo.priority.name.toUpperCase(),
                  style: TextStyle(
                    color: _priorityColor(todo.priority),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _editTask(existing: todo);
                    },
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _delete(todo);
                    },
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Delete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: pink,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(int completed, int total, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: panel,
                border: Border.all(color: border),
                borderRadius: BorderRadius.circular(30),
              ),
              child: IconButton(
                tooltip: 'Back',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: purple,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'My To-Do',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.7,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 51,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: panel,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, color: Colors.white54),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  onChanged: (value) => setState(() => _search = value),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Search your notes',
                    hintStyle: TextStyle(color: Colors.white38),
                    border: InputBorder.none,
                    isCollapsed: true,
                  ),
                ),
              ),
              const Icon(Icons.view_quilt_outlined, color: Colors.white70),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [purple, pink],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: purple.withValues(alpha: .24),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Your progress',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Text(
                    '$completed / $total done',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => LinearProgressIndicator(
                    value: value,
                    minHeight: 8,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 9),
              Text(
                total == 0
                    ? 'A fresh start. Add your first task!'
                    : '${(progress * 100).round()}% complete — keep going!',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 21),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Your tasks',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              '${_visibleTodos.length} items',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: ['All', 'Pending', 'Completed'].map((filter) {
            final selected = _filter == filter;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 7),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  decoration: BoxDecoration(
                    color: selected ? purple : panel,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(13),
                    onTap: () => setState(() => _filter = filter),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      child: Center(
                        child: Text(
                          filter,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _taskCard(TodoTask todo, int index) {
    final color = panel;
    final priority = _priorityColor(todo.priority);
    return TweenAnimationBuilder<double>(
      key: ValueKey(todo.id),
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + (index % 5) * 80),
      curve: Curves.easeOutBack,
      builder: (context, value, child) => Opacity(
        opacity: value.clamp(0.0, 1.0).toDouble(),
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Transform.scale(scale: .96 + .04 * value, child: child),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(19),
          onTap: () => _showDetails(todo),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.fromLTRB(13, 13, 13, 12),
            decoration: BoxDecoration(
              color: color,
              border: Border.all(
                color: todo.isCompleted ? border : border,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(19),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .12),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        todo.priority.name.toUpperCase(),
                        style: TextStyle(
                          color: priority,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .8,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(
                        Icons.more_horiz_rounded,
                        color: Colors.white70,
                        size: 20,
                      ),
                      color: panel,
                      onSelected: (value) {
                        if (value == 'edit') _editTask(existing: todo);
                        if (value == 'delete') _delete(todo);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  todo.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.18,
                    fontWeight: FontWeight.w800,
                    decoration: todo.isCompleted
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                if (todo.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    todo.description,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                ],
                const Spacer(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _toggle(todo),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: 23,
                        height: 23,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: todo.isCompleted
                              ? Colors.white
                              : Colors.white.withValues(alpha: .16),
                          border: Border.all(color: Colors.white70),
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          transitionBuilder: (child, animation) =>
                              ScaleTransition(scale: animation, child: child),
                          child: todo.isCompleted
                              ? const Icon(
                                  Icons.check_rounded,
                                  key: ValueKey('done'),
                                  size: 15,
                                  color: Color(0xFF202635),
                                )
                              : const SizedBox(key: ValueKey('not-done')),
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        _dateLabel(todo.dueDate),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: priority,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: 45),
        child: Column(
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: purple.withValues(alpha: .14),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.checklist_rounded, color: pink, size: 38),
            ),
            const SizedBox(height: 15),
            Text(
              _search.isNotEmpty
                  ? 'No matching tasks'
                  : _filter == 'Completed'
                  ? 'Nothing completed yet'
                  : _filter == 'Pending'
                  ? 'You are all caught up!'
                  : 'Your space is waiting',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Tap the + button to add something to your list.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final completed = _todos.where((item) => item.isCompleted).length;
    final total = _todos.length;
    final progress = total == 0 ? 0.0 : completed / total;

    return FadeTransition(
      opacity: _pageFade,
      child: SlideTransition(
        position: _pageSlide,
        child: Scaffold(
          backgroundColor: bg,
          floatingActionButton: _loading
              ? null
              : TweenAnimationBuilder<double>(
                  tween: Tween(begin: .8, end: 1),
                  duration: const Duration(milliseconds: 650),
                  curve: Curves.elasticOut,
                  builder: (context, scale, child) =>
                      Transform.scale(scale: scale, child: child),
                  child: FloatingActionButton(
                    onPressed: () => _editTask(),
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(19),
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: accentGradient,
                        borderRadius: BorderRadius.circular(19),
                        boxShadow: [
                          BoxShadow(
                            color: purple.withValues(alpha: .25),
                            blurRadius: 18,
                            offset: const Offset(0, 7),
                          ),
                        ],
                      ),
                      child: const SizedBox.expand(
                        child: Icon(
                          Icons.add_rounded,
                          size: 30,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
          body: SafeArea(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: purple))
                : RefreshIndicator(
                    color: purple,
                    backgroundColor: panel,
                    onRefresh: _loadTodos,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: <Widget>[
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 15, 20, 20),
                          sliver: SliverToBoxAdapter(
                            child: _header(completed, total, progress),
                          ),
                        ),
                        _visibleTodos.isEmpty
                            ? _emptyState()
                            : SliverPadding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  100,
                                ),
                                sliver: SliverLayoutBuilder(
                                  builder: (context, constraints) {
                                    final width = constraints.crossAxisExtent;
                                    final columns = width >= 650 ? 3 : 2;
                                    final cardWidth =
                                        (width - (columns - 1) * 11) / columns;
                                    final cardHeight = math.max(
                                      180.0,
                                      math.min(255.0, cardWidth * 1.25),
                                    );

                                    return SliverGrid(
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: columns,
                                            mainAxisSpacing: 11,
                                            crossAxisSpacing: 11,
                                            mainAxisExtent: cardHeight,
                                          ),
                                      delegate: SliverChildBuilderDelegate(
                                        (context, index) => _taskCard(
                                          _visibleTodos[index],
                                          index,
                                        ),
                                        childCount: _visibleTodos.length,
                                      ),
                                    );
                                  },
                                ),
                              ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
