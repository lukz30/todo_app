import 'package:flutter/material.dart';

void main() => runApp(const TodoApp());

class Task {
  Task({required this.title, this.important = false, this.done = false});

  final String title;
  final bool important;
  bool done; // false = da fare, true = completata
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'To-do list',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const TaskListScreen(),
    );
  }
}

/// Schermata elenco (S2, S3, S4): possiede lo stato della lista.
class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final List<Task> _tasks = [];

  int get _completedCount => _tasks.where((t) => t.done).length;

  // S1: apre la schermata di creazione e attende il risultato.
  // Se l'utente torna indietro senza confermare, il risultato è null
  // e non succede nulla (nessuna attività, nessun messaggio).
  Future<void> _openAddScreen() async {
    final Task? newTask = await Navigator.push<Task>(
      context,
      MaterialPageRoute(builder: (_) => const AddTaskScreen()),
    );
    if (newTask == null || !mounted) return;

    setState(() => _tasks.add(newTask));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Attività aggiunta')));
  }

  // S3: cambia lo stato e aggiorna subito la UI (e il conteggio).
  void _toggle(Task task) {
    setState(() => task.done = !task.done);
  }

  // S4: chiede conferma prima di eliminare.
  Future<void> _confirmDelete(Task task) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminare l\'attività?'),
        content: Text('«${task.title}» verrà rimossa dall\'elenco.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() => _tasks.remove(task));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Le mie attività')),
      body: _tasks.isEmpty ? _buildEmptyState() : _buildList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddScreen,
        icon: const Icon(Icons.add),
        label: const Text('Nuova attività'),
      ),
    );
  }

  // S2, variante: nessuna attività.
  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Nessuna attività.\nTocca "Nuova attività" per aggiungerne una.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Completate: $_completedCount su ${_tasks.length}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            itemCount: _tasks.length,
            itemBuilder: (context, index) {
              final task = _tasks[index];
              return TaskTile(
                task: task,
                onToggle: () => _toggle(task),
                onDelete: () => _confirmDelete(task),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Widget che mostra una singola attività con titolo, stato e importanza ben distinguibili.
class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onDelete,
  });

  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onToggle,
      leading: Checkbox(value: task.done, onChanged: (_) => onToggle()),
      title: Text(
        task.title,
        style: TextStyle(
          decoration: task.done ? TextDecoration.lineThrough : null,
          color: task.done ? Colors.grey : null,
          fontWeight: task.important ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Row(
        children: [
          Text(task.done ? 'Completata' : 'Da fare'),
          if (task.important) ...[
            const SizedBox(width: 12),
            const Icon(Icons.star, size: 16, color: Colors.amber),
            const SizedBox(width: 2),
            const Text('Importante'),
          ],
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        tooltip: 'Elimina',
        onPressed: onDelete,
      ),
    );
  }
}

/// Schermata di creazione (S1).
class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _important = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _controller.text.trim();
    if (title.isEmpty) {
      // Variante: titolo mancante -> errore, nessuna attività creata.
      setState(() => _error = 'Il titolo è obbligatorio');
      return;
    }
    Navigator.pop(context, Task(title: title, important: _important));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuova attività')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              // L'errore scompare appena il titolo viene corretto.
              onChanged: (value) {
                if (_error != null && value.trim().isNotEmpty) {
                  setState(() => _error = null);
                }
              },
              decoration: InputDecoration(
                labelText: 'Titolo',
                border: const OutlineInputBorder(),
                errorText: _error,
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Importante'),
              value: _important,
              onChanged: (v) => setState(() => _important = v),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                child: const Text('Aggiungi'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}