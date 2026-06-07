import 'package:flutter/material.dart';

import '../models/chemical.dart';
import '../models/enums.dart';
import '../services/app_state.dart';
import '../widgets/empty_state.dart';
import '../widgets/info_row.dart';
import '../widgets/latente_card.dart';
import '../widgets/latente_list_view.dart';
import '../widgets/section_title.dart';

class ChemicalArchiveScreen extends StatelessWidget {
  const ChemicalArchiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = LatenteScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Archivio chimici')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Chimico'),
      ),
      body: appState.chemicals.isEmpty
          ? const SafeArea(
              child: EmptyState(
                title: 'Nessun chimico',
                message: 'Aggiungi rivelatori, arresto, fissaggio o imbibente.',
              ),
            )
          : LatenteListView(
              children: [
                const SectionTitle(
                  title: 'Chimici',
                  subtitle: 'Diluizioni e regole di riutilizzo.',
                ),
                for (final chemical in appState.chemicals)
                  LatenteCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                chemical.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Modifica',
                              onPressed: () => _openForm(context, chemical),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              tooltip: 'Elimina',
                              onPressed: () => _delete(context, chemical),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                        const Divider(),
                        InfoRow(label: 'Tipo', value: chemical.type.label),
                        if (chemical.description.trim().isNotEmpty)
                          InfoRow(
                            label: 'Descrizione',
                            value: chemical.description,
                          ),
                        InfoRow(
                          label: 'Diluizioni',
                          value: chemical.dilutions.join(', '),
                        ),
                        InfoRow(
                          label: 'One-shot',
                          value: chemical.oneShot ? 'Sì' : 'No',
                        ),
                        InfoRow(
                          label: 'Utilizzi massimi',
                          value:
                              chemical.maxUses?.toString() ?? 'Non impostato',
                        ),
                        InfoRow(
                            label: 'Regola usura',
                            value: chemical.wearRule.label),
                        if (chemical.wearRule != WearRule.none)
                          InfoRow(
                            label: 'Incremento',
                            value: '${chemical.wearIncrement} per utilizzo',
                          ),
                        if (chemical.preparationSteps.isNotEmpty) ...[
                          const Divider(),
                          Text(
                            'Preparazione stock',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 6),
                          for (final step in chemical.preparationSteps)
                            Text('- $step'),
                        ],
                        if (chemical.capacityNotes.isNotEmpty) ...[
                          const Divider(),
                          Text(
                            'Capacita',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 6),
                          for (final note in chemical.capacityNotes)
                            Text('- $note'),
                        ],
                        if (chemical.notes.isNotEmpty) ...[
                          const Divider(),
                          Text(
                            'Note operative',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 6),
                          for (final note in chemical.notes) Text('- $note'),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  void _openForm(BuildContext context, [Chemical? chemical]) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ChemicalFormScreen(chemical: chemical)),
    );
  }

  Future<void> _delete(BuildContext context, Chemical chemical) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminare chimico?'),
        content: Text(
          'Eliminando ${chemical.name} verranno rimosse anche le ricette collegate.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await LatenteScope.of(context).deleteChemical(chemical.id);
    }
  }
}

class ChemicalFormScreen extends StatefulWidget {
  const ChemicalFormScreen({this.chemical, super.key});

  final Chemical? chemical;

  @override
  State<ChemicalFormScreen> createState() => _ChemicalFormScreenState();
}

