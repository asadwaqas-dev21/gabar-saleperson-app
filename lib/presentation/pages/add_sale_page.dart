import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salesperson_app/core/constants/app_colors.dart';
import 'package:salesperson_app/presentation/widgets/app_input.dart';
import 'package:salesperson_app/presentation/widgets/app_button.dart';
import 'package:salesperson_app/data/models/customer_model.dart';
import 'package:salesperson_app/data/repositories/data_repository.dart';
import 'package:salesperson_app/core/utils/receipt_generator.dart';

class AddSalePage extends StatefulWidget {
  final CustomerModel? customer;

  const AddSalePage({super.key, this.customer});

  @override
  State<AddSalePage> createState() => _AddSalePageState();
}

class _AddSalePageState extends State<AddSalePage> {
  final TextEditingController _qtyController = TextEditingController(text: '1');
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _paidController = TextEditingController();

  List<Map<String, dynamic>> _inventory = [];
  Map<String, dynamic>? _selectedInventory;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInventory();

    _qtyController.addListener(_onInputChanged);
    _priceController.addListener(_onInputChanged);
    _paidController.addListener(_onInputChanged);
  }

  Future<void> _loadInventory() async {
    final inv = await context
        .read<DataRepository>()
        .localDataSource
        .getJoinedInventory();
    setState(() {
      _inventory = inv;
      if (_inventory.isNotEmpty) {
        _selectedInventory = _inventory.first;
        _priceController.text =
            ((_selectedInventory!['sale_price'] ?? 0) as num)
                .toStringAsFixed(0);
      }
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _priceController.dispose();
    _paidController.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    setState(() {}); // Trigger rebuild to update totals
  }

  double get _qty => double.tryParse(_qtyController.text) ?? 0;
  double get _price => double.tryParse(_priceController.text) ?? 0;
  double get _totalSale => _qty * _price;
  double get _paid => double.tryParse(_paidController.text) ?? 0;
  double get _prevDue => widget.customer?.totalPending ?? 0;
  double get _finalDue => _prevDue + _totalSale - _paid;

  Future<void> _saveSale() async {
    if (widget.customer == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No customer selected')));
      return;
    }

    if (_selectedInventory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a product from inventory')),
      );
      return;
    }

    if (_qty <= 0 || _price <= 0 || _paid < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid quantity, price and paid amount')),
      );
      return;
    }

    if (_paid > _prevDue + _totalSale) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paid amount cannot exceed total payable')),
      );
      return;
    }

    final remaining = (_selectedInventory!['remaining_quantity'] ?? 0) as num;
    if (_qty > remaining.toDouble()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough inventory available!')),
      );
      return;
    }

    try {
      final item = {
        'product_id': _selectedInventory!['product_id'],
        'variant_id': _selectedInventory!['variant_id'],
        'quantity': _qty,
        'unit_price': _price,
        'subtotal': _totalSale,
      };

      await context.read<DataRepository>().addSale(
        customerLocalId: widget.customer!.localId,
        villageLocalId: widget.customer!.villageId,
        totalAmount: _totalSale,
        paidAmount: _paid,
        previousPending: _prevDue,
        items: [item],
      );

      try {
        item['product_name'] =
            _selectedInventory!['product_name']; // ensure name is there for receipt
        await ReceiptGenerator.generateAndPrintSaleReceipt(
          customer: widget.customer!,
          totalAmount: _totalSale,
          paidAmount: _paid,
          previousPending: _prevDue,
          newPending: _finalDue,
          items: [item],
        );
      } catch (e) {
        debugPrint('Error generating receipt: $e');
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'New Transaction',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.muted,
                            ),
                          ),
                          Text(
                            'Add Sale',
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warningLight,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.warningBorder),
                    ),
                    child: const Text(
                      'Offline',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_isLoading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      const Text(
                        'CUSTOMER',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          border: Border.all(color: AppColors.line),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              widget.customer?.name ?? 'Select Customer',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const Icon(Icons.person, color: AppColors.muted),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      const Text(
                        'PRODUCT DETAILS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 8),

                      if (_inventory.isEmpty)
                        const Text(
                          'No inventory available.',
                          style: TextStyle(color: AppColors.danger),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            border: Border.all(color: AppColors.line),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _selectedInventory?['id'] as String?,
                              items: _inventory.map((inv) {
                                return DropdownMenuItem<String>(
                                  value: inv['id'] as String?,
                                  child: Text(
                                    '${inv['product_name']} (${inv['size_label']} ${inv['unit']}) - Left: ${(inv['remaining_quantity'] as num).toInt()}',
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedInventory = _inventory.firstWhere(
                                    (item) => item['id'] == val,
                                  );
                                  _priceController.text =
                                      ((_selectedInventory!['sale_price'] ?? 0)
                                              as num)
                                          .toStringAsFixed(0);
                                });
                              },
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'QUANTITY',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.muted,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                AppInput(
                                  controller: _qtyController,
                                  placeholder: '1',
                                  keyboardType: TextInputType.number,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'UNIT PRICE (PKR)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.muted,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                AppInput(
                                  controller: _priceController,
                                  placeholder: 'e.g. 180',
                                  keyboardType: TextInputType.number,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Summary Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          border: Border.all(color: AppColors.line),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total Sale',
                                  style: TextStyle(
                                    color: AppColors.muted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'PKR ${_totalSale.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Previous Due',
                                  style: TextStyle(
                                    color: AppColors.muted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'PKR ${_prevDue.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    color: AppColors.warning,
                                  ),
                                ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12.0),
                              child: Divider(color: AppColors.line, height: 1),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Grand Total',
                                  style: TextStyle(
                                    color: AppColors.ink,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  'PKR ${(_prevDue + _totalSale).toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                      const Text(
                        'PAYMENT',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      AppInput(
                        controller: _paidController,
                        placeholder: 'Paid Amount (PKR)',
                        keyboardType: TextInputType.number,
                      ),

                      const SizedBox(height: 24),
                      // Final Due
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.brand.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.brand.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'New Pending',
                              style: TextStyle(
                                color: AppColors.brand,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              'PKR ${_finalDue.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                color: AppColors.brand,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),
                      AppButton(
                        text: 'Save & Print Receipt',
                        isFullWidth: true,
                        onPressed: _saveSale,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
