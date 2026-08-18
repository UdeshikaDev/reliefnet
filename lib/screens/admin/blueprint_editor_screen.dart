// lib/screens/admin/blueprint_editor_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/enums/user_role.dart';
import '../../models/parcel_blueprint_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/blueprint_provider.dart';

/// Admin-only screen for editing the global parcel blueprint.
///
/// Features:
///   - Loads and displays current blueprint items from [BlueprintProvider]
///   - Allows editing [quantityPerParcel] per item inline
///   - Add new items (name + unit + quantity)
///   - Remove existing items with confirmation
///   - Save via [BlueprintProvider.updateBlueprint]
///
/// Role guard: only [UserRole.admin] may see the editor content.
/// **Navigation in:** Admin panel → `context.go(RouteNames.blueprintEditor)`
class BlueprintEditorScreen extends StatefulWidget {
  const BlueprintEditorScreen({super.key});

  @override
  State<BlueprintEditorScreen> createState() => _BlueprintEditorScreenState();
}

class _BlueprintEditorScreenState extends State<BlueprintEditorScreen> {
  late final BlueprintProvider _blueprintProvider;

  // Local editable copy — populated when blueprint loads
  List<_EditableItem> _editableItems = [];
  bool _isDirty = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _blueprintProvider = context.read<BlueprintProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _blueprintProvider.startListening();
    });
  }

  @override
  void dispose() {
    _blueprintProvider.stopListening();
    for (final item in _editableItems) {
      item.dispose();
    }
    super.dispose();
  }

  void _initEditable(List<BlueprintItem> items) {
    if (_initialized) return;
    _editableItems = items
        .map((i) => _EditableItem.fromBlueprintItem(i))
        .toList();
    _initialized = true;
  }

  Future<void> _save() async {
    // Validate all quantities
    for (final item in _editableItems) {
      final qty = double.tryParse(item.qtyController.text.trim());
      if (qty == null || qty <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Invalid quantity for "${item.itemName}". Must be > 0.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    final now = DateTime.now();
    final uid = context.read<AuthProvider>().currentUser?.uid ?? 'admin';

    final updated = ParcelBlueprintModel(
      lastUpdatedByUid: uid,
      lastUpdatedAt: now,
      items: _editableItems.map((e) {
        final qty =
            double.tryParse(e.qtyController.text.trim()) ?? e.originalQty;
        return BlueprintItem(
          itemName: e.itemName,
          unit: e.unit,
          quantityPerParcel: qty,
        );
      }).toList(),
    );

    final ok = await _blueprintProvider.updateBlueprint(updated);
    if (!mounted) return;

    if (ok) {
      setState(() => _isDirty = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Blueprint saved successfully.'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              _blueprintProvider.error ?? 'Could not save blueprint.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _removeItem(int index) {
    showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Item'),
        content: Text(
            'Remove "${_editableItems[index].itemName}" from the blueprint?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Remove',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        setState(() {
          _editableItems[index].dispose();
          _editableItems.removeAt(index);
          _isDirty = true;
        });
      }
    });
  }

  void _addItem() {
    showDialog(
      context: context,
      builder: (_) => _AddItemDialog(),
    ).then((item) {
      if (item != null && item is _EditableItem) {
        setState(() {
          _editableItems.add(item);
          _isDirty = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    if (authProvider.currentUser?.role != UserRole.admin) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          title: const Text('Blueprint Editor'),
        ),
        body: const Center(
          child: Text(
            'Admin access required.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final blueprintProv = context.watch<BlueprintProvider>();

    // Populate editable items once blueprint is loaded
    if (!_initialized && blueprintProv.blueprint != null) {
      _initEditable(blueprintProv.blueprint!.items);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Blueprint Editor'),
        elevation: 0,
        actions: [
          if (_isDirty)
            TextButton(
              onPressed: blueprintProv.isSaving ? null : _save,
              child: blueprintProv.isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        tooltip: 'Add Item',
        child: const Icon(Icons.add),
      ),
      body: blueprintProv.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _editableItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'No items in blueprint.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _addItem,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Add First Item'),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  children: [
                    // Info banner
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.primary.withOpacity(0.2)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: AppColors.primary, size: 18),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Changes apply to all donation centers immediately. '
                              'Existing packed parcels are not retroactively updated.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Column headers
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        children: const [
                          Expanded(
                            flex: 4,
                            child: Text(
                              'ITEM NAME',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 64,
                            child: Text(
                              'QTY',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.6,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(
                            width: 44,
                            child: Text(
                              'UNIT',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.6,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(width: 40),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Divider(height: 1, color: AppColors.divider),

                    // Item rows
                    ...List.generate(_editableItems.length, (i) {
                      final item = _editableItems[i];
                      return _BlueprintEditorRow(
                        item: item,
                        onChanged: () => setState(() => _isDirty = true),
                        onRemove: () => _removeItem(i),
                      );
                    }),
                  ],
                ),
    );
  }
}

// ── Helper classes ────────────────────────────────────────────────────────────

class _EditableItem {
  final String itemName;
  final String unit;
  final double originalQty;
  final TextEditingController qtyController;

  _EditableItem({
    required this.itemName,
    required this.unit,
    required this.originalQty,
    required this.qtyController,
  });

  factory _EditableItem.fromBlueprintItem(BlueprintItem item) {
    final qty = item.quantityPerParcel;
    final display =
        qty == qty.truncate() ? qty.toInt().toString() : qty.toString();
    return _EditableItem(
      itemName: item.itemName,
      unit: item.unit,
      originalQty: item.quantityPerParcel,
      qtyController: TextEditingController(text: display),
    );
  }

  factory _EditableItem.newItem({
    required String itemName,
    required String unit,
    required double qty,
  }) {
    final display = qty == qty.truncate() ? qty.toInt().toString() : qty.toString();
    return _EditableItem(
      itemName: itemName,
      unit: unit,
      originalQty: qty,
      qtyController: TextEditingController(text: display),
    );
  }

  void dispose() => qtyController.dispose();
}

// ── Editor row widget ─────────────────────────────────────────────────────────

class _BlueprintEditorRow extends StatelessWidget {
  final _EditableItem item;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  const _BlueprintEditorRow({
    required this.item,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              // Item name (read-only in Phase 1)
              Expanded(
                flex: 4,
                child: Text(
                  item.itemName,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              // Quantity (editable)
              SizedBox(
                width: 64,
                child: TextFormField(
                  controller: item.qtyController,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide:
                          const BorderSide(color: AppColors.divider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide:
                          const BorderSide(color: AppColors.primary),
                    ),
                  ),
                  onChanged: (_) => onChanged(),
                ),
              ),
              const SizedBox(width: 8),
              // Unit label
              SizedBox(
                width: 36,
                child: Text(
                  item.unit,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 4),
              // Remove button
              SizedBox(
                width: 32,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.remove_circle_outline,
                      color: AppColors.error, size: 20),
                  tooltip: 'Remove',
                  onPressed: onRemove,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.divider),
      ],
    );
  }
}

// ── Add Item Dialog ───────────────────────────────────────────────────────────

class _AddItemDialog extends StatefulWidget {
  @override
  State<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<_AddItemDialog> {
  final _nameController = TextEditingController();
  final _unitController = TextEditingController();
  final _qtyController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  static const _unitOptions = ['kg', 'g', 'L', 'ml', 'units', 'pcs'];
  String _selectedUnit = 'kg';

  @override
  void dispose() {
    _nameController.dispose();
    _unitController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Blueprint Item'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Item Name',
                hintText: 'e.g. Canned Fish',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _qtyController,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Qty per parcel',
                    ),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      return (n == null || n <= 0) ? 'Must be > 0' : null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 90,
                  child: DropdownButtonFormField<String>(
                    value: _selectedUnit,
                    decoration: const InputDecoration(labelText: 'Unit'),
                    items: _unitOptions
                        .map((u) => DropdownMenuItem(
                              value: u,
                              child: Text(u),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedUnit = v ?? 'kg'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.pop(
                context,
                _EditableItem.newItem(
                  itemName: _nameController.text.trim(),
                  unit: _selectedUnit,
                  qty: double.parse(_qtyController.text.trim()),
                ),
              );
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}