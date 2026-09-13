import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cncc_portal/domain/entities/type_entity.dart';
import 'package:cncc_portal/presentation/providers/admin_provider.dart';
import 'package:cncc_portal/presentation/providers/rooms_provider.dart';
import 'package:cncc_portal/presentation/providers/types_provider.dart';
import 'package:cncc_portal/presentation/providers/users_provider.dart';

// ── Status options ────────────────────────────────────────────────────────────

const _kStatuses = [
  'RAISED',
  'REPLIED',
  'ASSIGNED',
  'IN_PROGRESS',
  'REASSIGN_REQUESTED',
  'COMPLETED',
  'REJECTED',
];

const _kStatusLabels = {
  'RAISED': 'Raised',
  'REPLIED': 'Replied',
  'ASSIGNED': 'Assigned',
  'IN_PROGRESS': 'In Progress',
  'REASSIGN_REQUESTED': 'Reassign Requested',
  'COMPLETED': 'Completed',
  'REJECTED': 'Rejected',
};

// ── Month abbreviations ───────────────────────────────────────────────────────

const _kMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage> {
  // Current applied filters (drives the provider family key).
  DashboardFilters _filters = const DashboardFilters();

  // Draft filter state held by the filter panel before the user taps "Apply".
  final _idCtrl = TextEditingController();
  String? _draftStatus;
  String? _draftRoomNo;
  String? _draftMainType;
  String? _draftSubType;
  String? _draftRaisedBy;

  // Selected main-type id for sub-type filtering (local only).
  int? _selectedMainTypeId;

  @override
  void dispose() {
    _idCtrl.dispose();
    super.dispose();
  }

  void _applyFilters() {
    setState(() {
      _filters = DashboardFilters(
        idPrefix: _idCtrl.text.trim().isEmpty ? null : _idCtrl.text.trim(),
        status: _draftStatus,
        roomNo: _draftRoomNo,
        mainType: _draftMainType,
        subType: _draftSubType,
        raisedBy: _draftRaisedBy,
      );
    });
  }

  void _clearFilters() {
    setState(() {
      _idCtrl.clear();
      _draftStatus = null;
      _draftRoomNo = null;
      _draftMainType = null;
      _draftSubType = null;
      _draftRaisedBy = null;
      _selectedMainTypeId = null;
      _filters = const DashboardFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final statsAsync = ref.watch(adminDashboardProvider(_filters));

    // Side-load dropdown data.
    final roomsAsync = ref.watch(roomsProvider);
    final mainTypesAsync = ref.watch(mainTypesProvider);
    final subTypesAsync = _selectedMainTypeId != null
        ? ref.watch(subTypesProvider(_selectedMainTypeId!))
        : const AsyncData<List<SubType>>([]);
    final usersState = ref.watch(usersProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────────────
              Row(
                children: [
                  Icon(Icons.bar_chart_rounded, color: cs.primary, size: 26),
                  const SizedBox(width: 10),
                  Text(
                    'Ticket Statistics',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const Spacer(),
                  if (!_filters.isEmpty)
                    TextButton.icon(
                      onPressed: _clearFilters,
                      icon: const Icon(Icons.clear_rounded, size: 16),
                      label: const Text('Clear filters'),
                    ),
                ],
              ),

              const SizedBox(height: 14),

              // ── Filter card ───────────────────────────────────────────────
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Filters',
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(height: 12),

                      // Row 1: ID prefix + Status
                      _FilterRow(children: [
                        _FilterField(
                          label: 'Request ID (first 8 chars)',
                          child: TextField(
                            controller: _idCtrl,
                            maxLength: 8,
                            decoration: _inputDec(
                                'e.g. a1b2c3d4', cs,
                                counter: false),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        _FilterField(
                          label: 'Status',
                          child: _DropdownFilter<String>(
                            value: _draftStatus,
                            hint: 'Any status',
                            items: _kStatuses
                                .map((s) => DropdownMenuItem(
                                      value: s,
                                      child:
                                          Text(_kStatusLabels[s] ?? s),
                                    ))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _draftStatus = v),
                          ),
                        ),
                      ]),

                      const SizedBox(height: 10),

                      // Row 2: Room + Main type
                      _FilterRow(children: [
                        _FilterField(
                          label: 'Room',
                          child: roomsAsync.when(
                            loading: () => _loadingDropdown(cs),
                            error: (_, __) => _errorDropdown(cs),
                            data: (rooms) => _DropdownFilter<String>(
                              value: _draftRoomNo,
                              hint: 'Any room',
                              items: rooms
                                  .map((r) => DropdownMenuItem(
                                        value: r.roomNo,
                                        child: Text(r.roomNo),
                                      ))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _draftRoomNo = v),
                            ),
                          ),
                        ),
                        _FilterField(
                          label: 'Main Type',
                          child: mainTypesAsync.when(
                            loading: () => _loadingDropdown(cs),
                            error: (_, __) => _errorDropdown(cs),
                            data: (types) => _DropdownFilter<String>(
                              value: _draftMainType,
                              hint: 'Any type',
                              items: types
                                  .map((t) => DropdownMenuItem(
                                        value: t.name,
                                        child: Text(t.name),
                                      ))
                                  .toList(),
                              onChanged: (v) {
                                // Also look up the id so we can load sub-types.
                                final matched = mainTypesAsync.valueOrNull
                                    ?.firstWhere((t) => t.name == v,
                                        orElse: () =>
                                            MainType(id: -1, name: ''));
                                setState(() {
                                  _draftMainType = v;
                                  _draftSubType = null;
                                  _selectedMainTypeId =
                                      (matched?.id != null &&
                                              matched!.id > 0)
                                          ? matched.id
                                          : null;
                                });
                              },
                            ),
                          ),
                        ),
                      ]),

                      const SizedBox(height: 10),

                      // Row 3: Sub type + Raised by
                      _FilterRow(children: [
                        _FilterField(
                          label: 'Sub Type',
                          child: _selectedMainTypeId == null
                              ? const _DropdownFilter<String>(
                                  value: null,
                                  hint: 'Select main type first',
                                  items: [],
                                  onChanged: null,
                                )
                              : subTypesAsync.when(
                                  loading: () => _loadingDropdown(cs),
                                  error: (_, __) => _errorDropdown(cs),
                                  data: (subs) => _DropdownFilter<String>(
                                    value: _draftSubType,
                                    hint: 'Any sub type',
                                    items: subs
                                        .map((s) => DropdownMenuItem(
                                              value: s.name,
                                              child: Text(s.name),
                                            ))
                                        .toList(),
                                    onChanged: (v) =>
                                        setState(() => _draftSubType = v),
                                  ),
                                ),
                        ),
                        _FilterField(
                          label: 'Raised By',
                          child: usersState.isLoading
                              ? _loadingDropdown(cs)
                              : _DropdownFilter<String>(
                                  value: _draftRaisedBy,
                                  hint: 'Any user',
                                  items: usersState.users
                                      .map((u) => DropdownMenuItem(
                                            value: u.id,
                                            child: Text(
                                              u.name != null &&
                                                      u.name!.isNotEmpty
                                                  ? '${u.name} · ${u.email}'
                                                  : u.email,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                            ),
                                          ))
                                      .toList(),
                                  onChanged: (v) =>
                                      setState(() => _draftRaisedBy = v),
                                ),
                        ),
                      ]),

                      const SizedBox(height: 14),

                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _applyFilters,
                          icon: const Icon(Icons.tune_rounded, size: 18),
                          label: const Text('Apply Filters'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Statistics content ────────────────────────────────────────
              statsAsync.when(
                loading: () => const _StatsLoadingShimmer(),
                error: (e, _) => _StatsError(
                  error: e.toString(),
                  onRetry: () => ref.invalidate(
                    adminDashboardProvider(_filters),
                  ),
                ),
                data: (stats) => _StatsContent(stats: stats),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  InputDecoration _inputDec(String hint, ColorScheme cs,
      {bool counter = true}) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.4)),
      filled: true,
      fillColor: cs.surfaceContainerLow,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      counterText: counter ? null : '',
    );
  }

  Widget _loadingDropdown(ColorScheme cs) => Container(
        height: 44,
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: cs.onSurface.withValues(alpha: 0.4)),
        ),
      );

  Widget _errorDropdown(ColorScheme cs) => Container(
        height: 44,
        decoration: BoxDecoration(
          color: cs.errorContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text('Failed to load',
            style:
                TextStyle(fontSize: 12, color: cs.error)),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter layout helpers
// ─────────────────────────────────────────────────────────────────────────────

class _FilterRow extends StatelessWidget {
  final List<Widget> children;
  const _FilterRow({required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, box) {
      final narrow = box.maxWidth < 500;
      if (narrow) {
        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children
                .expand((w) => [w, const SizedBox(height: 10)])
                .toList()
              ..removeLast());
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children
            .expand((w) => [Expanded(child: w), const SizedBox(width: 12)])
            .toList()
          ..removeLast(),
      );
    });
  }
}

class _FilterField extends StatelessWidget {
  final String label;
  final Widget child;
  const _FilterField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withValues(alpha: 0.55))),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}

