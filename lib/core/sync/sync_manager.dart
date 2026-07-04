import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:salesperson_app/data/datasources/local_data_source.dart';
import 'package:salesperson_app/data/datasources/remote_data_source.dart';

class SyncManager {
  final LocalDataSource localDataSource;
  final RemoteDataSource remoteDataSource;

  bool _isSyncing = false;
  final ValueNotifier<int> syncVersion = ValueNotifier<int>(0);

  SyncManager({required this.localDataSource, required this.remoteDataSource});

  void initRealtime() {
    log('--- INITIALIZING REALTIME LISTENERS ---');
    final client = remoteDataSource.client;
    
    // Listen to changes in the public schema
    client.channel('public:all').onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      callback: (payload) {
        log('Realtime change detected: ${payload.table}');
        // When a change is detected on the server, trigger a pull to update local DB
        _pullData();
      },
    ).subscribe();
  }

  Future<void> syncNow() async {
    if (_isSyncing) return;
    _isSyncing = true;

    log('--- STARTING SYNC ---');

    try {
      // 1. PUSH Pending Customers
      await _pushCustomers();

      // 2. PUSH Pending Sales
      await _pushSales();
      
      // 3. PUSH Pending Payments
      await _pushPayments();

      // 4. PUSH Inventory Returns
      await _pushInventoryReturns();

      // 5. PULL Remote Data
      await _pullData();

      await localDataSource.setMeta('last_sync_at', DateTime.now().toIso8601String());
      syncVersion.value++;

      log('--- SYNC COMPLETED SUCCESSFULLY ---');
    } catch (e) {
      log('--- SYNC FAILED: $e ---');
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _pullData() async {
    log('--- PULLING DATA FROM SUPABASE ---');
    var successCount = 0;
    var failureCount = 0;

    Future<void> runPull(String label, Future<void> Function() task) async {
      try {
        await task();
        successCount++;
      } catch (e) {
        failureCount++;
        log('Pull failed for $label: $e');
      }
    }

    await runPull('salesperson profile', () async {
      final profile = await remoteDataSource.fetchSalespersonProfile();
      await localDataSource.insertSalespersonProfile(profile);
      log('Pulled salesperson profile');
    });

    await runPull('villages', () async {
      final remoteVillages = await remoteDataSource.fetchVillages();
      for (var village in remoteVillages) {
        await localDataSource.insertVillage(village);
      }
      log('Pulled ${remoteVillages.length} villages');
    });

    await runPull('customers', () async {
      final remoteCustomers = await remoteDataSource.fetchCustomers();
      for (var customer in remoteCustomers) {
        await localDataSource.insertCustomer(customer);
      }
      log('Pulled ${remoteCustomers.length} customers');
    });

    await runPull('products', () async {
      final remoteProducts = await remoteDataSource.fetchProducts();
      await localDataSource.insertProducts(remoteProducts);
      log('Pulled ${remoteProducts.length} products');
    });

    await runPull('product variants', () async {
      final remoteVariants = await remoteDataSource.fetchProductVariants();
      await localDataSource.insertProductVariants(remoteVariants);
      log('Pulled ${remoteVariants.length} product variants');
    });

    await runPull('salesperson inventory', () async {
      final remoteInventory = await remoteDataSource.fetchSalespersonInventory();
      await localDataSource.insertSalespersonInventory(remoteInventory);
      log('Pulled ${remoteInventory.length} inventory records');
    });

    await runPull('sales', () async {
      final remoteSales = await remoteDataSource.fetchSales();
      await localDataSource.insertSales(remoteSales);
      log('Pulled ${remoteSales.length} sales');
    });

    await runPull('payments', () async {
      final remotePayments = await remoteDataSource.fetchPayments();
      await localDataSource.insertPayments(remotePayments);
      log('Pulled ${remotePayments.length} standalone payments');
    });

    log('Pull finished: $successCount successful, $failureCount failed');

    if (successCount == 0 && failureCount > 0) {
      throw Exception('All pull sections failed');
    }
  }

  Future<void> _pushCustomers() async {
    final pendingCustomers = await localDataSource.getRetryableSyncItems(
      'customers',
    );
    log('Found ${pendingCustomers.length} pending customers.');

    for (var customerMap in pendingCustomers) {
      try {
        final contextIds = await remoteDataSource.fetchSalespersonContext();
        // Resolve village server ID
        final villageServerId = await localDataSource.getServerIdForVillage(customerMap['village_local_id']);
        
        final Map<String, dynamic> remoteData = {
          'business_id': contextIds['businessId'],
          'salesperson_id': contextIds['salespersonId'],
          'village_id': villageServerId ?? customerMap['village_server_id'], // Fallback if available
          'name': customerMap['name'],
          'phone': customerMap['phone'],
          'house_number': customerMap['house_number'],
          'address': customerMap['address'],
          'local_id': customerMap['local_id'],
          'sync_status': 'synced',
        };

        if (remoteData['village_id'] == null) {
          throw Exception('Cannot sync customer without a synced village');
        }

        final serverId = await remoteDataSource.pushCustomer(remoteData);
        await localDataSource.markAsSynced(
          'customers',
          customerMap['local_id'],
          serverId,
        );
        log("Synced customer: ${customerMap['name']}");
      } catch (e) {
        final status = _isConflict(e) ? 'conflict' : 'failed';
        await localDataSource.markSyncFailed(
          'customers',
          customerMap['local_id'],
          e,
          status: status,
        );
        log("Failed to sync customer ${customerMap['name']}: $e");
      }
    }
  }

  Future<void> _pushSales() async {
    final pendingSales = await localDataSource.getRetryableSyncItems('sales');
    log('Found ${pendingSales.length} pending sales.');

    for (var saleMap in pendingSales) {
      try {
        final contextIds = await remoteDataSource.fetchSalespersonContext();
        final customerServerId = await localDataSource.getServerIdForCustomer(saleMap['customer_local_id']);
        final villageServerId = await localDataSource.getServerIdForVillage(saleMap['village_local_id']);
        
        final Map<String, dynamic> remoteData = {
          'business_id': contextIds['businessId'],
          'salesperson_id': contextIds['salespersonId'],
          'customer_id': customerServerId ?? saleMap['customer_server_id'],
          'village_id': villageServerId ?? saleMap['village_server_id'],
          'total_amount': saleMap['total_amount'],
          'paid_amount': saleMap['paid_amount'],
          'previous_pending': saleMap['previous_pending'],
          'new_pending': saleMap['new_pending'],
          'sale_date': saleMap['sale_date'],
          'sale_status': saleMap['sale_status'] ?? 'completed',
          'local_id': saleMap['local_id'],
          'sync_status': 'synced',
        };

        if (remoteData['customer_id'] == null || remoteData['village_id'] == null) {
          throw Exception('Cannot sync sale without synced customer and village');
        }

        final serverId = await remoteDataSource.pushSale(remoteData);
        await localDataSource.markAsSynced(
          'sales',
          saleMap['local_id'],
          serverId,
        );
        log("Synced sale: ${saleMap['local_id']}");

        // Now push sale items for this sale
        final database = await localDataSource.db;
        final items = await database.query('sale_items', where: 'sale_local_id = ?', whereArgs: [saleMap['local_id']]);
        
        for (var item in items) {
          final Map<String, dynamic> itemData = {
            'sale_id': serverId,
            'business_id': contextIds['businessId'],
            'product_id': item['product_id'],
            'variant_id': item['variant_id'],
            'quantity': item['quantity'],
            'unit_price': item['unit_price'],
          };
          
          final itemServerId = await remoteDataSource.pushSaleItem(itemData);
          await localDataSource.markAsSynced(
            'sale_items',
            item['local_id'] as String,
            itemServerId,
          );
        }

      } catch (e) {
        await localDataSource.markSyncFailed('sales', saleMap['local_id'], e);
        log("Failed to sync sale ${saleMap['local_id']}: $e");
      }
    }
  }

  Future<void> _pushPayments() async {
    final pendingPayments = (await localDataSource.getRetryableSyncItems('payments'))
        .where((payment) => payment['source_sale_local_id'] == null)
        .toList();
    log('Found ${pendingPayments.length} pending payments.');

    for (var paymentMap in pendingPayments) {
      try {
        final contextIds = await remoteDataSource.fetchSalespersonContext();
        final customerServerId = await localDataSource.getServerIdForCustomer(paymentMap['customer_local_id']);
        
        final Map<String, dynamic> remoteData = {
          'business_id': contextIds['businessId'],
          'salesperson_id': contextIds['salespersonId'],
          'customer_id': customerServerId ?? paymentMap['customer_server_id'],
          'amount': paymentMap['amount'],
          'payment_method': paymentMap['payment_method'],
          'notes': paymentMap['notes'],
          'payment_date': paymentMap['payment_date'],
          'local_id': paymentMap['local_id'],
          'sync_status': 'synced',
        };

        if (remoteData['customer_id'] == null) {
          throw Exception('Cannot sync payment without synced customer');
        }

        final serverId = await remoteDataSource.pushPayment(remoteData);
        await localDataSource.markAsSynced(
          'payments',
          paymentMap['local_id'],
          serverId,
        );
        log("Synced payment: ${paymentMap['local_id']}");
      } catch (e) {
        await localDataSource.markSyncFailed('payments', paymentMap['local_id'], e);
        log("Failed to sync payment ${paymentMap['local_id']}: $e");
      }
    }
  }

  Future<void> _pushInventoryReturns() async {
    final pendingReturns = await localDataSource.getRetryableSyncItems('inventory_returns');
    log('Found ${pendingReturns.length} pending inventory returns.');

    for (final returnMap in pendingReturns) {
      try {
        final contextIds = await remoteDataSource.fetchSalespersonContext();
        final remoteData = {
          'business_id': contextIds['businessId'],
          'salesperson_id': contextIds['salespersonId'],
          'product_id': returnMap['product_id'],
          'variant_id': returnMap['variant_id'],
          'quantity_returned': returnMap['quantity_returned'],
          'return_date': returnMap['return_date'],
          'reason': returnMap['reason'],
          'local_id': returnMap['local_id'],
          'sync_status': 'synced',
        };

        final serverId = await remoteDataSource.pushInventoryReturn(remoteData);
        await localDataSource.markAsSynced(
          'inventory_returns',
          returnMap['local_id'],
          serverId,
        );
      } catch (e) {
        await localDataSource.markSyncFailed(
          'inventory_returns',
          returnMap['local_id'],
          e,
        );
        log("Failed to sync inventory return ${returnMap['local_id']}: $e");
      }
    }
  }

  bool _isConflict(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('23505') ||
        message.contains('duplicate key') ||
        message.contains('unique constraint');
  }
}
