import 'package:flutter/material.dart';

import '../../../core/theme/wicara_colors.dart';
import '../../review/domain/review_models.dart';
import '../../review/presentation/review_queue_page.dart';
import '../domain/teacher_student_models.dart';
import 'student_progress_page.dart';

class TeacherDashboardPage extends StatefulWidget {
  const TeacherDashboardPage({
    required this.repository,
    this.reviewRepository,
    this.onSignOut,
    super.key,
  });

  final TeacherStudentRepository repository;
  final ReviewRepository? reviewRepository;
  final Future<void> Function()? onSignOut;

  @override
  State<TeacherDashboardPage> createState() => _TeacherDashboardPageState();
}

class _TeacherDashboardPageState extends State<TeacherDashboardPage> {
  List<TeacherStudentConnection> _connections = const [];
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final connections = await widget.repository.fetchTeacherConnections();
      if (!mounted) return;
      setState(() => _connections = connections);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _invite() async {
    final controller = TextEditingController();
    final email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invite a student'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Student email',
            hintText: 'student@example.com',
          ),
          onSubmitted: (value) => Navigator.pop(context, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Send request'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (email == null || email.isEmpty || !mounted) return;

    setState(() => _sending = true);
    try {
      await widget.repository.inviteStudent(email);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request sent. Progress stays private until accepted.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _disconnect(TeacherStudentConnection connection) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove connection?'),
        content: Text(
          'You will no longer be able to view ${connection.studentName}’s progress.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.repository.disconnect(connection.id);
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  void _openReviewQueue() {
    final repository = widget.reviewRepository;
    if (repository == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReviewQueuePage(repository: repository),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accepted = _connections.where((item) => item.isAccepted).toList();
    final pending = _connections.where((item) => item.isPending).toList();
    return Scaffold(
      backgroundColor: WicaraColors.pageBackground,
      appBar: AppBar(
        title: const Text('Teacher dashboard'),
        backgroundColor: Colors.white,
        foregroundColor: WicaraColors.ink,
        actions: [
          if (widget.reviewRepository != null)
            IconButton(
              tooltip: 'AI review queue',
              onPressed: _openReviewQueue,
              icon: const Icon(Icons.rate_review_outlined),
            ),
          if (widget.onSignOut != null)
            IconButton(
              tooltip: 'Sign out',
              onPressed: widget.onSignOut,
              icon: const Icon(Icons.logout_rounded),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _sending ? null : _invite,
        icon: _sending
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.person_add_alt_1),
        label: const Text('Invite by email'),
      ),
      body: _body(accepted, pending),
    );
  }

  Widget _body(
    List<TeacherStudentConnection> accepted,
    List<TeacherStudentConnection> pending,
  ) {
    if (_loading && _connections.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _connections.isEmpty) {
      return _message(Icons.error_outline, 'Could not load students', _error!);
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
        children: [
          _summary(accepted.length, pending.length),
          const SizedBox(height: 20),
          const Text(
            'Connected students',
            style: TextStyle(
              color: WicaraColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          if (accepted.isEmpty)
            _emptyCard(
              'No connected students yet',
              'Invite a student by email. Their progress appears after they accept.',
            )
          else
            ...accepted.map(_studentCard),
          if (pending.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'Waiting for approval',
              style: TextStyle(
                color: WicaraColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            ...pending.map(_studentCard),
          ],
        ],
      ),
    );
  }

  Widget _summary(int connected, int pending) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [WicaraColors.primaryDeep, WicaraColors.secondaryDeep],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _summaryValue('$connected', 'Connected'),
          const SizedBox(width: 32),
          _summaryValue('$pending', 'Pending'),
        ],
      ),
    );
  }

  Widget _summaryValue(String value, String label) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    ),
  );

  Widget _studentCard(TeacherStudentConnection connection) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: WicaraColors.line),
      ),
      child: ListTile(
        onTap: connection.isAccepted
            ? () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => StudentProgressPage(
                    repository: widget.repository,
                    studentId: connection.studentId,
                  ),
                ),
              )
            : null,
        leading: CircleAvatar(
          backgroundColor: connection.isAccepted
              ? WicaraColors.primarySoft
              : WicaraColors.softMuted,
          child: Icon(
            connection.isAccepted ? Icons.school_outlined : Icons.schedule,
            color: WicaraColors.primaryDeep,
          ),
        ),
        title: Text(
          connection.studentName,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          connection.isAccepted
              ? (connection.studentEmail ?? 'Connected')
              : 'Request pending · ${connection.studentEmail ?? ''}',
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (_) => _disconnect(connection),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'remove', child: Text('Remove')),
          ],
        ),
      ),
    );
  }

  Widget _emptyCard(String title, String subtitle) =>
      _message(Icons.groups_outlined, title, subtitle);

  Widget _message(IconData icon, String title, String subtitle) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: WicaraColors.line),
    ),
    child: Column(
      children: [
        Icon(icon, size: 42, color: WicaraColors.softMuted),
        const SizedBox(height: 10),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 5),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: WicaraColors.muted),
        ),
      ],
    ),
  );
}
