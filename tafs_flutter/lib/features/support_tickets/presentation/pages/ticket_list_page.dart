import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/origination_options.dart';
import '../bloc/support_ticket_list_bloc.dart';
import '../bloc/support_ticket_list_event.dart';
import '../bloc/ticket_thread_cubit.dart';
import '../widgets/mcq_question_card.dart';
import 'ticket_thread_page.dart';
import '../bloc/support_ticket_list_state.dart';

class TicketListPage extends StatefulWidget {
  const TicketListPage({super.key});

  @override
  State<TicketListPage> createState() => _TicketListPageState();
}

class _TicketListPageState extends State<TicketListPage> {
  bool _showOpen = true;

  @override
  void initState() {
    super.initState();
    context.read<SupportTicketListBloc>().add(const SupportTicketListLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Queries'),
        backgroundColor: AppTheme.white,
        foregroundColor: AppTheme.navy,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TicketOriginationPage()),
          );
          if (mounted) {
            context.read<SupportTicketListBloc>().add(const SupportTicketListLoadRequested());
          }
        },
        label: const Text('Raise a new query'),
        icon: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Open'),
                  selected: _showOpen,
                  onSelected: (_) => setState(() => _showOpen = true),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('History'),
                  selected: !_showOpen,
                  onSelected: (_) => setState(() => _showOpen = false),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<SupportTicketListBloc, SupportTicketListState>(
              builder: (context, state) {
                if (state is SupportTicketListLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is SupportTicketListError) {
                  return Center(child: Text(state.message));
                }
                if (state is! SupportTicketListLoaded) {
                  return const SizedBox.shrink();
                }
                final tickets = _showOpen ? state.openTickets : state.closedTickets;
                if (tickets.isEmpty) {
                  return Center(
                    child: Text(_showOpen ? 'No open queries' : 'No closed queries yet'),
                  );
                }
                return ListView.builder(
                  itemCount: tickets.length,
                  itemBuilder: (context, index) {
                    final ticket = tickets[index];
                    return ListTile(
                      title: Text(ticket.subtopic ?? ticket.category.name),
                      subtitle: Text(
                        ticket.lastMessageSnippet ?? ticket.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: ticket.unreadByParent > 0
                          ? Text('${ticket.unreadByParent} new',
                              style: const TextStyle(color: Colors.red, fontSize: 10))
                          : null,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BlocProvider(
                              create: (_) => TicketThreadCubit(
                                repository: InjectionContainer.supportTicketRepository,
                              )..load(ticket.id),
                              child: TicketThreadPage(ticketId: ticket.id),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class TicketOriginationPage extends StatefulWidget {
  const TicketOriginationPage({super.key});

  @override
  State<TicketOriginationPage> createState() => _TicketOriginationPageState();
}

class _TicketOriginationPageState extends State<TicketOriginationPage> {
  int _step = 0;
  String? _category;
  int? _studentId;
  String? _childLabel;
  String? _subtopic;
  final _descriptionController = TextEditingController();
  OriginationOptions? _options;
  List<Map<String, dynamic>> _students = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = InjectionContainer.supportTicketRepository;
    final options = await repo.getOriginationOptions();
    final dio = InjectionContainer.dio;
    final studentsRes = await dio.get('/chat/students');
    final students = (studentsRes.data as List).cast<Map<String, dynamic>>();
    setState(() {
      _options = options;
      _students = students;
      _loading = false;
      // Pre-select sole child for Q2 skip — category (Q1) must still be answered first.
      if (students.length == 1) {
        _studentId = students.first['cc'] as int;
        _childLabel = _studentLabel(students.first);
      }
    });
  }

  String _studentLabel(Map<String, dynamic> s) {
    final name = s['full_name'] ?? '';
    final cls = s['classes']?['description'] ?? '';
    final campus = s['campuses']?['campus_name'] ?? '';
    return '$name — $cls, $campus';
  }

  void _onCategorySelected(String label) {
    final cat = _options!.categories.firstWhere((c) => c['label'] == label);
    setState(() {
      _category = cat['value'];
      _subtopic = null;
      if (_students.isEmpty) {
        _studentId = null;
        _childLabel = _category == 'FINANCIAL'
            ? _options!.financialFamilyLabel
            : _options!.generalNoChildLabel;
        _step = 2;
      } else if (_students.length == 1) {
        _studentId = _students.first['cc'] as int;
        _childLabel = _studentLabel(_students.first);
        _step = 2;
      } else {
        _step = 1;
      }
    });
  }

  void _onChildSelected(String label) {
    setState(() {
      _childLabel = label;
      _subtopic = null;
      if (label == _options!.generalNoChildLabel ||
          label == _options!.financialFamilyLabel) {
        _studentId = null;
      } else {
        final idx = _childOptions.indexOf(label);
        if (idx >= 0 && idx < _students.length) {
          _studentId = _students[idx]['cc'] as int;
        }
      }
      _step = 2;
    });
  }

  List<String> get _childOptions {
    if (_options == null || _category == null) return [];
    final labels = _students.map(_studentLabel).toList();
    if (_category == 'FINANCIAL') {
      labels.add(_options!.financialFamilyLabel);
    } else {
      labels.add(_options!.generalNoChildLabel);
    }
    return labels;
  }

  List<String> get _topicOptions {
    if (_options == null || _category == null) return [];
    if (_category == 'FINANCIAL') return _options!.topicsFinancial;
    if (_studentId == null) return _options!.topicsGeneralNoChild;
    return _options!.topicsGeneralWithChild;
  }

  Future<void> _submit() async {
    if (_category == null || _subtopic == null || _descriptionController.text.length < 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all steps (min 20 characters)')),
      );
      return;
    }
    final ticket = await InjectionContainer.supportTicketRepository.createTicket(
      category: _category!,
      studentId: _studentId,
      subtopic: _subtopic!,
      description: _descriptionController.text.trim(),
    );
    if (!mounted) return;
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TicketThreadPage(ticketId: ticket.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _options == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Raise a query')),
      body: ListView(
        children: [
          if (_step == 0)
            McqQuestionCard(
              question: 'What would you like to ask about?',
              options: _options!.categories.map((c) => c['label']!).toList(),
              selected: _category == 'GENERAL'
                  ? _options!.categories.first['label']
                  : _category == 'FINANCIAL'
                      ? _options!.categories.last['label']
                      : null,
              onSelected: _onCategorySelected,
            ),
          if (_step == 1)
            McqQuestionCard(
              question: 'Which child is this regarding?',
              options: _childOptions,
              selected: _childLabel,
              onSelected: _onChildSelected,
            ),
          if (_step == 2)
            _topicOptions.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Could not load topics. Please go back and choose a category first.',
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  )
                : McqQuestionCard(
              question: 'What is the topic?',
              options: _topicOptions,
              selected: _subtopic,
              onSelected: (t) => setState(() {
                _subtopic = t;
                _step = 3;
              }),
            ),
          if (_step == 3)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Please describe your question in your own words',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'At least 20 characters...',
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: _submit, child: const Text('Submit query')),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
