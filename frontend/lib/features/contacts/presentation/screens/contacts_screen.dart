// lib/features/contacts/presentation/screens/contacts_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/contact_provider.dart';
import '../../domain/models/contact_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_view.dart';

class ContactsScreen extends ConsumerWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsAsync = ref.watch(contactsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Contactos')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: contactsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.read(contactsProvider.notifier).load()),
        data: (contacts) {
          if (contacts.isEmpty) {
            return EmptyState(
              icon: Icons.people_outline,
              title: 'Sin contactos',
              subtitle: 'Agrega personas para registrar transferencias',
              onAction: () => _showDialog(context, ref),
              actionLabel: 'Agregar contacto',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: contacts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _ContactCard(
              contact: contacts[i],
              onEdit: () => _showDialog(context, ref, contact: contacts[i]),
              onDelete: () => _confirmDelete(context, ref, contacts[i]),
            ),
          );
        },
      ),
    );
  }

  void _showDialog(BuildContext context, WidgetRef ref, {Contact? contact}) {
    showDialog(context: context, builder: (_) => _ContactDialog(contact: contact, ref: ref));
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Contact c) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar contacto'),
        content: Text('¿Eliminar a "${c.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              ref.read(contactsProvider.notifier).delete(c.id);
              Navigator.pop(context);
            },
            child: const Text('Eliminar', style: TextStyle(color: AppTheme.expense)),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final Contact contact;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _ContactCard({required this.contact, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primary.withOpacity(0.12),
          child: Text(
            contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
            style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(contact.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: contact.description != null ? Text(contact.description!) : null,
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

class _ContactDialog extends ConsumerStatefulWidget {
  final Contact? contact;
  final WidgetRef ref;
  const _ContactDialog({this.contact, required this.ref});

  @override
  ConsumerState<_ContactDialog> createState() => _ContactDialogState();
}

class _ContactDialogState extends ConsumerState<_ContactDialog> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.contact != null) {
      _nameCtrl.text = widget.contact!.name;
      _descCtrl.text = widget.contact!.description ?? '';
    }
  }

  @override
  void dispose() { _nameCtrl.dispose(); _descCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final desc = _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim();
      if (widget.contact == null) {
        await widget.ref.read(contactsProvider.notifier).create(_nameCtrl.text.trim(), desc);
      } else {
        await widget.ref.read(contactsProvider.notifier).update(widget.contact!.id, _nameCtrl.text.trim(), desc);
      }
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
      title: Text(widget.contact == null ? 'Nuevo contacto' : 'Editar contacto'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Nombre'), autofocus: true),
          const SizedBox(height: 12),
          TextFormField(controller: _descCtrl, decoration: const InputDecoration(labelText: 'Descripción (opcional)')),
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
