// lib/screens/volunteer/add_stock_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/inventory_item_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../widgets/common/app_error_widget.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/common/relief_button.dart';

class AddStockScreen extends StatefulWidget {
  final String centerId;
  const AddStockScreen({super.key, required this.centerId});
  @override
  State<AddStockScreen> createState() => _AddStockScreenState();
}

class _AddStockScreenState extends State<AddStockScreen> {
  // ── FIX: use itemId String as dropdown value, NOT the model object. ──────
  // When the inventory stream re-emits after addStock(), it creates brand-new
  // InventoryItemModel instances. InventoryItemModel doesn't override == so
  // old-instance != new-instance → DropdownButton assertion fires.
  // A String itemId is always stable across stream re-emissions.
  String? _selectedItemId;

  final _amountCtrl = TextEditingController();
  String? _amountError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ip = context.read<InventoryProvider>();
      if (ip.items.isEmpty) ip.listenToInventory(widget.centerId);
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  /// Resolve the selected model from the current items list using the stable ID.
  /// Returns null if no item is selected or items haven't loaded yet.
  InventoryItemModel? _selectedItem(List<InventoryItemModel> items) {
    if (_selectedItemId == null) return null;
    try {
      return items.firstWhere((i) => i.itemId == _selectedItemId);
    } catch (_) {
      return null; // item no longer in list (shouldn't happen in Phase 1)
    }
  }

  void _validate() {
    final text = _amountCtrl.text.trim();
    if (text.isEmpty) {
      setState(() => _amountError = 'Amount is required.');
      return;
    }
    final v = double.tryParse(text);
    if (v == null || v <= 0) {
      setState(() => _amountError = 'Enter a valid amount greater than 0.');
    } else {
      setState(() => _amountError = null);
    }
  }

  Future<void> _addStock() async {
    _validate();
    if (_amountError != null) return;

    final ip = context.read<InventoryProvider>();
    final item = _selectedItem(ip.items);
    if (item == null) return;

    final amount = double.parse(_amountCtrl.text.trim());
    final uid = context.read<AuthProvider>().currentUser?.uid ?? '';

    final ok = await ip.addStock(
      centerId: widget.centerId,
      itemId: item.itemId,
      amount: amount,
      performedByUid: uid,
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          '+$amount ${item.unit} ${item.itemName} added successfully.',
        ),
        backgroundColor: AppColors.success,
      ));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ip = context.watch<InventoryProvider>();
    final currentItem = _selectedItem(ip.items);

    return LoadingOverlay(
      isLoading: ip.isAddingStock,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          title: const Text('Add Stock',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Error banner ────────────────────────────────────────────
              if (ip.error != null) ...[
                AppErrorBanner(message: ip.error!),
                const SizedBox(height: 14),
              ],

              // ── Item selection ──────────────────────────────────────────
              const Text(
                'Select Item',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),

              if (ip.isLoading && ip.items.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: CircularProgressIndicator(
                        color: AppColors.primary, strokeWidth: 2),
                  ),
                )
              else if (ip.items.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: const Center(
                    child: Text('No inventory items found.',
                        style:
                            TextStyle(color: AppColors.textSecondary)),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: DropdownButtonHideUnderline(
                    // ── FIX: value type is String (itemId), not model ──
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedItemId, // stable String ID
                      hint: const Text(
                        'Choose an item',
                        style: TextStyle(color: AppColors.textHint),
                      ),
                      items: ip.items
                          .map((item) => DropdownMenuItem<String>(
                                value: item.itemId, // String key
                                child: Row(
                                  children: [
                                    if (item.isBottleneck) ...[
                                      const Icon(
                                        Icons.warning_amber_outlined,
                                        size: 16,
                                        color: AppColors.error,
                                      ),
                                      const SizedBox(width: 6),
                                    ],
                                    Expanded(
                                      child: Text(
                                        '${item.itemName}'
                                        ' (${item.currentStock % 1 == 0 ? item.currentStock.toInt() : item.currentStock}'
                                        ' ${item.unit})',
                                        style: TextStyle(
                                          color: item.isBottleneck
                                              ? AppColors.error
                                              : AppColors.textPrimary,
                                          fontWeight: item.isBottleneck
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                      onChanged: (id) =>
                          setState(() => _selectedItemId = id),
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              // ── Amount input ────────────────────────────────────────────
              const Text(
                'Amount to Add',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*')),
                      ],
                      onChanged: (_) => _validate(),
                      decoration: InputDecoration(
                        hintText: '0.0',
                        errorText: _amountError,
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.divider),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.divider),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.primary),
                        ),
                      ),
                    ),
                  ),
                  // Unit label — only shown when an item is selected
                  if (currentItem != null) ...[
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: AppColors.divider),
                      ),
                      child: Text(
                        currentItem.unit,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              // ── Selected item info card ─────────────────────────────────
              if (currentItem != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: currentItem.isBottleneck
                        ? AppColors.error.withValues(alpha: 0.06)
                        : AppColors.success.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: currentItem.isBottleneck
                          ? AppColors.error.withValues(alpha: 0.25)
                          : AppColors.success.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        currentItem.isBottleneck
                            ? Icons.warning_amber_outlined
                            : Icons.inventory_2_outlined,
                        size: 18,
                        color: currentItem.isBottleneck
                            ? AppColors.error
                            : AppColors.success,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current stock: '
                            '${currentItem.currentStock % 1 == 0 ? currentItem.currentStock.toInt() : currentItem.currentStock}'
                            ' ${currentItem.unit}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Kit potential: ${currentItem.kitPotential} parcels'
                            '${currentItem.isBottleneck ? ' — BOTTLENECK' : ''}',
                            style: TextStyle(
                              fontSize: 12,
                              color: currentItem.isBottleneck
                                  ? AppColors.error
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // ── Submit button ───────────────────────────────────────────
              ReliefButton(
                label: 'Add Stock',
                onPressed:
                    (_selectedItemId == null || ip.isAddingStock)
                        ? null
                        : _addStock,
                isLoading: ip.isAddingStock,
                icon: Icons.add,
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'Kit potential recalculates automatically after adding stock.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}