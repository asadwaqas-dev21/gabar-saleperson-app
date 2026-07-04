import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:salesperson_app/core/constants/app_colors.dart';
import 'package:salesperson_app/core/database/sqlite_database.dart';
import 'package:google_fonts/google_fonts.dart';

// Setup routing or direct to login page for now
import 'package:salesperson_app/presentation/pages/login_page.dart';
import 'package:salesperson_app/presentation/pages/main_layout.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salesperson_app/data/repositories/data_repository.dart';
import 'package:salesperson_app/data/datasources/local_data_source.dart';
import 'package:salesperson_app/data/datasources/remote_data_source.dart';
import 'package:salesperson_app/core/sync/sync_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://qlukwajfhzwvhslbxiuc.supabase.co',
    publishableKey: 'sb_publishable_RqMLnlyC-zJZ8kYAtQq_yw_lKgLFuu3',
  );

  // Initialize SQLite local database
  await LocalDatabase.instance.database;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localDataSource = LocalDataSource();
    final remoteDataSource = RemoteDataSource();
    final dataRepository = DataRepository(
      localDataSource: localDataSource,
      remoteDataSource: remoteDataSource,
    );
    final syncManager = SyncManager(
      localDataSource: localDataSource,
      remoteDataSource: remoteDataSource,
    );

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<DataRepository>.value(value: dataRepository),
        RepositoryProvider<SyncManager>.value(value: syncManager),
      ],
      child: MaterialApp(
        title: 'Gabar Production Salesperson',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor: AppColors.surface,
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.brand),
          textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
          useMaterial3: true,
        ),
        home: Supabase.instance.client.auth.currentSession != null
            ? const MainLayout()
            : const LoginPage(),
      ),
    );
  }
}