class _DropdownFilter<T> extends StatelessWidget {
  final T? value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;

  const _DropdownFilter({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: cs.surfaceContainerLow,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      hint: Text(hint,
          style: TextStyle(
              fontSize: 13,
              color: cs.onSurface.withValues(alpha: 0.4))),
      items: [
        DropdownMenuItem<T>(value: null, child: Text(hint)),
        ...items,
      ],
      onChanged: onChanged,
      style: TextStyle(fontSize: 13, color: cs.onSurface),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading shimmer
// ─────────────────────────────────────────────────────────────────────────────

class _StatsLoadingShimmer extends StatelessWidget {
  const _StatsLoadingShimmer();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _ChartPlaceholder(label: 'Daily Requests — This Month'),
        SizedBox(height: 16),
        _ChartPlaceholder(label: 'Monthly Requests — This Year'),
        SizedBox(height: 16),
        _ChartPlaceholder(label: 'Requests Per Year'),
      ],
    );
  }
}

class _ChartPlaceholder extends StatelessWidget {
  final String label;
  const _ChartPlaceholder({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error state
// ─────────────────────────────────────────────────────────────────────────────

class _StatsError extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _StatsError({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 42, color: cs.error),
            const SizedBox(height: 12),
            Text('Failed to load statistics',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(error,
                style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.55)),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main stats content — three sections
// ─────────────────────────────────────────────────────────────────────────────

class _StatsContent extends StatelessWidget {
  final DashboardStats stats;
  const _StatsContent({required this.stats});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Daily — current month
        _ChartCard(
          title: 'Daily Requests',
          subtitle:
              '${_kMonths[now.month - 1]} ${now.year}',
          icon: Icons.today_rounded,
          child: stats.daily.isEmpty || stats.daily.every((p) => p.count == 0)
              ? const _EmptyChart()
              : _DailyChart(points: stats.daily),
        ),

        const SizedBox(height: 16),

        // 2. Monthly — current year
        _ChartCard(
          title: 'Monthly Requests',
          subtitle: '${now.year}',
          icon: Icons.calendar_month_rounded,
          child: stats.monthly.isEmpty ||
                  stats.monthly.every((p) => p.count == 0)
              ? const _EmptyChart()
              : _MonthlyChart(points: stats.monthly),
        ),

        const SizedBox(height: 16),

        // 3. Yearly — all time (scrollable list)
        _ChartCard(
          title: 'Requests Per Year',
          subtitle: 'All time',
          icon: Icons.history_rounded,
          child: stats.yearly.isEmpty
              ? const _EmptyChart()
              : _YearlyList(points: stats.yearly),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared card wrapper
// ─────────────────────────────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.45))),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 120,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_rounded,
                size: 32, color: cs.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 8),
            Text('No data',
                style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurface.withValues(alpha: 0.4))),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Daily line chart
// ─────────────────────────────────────────────────────────────────────────────

class _DailyChart extends StatelessWidget {
  final List<StatPoint> points;
  const _DailyChart({required this.points});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final maxY = (points.map((p) => p.count).reduce((a, b) => a > b ? a : b))
            .toDouble() +
        1;

    final spots = points.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.count.toDouble());
    }).toList();

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY > 4 ? (maxY / 4).ceilToDouble() : 1,
            getDrawingHorizontalLine: (v) => FlLine(
              color: cs.onSurface.withValues(alpha: 0.07),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: maxY > 4 ? (maxY / 4).ceilToDouble() : 1,
                getTitlesWidget: (v, _) => Text(
                  v.toInt().toString(),
                  style: TextStyle(
                      fontSize: 10,
                      color: cs.onSurface.withValues(alpha: 0.5)),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: (points.length / 6).ceilToDouble(),
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= points.length) {
                    return const SizedBox.shrink();
                  }
                  // Show day-of-month from "YYYY-MM-DD"
                  final day = points[idx].label.split('-').last;
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(day,
                        style: TextStyle(
                            fontSize: 10,
                            color: cs.onSurface.withValues(alpha: 0.5))),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: cs.primary,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: cs.primary.withValues(alpha: 0.08),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => cs.surfaceContainerHighest,
              getTooltipItems: (spots) => spots.map((s) {
                final idx = s.x.toInt();
                final label = idx >= 0 && idx < points.length
                    ? points[idx].label
                    : '';
                return LineTooltipItem(
                  '$label\n${s.y.toInt()} requests',
                  TextStyle(
                      fontSize: 11,
                      color: cs.onSurface,
                      fontWeight: FontWeight.w600),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Monthly line chart
// ─────────────────────────────────────────────────────────────────────────────

class _MonthlyChart extends StatelessWidget {
  final List<StatPoint> points;
  const _MonthlyChart({required this.points});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final maxY = (points.map((p) => p.count).reduce((a, b) => a > b ? a : b))
            .toDouble() +
        1;

    final spots = points.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.count.toDouble());
    }).toList();

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY > 4 ? (maxY / 4).ceilToDouble() : 1,
            getDrawingHorizontalLine: (v) => FlLine(
              color: cs.onSurface.withValues(alpha: 0.07),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: maxY > 4 ? (maxY / 4).ceilToDouble() : 1,
                getTitlesWidget: (v, _) => Text(
                  v.toInt().toString(),
                  style: TextStyle(
                      fontSize: 10,
                      color: cs.onSurface.withValues(alpha: 0.5)),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= _kMonths.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(_kMonths[idx],
                        style: TextStyle(
                            fontSize: 10,
                            color: cs.onSurface.withValues(alpha: 0.5))),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: const Color(0xFFA6E3A1),
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFFA6E3A1).withValues(alpha: 0.08),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => cs.surfaceContainerHighest,
              getTooltipItems: (spots) => spots.map((s) {
                final idx = s.x.toInt();
                final label = idx >= 0 && idx < points.length
                    ? points[idx].label
                    : '';
                return LineTooltipItem(
                  '$label\n${s.y.toInt()} requests',
                  TextStyle(
                      fontSize: 11,
                      color: cs.onSurface,
                      fontWeight: FontWeight.w600),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Yearly scrollable list
// ─────────────────────────────────────────────────────────────────────────────

class _YearlyList extends StatelessWidget {
  final List<StatPoint> points;
  const _YearlyList({required this.points});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Find max count for relative bar width.
    final maxCount = points
        .map((p) => p.count)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return Column(
      children: points.map((p) {
        final fraction = maxCount > 0 ? p.count / maxCount : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              // Year label
              SizedBox(
                width: 44,
                child: Text(
                  p.label,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 10),
              // Proportional bar
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: fraction,
                    minHeight: 18,
                    backgroundColor:
                        cs.onSurface.withValues(alpha: 0.07),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(cs.primary),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Count label
              SizedBox(
                width: 36,
                child: Text(
                  '${p.count}',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface.withValues(alpha: 0.75)),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
