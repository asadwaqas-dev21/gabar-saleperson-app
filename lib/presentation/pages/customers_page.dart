import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salesperson_app/core/constants/app_colors.dart';
import 'package:salesperson_app/data/repositories/data_repository.dart';
import 'package:salesperson_app/presentation/blocs/customers/customers_bloc.dart';
import 'package:salesperson_app/presentation/blocs/customers/customers_event.dart';
import 'package:salesperson_app/presentation/blocs/customers/customers_state.dart';
import 'package:salesperson_app/presentation/widgets/app_input.dart';
import 'package:salesperson_app/data/models/customer_model.dart';
import 'package:salesperson_app/presentation/pages/customer_profile_page.dart';

import 'package:salesperson_app/presentation/widgets/add_customer_sheet.dart';

class CustomersPage extends StatelessWidget {
  final String villageLocalId;
  final String villageName;

  const CustomersPage({
    super.key,
    required this.villageLocalId,
    required this.villageName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          CustomersBloc(repository: context.read<DataRepository>())
            ..add(LoadCustomers(villageLocalId)),
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
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
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            size: 20,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              villageName,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.muted,
                              ),
                            ),
                            const Text(
                              'Customers',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                                color: AppColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    BlocBuilder<CustomersBloc, CustomersState>(
                      builder: (context, state) {
                        return GestureDetector(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => BlocProvider.value(
                                value: context.read<CustomersBloc>(),
                                child: AddCustomerSheet(
                                  villageLocalId: villageLocalId,
                                  villageName: villageName,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.ink,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              '+',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 24,
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

                const AppInput(placeholder: 'Search name or phone'),

                const SizedBox(height: 12),

                BlocBuilder<CustomersBloc, CustomersState>(
                  builder: (context, state) {
                    if (state is CustomersLoaded) {
                      final pendingCount = state.customers
                          .where((c) => c.syncStatus == 'pending_sync')
                          .length;
                      return Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              'Customers',
                              '${state.customers.length}',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetricCard(
                              'Pending Sync',
                              '$pendingCount',
                              isWarning: pendingCount > 0,
                            ),
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: _buildMetricCard('Customers', '-')),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            'Pending',
                            '-',
                            isWarning: false,
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 12),

                Expanded(
                  child: BlocBuilder<CustomersBloc, CustomersState>(
                    builder: (context, state) {
                      if (state is CustomersLoading) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.brand,
                          ),
                        );
                      } else if (state is CustomersError) {
                        return Center(child: Text(state.message));
                      } else if (state is CustomersLoaded) {
                        if (state.customers.isEmpty) {
                          return const Center(
                            child: Text(
                              'No customers found. Click + to add one.',
                              style: TextStyle(color: AppColors.muted),
                            ),
                          );
                        }

                        return ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: state.customers.length,
                          itemBuilder: (context, index) {
                            final customer = state.customers[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: _buildCustomerCard(
                                context,
                                customer: customer,
                              ),
                            );
                          },
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

  Widget _buildCustomerCard(
    BuildContext context, {
    required CustomerModel customer,
  }) {
    final status = customer.syncStatus == 'pending_sync'
        ? 'Pending Sync'
        : 'Synced';
    final isClear = status == 'Synced';
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CustomerProfilePage(customer: customer),
          ),
        );
      },
      child: Container(
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
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        '${customer.phone ?? ''} · ${customer.houseNumber ?? ''}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isClear
                        ? AppColors.successLight
                        : AppColors.warningLight,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isClear
                          ? AppColors.successBorder
                          : AppColors.warningBorder,
                    ),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: isClear ? AppColors.success : AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Paid PKR ${customer.totalPaid.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
                Text(
                  'Due PKR ${customer.totalPending.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
