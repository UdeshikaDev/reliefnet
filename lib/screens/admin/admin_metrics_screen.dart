// lib/screens/admin/admin_metrics_screen.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/admin_metrics_model.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/common/app_error_widget.dart';

class AdminMetricsScreen extends StatefulWidget {
  const AdminMetricsScreen({super.key});

  @override
  State<AdminMetricsScreen> createState() => _AdminMetricsScreenState();
}

class _AdminMetricsScreenState extends State<AdminMetricsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AdminProvider>().loadMetrics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminProv = context.watch<AdminProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Metrics Dashboard',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Builder(builder: (_) {
        if (adminProv.isLoadingMetrics) {
          return const Center(
            child: CircularProgressIndicator(
                color: AppColors.primary, strokeWidth: 2),
          );
        }
        if (adminProv.error != null) {
          return Center(child: AppErrorBanner(message: adminProv.error!));
        }
        if (adminProv.metrics == null) {
          return const SizedBox.shrink();
        }

        final m = adminProv.metrics!;
        return _MetricsBody(metrics: m);
      }),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _MetricsBody extends StatelessWidget {
  final AdminMetrics metrics;
  const _MetricsBody({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Summary stat cards ─────────────────────────────────────────
          _SectionHeader('Summary'),
          const SizedBox(height: 10),
          Row(
            children: [
              _StatCard(
                  label: 'Total Requests',
                  value: '${metrics.totalRequests}',
                  color: AppColors.primary),
              const SizedBox(width: 10),
              _StatCard(
                  label: 'Parcels Delivered',
                  value: '${metrics.totalParcelsDistributed}',
                  color: AppColors.success),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _StatCard(
                  label: 'Active Centers',
                  value: '${metrics.activeCenters}',
                  color: AppColors.primary),
              const SizedBox(width: 10),
              _StatCard(
                  label: 'Approved Volunteers',
                  value: '${metrics.approvedVolunteers}',
                  color: AppColors.success),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _StatCard(
                  label: 'Pending Volunteers',
                  value: '${metrics.pendingVolunteers}',
                  color: AppColors.warning),
              const SizedBox(width: 10),
              _StatCard(
                  label: 'Expired Requests',
                  value: '${metrics.expiredRequests}',
                  color: AppColors.error),
            ],
          ),
          const SizedBox(height: 24),

          // ── Pie chart — request status breakdown ───────────────────────
          _SectionHeader('Request Status Breakdown'),
          const SizedBox(height: 12),
          _ChartCard(
            height: 220,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 36,
                sections: [
                  _pieSection(
                    value: metrics.completedRequests.toDouble(),
                    color: AppColors.success,
                    label: 'Done\n${metrics.completedRequests}',
                  ),
                  _pieSection(
                    value: metrics.pendingRequests.toDouble(),
                    color: AppColors.warning,
                    label: 'Pending\n${metrics.pendingRequests}',
                  ),
                  _pieSection(
                    value: metrics.expiredRequests.toDouble(),
                    color: AppColors.textSecondary,
                    label: 'Expired\n${metrics.expiredRequests}',
                  ),
                  _pieSection(
                    value: metrics.cancelledRequests.toDouble(),
                    color: AppColors.error,
                    label: 'Cancelled\n${metrics.cancelledRequests}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Pie legend
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _LegendDot('Completed', AppColors.success),
              _LegendDot('Pending', AppColors.warning),
              _LegendDot('Expired', AppColors.textSecondary),
              _LegendDot('Cancelled', AppColors.error),
            ],
          ),
          const SizedBox(height: 24),

          // ── Bar chart — requests per day ───────────────────────────────
          _SectionHeader('Requests — Last 7 Days'),
          const SizedBox(height: 12),
          _ChartCard(
            height: 200,
            child: BarChart(
              BarChartData(
                maxY: (metrics.requestsLast7Days
                            .map((d) => d.count)
                            .reduce((a, b) => a > b ? a : b) +
                        5)
                    .toDouble(),
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, _) {
                        final i = value.toInt();
                        if (i < 0 ||
                            i >= metrics.requestsLast7Days.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            metrics.requestsLast7Days[i].label,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.divider.withValues(alpha: 0.6),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: metrics.requestsLast7Days
                    .asMap()
                    .entries
                    .map(
                      (e) => BarChartGroupData(
                        x: e.key,
                        barRods: [
                          BarChartRodData(
                            toY: e.value.count.toDouble(),
                            color: AppColors.primary,
                            width: 20,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  PieChartSectionData _pieSection({
    required double value,
    required Color color,
    required String label,
  }) {
    return PieChartSectionData(
      value: value,
      color: color,
      title: value > 0 ? label : '',
      radius: 60,
      titleStyle: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final Widget child;
  final double height;

  const _ChartCard({required this.child, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _LegendDot extends StatelessWidget {
  final String label;
  final Color color;
  const _LegendDot(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}