import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/firestore_service.dart';

enum TaskFilter { all, active, done }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();

  TaskFilter _selectedFilter = TaskFilter.all;
  String _searchText = '';

  List<Task> _applyFilter(List<Task> tasks) {
    List<Task> filtered = List.from(tasks);

    if (_selectedFilter == TaskFilter.active) {
      filtered = filtered.where((task) => !task.isDone).toList();
    } else if (_selectedFilter == TaskFilter.done) {
      filtered = filtered.where((task) => task.isDone).toList();
    }

    final query = _searchText.trim().toLowerCase();

    if (query.isNotEmpty) {
      filtered = filtered.where((task) {
        final title = task.title.toLowerCase();
        final subject = task.subject.toLowerCase();
        final note = task.note.toLowerCase();

        return title.contains(query) ||
            subject.contains(query) ||
            note.contains(query);
      }).toList();
    }

    return filtered;
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Bez termínu';
    final date = timestamp.toDate();
    return '${date.day}.${date.month}.${date.year}';
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _priorityLabel(String priority) {
    switch (priority) {
      case 'high':
        return 'Vysoká';
      case 'medium':
        return 'Střední';
      case 'low':
        return 'Nízká';
      default:
        return priority;
    }
  }

  Future<void> _showTaskDialog({Task? task}) async {
    final titleController = TextEditingController(text: task?.title ?? '');
    final subjectController = TextEditingController(text: task?.subject ?? '');
    final noteController = TextEditingController(text: task?.note ?? '');

    String selectedPriority = task?.priority ?? 'medium';
    DateTime? selectedDueDate = task?.dueDate?.toDate();

    final isEditing = task != null;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'Upravit úkol' : 'Nový úkol'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Název úkolu',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: subjectController,
                      decoration: const InputDecoration(
                        labelText: 'Předmět',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Poznámka',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedPriority,
                      decoration: const InputDecoration(
                        labelText: 'Priorita',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'low',
                          child: Text('Nízká'),
                        ),
                        DropdownMenuItem(
                          value: 'medium',
                          child: Text('Střední'),
                        ),
                        DropdownMenuItem(
                          value: 'high',
                          child: Text('Vysoká'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedPriority = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedDueDate == null
                                ? 'Termín: nevybrán'
                                : 'Termín: ${selectedDueDate!.day}.${selectedDueDate!.month}.${selectedDueDate!.year}',
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.calendar_month),
                          onPressed: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: selectedDueDate ?? DateTime.now(),
                              firstDate: DateTime.now().subtract(
                                const Duration(days: 365),
                              ),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365 * 5),
                              ),
                            );

                            if (pickedDate != null) {
                              setDialogState(() {
                                selectedDueDate = pickedDate;
                              });
                            }
                          },
                        ),
                        if (selectedDueDate != null)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setDialogState(() {
                                selectedDueDate = null;
                              });
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Zrušit'),
                ),
                FilledButton(
                  onPressed: () async {
                    final title = titleController.text.trim();
                    final subject = subjectController.text.trim();
                    final note = noteController.text.trim();

                    if (title.isEmpty || subject.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Vyplň název úkolu a předmět.'),
                        ),
                      );
                      return;
                    }

                    try {
                      if (isEditing) {
                        await _firestoreService.updateTask(
                          id: task.id,
                          title: title,
                          subject: subject,
                          note: note,
                          priority: selectedPriority,
                          dueDate: selectedDueDate,
                        );
                      } else {
                        await _firestoreService.addTask(
                          title: title,
                          subject: subject,
                          note: note,
                          priority: selectedPriority,
                          dueDate: selectedDueDate,
                        );
                      }

                      if (mounted) {
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Chyba při ukládání: $e'),
                          ),
                        );
                      }
                    }
                  },
                  child: Text(isEditing ? 'Uložit' : 'Přidat'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteTask(Task task) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Smazat úkol?'),
        content: Text('Opravdu chceš smazat úkol "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Ne'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ano'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _firestoreService.deleteTask(task.id);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('School Task Planner'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTaskDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Přidat úkol'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getTasksStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Chyba při načítání dat:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          final tasks = docs.map((doc) => Task.fromFirestore(doc)).toList();
          final filteredTasks = _applyFilter(tasks);

          final totalCount = tasks.length;
          final activeCount = tasks.where((task) => !task.isDone).length;
          final doneCount = tasks.where((task) => task.isDone).length;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Vyhledat úkol',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchText.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchText = '';
                              });
                            },
                          )
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchText = value.trim();
                    });
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Celkem',
                        value: totalCount.toString(),
                        icon: Icons.list_alt,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        title: 'Aktivní',
                        value: activeCount.toString(),
                        icon: Icons.schedule,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        title: 'Hotové',
                        value: doneCount.toString(),
                        icon: Icons.check_circle_outline,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SegmentedButton<TaskFilter>(
                  segments: const [
                    ButtonSegment(
                      value: TaskFilter.all,
                      label: Text('Vše'),
                      icon: Icon(Icons.list),
                    ),
                    ButtonSegment(
                      value: TaskFilter.active,
                      label: Text('Aktivní'),
                      icon: Icon(Icons.pending_actions),
                    ),
                    ButtonSegment(
                      value: TaskFilter.done,
                      label: Text('Hotové'),
                      icon: Icon(Icons.check),
                    ),
                  ],
                  selected: {_selectedFilter},
                  onSelectionChanged: (newSelection) {
                    setState(() {
                      _selectedFilter = newSelection.first;
                    });
                  },
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: filteredTasks.isEmpty
                    ? const Center(
                        child: Text('Žádné úkoly k zobrazení'),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        itemCount: filteredTasks.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final task = filteredTasks[index];

                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: Checkbox(
                                value: task.isDone,
                                onChanged: (_) async {
                                  await _firestoreService.toggleTask(
                                    id: task.id,
                                    currentValue: task.isDone,
                                  );
                                },
                              ),
                              title: Text(
                                task.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  decoration: task.isDone
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Předmět: ${task.subject}'),
                                    if (task.note.isNotEmpty)
                                      Text('Poznámka: ${task.note}'),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Priorita: ${_priorityLabel(task.priority)}',
                                      style: TextStyle(
                                        color: _priorityColor(task.priority),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text('Termín: ${_formatDate(task.dueDate)}'),
                                  ],
                                ),
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showTaskDialog(task: task);
                                  } else if (value == 'delete') {
                                    _deleteTask(task);
                                  }
                                },
                                itemBuilder: (context) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Upravit'),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Smazat'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Icon(icon),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Text(title),
          ],
        ),
      ),
    );
  }
}