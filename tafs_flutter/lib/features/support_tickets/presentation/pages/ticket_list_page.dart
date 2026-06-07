import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/origination_options.dart';
import '../bloc/support_ticket_list_bloc.dart';
import '../bloc/support_ticket_list_event.dart';
import '../bloc/support_ticket_list_state.dart';
import '../widgets/mcq_question_card.dart';
import '../widgets/ticket_status_badge.dart';
import 'ticket_thread_page.dart';

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

  String _categoryLabel(String name) {
    if (name == 'financial') return 'Financial';
    if (name == 'general') return 'General';
    return name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('My Queries'),
        backgroundColor: AppTheme.white,
        foregroundColor: AppTheme.navy,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.navy,
        foregroundColor: AppTheme.white,
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
                  selectedColor: AppTheme.navy,
                  labelStyle: TextStyle(
                    color: _showOpen ? AppTheme.white : AppTheme.navy,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (_) => setState(() => _showOpen = true),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('History'),
                  selected: !_showOpen,
                  selectedColor: AppTheme.navy,
                  labelStyle: TextStyle(
                    color: !_showOpen ? AppTheme.white : AppTheme.navy,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (_) => setState(() => _showOpen = false),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<SupportTicketListBloc, SupportTicketListState>(
              builder: (context, state) {
                if (state is SupportTicketListLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.navy),
                  );
                }
                if (state is SupportTicketListError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Could not load your queries.',
                            style: TextStyle(color: Theme.of(context).colorScheme.error),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => context
                                .read<SupportTicketListBloc>()
                                .add(const SupportTicketListLoadRequested()),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (state is! SupportTicketListLoaded) {
                  return const SizedBox.shrink();
                }
                final tickets = _showOpen ? state.openTickets : state.closedTickets;
                if (tickets.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.support_agent_outlined, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text(
                            _showOpen ? 'No open queries' : 'No closed queries yet',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          if (_showOpen)
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text(
                                'Tap the button below to raise a new query.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppTheme.blue300, fontSize: 13),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: tickets.length,
                  itemBuilder: (context, index) {
                    final ticket = tickets[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Text(
                          ticket.subtopic ?? _categoryLabel(ticket.category.name),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            ticket.lastMessageSnippet ?? ticket.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (ticket.unreadByParent > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${ticket.unreadByParent}',
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            const SizedBox(width: 8),
                            TicketStatusBadge(status: ticket.status),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TicketThreadPage(ticketId: ticket.id),
                            ),
                          ).then((_) {
                            if (context.mounted) {
                              context.read<SupportTicketListBloc>().add(
                                    const SupportTicketListLoadRequested(),
                                  );
                            }
                          });
                        },
                      ),
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
  bool _submitting = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final repo = InjectionContainer.supportTicketRepository;
      final options = await repo.getOriginationOptions();
      final dio = InjectionContainer.dio;
      final studentsRes = await dio.get('/chat/students');
      final students = (studentsRes.data as List).cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() {
        _options = options;
        _students = students;
        _loading = false;
        if (students.length == 1) {
          _studentId = students.first['cc'] as int;
          _childLabel = _studentLabel(students.first);
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = 'Could not load query options. Please try again.';
      });
    }
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
    setState(() => _submitting = true);
    try {
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
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not submit your query. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Raise a query'),
          backgroundColor: AppTheme.white,
          foregroundColor: AppTheme.navy,
        ),
        body: const Center(child: CircularProgressIndicator(color: AppTheme.navy)),
      );
    }

    if (_loadError != null || _options == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Raise a query'),
          backgroundColor: AppTheme.white,
          foregroundColor: AppTheme.navy,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_loadError ?? 'Something went wrong', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _load, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Raise a query'),
        backgroundColor: AppTheme.white,
        foregroundColor: AppTheme.navy,
      ),
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
                  const Text(
                    'Please describe your question in your own words',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppTheme.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      hintText: 'At least 20 characters...',
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.navy,
                      foregroundColor: AppTheme.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.white),
                          )
                        : const Text('Submit query'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
