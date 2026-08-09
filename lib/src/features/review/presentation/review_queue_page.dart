import 'package:flutter/material.dart';

import '../../../core/localization/wicara_copy_scope.dart';
import '../../../core/theme/wicara_colors.dart';
import '../../onboarding/domain/onboarding_copy.dart';
import '../application/review_controller.dart';
import '../domain/review_models.dart';
import 'review_item_detail_page.dart';
import 'review_metrics_page.dart';
import 'review_widgets.dart';

/// Teacher review queue — the "show when teachers need to review" surface.
class ReviewQueuePage extends StatefulWidget {
  const ReviewQueuePage({required this.repository, super.key});

  final ReviewRepository repository;

  @override
  State<ReviewQueuePage> createState() => _ReviewQueuePageState();
}

class _ReviewQueuePageState extends State<ReviewQueuePage> {
  late final ReviewController _controller;

  static const _statuses = ['open', 'all', 'corrected', 'rejected', 'approved'];
  static const _types = [null, 'question', 'diagnosis', 'evaluation'];
  static const _triggers = [
    null,
    'low_confidence',
    'risk_signal',
    'sampled',
    'learner_flag',
  ];

  @override
  void initState() {
    super.initState();
    _controller = ReviewController(repository: widget.repository);
    _controller.loadQueue();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openDetail(ReviewItem item) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReviewItemDetailPage(
          repository: widget.repository,
          itemId: item.id,
        ),
      ),
    );
    // The item may have been resolved while in detail; refresh the queue.
    await _controller.loadQueue();
  }

  void _openMetrics() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReviewMetricsPage(repository: widget.repository),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final copy = WicaraCopyScope.of(context);
    return Scaffold(
      backgroundColor: WicaraColors.pageBackground,
      appBar: AppBar(
        title: Text(copy.teacherReviewLabel),
        backgroundColor: Colors.white,
        foregroundColor: WicaraColors.ink,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: copy.correctionMetricsLabel,
            icon: const Icon(Icons.insights_outlined),
            onPressed: _openMetrics,
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Column(
            children: [
              _filters(copy),
              Expanded(child: _list(copy)),
            ],
          );
        },
      ),
    );
  }

  Widget _filters(OnboardingCopy copy) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _filterRow(
            copy,
            copy.statusLabel,
            _statuses,
            _controller.statusFilter,
            (v) => _controller.setStatusFilter(v ?? 'open'),
            allowNull: false,
          ),
          _filterRow(
            copy,
            copy.typeLabel,
            _types,
            _controller.typeFilter,
            _controller.setTypeFilter,
          ),
          _filterRow(
            copy,
            copy.triggerLabel,
            _triggers,
            _controller.triggerFilter,
            _controller.setTriggerFilter,
          ),
        ],
      ),
    );
  }

  Widget _filterRow(
    OnboardingCopy copy,
    String label,
    List<String?> values,
    String? selected,
    void Function(String?) onSelected, {
    bool allowNull = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                label,
                style: const TextStyle(
                  color: WicaraColors.muted,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: values.map((value) {
                final isSelected = selected == value;
                final text = value == null
                    ? copy.allFilterLabel
                    : copy.reviewArtifactLabel(value);
                return ChoiceChip(
                  label: Text(text),
                  selected: isSelected,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : WicaraColors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  selectedColor: WicaraColors.primaryDeep,
                  backgroundColor: WicaraColors.primarySoft,
                  side: BorderSide.none,
                  onSelected: (_) {
                    if (!allowNull && value == null) return;
                    onSelected(value);
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _list(OnboardingCopy copy) {
    if (_controller.isLoadingQueue && _controller.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_controller.queueError != null && _controller.items.isEmpty) {
      return _message(
        copy: copy,
        icon: Icons.error_outline,
        title: copy.couldNotLoadQueueLabel,
        subtitle: _controller.queueError!,
        onRetry: _controller.loadQueue,
      );
    }
    if (_controller.items.isEmpty) {
      return _message(
        copy: copy,
        icon: Icons.verified_outlined,
        title: copy.nothingToReviewLabel,
        subtitle: copy.noAiOutputsMatchFiltersLabel,
        onRetry: _controller.loadQueue,
      );
    }
    return RefreshIndicator(
      onRefresh: _controller.loadQueue,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        itemCount: _controller.items.length,
        itemBuilder: (context, index) =>
            _itemCard(copy, _controller.items[index]),
      ),
    );
  }

  Widget _itemCard(OnboardingCopy copy, ReviewItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: WicaraColors.line),
      ),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openDetail(item),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ArtifactTypeBadge(type: item.artifactType),
                  const SizedBox(width: 8),
                  StatusBadge(status: item.status),
                  const Spacer(),
                  if (item.confidence != null)
                    ConfidenceChip(confidence: item.confidence!),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item.summary.isEmpty ? copy.noSummaryLabel : item.summary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: WicaraColors.ink,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final reason in item.triggerReasons)
                    TriggerBadge(trigger: reason),
                  PriorityChip(priority: item.priority),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _message({
    required OnboardingCopy copy,
    required IconData icon,
    required String title,
    required String subtitle,
    required Future<void> Function() onRetry,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: WicaraColors.softMuted),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: WicaraColors.ink,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: WicaraColors.muted),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => onRetry(),
              icon: const Icon(Icons.refresh),
              label: Text(copy.refreshLabel),
            ),
          ],
        ),
      ),
    );
  }
}
