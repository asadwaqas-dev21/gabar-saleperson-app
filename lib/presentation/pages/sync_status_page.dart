import 'package:flutter/material.dart';
import 'package:salesperson_app/core/constants/app_colors.dart';
import 'package:salesperson_app/presentation/widgets/app_button.dart';
import 'package:salesperson_app/data/repositories/data_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salesperson_app/core/sync/sync_manager.dart';

class SyncStatusPage extends StatefulWidget {
  const SyncStatusPage({super.key});

  @override
  State<SyncStatusPage> createState() => _SyncStatusPageState();
}

class _SyncStatusPageState extends State<SyncStatusPage> {
  bool _isSyncing = false;
  int _pendingCount = 0;
  int _failedCount = 0;
  int _conflictCount = 0;
  String? _lastSyncAt;
  List<Map<String, dynamic>> _queue = [];

  @override
  void initState() {
    super.initState();
    _loadQueue();
  }

  Future<void> _loadQueue() async {
    final repo = context.read<DataRepository>();
    final queue = await repo.localDataSource.getSyncQueue();
    final lastSyncAt = await repo.localDataSource.getMeta('last_sync_at');

    if (!mounted) return;
    
    setState(() {
      _queue = queue;
      _pendingCount = _queue.where((e) => e['status'] == 'pending_sync').length;
      _failedCount = _queue.where((e) => e['status'] == 'failed').length;
      _conflictCount = _queue.where((e) => e['status'] == 'conflict').length;
      _lastSyncAt = lastSyncAt;
    });
  }

  Future<void> _performSync() async {
    if (!mounted) return;
    setState(() => _isSyncing = true);
    try {
      final syncManager = context.read<SyncManager>();
      await syncManager.syncNow();
    } finally {
      if (mounted) {
        await _loadQueue();
      }
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // App Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Offline Queue',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.muted,
                      ),
                    ),
                    Text(
                      'Sync Status',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.brandLight,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.brandBorder),
                  ),
                  child: const Text(
                    'Online',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppColors.brand,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  // Main Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(16, 24, 40, 0.04),
                          offset: Offset(0, 1),
                          blurRadius: 2,
                        ),
                        BoxShadow(
                          color: Color.fromRGBO(16, 24, 40, 0.06),
                          offset: Offset(0, 8),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'LAST SYNC',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFCBD5E1), // slate-300
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isSyncing
                              ? 'Syncing now...'
                              : _lastSyncAt == null
                                  ? 'Never synced'
                                  : _formatLastSync(_lastSyncAt!),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: AppColors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$_pendingCount pending - $_failedCount failed - $_conflictCount conflict',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFCBD5E1),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Metrics Grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard('Pending', '$_pendingCount', AppColors.warning),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard('Failed', '$_failedCount', AppColors.danger),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard('Conflict', '$_conflictCount', AppColors.warning),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  const Text(
                    'Sync Queue',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  if (_queue.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: Text("All caught up! No pending data.")),
                    )
                  else
                    ..._queue.map((item) {
                      Color bg = AppColors.warningLight;
                      Color txt = AppColors.warning;
                      Color border = AppColors.warningBorder;
                      if (item['status'] == 'failed') {
                        bg = AppColors.dangerLight;
                        txt = AppColors.danger;
                        border = AppColors.dangerBorder;
                      } else if (item['status'] == 'conflict') {
                        bg = AppColors.warningLight;
                        txt = AppColors.warning;
                        border = AppColors.warningBorder;
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: _buildQueueCard(
                          item['type'],
                          _queueSubtitle(item),
                          item['status'],
                          bg,
                          txt,
                          border,
                        ),
                      );
                    }),
                  
                  const SizedBox(height: 16),
                  
                  AppButton(
                    text: _isSyncing ? 'Syncing...' : 'Sync Now', 
                    isFullWidth: true, 
                    onPressed: _isSyncing ? () {} : _performSync,
                  ),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueCard(String title, String subtitle, String status, Color badgeBg, Color badgeText, Color badgeBorder) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(16, 24, 40, 0.04),
            offset: Offset(0, 1),
            blurRadius: 2,
          ),
          BoxShadow(
            color: Color.fromRGBO(16, 24, 40, 0.04),
            offset: Offset(0, 8),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: badgeBorder),
              ),
              child: Text(
                status.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: badgeText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _queueSubtitle(Map<String, dynamic> item) {
    final error = item['error'];
    if (error != null && error.toString().isNotEmpty) {
      return error.toString();
    }

    final amount = item['amount'];
    if (amount != null) {
      return 'Amount: $amount';
    }

    return item['title']?.toString() ?? '';
  }

  String _formatLastSync(String isoValue) {
    final date = DateTime.tryParse(isoValue);
    if (date == null) return 'Last sync saved';
    return 'Last Sync: ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
