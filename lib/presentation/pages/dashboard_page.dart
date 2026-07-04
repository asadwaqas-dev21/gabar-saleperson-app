import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salesperson_app/core/constants/app_colors.dart';
import 'package:salesperson_app/presentation/widgets/app_button.dart';
import 'package:salesperson_app/presentation/blocs/dashboard/dashboard_bloc.dart';
import 'package:salesperson_app/presentation/blocs/dashboard/dashboard_event.dart';
import 'package:salesperson_app/presentation/blocs/dashboard/dashboard_state.dart';
import 'package:salesperson_app/data/repositories/data_repository.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          DashboardBloc(repository: context.read<DataRepository>())
            ..add(LoadDashboardData()),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              BlocBuilder<DashboardBloc, DashboardState>(
                builder: (context, state) {
                  final name = state is DashboardLoaded
                      ? state.salespersonName
                      : 'Salesperson';
                  final initial = name.trim().isEmpty
                      ? 'S'
                      : name.trim().characters.first.toUpperCase();

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Assalam o Alaikum',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.muted,
                            ),
                          ),
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.ink,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initial,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              Expanded(
                child: BlocBuilder<DashboardBloc, DashboardState>(
                  builder: (context, state) {
                    if (state is DashboardLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.brand,
                        ),
                      );
                    }
                    if (state is DashboardError) {
                      return Center(
                        child: Text(
                          state.message,
                          style: const TextStyle(color: AppColors.warning),
                        ),
                      );
                    }

                    if (state is DashboardLoaded) {
                      return ListView(
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
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Today Sales',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: Color(
                                              0xFFCBD5E1,
                                            ), // slate-300
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'PKR ${state.todaySales.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            fontSize: 30,
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0x3310B981,
                                        ), // emerald-500/20
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        border: Border.all(
                                          color: const Color(0x3334D399),
                                        ), // emerald-400/20
                                      ),
                                      child: Text(
                                        state.pendingSync > 0
                                            ? '${state.pendingSync} Pending'
                                            : 'Synced',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          color: Color(
                                            0xFFD1FAE5,
                                          ), // emerald-100
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withAlpha(25),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Collection',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFFCBD5E1),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'PKR ${state.collection.toStringAsFixed(0)}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w900,
                                                color: AppColors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withAlpha(25),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Pending',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFFCBD5E1),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'PKR ${state.pending.toStringAsFixed(0)}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w900,
                                                color: AppColors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Metrics Grid
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            childAspectRatio: 1.8,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            children: [
                              _buildMetricCard(
                                'Villages',
                                '${state.villagesCount}',
                              ),
                              _buildMetricCard(
                                'Customers',
                                '${state.customersCount}',
                              ),
                              _buildMetricCard(
                                'Inventory Left',
                                '${state.inventoryLeft}',
                              ),
                              _buildMetricCard(
                                'Pending Sync',
                                '${state.pendingSync}',
                                isWarning: state.pendingSync > 0,
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Buttons
                          Row(
                            children: [
                              Expanded(
                                child: AppButton(
                                  text: 'Add Sale',
                                  type: ButtonType.brand,
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Open a village customer to add a sale.',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: AppButton(
                                  text: 'Add Payment',
                                  type: ButtonType.light,
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Open a customer profile to add payment.',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Follow-ups
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Follow-ups',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.ink,
                                ),
                              ),
                              Text(
                                'View All',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.brand,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (state.followUps.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16.0),
                              child: Center(
                                child: Text(
                                  'No pending follow-ups.',
                                  style: TextStyle(color: AppColors.muted),
                                ),
                              ),
                            )
                          else
                            ...state.followUps.map((customer) {
                              final amount =
                                  ((customer['total_pending'] ?? 0) as num)
                                      .toDouble();
                              final details = [
                                customer['phone'],
                                customer['house_number'],
                              ]
                                  .where(
                                    (value) =>
                                        value != null &&
                                        value.toString().isNotEmpty,
                                  )
                                  .join(' - ');
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: _buildFollowUpCard(
                                  customer['name']?.toString() ?? 'Customer',
                                  details.isEmpty
                                      ? 'Pending collection'
                                      : details,
                                  'PKR ${amount.toStringAsFixed(0)}',
                                ),
                              );
                            }),
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                  color: isWarning ? AppColors.warning : AppColors.ink,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowUpCard(String name, String details, String amount) {
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
              Text(
                details,
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
          ),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}
