import 'package:flutter/material.dart';
import 'package:salesperson_app/core/constants/app_colors.dart';
import 'package:salesperson_app/presentation/pages/dashboard_page.dart';
import 'package:salesperson_app/presentation/pages/villages_page.dart';
import 'package:salesperson_app/presentation/pages/add_sale_page.dart';
import 'package:salesperson_app/presentation/pages/inventory_page.dart';
import 'package:salesperson_app/presentation/pages/sync_status_page.dart';
import 'package:salesperson_app/presentation/pages/profile_page.dart';
import 'package:salesperson_app/core/sync/sync_manager.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  int _localRefreshVersion = 0;
  late SyncManager _syncManager;

  @override
  void initState() {
    super.initState();
    _syncManager = context.read<SyncManager>();

    // Initialize realtime listeners and trigger background sync
    _syncManager.initRealtime();
    _syncManager.syncNow();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: ValueListenableBuilder<int>(
        valueListenable: _syncManager.syncVersion,
        builder: (context, version, _) {
          final pageVersion = '$version-$_localRefreshVersion';
          final pages = [
            DashboardPage(key: ValueKey('dashboard-$pageVersion')),
            VillagesPage(key: ValueKey('villages-$pageVersion')),
            AddSalePage(key: ValueKey('sale-$pageVersion')),
            InventoryPage(key: ValueKey('inventory-$pageVersion')),
            SyncStatusPage(key: ValueKey('sync-$pageVersion')),
            ProfilePage(key: ValueKey('profile-$pageVersion')),
          ];

          return IndexedStack(index: _currentIndex, children: pages);
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              _buildNavItem(0, 'Home', Icons.home_rounded),
              _buildNavItem(1, 'Villages', Icons.map_rounded),
              _buildNavItem(2, 'Sale', Icons.add_shopping_cart_rounded),
              _buildNavItem(3, 'Stock', Icons.inventory_2_rounded),
              _buildNavItem(4, 'Sync', Icons.sync_rounded),
              _buildNavItem(5, 'Profile', Icons.person_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String label, IconData icon) {
    final isActive = _currentIndex == index;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() {
            _currentIndex = index;
            _localRefreshVersion++;
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
            decoration: BoxDecoration(
              color: isActive ? AppColors.brandLight : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive ? AppColors.brandBorder : Colors.transparent,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 21,
                  color: isActive ? AppColors.brand : AppColors.muted,
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: isActive ? AppColors.brand : AppColors.muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
