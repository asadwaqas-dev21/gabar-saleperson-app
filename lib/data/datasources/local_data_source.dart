import 'package:sqflite/sqflite.dart';
import 'package:salesperson_app/core/database/sqlite_database.dart';
import 'package:salesperson_app/data/models/village_model.dart';
import 'package:salesperson_app/data/models/customer_model.dart';
import 'package:salesperson_app/data/models/sale_model.dart';
import 'package:salesperson_app/data/models/sale_item_model.dart';
import 'package:salesperson_app/data/models/payment_model.dart';
import 'package:salesperson_app/data/models/inventory_model.dart';

class LocalDataSource {
  Future<Database> get db async => await LocalDatabase.instance.database;

  Future<void> prepareForAuthenticatedUser(String userId) async {
    final previousUserId = await getMeta('auth_user_id');
    if (previousUserId != null && previousUserId != userId) {
      await clearCachedBusinessData();
    }
    await setMeta('auth_user_id', userId);
  }

  Future<void> clearCachedBusinessData() async {
    final database = await db;
    await database.transaction((txn) async {
      final tables = [
        'receipts',
        'inventory_returns',
        'sale_items',
        'payments',
        'sales',
        'salesperson_inventory',
        'product_variants',
        'products',
        'customers',
        'villages',
        'salesperson_profile',
      ];

      for (final table in tables) {
        await txn.delete(table);
      }

      await txn.delete('app_meta', where: 'key != ?', whereArgs: ['auth_user_id']);
    });
  }

  // --- Villages ---

  Future<List<VillageModel>> getVillages() async {
    final database = await db;
    final List<Map<String, dynamic>> maps = await database.query(
      'villages',
      where: 'deleted_at IS NULL',
      orderBy: 'name ASC',
    );
    return maps.map((map) => VillageModel.fromMap(map)).toList();
  }

