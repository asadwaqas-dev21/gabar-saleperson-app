import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salesperson_app/core/constants/app_colors.dart';
import 'package:salesperson_app/data/repositories/data_repository.dart';
import 'package:salesperson_app/presentation/blocs/inventory/inventory_bloc.dart';
import 'package:salesperson_app/presentation/blocs/inventory/inventory_event.dart';
import 'package:salesperson_app/presentation/blocs/inventory/inventory_state.dart';

class InventoryPage extends StatelessWidget {
  const InventoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          InventoryBloc(repository: context.read<DataRepository>())
            ..add(LoadInventory()),
      child: SafeArea(
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
                        'Stock Assigned',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.muted,
                        ),
                      ),
                      Text(
                        'My Inventory',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                  BlocBuilder<InventoryBloc, InventoryState>(
                    builder: (context, state) {
                      return GestureDetector(
                        onTap: () {
                          context.read<InventoryBloc>().add(LoadInventory());
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.line),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            '↺',
                            style: TextStyle(
                              color: AppColors.ink,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Expanded(
                child: BlocBuilder<InventoryBloc, InventoryState>(
                  builder: (context, state) {
                    if (state is InventoryLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.brand,
                        ),
                      );
                    } else if (state is InventoryError) {
                      return Center(
                        child: Text(
                          state.message,
                          style: const TextStyle(color: AppColors.danger),
                        ),
                      );
                    } else if (state is InventoryLoaded) {
                      final items = state.items;

                      double totalReceived = 0;
                      double totalRemaining = 0;
                      for (var item in items) {
                        totalReceived += item['quantity_received'] ?? 0;
                        totalRemaining += item['remaining_quantity'] ?? 0;
                      }

                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildMetricCard(
                                  'Received',
                                  totalReceived.toStringAsFixed(0),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildMetricCard(
                                  'Remaining',
                                  totalRemaining.toStringAsFixed(0),
                                  isWarning: totalRemaining < 50,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: items.isEmpty
                                ? const Center(
                                    child: Text("No inventory assigned yet."),
                                  )
                                : ListView.builder(
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: items.length,
                                    itemBuilder: (context, index) {
                                      final item = items[index];
                                      final received =
                                          (item['quantity_received'] ?? 0)
                                              .toDouble();
                                      final remaining =
                                          (item['remaining_quantity'] ?? 0)
                                              .toDouble();
                                      final sold = (item['quantity_sold'] ?? 0)
                                          .toDouble();
                                      final returned =
                                          (item['quantity_returned'] ?? 0)
                                              .toDouble();

                                      double progress = 0;
                                      if (received > 0) {
                                        progress = remaining / received;
                                      }

                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12.0,
                                        ),
                                        child: _buildInventoryCard(
                                          name:
                                              item['product_name'] ?? 'Unknown',
                                          details:
                                              '${item['size_label']} ${item['unit']}',
                                          left:
                                              '${remaining.toStringAsFixed(0)} left',
                                          progress: progress,
                                          progressColor: progress > 0.3
                                              ? AppColors.brand
                                              : AppColors.warning,
                                          badgeBg: progress > 0.3
                                              ? AppColors.brandLight
                                              : AppColors.warningLight,
                                          badgeText: progress > 0.3
                                              ? AppColors.brand
                                              : AppColors.warning,
                                          badgeBorder: progress > 0.3
                                              ? AppColors.brandBorder
                                              : AppColors.warningBorder,
                                          issued: received.toStringAsFixed(0),
                                          sold: sold.toStringAsFixed(0),
                                          returned: returned.toStringAsFixed(0),
                                          onReturn: () => _showReturnDialog(
                                            context,
                                            item: item,
                                            maxQuantity: remaining,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    String label,
    String value, {
    bool isWarning = false,
  }) {
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
              color: isWarning ? AppColors.warning : AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryCard({
    required String name,
    required String details,
    required String left,
    required double progress,
    required Color progressColor,
    required Color badgeBg,
    required Color badgeText,
    required Color badgeBorder,
    required String issued,
    required String sold,
    required String returned,
    required VoidCallback onReturn,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    details,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: badgeBorder),
                ),
                child: Text(
                  left,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: badgeText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar
          Container(
            height: 8,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0), // slate-200
              borderRadius: BorderRadius.circular(999),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: progressColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Issued',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.muted,
                      ),
                    ),
                    Text(
                      issued,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sold',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.muted,
                      ),
                    ),
                    Text(
                      sold,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Return',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.muted,
                      ),
                    ),
                    Text(
                      returned,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onReturn,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.ink,
                side: const BorderSide(color: AppColors.line),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Return Stock',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showReturnDialog(
    BuildContext context, {
    required Map<String, dynamic> item,
    required double maxQuantity,
  }) async {
    final controller = TextEditingController();
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Return Stock'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Available: ${maxQuantity.toStringAsFixed(0)}'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantity'),
              ),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(labelText: 'Reason'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    final quantity = double.tryParse(controller.text) ?? 0;
    if (quantity <= 0 || quantity > maxQuantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid return quantity')),
      );
      return;
    }

    await context.read<DataRepository>().addInventoryReturn(
          productId: item['product_id'] as String,
          variantId: item['variant_id'] as String,
          quantity: quantity,
          reason: reasonController.text.trim().isEmpty
              ? null
              : reasonController.text.trim(),
        );

    if (context.mounted) {
      context.read<InventoryBloc>().add(LoadInventory());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stock return saved for sync')),
      );
    }
  }
}
