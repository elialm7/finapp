// lib/features/categories/presentation/screens/categories_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/category_provider.dart';
import '../../domain/models/category_model.dart';
import '../../../transactions/domain/models/transaction_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_view.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catsAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Categorías')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: catsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.read(categoriesProvider.notifier).load()),
        data: (cats) {
          if (cats.isEmpty) {
            return EmptyState(
              icon: Icons.category_outlined,
              title: 'Sin categorías',
              subtitle: 'Las categorías también se crean automáticamente al registrar una transacción',
              onAction: () => _showDialog(context, ref),
              actionLabel: 'Agregar categoría',
            );
          }

          final expenses = cats.where((c) => c.type == MovementType.expense).toList();
          final income = cats.where((c) => c.type == MovementType.income).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (expenses.isNotEmpty) ...[
                _GroupHeader(label: 'Gastos', color: AppTheme.expense),
                ...expenses.map((c) => _CategoryTile(category: c, onDelete: () => _confirmDelete(context, ref, c))),
                const SizedBox(height: 16),
              ],
              if (income.isNotEmpty) ...[
                _GroupHeader(label: 'Ingresos', color: AppTheme.income),
                ...income.map((c) => _CategoryTile(category: c, onDelete: () => _confirmDelete(context, ref, c))),
              ],
            ],
          );
        },
      ),
    );
  }

  void _showDialog(BuildContext context, WidgetRef ref) {
    showDialog(context: context, builder: (_) => _CategoryDialog(ref: ref));
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Category cat) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar categoría'),
        content: Text('¿Eliminar "${cat.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              ref.read(categoriesProvider.notifier).delete(cat.id);
              Navigator.pop(context);
            },
            child: const Text('Eliminar', style: TextStyle(color: AppTheme.expense)),
          ),
        ],
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  final String label;
  final Color color;
  const _GroupHeader({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 14)),
  );
}

class _CategoryTile extends StatelessWidget {
  final Category category;
  final VoidCallback onDelete;
  const _CategoryTile({required this.category, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final color = category.type == MovementType.income ? AppTheme.income : AppTheme.expense;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(Icons.label_outline, color: color, size: 18),
        ),
        title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: IconButton(icon: const Icon(Icons.delete_outline, color: AppTheme.textSecondary), onPressed: onDelete),
      ),
    );
  }
}

class _CategoryDialog extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const _CategoryDialog({required this.ref});

  @override
  ConsumerState<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends ConsumerState<_CategoryDialog> {
  final _nameCtrl = TextEditingController();
  String _type = 'EXPENSE';
  bool _isLoading = false;

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await widget.ref.read(categoriesProvider.notifier).create(_nameCtrl.text.trim(), _type);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nueva categoría'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Nombre'),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _type,
            decoration: const InputDecoration(labelText: 'Tipo'),
            items: const [
              DropdownMenuItem(value: 'EXPENSE', child: Text('Gasto')),
              DropdownMenuItem(value: 'INCOME', child: Text('Ingreso')),
            ],
            onChanged: (v) => setState(() => _type = v!),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Guardar'),
        ),
      ],
    );
  }
}
