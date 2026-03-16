// lib/features/accounts/presentation/screens/accounts_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/account_provider.dart';
import '../../domain/models/account_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_view.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);
    final currency = ref.watch(currentCurrencyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Cuentas')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAccountDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: accountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.read(accountsProvider.notifier).load()),
        data: (accounts) {
          if (accounts.isEmpty) {
            return EmptyState(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Sin cuentas',
              subtitle: 'Agrega tu primera cuenta',
              onAction: () => _showAccountDialog(context, ref),
              actionLabel: 'Agregar cuenta',
            );
          }
          // Total balance card
          final total = accounts.fold(0.0, (sum, a) => sum + a.currentBalance);
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _TotalCard(total: total, currency: currency),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _AccountCard(
                      account: accounts[i],
                      currency: currency,
                      onEdit: () => _showAccountDialog(context, ref, account: accounts[i]),
                      onDelete: () => _confirmDelete(context, ref, accounts[i]),
                    ),
                    childCount: accounts.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAccountDialog(BuildContext context, WidgetRef ref, {Account? account}) {
    showDialog(
      context: context,
      builder: (_) => _AccountDialog(account: account, ref: ref),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Account account) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar cuenta'),
        content: Text('¿Eliminar "${account.name}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              ref.read(accountsProvider.notifier).delete(account.id);
              Navigator.pop(context);
            },
            child: const Text('Eliminar', style: TextStyle(color: AppTheme.expense)),
          ),
        ],
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  final double total;
  final String currency;
  const _TotalCard({required this.total, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryLight]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Patrimonio total', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.format(total, currency),
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final Account account;
  final String currency;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _AccountCard({required this.account, required this.currency, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isPositive = account.currentBalance >= 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.account_balance_wallet_outlined, color: AppTheme.primary),
        ),
        title: Text(account.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          CurrencyFormatter.format(account.currentBalance, currency),
          style: TextStyle(
            color: isPositive ? AppTheme.income : AppTheme.expense,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.edit_outlined), onPressed: onEdit),
            IconButton(icon: const Icon(Icons.delete_outline, color: AppTheme.expense), onPressed: onDelete),
          ],
        ),
      ),
    );
  }
}

class _AccountDialog extends ConsumerStatefulWidget {
  final Account? account;
  final WidgetRef ref;
  const _AccountDialog({this.account, required this.ref});

  @override
  ConsumerState<_AccountDialog> createState() => _AccountDialogState();
}

class _AccountDialogState extends ConsumerState<_AccountDialog> {
  final _nameCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.account != null) {
      _nameCtrl.text = widget.account!.name;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      if (widget.account == null) {
        final balance = double.tryParse(_balanceCtrl.text.replaceAll(',', '.')) ?? 0.0;
        await widget.ref.read(accountsProvider.notifier).create(_nameCtrl.text.trim(), balance);
      } else {
        await widget.ref.read(accountsProvider.notifier).update(widget.account!.id, _nameCtrl.text.trim());
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.account == null ? 'Nueva cuenta' : 'Editar cuenta'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nombre'),
              validator: (v) => v?.isEmpty == true ? 'Requerido' : null,
            ),
            if (widget.account == null) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _balanceCtrl,
                decoration: const InputDecoration(labelText: 'Saldo inicial'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Guardar'),
        ),
      ],
    );
  }
}