  Future<void> insertVillage(VillageModel village) async {
    final database = await db;
    await database.insert(
      'villages',
      village.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getVillageSummaries() async {
    final database = await db;
    return await database.rawQuery('''
      SELECT
        v.local_id,
        v.server_id,
        v.name,
        v.sync_status,
        COUNT(c.local_id) AS total_customers,
        COALESCE(SUM(c.total_sales), 0) AS total_sales,
        COALESCE(SUM(c.total_paid), 0) AS total_paid,
        COALESCE(SUM(c.total_pending), 0) AS total_pending
      FROM villages v
      LEFT JOIN customers c
        ON c.village_local_id = v.local_id
       AND c.deleted_at IS NULL
      WHERE v.deleted_at IS NULL
      GROUP BY v.local_id, v.server_id, v.name, v.sync_status
      ORDER BY v.name ASC
    ''');
  }

  // --- Customers ---

  Future<List<CustomerModel>> getCustomersByVillage(
    String villageLocalId,
  ) async {
    final database = await db;
    final List<Map<String, dynamic>> maps = await database.query(
      'customers',
      where: 'village_local_id = ? AND deleted_at IS NULL',
      whereArgs: [villageLocalId],
      orderBy: 'name ASC',
    );
    return maps.map((map) => CustomerModel.fromMap(map)).toList();
  }

  Future<void> insertCustomer(CustomerModel customer) async {
    final database = await db;
    await database.insert(
      'customers',
      customer.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<CustomerModel?> getCustomerByLocalId(String localId) async {
    final database = await db;
    final maps = await database.query(
      'customers',
      where: 'local_id = ?',
      whereArgs: [localId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return CustomerModel.fromMap(maps.first);
  }

  // --- Sales ---

  Future<void> insertSale(
    SaleModel sale,
    List<SaleItemModel> items, {
    PaymentModel? payment,
  }) async {
    final database = await db;
    await database.transaction((txn) async {
      // 1. Insert the sale
      await txn.insert(
        'sales',
        sale.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 2. Insert Sale Items and Update Inventory
      for (var item in items) {
        await txn.insert(
          'sale_items',
          item.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        final updatedInventoryRows = await txn.rawUpdate(
          '''
          UPDATE salesperson_inventory 
          SET quantity_sold = quantity_sold + ?,
              remaining_quantity = remaining_quantity - ?,
              updated_at = ?
          WHERE product_id = ? AND variant_id = ?
          ''',
          [
            item.quantity,
            item.quantity,
            DateTime.now().toIso8601String(),
            item.productId,
            item.variantId,
          ],
        );

        if (updatedInventoryRows == 0) {
          throw Exception('Inventory item not found for selected product');
        }
      }

      // 3. Update customer balances
      await txn.rawUpdate(
        '''
        UPDATE customers 
        SET total_sales = total_sales + ?,
            total_paid = total_paid + ?,
            total_pending = ?,
            last_purchase_date = ?,
            last_payment_date = CASE WHEN ? > 0 THEN ? ELSE last_payment_date END,
            updated_at = ?
        WHERE local_id = ?
      ''',
        [
          sale.totalAmount,
          sale.paidAmount,
          sale.newPending,
          sale.saleDate.toIso8601String(),
          sale.paidAmount,
          sale.saleDate.toIso8601String(),
          DateTime.now().toIso8601String(),
          sale.customerLocalId,
        ],
      );

      if (payment != null) {
        await txn.insert(
          'payments',
          payment.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<List<SaleModel>> getSalesByCustomer(String customerLocalId) async {
    final database = await db;
    final List<Map<String, dynamic>> maps = await database.query(
      'sales',
      where: 'customer_local_id = ?',
      whereArgs: [customerLocalId],
      orderBy: 'sale_date DESC',
    );
    return maps.map((map) => SaleModel.fromMap(map)).toList();
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    final database = await db;
    
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    
    // Today's Sales Amount
    final salesRes = await database.rawQuery(
      "SELECT SUM(total_amount) as total FROM sales WHERE date(sale_date) = ?",
      [todayStr]
    );
    final todaySales = ((salesRes.first['total'] ?? 0) as num).toDouble();

    // Today's Collection (sale payments are stored locally in payments too)
    final paymentsRes = await database.rawQuery(
      "SELECT SUM(amount) as total FROM payments WHERE date(payment_date) = ?",
      [todayStr]
    );
    final todayCollection = ((paymentsRes.first['total'] ?? 0) as num).toDouble();

    // Total Pending across all customers
    final pendingRes = await database.rawQuery(
      "SELECT SUM(total_pending) as total FROM customers WHERE deleted_at IS NULL"
    );
    final totalPendingAmount = ((pendingRes.first['total'] ?? 0) as num).toDouble();

    // Total Customers
    final customerCount = await database.rawQuery(
      "SELECT COUNT(*) as count FROM customers WHERE deleted_at IS NULL"
    );
    final totalCustomers = (customerCount.first['count'] ?? 0) as int;

    // Total Villages
    final villageCount = await database.rawQuery(
      "SELECT COUNT(*) as count FROM villages WHERE deleted_at IS NULL"
    );
    final totalVillages = (villageCount.first['count'] ?? 0) as int;

    // Pending Sync Count
    final pendingCustomers = await getPendingSyncItems('customers');
    final pendingSales = await getPendingSyncItems('sales');
    final pendingPayments = await getPendingSyncItems('payments');
    final pendingReturns = await getPendingSyncItems('inventory_returns');
    final pendingSyncCount =
        pendingCustomers.length + pendingSales.length + pendingPayments.length + pendingReturns.length;

    final inventoryRes = await database.rawQuery(
      "SELECT SUM(remaining_quantity) as total FROM salesperson_inventory"
    );
    final inventoryLeft = ((inventoryRes.first['total'] ?? 0) as num).toInt();

    return {
      'customersCount': totalCustomers,
      'villagesCount': totalVillages,
      'todaySales': todaySales,
      'collection': todayCollection,
      'pending': totalPendingAmount,
      'pendingSync': pendingSyncCount,
      'inventoryLeft': inventoryLeft,
    };
  }

  Future<List<Map<String, dynamic>>> getFollowUps({int limit = 5}) async {
    final database = await db;
    return await database.rawQuery(
      '''
      SELECT name, phone, house_number, total_pending, last_payment_date, updated_at
      FROM customers
      WHERE deleted_at IS NULL AND total_pending > 0
      ORDER BY total_pending DESC, updated_at ASC
      LIMIT ?
      ''',
      [limit],
    );
  }

  // --- Payments ---

  Future<void> insertPayment(PaymentModel payment, double newCustomerPending) async {
    final database = await db;
    await database.transaction((txn) async {
      await txn.insert(
        'payments',
        payment.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await txn.rawUpdate(
        '''
        UPDATE customers 
        SET total_paid = total_paid + ?,
            total_pending = ?,
            last_payment_date = ?,
            updated_at = ?
        WHERE local_id = ?
        ''',
        [
          payment.amount,
          newCustomerPending,
          payment.paymentDate.toIso8601String(),
          DateTime.now().toIso8601String(),
          payment.customerLocalId,
        ],
      );
    });
  }

  Future<List<PaymentModel>> getPaymentsByCustomer(String customerLocalId) async {
    final database = await db;
    final List<Map<String, dynamic>> maps = await database.query(
      'payments',
      where: 'customer_local_id = ?',
      whereArgs: [customerLocalId],
      orderBy: 'payment_date DESC',
    );
    return maps.map((map) => PaymentModel.fromMap(map)).toList();
  }

  // --- Inventory ---

  Future<void> insertProducts(List<ProductModel> products) async {
    final database = await db;
    final batch = database.batch();
    for (var p in products) {
      batch.insert('products', p.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> insertProductVariants(List<ProductVariantModel> variants) async {
    final database = await db;
    final batch = database.batch();
    for (var v in variants) {
      batch.insert('product_variants', v.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> insertSalespersonInventory(List<SalespersonInventoryModel> inventory) async {
    final database = await db;
    await database.transaction((txn) async {
      for (final item in inventory) {
        final pendingSold = await txn.rawQuery(
          '''
          SELECT COALESCE(SUM(si.quantity), 0) AS total
          FROM sale_items si
          JOIN sales s ON s.local_id = si.sale_local_id
          WHERE si.variant_id = ?
            AND (si.sync_status != 'synced' OR s.sync_status != 'synced')
          ''',
          [item.variantId],
        );
        final pendingReturned = await txn.rawQuery(
          '''
          SELECT COALESCE(SUM(quantity_returned), 0) AS total
          FROM inventory_returns
          WHERE variant_id = ? AND sync_status != 'synced'
          ''',
          [item.variantId],
        );

        final localSold =
            ((pendingSold.first['total'] ?? 0) as num).toDouble();
        final localReturned =
            ((pendingReturned.first['total'] ?? 0) as num).toDouble();
        final adjusted = item.toMap()
          ..['quantity_sold'] = item.quantitySold + localSold
          ..['quantity_returned'] = item.quantityReturned + localReturned
          ..['remaining_quantity'] =
              (item.remainingQuantity - localSold - localReturned)
                  .clamp(0, double.infinity)
                  .toDouble()
          ..['updated_at'] = DateTime.now().toIso8601String();

        await txn.insert(
          'salesperson_inventory',
          adjusted,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<List<Map<String, dynamic>>> getJoinedInventory() async {
    final database = await db;
    final sql = '''
      SELECT 
        i.id,
        i.product_id,
        i.variant_id,
        p.name as product_name,
        p.description as product_description,
        v.size_label,
        v.unit,
        v.sale_price,
        i.quantity_received,
        i.quantity_sold,
        i.quantity_returned,
        i.quantity_damaged,
        i.remaining_quantity
      FROM salesperson_inventory i
      JOIN products p ON i.product_id = p.id
      JOIN product_variants v ON i.variant_id = v.id
      ORDER BY p.name ASC, v.size_label ASC
    ''';
    
    return await database.rawQuery(sql);
  }

  // --- Sync Engine Queries ---

  Future<List<Map<String, dynamic>>> getPendingSyncItems(String table) async {
    final database = await db;
    return await database.query(
      table,
      where: 'sync_status = ?',
      whereArgs: ['pending_sync'],
    );
  }

  Future<List<Map<String, dynamic>>> getRetryableSyncItems(String table) async {
    final database = await db;
    return await database.query(
      table,
      where: 'sync_status IN (?, ?)',
      whereArgs: ['pending_sync', 'failed'],
    );
  }

  Future<List<Map<String, dynamic>>> getSyncQueue() async {
    final database = await db;
    final queue = <Map<String, dynamic>>[];
    final tables = {
      'customers': 'Customer',
      'sales': 'Sale',
      'payments': 'Payment',
      'inventory_returns': 'Inventory Return',
    };

    for (final entry in tables.entries) {
      final rows = await database.query(
        entry.key,
        where: 'sync_status IN (?, ?, ?)',
        whereArgs: ['pending_sync', 'failed', 'conflict'],
      );
      for (final row in rows) {
        queue.add({
          'table': entry.key,
          'type': entry.value,
          'local_id': row['local_id'],
          'title': row['name'] ?? row['local_id'] ?? entry.value,
          'amount': row['total_amount'] ?? row['amount'] ?? row['quantity_returned'],
          'status': row['sync_status'],
          'error': row['sync_error'],
        });
      }
    }

    return queue;
  }

  Future<void> markAsSynced(
    String table,
    String localId,
    String serverId,
  ) async {
    final database = await db;
    await database.update(
      table,
      {
        'sync_status': 'synced',
        'sync_error': null,
        'server_id': serverId,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'local_id = ?',
      whereArgs: [localId],
    );
  }

  Future<void> markSyncFailed(
    String table,
    String localId,
    Object error, {
    String status = 'failed',
  }) async {
    final database = await db;
    await database.update(
      table,
      {
        'sync_status': status,
        'sync_error': error.toString(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'local_id = ?',
      whereArgs: [localId],
    );
  }

  Future<void> setMeta(String key, String value) async {
    final database = await db;
    await database.insert(
      'app_meta',
      {
        'key': key,
        'value': value,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getMeta(String key) async {
    final database = await db;
    final result = await database.query(
      'app_meta',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
    );
    if (result.isEmpty) return null;
    return result.first['value'] as String?;
  }

  Future<String?> getServerIdForVillage(String localId) async {
    final database = await db;
    final result = await database.query(
      'villages',
      columns: ['server_id'],
      where: 'local_id = ?',
      whereArgs: [localId],
    );
    if (result.isNotEmpty) {
      return result.first['server_id'] as String?;
    }
    return null;
  }

  Future<String?> getServerIdForCustomer(String localId) async {
    final database = await db;
    final result = await database.query(
      'customers',
      columns: ['server_id'],
      where: 'local_id = ?',
      whereArgs: [localId],
    );
    if (result.isNotEmpty) {
      return result.first['server_id'] as String?;
    }
    return null;
  }

  Future<void> insertSales(List<SaleModel> sales) async {
    final database = await db;
    await database.transaction((txn) async {
      for (final sale in sales) {
        await txn.insert(
          'sales',
          sale.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        final existingPayments = await txn.query(
          'payments',
          columns: ['local_id'],
          where: 'source_sale_local_id = ?',
          whereArgs: [sale.localId],
          limit: 1,
        );

        if (sale.paidAmount > 0 && existingPayments.isEmpty) {
          final payment = PaymentModel(
            businessId: sale.businessId,
            salespersonId: sale.salespersonId,
            customerLocalId: sale.customerLocalId,
            villageLocalId: sale.villageLocalId,
            saleLocalId: sale.localId,
            amount: sale.paidAmount,
            paymentMethod: 'cash',
            notes: 'Payment received with sale',
            localId: '${sale.localId}_payment',
            syncStatus: 'synced',
            paymentDate: sale.saleDate,
            createdAt: sale.createdAt,
            updatedAt: sale.updatedAt,
          );
          await txn.insert(
            'payments',
            payment.toMap(),
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
      }
    });
  }

  Future<void> insertPayments(List<PaymentModel> payments) async {
    final database = await db;
    final batch = database.batch();
    for (final payment in payments) {
      batch.insert(
        'payments',
        payment.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> insertSalespersonProfile(Map<String, dynamic> profile) async {
    final database = await db;
    await _ensureSalespersonProfileColumns(database);
    await database.insert(
      'salesperson_profile',
      profile,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getSalespersonProfile() async {
    final database = await db;
    await _ensureSalespersonProfileColumns(database);
    final rows = await database.query('salesperson_profile', limit: 1);
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<void> _ensureSalespersonProfileColumns(Database database) async {
    final columns = await database.rawQuery('PRAGMA table_info(salesperson_profile)');
    final existing = columns.map((column) => column['name'] as String).toSet();
    final requiredColumns = {
      'business_name': 'TEXT',
      'currency': 'TEXT',
      'receipt_footer': 'TEXT',
    };

    for (final entry in requiredColumns.entries) {
      if (!existing.contains(entry.key)) {
        await database.execute(
          'ALTER TABLE salesperson_profile ADD COLUMN ${entry.key} ${entry.value}',
        );
      }
    }
  }

  Future<void> insertInventoryReturn(Map<String, dynamic> data) async {
    final database = await db;
    await database.transaction((txn) async {
      await txn.insert(
        'inventory_returns',
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await txn.rawUpdate(
        '''
        UPDATE salesperson_inventory
        SET quantity_returned = quantity_returned + ?,
            remaining_quantity = remaining_quantity - ?,
            updated_at = ?
        WHERE product_id = ? AND variant_id = ?
        ''',
        [
          data['quantity_returned'],
          data['quantity_returned'],
          DateTime.now().toIso8601String(),
          data['product_id'],
          data['variant_id'],
        ],
      );
    });
  }
}
