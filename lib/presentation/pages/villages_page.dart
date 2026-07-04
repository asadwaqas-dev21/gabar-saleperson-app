import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salesperson_app/core/constants/app_colors.dart';
import 'package:salesperson_app/data/repositories/data_repository.dart';
import 'package:salesperson_app/presentation/blocs/villages/villages_bloc.dart';
import 'package:salesperson_app/presentation/blocs/villages/villages_event.dart';
import 'package:salesperson_app/presentation/blocs/villages/villages_state.dart';
import 'package:salesperson_app/presentation/widgets/app_input.dart';
import 'package:salesperson_app/presentation/pages/customers_page.dart';

class VillagesPage extends StatelessWidget {
  const VillagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => VillagesBloc(
        repository: context.read<DataRepository>(),
      )..add(LoadVillages()),
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
                        'Manage Area',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.muted,
                        ),
                      ),
                      Text(
                        'My Villages',
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
              const SizedBox(height: 16),
              
              const AppInput(placeholder: 'Search village'),
              
              const SizedBox(height: 12),
              
              Expanded(
                child: BlocBuilder<VillagesBloc, VillagesState>(
                  builder: (context, state) {
                    if (state is VillagesLoading) {
                      return const Center(child: CircularProgressIndicator(color: AppColors.brand));
                    } else if (state is VillagesError) {
                      return Center(child: Text(state.message));
                    } else if (state is VillagesLoaded) {
                      if (state.villages.isEmpty) {
                        return const Center(
                          child: Text('No villages found. Click + to add one.', style: TextStyle(color: AppColors.muted)),
                        );
                      }
                      
                      return ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: state.villages.length,
                        itemBuilder: (context, index) {
                          final village = state.villages[index];
                          final summary = state.summaries.firstWhere(
                            (item) => item['local_id'] == village.localId,
                            orElse: () => <String, dynamic>{},
                          );
                          final totalCustomers =
                              ((summary['total_customers'] ?? 0) as num)
                                  .toInt();
                          final totalSales =
                              ((summary['total_sales'] ?? 0) as num)
                                  .toDouble();
                          final totalPaid =
                              ((summary['total_paid'] ?? 0) as num)
                                  .toDouble();
                          final totalPending =
                              ((summary['total_pending'] ?? 0) as num)
                                  .toDouble();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: _buildVillageCard(
                              context,
                              localId: village.localId,
                              name: village.name,
                              details: '$totalCustomers customers',
                              syncStatus: village.syncStatus,
                              sales: 'PKR ${totalSales.toStringAsFixed(0)}',
                              paid: 'PKR ${totalPaid.toStringAsFixed(0)}',
                              pending: 'PKR ${totalPending.toStringAsFixed(0)}',
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
    );
  }

  Widget _buildVillageCard(BuildContext context, {
    required String localId,
    required String name,
    required String details,
    required String syncStatus,
    required String sales,
    required String paid,
    required String pending,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => CustomersPage(
            villageLocalId: localId,
            villageName: name,
          )),
        );
      },
      child: Container(
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
                Expanded(
                  child: Column(
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
                    const SizedBox(height: 4),
                    Text(
                      details,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: syncStatus == 'synced'
                        ? AppColors.successLight
                        : AppColors.warningLight,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: syncStatus == 'synced'
                          ? AppColors.successBorder
                          : AppColors.warningBorder,
                    ),
                  ),
                  child: Text(
                    syncStatus == 'synced' ? 'Active' : 'Pending',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: syncStatus == 'synced'
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Sales', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.muted)),
                      Text(sales, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.ink)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Paid', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.muted)),
                      Text(paid, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.success)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pending', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.muted)),
                      Text(pending, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.warning)),
                    ],
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
