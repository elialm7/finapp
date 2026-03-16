// lib/features/transactions/presentation/screens/transaction_form_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../../domain/models/transaction_model.dart';
import '../../data/dtos/transaction_dto.dart';
import '../../../accounts/presentation/providers/account_provider.dart';
import '../../../categories/data/repositories/category_repository.dart';
import '../../../categories/domain/models/category_model.dart';
import '../../../contacts/data/repositories/contact_repository.dart';
import '../../../contacts/domain/models/contact_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_button.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
  const TransactionFormScreen({super.key});

  @override
  ConsumerState<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();

  MovementType _type = MovementType.expense;
  String? _selectedAccountId;
  String? _selectedDestinationAccountId;
  String? _selectedContactId;
  String? _selectedCategoryId;
  String? _newCategoryName;
  DateTime _date = DateTime.now();
  bool _isLoading = false;
  bool _useContact = false; // toggle for transfer: account vs contact

  List<Category> _categories = [];
  List<Contact> _contacts = [];
  List<String> _categorySuggestions = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadContacts();
  }

  Future<void> _loadCategories() async {
    final repo = ref.read(categoryRepositoryProvider);
    final cats = await repo.getAll();
    if (mounted) setState(() => _categories = cats);
  }

  Future<void> _loadContacts() async {
    final repo = ref.read(contactRepositoryProvider);
    final contacts = await repo.getAll();
    if (mounted) setState(() => _contacts = contacts);
  }

  void _onCategoryChanged(String value) {
    setState(() {
      _categoryCtrl.text = value;
      _newCategoryName = value.trim().isEmpty ? null : value.trim();
      _selectedCategoryId = null;

      // Filter suggestions
      if (value.isNotEmpty) {
        _categorySuggestions = _categories
            .where((c) =>
                c.type.apiValue == _type.apiValue &&
                c.name.toLowerCase().contains(value.toLowerCase()))
            .map((c) => c.name)
            .toList();
      } else {
        _categorySuggestions = [];
      }
    });
  }

  void _selectCategory(Category cat) {
    setState(() {
      _selectedCategoryId = cat.id;
      _newCategoryName = null;
      _categoryCtrl.text = cat.name;
      _categorySuggestions = [];
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una cuenta de origen')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final dto = TransactionRequestDto(
        accountId: _selectedAccountId!,
        destinationAccountId: _type == MovementType.transfer && !_useContact
            ? _selectedDestinationAccountId
            : null,
        contactId: _type == MovementType.transfer && _useContact
            ? _selectedContactId
            : (_type != MovementType.transfer ? _selectedContactId : null),
        categoryId: _selectedCategoryId,
        newCategoryName: _selectedCategoryId == null ? _newCategoryName : null,
        amount: double.parse(_amountCtrl.text.replaceAll(',', '.')),
        type: _type.apiValue,
        description: _descriptionCtrl.text.trim().isEmpty ? null : _descriptionCtrl.text.trim(),
        transactionDate: AppDateUtils.toIso(_date),
      );

      await ref.read(transactionsProvider.notifier).create(dto, ref);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transacción registrada'),
            backgroundColor: AppTheme.income,
          ),
        );
        context.go('/transactions');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.expense),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descriptionCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);
    final accounts = accountsAsync.value ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Nueva transacción')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type selector
                _SectionLabel('Tipo de movimiento'),
                const SizedBox(height: 8),
                _TypeSelector(
                  selected: _type,
                  onChanged: (t) => setState(() {
                    _type = t;
                    _selectedCategoryId = null;
                    _newCategoryName = null;
                    _categoryCtrl.clear();
                    _categorySuggestions = [];
                  }),
                ),
                const SizedBox(height: 20),

                // Amount
                _SectionLabel('Monto'),
                const SizedBox(height: 8),
                AppTextField(
                  controller: _amountCtrl,
                  label: 'Monto',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requerido';
                    if (double.tryParse(v.replaceAll(',', '.')) == null) return 'Monto inválido';
                    if (double.parse(v.replaceAll(',', '.')) <= 0) return 'Debe ser mayor a 0';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Source account
                _SectionLabel('Cuenta de origen'),
                const SizedBox(height: 8),
                _AccountDropdown(
                  accounts: accounts,
                  value: _selectedAccountId,
                  hint: 'Seleccionar cuenta',
                  onChanged: (v) => setState(() => _selectedAccountId = v),
                ),
                const SizedBox(height: 20),

                // Transfer destination
                if (_type == MovementType.transfer) ...[
                  _SectionLabel('Destino'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Cuenta'),
                        selected: !_useContact,
                        onSelected: (_) => setState(() => _useContact = false),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Persona'),
                        selected: _useContact,
                        onSelected: (_) => setState(() => _useContact = true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (!_useContact)
                    _AccountDropdown(
                      accounts: accounts.where((a) => a.id != _selectedAccountId).toList(),
                      value: _selectedDestinationAccountId,
                      hint: 'Cuenta destino',
                      onChanged: (v) => setState(() => _selectedDestinationAccountId = v),
                    )
                  else
                    _ContactDropdown(
                      contacts: _contacts,
                      value: _selectedContactId,
                      onChanged: (v) => setState(() => _selectedContactId = v),
                    ),
                  const SizedBox(height: 20),
                ],

                // Contact (for income/expense)
                if (_type != MovementType.transfer) ...[
                  _SectionLabel('Persona (opcional)'),
                  const SizedBox(height: 8),
                  _ContactDropdown(
                    contacts: _contacts,
                    value: _selectedContactId,
                    onChanged: (v) => setState(() => _selectedContactId = v),
                  ),
                  const SizedBox(height: 20),
                ],

                // Category (with on-demand creation)
                if (_type != MovementType.transfer) ...[
                  _SectionLabel('Categoría (se crea automáticamente si es nueva)'),
                  const SizedBox(height: 8),
                  Column(
                    children: [
                      TextFormField(
                        controller: _categoryCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Categoría',
                          hintText: 'Escribe o elige una categoría...',
                          suffixIcon: Icon(Icons.category_outlined),
                        ),
                        onChanged: _onCategoryChanged,
                      ),
                      if (_categorySuggestions.isNotEmpty)
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.border),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: _categorySuggestions.map((name) {
                              final cat = _categories.firstWhere((c) => c.name == name);
                              return ListTile(
                                dense: true,
                                title: Text(name),
                                onTap: () => _selectCategory(cat),
                              );
                            }).toList(),
                          ),
                        ),
                      if (_newCategoryName != null && _selectedCategoryId == null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              const Icon(Icons.add_circle_outline, size: 16, color: AppTheme.income),
                              const SizedBox(width: 6),
                              Text(
                                'Se creará la categoría "$_newCategoryName"',
                                style: const TextStyle(fontSize: 12, color: AppTheme.income),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],

                // Description
                _SectionLabel('Descripción (opcional)'),
                const SizedBox(height: 8),
                AppTextField(
                  controller: _descriptionCtrl,
                  label: 'Descripción',
                  maxLines: 2,
                ),
                const SizedBox(height: 20),

                // Date
                _SectionLabel('Fecha'),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      border: Border.all(color: AppTheme.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 18, color: AppTheme.textSecondary),
                        const SizedBox(width: 10),
                        Text(
                          AppDateUtils.formatDate(_date),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                AppButton(
                  label: 'Registrar transacción',
                  isLoading: _isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppTheme.textSecondary,
      letterSpacing: 0.3,
    ),
  );
}

class _TypeSelector extends StatelessWidget {
  final MovementType selected;
  final ValueChanged<MovementType> onChanged;
  const _TypeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: MovementType.values.map((t) {
        final isSelected = t == selected;
        Color color;
        switch (t) {
          case MovementType.income: color = AppTheme.income;
          case MovementType.expense: color = AppTheme.expense;
          case MovementType.transfer: color = AppTheme.transfer;
        }
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(t),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.15) : AppTheme.background,
                border: Border.all(color: isSelected ? color : AppTheme.border, width: isSelected ? 2 : 1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    t == MovementType.income
                        ? Icons.arrow_downward_rounded
                        : t == MovementType.expense
                            ? Icons.arrow_upward_rounded
                            : Icons.swap_horiz_rounded,
                    color: isSelected ? color : AppTheme.textSecondary,
                    size: 22,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                      color: isSelected ? color : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _AccountDropdown extends StatelessWidget {
  final List accounts;
  final String? value;
  final String hint;
  final ValueChanged<String?> onChanged;
  const _AccountDropdown({required this.accounts, this.value, required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      hint: Text(hint),
      decoration: const InputDecoration(),
      items: accounts.map<DropdownMenuItem<String>>((a) => DropdownMenuItem(
        value: a.id as String,
        child: Text(a.name as String),
      )).toList(),
      onChanged: onChanged,
    );
  }
}

class _ContactDropdown extends StatelessWidget {
  final List<Contact> contacts;
  final String? value;
  final ValueChanged<String?> onChanged;
  const _ContactDropdown({required this.contacts, this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      hint: const Text('Seleccionar persona'),
      decoration: const InputDecoration(),
      items: [
        const DropdownMenuItem(value: null, child: Text('Ninguna')),
        ...contacts.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
      ],
      onChanged: onChanged,
    );
  }
}
