import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salesperson_app/core/constants/app_colors.dart';
import 'package:salesperson_app/presentation/widgets/app_button.dart';
import 'package:salesperson_app/data/models/customer_model.dart';
import 'package:salesperson_app/data/repositories/data_repository.dart';
import 'package:salesperson_app/presentation/blocs/customer_profile/customer_profile_bloc.dart';
import 'package:salesperson_app/presentation/blocs/customer_profile/customer_profile_event.dart';
import 'package:salesperson_app/presentation/blocs/customer_profile/customer_profile_state.dart';
import 'package:salesperson_app/presentation/pages/add_sale_page.dart';
import 'package:salesperson_app/presentation/pages/add_payment_page.dart';

class CustomerProfilePage extends StatelessWidget {
  final CustomerModel customer;

  const CustomerProfilePage({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          CustomerProfileBloc(repository: context.read<DataRepository>())
            ..add(LoadCustomerProfileData(customer.localId)),
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
                            const Text(
                              'Customer Profile',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.muted,
                              ),
                            ),
                            Text(
                              customer.name,
                              style: const TextStyle(
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
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.line),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        '⋯',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
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
                      // Main Stats Card
                      BlocBuilder<CustomerProfileBloc, CustomerProfileState>(
                        builder: (context, state) {
                          final activeCustomer = state is CustomerProfileLoaded
                              ? state.customer
                              : customer;
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${activeCustomer.phone ?? ''} - ${activeCustomer.houseNumber ?? ''} - ${activeCustomer.address ?? ''}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.muted,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Sales',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.muted,
                                        ),
                                      ),
                                      Text(
                                        activeCustomer.totalSales.toStringAsFixed(0),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Paid',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.muted,
                                        ),
                                      ),
                                      Text(
                                        activeCustomer.totalPaid.toStringAsFixed(0),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Due',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.muted,
                                        ),
                                      ),
                                      Text(
                                        activeCustomer.totalPending.toStringAsFixed(
                                          0,
                                        ),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.warning,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                        },
                      ),

                      const SizedBox(height: 12),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              text: 'Add Sale',
                              type: ButtonType.brand,
                              onPressed: () async {
                                final latestCustomer = await context
                                        .read<DataRepository>()
                                        .getCustomerByLocalId(customer.localId) ??
                                    customer;
                                if (!context.mounted) return;
                                final result = await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        AddSalePage(customer: latestCustomer),
                                  ),
                                );
                                if (result == true && context.mounted) {
                                  context.read<CustomerProfileBloc>().add(
                                        LoadCustomerProfileData(
                                          customer.localId,
                                        ),
                                      );
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AppButton(
                              text: 'Add Payment',
                              type: ButtonType.primary,
                              onPressed: () async {
                                final latestCustomer = await context
                                        .read<DataRepository>()
                                        .getCustomerByLocalId(customer.localId) ??
                                    customer;
                                if (!context.mounted) return;
                                final result = await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => AddPaymentPage(customer: latestCustomer),
                                  ),
                                );
                                if (result == true && context.mounted) {
                                  context.read<CustomerProfileBloc>().add(LoadCustomerProfileData(customer.localId));
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              text: 'Statement',
                              type: ButtonType.light,
                              onPressed: () {},
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AppButton(
                              text: 'Send SMS',
                              type: ButtonType.light,
                              onPressed: () {},
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      const Text(
                        'Ledger',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 8),

                      BlocBuilder<CustomerProfileBloc, CustomerProfileState>(
                        builder: (context, state) {
                          if (state is CustomerProfileLoading) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.brand,
                              ),
                            );
                          }
                          if (state is CustomerProfileError) {
                            return Center(
                              child: Text(
                                state.message,
                                style: const TextStyle(
                                  color: AppColors.warning,
                                ),
                              ),
                            );
                          }
                          if (state is CustomerProfileLoaded) {
                            final items = <Map<String, dynamic>>[];
                            
                            for (var sale in state.sales) {
                              items.add({
                                'type': 'Sale',
                                'date': sale.saleDate,
                                'amount': sale.totalAmount,
                                'paid': sale.paidAmount,
                              });
                            }
                            
                            for (var payment in state.payments) {
                              items.add({
                                'type': 'Payment',
                                'date': payment.paymentDate,
                                'amount': payment.amount,
                                'paid': payment.amount,
                              });
                            }
                            
                            items.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

                            if (items.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24.0),
                                child: Center(
                                  child: Text(
                                    'No records found.',
                                    style: TextStyle(color: AppColors.muted),
                                  ),
                                ),
                              );
                            }
                            return Column(
                              children: items.map((item) {
                                final isSale = item['type'] == 'Sale';
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: _buildLedgerCard(
                                    isSale ? 'Sale' : 'Payment',
                                    item['date'].toString().split(' ')[0],
                                    isSale ? '+PKR ${item['amount'].toStringAsFixed(0)}' : '-PKR ${item['amount'].toStringAsFixed(0)}',
                                    isSale ? AppColors.ink : AppColors.success,
                                  ),
                                );
                              }).toList(),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLedgerCard(
    String title,
    String subtitle,
    String amount,
    Color amountColor,
  ) {
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
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }
}
