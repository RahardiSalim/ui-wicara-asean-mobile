import 'package:flutter/material.dart';

import '../../../core/theme/wicara_colors.dart';
import '../domain/teacher_student_models.dart';

class StudentTeacherConnectionsPage extends StatefulWidget {
  const StudentTeacherConnectionsPage({required this.repository, super.key});

  final TeacherStudentRepository repository;

  @override
  State<StudentTeacherConnectionsPage> createState() =>
      _StudentTeacherConnectionsPageState();
}

class _StudentTeacherConnectionsPageState
    extends State<StudentTeacherConnectionsPage> {
  List<TeacherStudentConnection> _connections = const [];
  bool _loading = true;
  String? _error;
  String? _busyId;

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
      final items = await widget.repository.fetchStudentConnections();
      if (!mounted) return;
      setState(() => _connections = items);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _respond(
    TeacherStudentConnection connection, {
    required bool accept,
  }) async {
    setState(() => _busyId = connection.id);
    try {
      if (accept) {
        await widget.repository.acceptInvitation(connection.id);
      } else {
        await widget.repository.rejectInvitation(connection.id);
      }
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _disconnect(TeacherStudentConnection connection) async {
    setState(() => _busyId = connection.id);
    try {
      await widget.repository.disconnect(connection.id);
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WicaraColors.pageBackground,
      appBar: AppBar(
        title: const Text('My teachers'),
        backgroundColor: Colors.white,
        foregroundColor: WicaraColors.ink,
      ),
      body: _body(),
    );
  }

  Widget _body() {
    if (_loading && _connections.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _connections.isEmpty) {
      return _message(
        Icons.error_outline,
        'Could not load teacher requests',
        _error!,
      );
    }
    final pending = _connections.where((item) => item.isPending).toList();
    final connected = _connections.where((item) => item.isAccepted).toList();
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: WicaraColors.primarySoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.privacy_tip_outlined),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Teachers can only see your learning progress after you accept their request.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (pending.isNotEmpty) ...[
            const Text(
              'Requests',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            ...pending.map(_requestCard),
            const SizedBox(height: 20),
          ],
          const Text(
            'Connected teachers',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          if (connected.isEmpty)
            _message(
              Icons.person_search_outlined,
              'No connected teachers',
              pending.isEmpty
                  ? 'A teacher can send a request using your account email.'
                  : 'Review the request above to connect.',
            )
          else
            ...connected.map(_connectedCard),
        ],
      ),
    );
  }

  Widget _requestCard(TeacherStudentConnection connection) {
    final busy = _busyId == connection.id;
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: WicaraColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              connection.teacherName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            Text(
              connection.teacherEmail ?? '',
              style: const TextStyle(color: WicaraColors.muted),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: busy
                      ? null
                      : () => _respond(connection, accept: false),
                  child: const Text('Reject'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: busy
                      ? null
                      : () => _respond(connection, accept: true),
                  icon: busy
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: const Text('Accept'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _connectedCard(TeacherStudentConnection connection) => Card(
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: WicaraColors.line),
    ),
    child: ListTile(
      leading: const CircleAvatar(child: Icon(Icons.school_outlined)),
      title: Text(
        connection.teacherName,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(connection.teacherEmail ?? 'Connected'),
      trailing: TextButton(
        onPressed: _busyId == connection.id
            ? null
            : () => _disconnect(connection),
        child: const Text('Remove'),
      ),
    ),
  );

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
