import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salesperson_app/core/constants/app_colors.dart';
import 'package:salesperson_app/data/models/customer_model.dart';
import 'package:salesperson_app/data/repositories/data_repository.dart';
import 'package:salesperson_app/presentation/widgets/app_button.dart';
import 'package:salesperson_app/presentation/widgets/app_input.dart';
import 'package:salesperson_app/core/utils/receipt_generator.dart';

class AddPaymentPage extends StatefulWidget {
  final CustomerModel customer;

  const AddPaymentPage({super.key, required this.customer});

  @override
  State<AddPaymentPage> createState() => _AddPaymentPageState();
}

class _AddPaymentPageState extends State<AddPaymentPage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _isSaving = false;

  void _savePayment() async {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }
    if (amount > widget.customer.totalPending) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment cannot exceed current pending')),
      );
      return;
    }

    setState(() => _isSaving = true);
    
    final repo = context.read<DataRepository>();
    
    final newPending = (widget.customer.totalPending - amount)
        .clamp(0, double.infinity)
        .toDouble();
    
    try {
      await repo.addPayment(
        customerLocalId: widget.customer.localId,
        villageLocalId: widget.customer.villageId,
        currentPending: widget.customer.totalPending,
        amount: amount,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
      
      try {
        await ReceiptGenerator.generateAndPrintPaymentReceipt(
          customer: widget.customer,
          amount: amount,
          previousPending: widget.customer.totalPending,
          newPending: newPending,
        );
      } catch (e) {
        debugPrint('Error generating receipt: $e');
      }

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Payment', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: AppColors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customer: ${widget.customer.name}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Current Pending: PKR ${widget.customer.totalPending.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 16, color: AppColors.danger, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              const Text(
                'PAYMENT AMOUNT (PKR)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 8),
              AppInput(
                controller: _amountController,
                placeholder: 'e.g. 500',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              const Text(
                'NOTES (OPTIONAL)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 8),
              AppInput(
                controller: _notesController,
                placeholder: 'e.g. Cash collected by Ali',
              ),
              const Spacer(),
              AppButton(
                text: _isSaving ? 'Saving...' : 'Save & Print Receipt',
                isFullWidth: true,
                onPressed: _isSaving ? () {} : _savePayment,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
