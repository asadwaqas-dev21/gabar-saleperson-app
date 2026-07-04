import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:salesperson_app/core/constants/app_colors.dart';
import 'package:salesperson_app/data/repositories/data_repository.dart';
import 'package:salesperson_app/presentation/pages/login_page.dart';
import 'package:salesperson_app/presentation/widgets/app_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (context.mounted) {
      await context.read<DataRepository>().localDataSource.clearCachedBusinessData();
    }
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: FutureBuilder<Map<String, dynamic>?>(
            future: context.read<DataRepository>().getSalespersonProfile(),
            builder: (context, snapshot) {
              final profile = snapshot.data;
              final name = profile?['name']?.toString() ?? 'Salesperson';
              final profilePicUrl = profile?['profile_pic_url']?.toString();
              final phone = profile?['phone']?.toString() ?? 'Active Account';
              final email = profile?['email']?.toString() ?? '-';
              final cnic = profile?['cnic']?.toString() ?? '-';
              final businessName = profile?['business_name']?.toString() ?? '-';
              final currency = profile?['currency']?.toString() ?? 'PKR';
              final language =
                  profile?['preferred_language']?.toString() ?? 'english';
              final receiptFooter =
                  profile?['receipt_footer']?.toString() ?? '-';
              final canSms = profile?['can_send_sms'] == 1;
              final canOffline = profile?['can_use_offline'] == 1;

              return ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  const SizedBox(height: 20),
                  Center(
                    child: profilePicUrl != null && profilePicUrl.isNotEmpty
                        ? CircleAvatar(
                            radius: 40,
                            backgroundImage: NetworkImage(profilePicUrl),
                            backgroundColor: AppColors.brand.withOpacity(0.1),
                          )
                        : Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppColors.brand.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person, size: 40, color: AppColors.brand),
                          ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      phone,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _infoCard(
                    title: 'Account',
                    rows: [
                      _InfoRow('Email', email),
                      _InfoRow('Phone', phone),
                      _InfoRow('ID Card / CNIC', cnic),
                      _InfoRow('Address', profile?['address']?.toString() ?? '-'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _infoCard(
                    title: 'Business Settings',
                    rows: [
                      _InfoRow('Business', businessName),
                      _InfoRow('Currency', currency),
                      _InfoRow('Language', language),
                      _InfoRow('Receipt Footer', receiptFooter),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _infoCard(
                    title: 'Permissions',
                    rows: [
                      _InfoRow('Offline Mode', canOffline ? 'Allowed' : 'Blocked'),
                      _InfoRow('SMS Reminder', canSms ? 'Allowed' : 'Blocked'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    text: 'Logout',
                    type: ButtonType.light,
                    isFullWidth: true,
                    onPressed: () => _logout(context),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _infoCard({required String title, required List<_InfoRow> rows}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
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
          const SizedBox(height: 12),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 112,
                    child: Text(
                      row.label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      row.value,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);
}
