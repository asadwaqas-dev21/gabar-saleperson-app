import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDatabase {
  LocalDatabase._privateConstructor();
  static final LocalDatabase instance = LocalDatabase._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String dbPath = await getDatabasesPath();
    String path = join(dbPath, 'detertrack_local.db');

    return await openDatabase(
      path,
      version: 7,
      onCreate: _onCreate,
      onConfigure: _onConfigure,
      onUpgrade: _onUpgrade,
      onOpen: _onOpen,
    );
  }

  Future<void> _onConfigure(Database db) async {
    // Foreign keys are turned OFF by default in SQLite.
    // We keep them OFF because partial data syncs (like syncing customers whose villages were deleted on the server) 
    // will cause FOREIGN KEY constraint failures and break the sync process.
    await db.execute('PRAGMA foreign_keys = OFF');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 6) {
      await db.execute('DROP TABLE IF EXISTS inventory_returns');
      await db.execute('DROP TABLE IF EXISTS receipts');
      await db.execute('DROP TABLE IF EXISTS payments');
      await db.execute('DROP TABLE IF EXISTS sale_items');
      await db.execute('DROP TABLE IF EXISTS sales');
      await db.execute('DROP TABLE IF EXISTS salesperson_inventory');
      await db.execute('DROP TABLE IF EXISTS product_variants');
      await db.execute('DROP TABLE IF EXISTS products');
      await db.execute('DROP TABLE IF EXISTS customers');
      await db.execute('DROP TABLE IF EXISTS villages');
      await db.execute('DROP TABLE IF EXISTS salesperson_profile');
      await db.execute('DROP TABLE IF EXISTS app_meta');
      await _onCreate(db, newVersion);
    }

    await _runNonDestructiveMigrations(db);
  }

  Future<void> _onOpen(Database db) async {
    await _runNonDestructiveMigrations(db);
  }

  Future<void> _runNonDestructiveMigrations(Database db) async {
    await _ensureColumns(
      db,
      tableName: 'salesperson_profile',
      columns: const {
        'profile_pic_url': 'TEXT',
        'business_name': 'TEXT',
        'currency': 'TEXT',
        'receipt_footer': 'TEXT',
      },
    );
    await _ensureColumns(
      db,
      tableName: 'villages',
      columns: const {'sync_error': 'TEXT'},
    );
    await _ensureColumns(
      db,
      tableName: 'customers',
      columns: const {'sync_error': 'TEXT'},
    );
    await _ensureColumns(
      db,
      tableName: 'salesperson_inventory',
      columns: const {'updated_at': 'TEXT'},
    );
    await _ensureColumns(
      db,
      tableName: 'sales',
      columns: const {'sync_error': 'TEXT'},
    );
    await _ensureColumns(
      db,
      tableName: 'payments',
      columns: const {'sync_error': 'TEXT', 'updated_at': 'TEXT'},
    );
    await _ensureColumns(
      db,
      tableName: 'sale_items',
      columns: const {
        'sync_status': "TEXT NOT NULL DEFAULT 'pending_sync'",
        'sync_error': 'TEXT',
        'updated_at': 'TEXT',
      },
    );
  }

  Future<void> _ensureColumns(
    Database db, {
    required String tableName,
    required Map<String, String> columns,
  }) async {
    final tableInfo = await db.rawQuery('PRAGMA table_info($tableName)');
    if (tableInfo.isEmpty) return;

    final existing = tableInfo
        .map((column) => column['name'] as String)
        .toSet();
    for (final entry in columns.entries) {
      if (!existing.contains(entry.key)) {
        await db.execute(
          'ALTER TABLE $tableName ADD COLUMN ${entry.key} ${entry.value}',
        );
      }
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // In a real app we might bundle the SQL string directly.
    // For this implementation, we will use a hardcoded version of the essential tables
    // or load it from assets. Since loading from file system during runtime on device
    // requires the file to be in assets, let's just define the key tables here
    // to guarantee it runs perfectly without asset configuration issues.

    final schema = '''
      CREATE TABLE IF NOT EXISTS app_meta (
        key TEXT PRIMARY KEY,
        value TEXT,
        updated_at TEXT NOT NULL
      );

      CREATE TABLE IF NOT EXISTS salesperson_profile (
        local_id TEXT PRIMARY KEY,
        server_id TEXT,
        business_id TEXT NOT NULL,
        profile_id TEXT,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        cnic TEXT,
        address TEXT,
        profile_pic_url TEXT,
        business_name TEXT,
        currency TEXT,
        receipt_footer TEXT,
        preferred_language TEXT DEFAULT 'english',
        can_send_sms INTEGER NOT NULL DEFAULT 1,
        can_delete_customers INTEGER NOT NULL DEFAULT 0,
        can_use_offline INTEGER NOT NULL DEFAULT 1,
        last_sync_at TEXT,
        updated_at TEXT NOT NULL
      );

      CREATE TABLE IF NOT EXISTS villages (
        local_id TEXT PRIMARY KEY,
        server_id TEXT,
        business_id TEXT NOT NULL,
        salesperson_id TEXT NOT NULL,
        name TEXT NOT NULL,
        notes TEXT,
        status TEXT NOT NULL DEFAULT 'active',
        sync_status TEXT NOT NULL DEFAULT 'synced',
        sync_error TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT
      );

      CREATE TABLE IF NOT EXISTS customers (
        local_id TEXT PRIMARY KEY,
        server_id TEXT,
        business_id TEXT NOT NULL,
        salesperson_id TEXT NOT NULL,
        village_local_id TEXT NOT NULL,
        village_server_id TEXT,
        name TEXT NOT NULL,
        phone TEXT,
        house_number TEXT,
        address TEXT,
        total_sales REAL NOT NULL DEFAULT 0,
        total_paid REAL NOT NULL DEFAULT 0,
        total_pending REAL NOT NULL DEFAULT 0,
        last_purchase_date TEXT,
        last_payment_date TEXT,
        status TEXT NOT NULL DEFAULT 'active',
        notes TEXT,
        sync_status TEXT NOT NULL DEFAULT 'synced',
        sync_error TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        FOREIGN KEY (village_local_id) REFERENCES villages(local_id)
      );

      CREATE TABLE IF NOT EXISTS products (
        id TEXT PRIMARY KEY,
        business_id TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        status TEXT NOT NULL DEFAULT 'active',
        category_id TEXT
      );

      CREATE TABLE IF NOT EXISTS product_variants (
        id TEXT PRIMARY KEY,
        business_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        size_label TEXT NOT NULL,
        unit TEXT NOT NULL DEFAULT 'pcs',
        sku TEXT,
        sale_price REAL NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'active',
        FOREIGN KEY (product_id) REFERENCES products(id)
      );

      CREATE TABLE IF NOT EXISTS salesperson_inventory (
        id TEXT PRIMARY KEY,
        business_id TEXT NOT NULL,
        salesperson_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        variant_id TEXT NOT NULL,
        quantity_received REAL NOT NULL DEFAULT 0,
        quantity_sold REAL NOT NULL DEFAULT 0,
        quantity_returned REAL NOT NULL DEFAULT 0,
        quantity_damaged REAL NOT NULL DEFAULT 0,
        remaining_quantity REAL NOT NULL DEFAULT 0,
        updated_at TEXT,
        FOREIGN KEY (product_id) REFERENCES products(id),
        FOREIGN KEY (variant_id) REFERENCES product_variants(id)
      );

      CREATE TABLE IF NOT EXISTS sales (
        local_id TEXT PRIMARY KEY,
        server_id TEXT,
        business_id TEXT NOT NULL,
        customer_local_id TEXT NOT NULL,
        customer_server_id TEXT,
        salesperson_id TEXT NOT NULL,
        village_local_id TEXT NOT NULL,
        village_server_id TEXT,
        sale_date TEXT NOT NULL,
        previous_pending REAL NOT NULL DEFAULT 0,
        total_amount REAL NOT NULL DEFAULT 0,
        paid_amount REAL NOT NULL DEFAULT 0,
        new_pending REAL NOT NULL DEFAULT 0,
        sale_status TEXT NOT NULL DEFAULT 'completed',
        sync_status TEXT NOT NULL DEFAULT 'pending_sync',
        sync_error TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (customer_local_id) REFERENCES customers(local_id),
        FOREIGN KEY (village_local_id) REFERENCES villages(local_id)
      );

      CREATE TABLE IF NOT EXISTS payments (
        local_id TEXT PRIMARY KEY,
        server_id TEXT,
        business_id TEXT NOT NULL,
        customer_local_id TEXT NOT NULL,
        customer_server_id TEXT,
        village_local_id TEXT NOT NULL,
        salesperson_id TEXT NOT NULL,
        source_sale_local_id TEXT,
        source_sale_server_id TEXT,
        amount REAL NOT NULL,
        payment_date TEXT NOT NULL,
        payment_method TEXT NOT NULL DEFAULT 'cash',
        sync_status TEXT NOT NULL DEFAULT 'pending_sync',
        sync_error TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (customer_local_id) REFERENCES customers(local_id),
        FOREIGN KEY (village_local_id) REFERENCES villages(local_id),
        FOREIGN KEY (source_sale_local_id) REFERENCES sales(local_id)
      );

      CREATE TABLE IF NOT EXISTS sale_items (
        local_id TEXT PRIMARY KEY,
        server_id TEXT,
        sale_local_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        variant_id TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit_price REAL NOT NULL,
        subtotal REAL NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'pending_sync',
        sync_error TEXT,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (sale_local_id) REFERENCES sales(local_id),
        FOREIGN KEY (product_id) REFERENCES products(id),
        FOREIGN KEY (variant_id) REFERENCES product_variants(id)
      );

      CREATE TABLE IF NOT EXISTS inventory_returns (
        local_id TEXT PRIMARY KEY,
        server_id TEXT,
        business_id TEXT NOT NULL,
        salesperson_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        variant_id TEXT NOT NULL,
        quantity_returned REAL NOT NULL,
        return_date TEXT NOT NULL,
        reason TEXT,
        sync_status TEXT NOT NULL DEFAULT 'pending_sync',
        sync_error TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (product_id) REFERENCES products(id),
        FOREIGN KEY (variant_id) REFERENCES product_variants(id)
      );

      CREATE TABLE IF NOT EXISTS receipts (
        local_id TEXT PRIMARY KEY,
        server_id TEXT,
        business_id TEXT NOT NULL,
        salesperson_id TEXT NOT NULL,
        customer_local_id TEXT,
        sale_local_id TEXT,
        payment_local_id TEXT,
        receipt_number TEXT NOT NULL,
        receipt_type TEXT NOT NULL,
        total_amount REAL NOT NULL DEFAULT 0,
        paid_amount REAL NOT NULL DEFAULT 0,
        pending_amount REAL NOT NULL DEFAULT 0,
        sync_status TEXT NOT NULL DEFAULT 'pending_sync',
        sync_error TEXT,
        generated_at TEXT NOT NULL
      );
    ''';

    // Execute statements one by one since sqflite doesn't support executing multiple statements at once easily without splitting
    List<String> statements = schema.split(';');
    for (String statement in statements) {
      if (statement.trim().isNotEmpty) {
        await db.execute(statement);
      }
    }
  }
}