class _ChemicalFormScreenState extends State<ChemicalFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _dilutionsController;
  late final TextEditingController _maxUsesController;
  late final TextEditingController _wearIncrementController;
  late ChemicalType _type;
  late bool _oneShot;
  late WearRule _wearRule;

  @override
  void initState() {
    super.initState();
    final chemical = widget.chemical;
    _nameController = TextEditingController(text: chemical?.name ?? '');
    _dilutionsController = TextEditingController(
      text: chemical?.dilutions.join(', ') ?? '',
    );
    _maxUsesController = TextEditingController(
      text: chemical?.maxUses?.toString() ?? '',
    );
    _wearIncrementController = TextEditingController(
      text: (chemical?.wearIncrement ?? 1).toString(),
    );
    _type = chemical?.type ?? ChemicalType.developer;
    _oneShot = chemical?.oneShot ?? false;
    _wearRule = chemical?.wearRule ?? WearRule.addMinutesPerPreviousUse;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dilutionsController.dispose();
    _maxUsesController.dispose();
    _wearIncrementController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.chemical != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifica chimico' : 'Nuovo chimico'),
      ),
      body: Form(
        key: _formKey,
        child: LatenteListView(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nome'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ChemicalType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: ChemicalType.values
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(type.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _type = value);
                }
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _dilutionsController,
              decoration: const InputDecoration(
                labelText: 'Diluizioni disponibili',
                hintText: 'Esempio: Stock, 1+1, 1+3',
              ),
              validator: _required,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('One-shot'),
              subtitle: const Text('Il bagno viene scartato dopo l’uso'),
              value: _oneShot,
              onChanged: (value) {
                setState(() {
                  _oneShot = value;
                  if (_oneShot) {
                    _wearRule = WearRule.none;
                    _maxUsesController.text = '1';
                  } else {
                    _wearRule = WearRule.addMinutesPerPreviousUse;
                    if (_wearIncrementController.text.trim().isEmpty) {
                      _wearIncrementController.text = '1';
                    }
                  }
                });
              },
            ),
            TextFormField(
              controller: _maxUsesController,
              decoration: const InputDecoration(
                labelText: 'Numero massimo utilizzi',
                hintText: 'Opzionale',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<WearRule>(
              initialValue: _wearRule,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Regola usura'),
              items: WearRule.values
                  .map(
                    (rule) => DropdownMenuItem(
                      value: rule,
                      child: Text(
                        rule.label,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _wearRule = value);
                }
              },
            ),
            const SizedBox(height: 6),
            Text(
              _wearRuleHelp(_wearRule),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (_wearRule != WearRule.none) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _wearIncrementController,
                decoration: InputDecoration(
                  labelText: _wearRule == WearRule.addMinutesPerPreviousUse
                      ? 'Minuti aggiunti per utilizzo'
                      : 'Secondi aggiunti per utilizzo',
                  hintText: 'Default: 1',
                ),
                keyboardType: TextInputType.number,
                validator: _positiveOrZero,
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Salva chimico'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final chemical = Chemical(
      id: widget.chemical?.id ?? _newId('chemical'),
      name: _nameController.text.trim(),
      type: _type,
      dilutions: _parseList(_dilutionsController.text),
      oneShot: _oneShot,
      maxUses: int.tryParse(_maxUsesController.text.trim()),
      wearRule: _wearRule,
      wearIncrement: int.tryParse(_wearIncrementController.text.trim()) ?? 1,
      description: widget.chemical?.description ?? '',
      preparationSteps: widget.chemical?.preparationSteps ?? const [],
      capacityNotes: widget.chemical?.capacityNotes ?? const [],
      notes: widget.chemical?.notes ?? const [],
    );

    await LatenteScope.of(context).upsertChemical(chemical);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  List<String> _parseList(String value) {
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo obbligatorio';
    }
    return null;
  }

  String? _positiveOrZero(String? value) {
    final number = int.tryParse(value ?? '');
    if (number == null || number < 0) {
      return 'Inserire un numero valido';
    }
    return null;
  }

  String _wearRuleHelp(WearRule rule) {
    switch (rule) {
      case WearRule.none:
        return 'Nessuna correzione automatica legata agli utilizzi precedenti.';
      case WearRule.addSecondsPerPreviousUse:
        return 'Aggiunge secondi al tempo finale per ogni utilizzo precedente del bagno.';
      case WearRule.addMinutesPerPreviousUse:
        return 'Aggiunge minuti al tempo finale per ogni utilizzo precedente del bagno.';
    }
  }

  String _newId(String prefix) {
    return '${prefix}_${DateTime.now().microsecondsSinceEpoch}';
  }
}
