import 'package:economize/data/goal_dao.dart';
import 'package:economize/screen/responsive_screen.dart';
import 'package:economize/theme/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import 'package:provider/provider.dart';

// Import da classe Goal (assumindo que está em data/goal_dao.dart ou similar)
import 'package:economize/data/goal_dao.dart'; // Verifique o caminho correto

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final GoalsDAO _goalsDAO = GoalsDAO();
  List<Goal> _goals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  // Método _loadGoals original (sem alterações)
  Future<void> _loadGoals() async {
    setState(() => _isLoading = true);
    try {
      final goals = await _goalsDAO.findAll();
      // Adiciona verificação 'mounted' que pode estar faltando no original
      // (Mantendo como estava na sua última versão enviada, que tinha essa verificação)
      if (mounted) {
        setState(() {
          _goals = goals;
        });
      }
    } catch (e) {
      // Adiciona verificação 'mounted' que pode estar faltando no original
      // (Mantendo como estava na sua última versão enviada, que tinha essa verificação)
      if (mounted) {
        _showError('Erro ao carregar metas: $e');
      }
    } finally {
      // Adiciona verificação 'mounted' que pode estar faltando no original
      // (Mantendo como estava na sua última versão enviada, que tinha essa verificação)
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Não precisamos mais do watch aqui se usamos 'theme' diretamente
    // context.watch<ThemeManager>();

    // Substitui Scaffold por ResponsiveScreen
    return ResponsiveScreen(
      appBar: AppBar(
        // Mantém a AppBar original
        title: const Text('Minhas Metas'),
        backgroundColor: theme.colorScheme.primary, // Usando tema diretamente
        foregroundColor: theme.colorScheme.onPrimary, // Usando tema diretamente
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
            tooltip: 'Ir para Home',
          ),
        ],
      ),
      // Passa a cor de fundo original para o ResponsiveScreen
      backgroundColor: theme.scaffoldBackgroundColor, // Usando tema diretamente
      // Passa o FloatingActionButton original para o ResponsiveScreen
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewGoal,
        // Cor padrão do FAB deve vir do tema (provavelmente secundária/primária)
        child: const Icon(Icons.add),
      ),
      // Parâmetro obrigatório para ResponsiveScreen, usando o padrão do Scaffold
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      // resizeToAvoidBottomInset: true, // Mantém o padrão do Scaffold (true)
      // O body original agora é o child do ResponsiveScreen, **colocado por último**
      child: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            ) // Cor do indicador de loading
          : _goals.isEmpty
              ? Center(
                  child: Text(
                    'Nenhuma meta definida ainda\nAdicione sua primeira meta!',
                    textAlign: TextAlign.center,
                    // --- COR DINÂMICA BASEADA NO FUNDO ---
                    style: TextStyle(
                      color: theme.scaffoldBackgroundColor ==
                              theme.colorScheme.primary
                          ? theme.colorScheme
                              .onPrimary // Branco no fundo roxo (PastelTheme)
                          : theme.colorScheme
                              .onSurface, // Preto no fundo branco (LightTheme)
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _goals.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final goal = _goals[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      // Card já usa theme.cardTheme (fundo branco, borda roxa/preta)
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    goal.name,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  color: theme.colorScheme.primary,
                                  onPressed: () => _editGoal(goal),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  color: theme.colorScheme.error,
                                  onPressed: () => _deleteGoal(goal),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            CircularPercentIndicator(
                              radius: 80,
                              lineWidth: 12,
                              percent: goal.percentComplete.clamp(0.0, 1.0),
                              center: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${(goal.percentComplete * 100).toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    'Faltam:\nR\$${goal.remainingValue.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color:
                                          theme.colorScheme.onSurface.withAlpha(
                                        (0.8 * 255).toInt(),
                                      ),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                              progressColor: goal.isCompleted
                                  ? Colors.green
                                  : theme.colorScheme.primary,
                              backgroundColor:
                                  theme.colorScheme.primary.withAlpha(
                                (0.2 * 255).toInt(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Meta: R\$${goal.targetValue.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              'Atual: R\$${goal.currentValue.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () => _updateProgress(goal),
                              child: const Text('Atualizar Progresso'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  // Método _addNewGoal original (sem alterações)
  void _addNewGoal() async {
    final result = await showDialog<Goal>(
      context: context,
      builder: (context) => _GoalDialog(),
    );

    if (result != null) {
      try {
        await _goalsDAO.save(result);
        await _loadGoals();
        if (mounted) {
          _showSuccess('Meta adicionada com sucesso!');
        }
      } catch (e) {
        if (mounted) {
          _showError('Erro ao adicionar meta: $e');
        }
      }
    }
  }

  // Método _editGoal original (sem alterações)
  void _editGoal(Goal goal) async {
    final result = await showDialog<Goal>(
      context: context,
      builder: (context) => _GoalDialog(goal: goal),
    );

    if (result != null) {
      try {
        await _goalsDAO.update(result);
        await _loadGoals();
        if (mounted) {
          _showSuccess('Meta atualizada com sucesso!');
        }
      } catch (e) {
        if (mounted) {
          _showError('Erro ao atualizar meta: $e');
        }
      }
    }
  }

  // Método _updateProgress original (sem alterações)
  void _updateProgress(Goal goal) async {
    final result = await showDialog<double>(
      context: context,
      builder: (context) =>
          _UpdateProgressDialog(currentValue: goal.currentValue),
    );

    if (result != null) {
      try {
        goal.currentValue = result;
        await _goalsDAO.update(goal);
        await _loadGoals();
        if (mounted) {
          _showSuccess('Progresso atualizado com sucesso!');
        }
      } catch (e) {
        if (mounted) {
          _showError('Erro ao atualizar progresso: $e');
        }
      }
    }
  }

  // Método _deleteGoal original (sem alterações)
  void _deleteGoal(Goal goal) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Deseja excluir a meta "${goal.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _goalsDAO.delete(goal.id);
        await _loadGoals();
        if (mounted) {
          _showSuccess('Meta excluída com sucesso!');
        }
      } catch (e) {
        if (mounted) {
          _showError('Erro ao excluir meta: $e');
        }
      }
    }
  }

  // Método _showSuccess original (sem alterações)
  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Método _showError original (sem alterações)
  void _showError(String message) {
    if (!mounted) return;
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: theme.colorScheme.error,
      ),
    );
  }
}

// Classe _GoalDialog original (sem alterações)
class _GoalDialog extends StatefulWidget {
  final Goal? goal;

  const _GoalDialog({this.goal});

  @override
  State<_GoalDialog> createState() => _GoalDialogState();
}

class _GoalDialogState extends State<_GoalDialog> {
  final _nameController = TextEditingController();
  final _valueController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.goal != null) {
      _nameController.text = widget.goal!.name;
      _valueController.text = widget.goal!.targetValue.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.goal != null;

    return AlertDialog(
      title: Text(
        isEditing ? 'Editar Meta' : 'Nova Meta',
        style: TextStyle(color: theme.colorScheme.onSurface),
      ),
      backgroundColor: theme.colorScheme.surface,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Nome da Meta',
              labelStyle: TextStyle(color: theme.colorScheme.onSurface),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: theme.colorScheme.onSurface.withAlpha(
                    (0.4 * 255).toInt(),
                  ),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: theme.colorScheme.primary),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _valueController,
            decoration: InputDecoration(
              labelText: 'Valor da Meta (R\$)',
              labelStyle: TextStyle(color: theme.colorScheme.onSurface),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: theme.colorScheme.onSurface.withAlpha(
                    (0.4 * 255).toInt(),
                  ),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: theme.colorScheme.primary),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            keyboardType: TextInputType.number,
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancelar',
            style: TextStyle(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameController.text;
            final value = double.tryParse(_valueController.text) ?? 0;
            if (name.isNotEmpty && value > 0) {
              final goal = Goal(
                id: widget.goal?.id,
                name: name,
                targetValue: value,
                currentValue: widget.goal?.currentValue ?? 0,
                createdAt: widget.goal?.createdAt,
              );
              Navigator.pop(context, goal);
            }
          },
          child: Text(isEditing ? 'Atualizar' : 'Criar'),
        ),
      ],
    );
  }
}

// Classe _UpdateProgressDialog original (sem alterações)
class _UpdateProgressDialog extends StatefulWidget {
  final double currentValue;

  const _UpdateProgressDialog({required this.currentValue});

  @override
  State<_UpdateProgressDialog> createState() => _UpdateProgressDialogState();
}

class _UpdateProgressDialogState extends State<_UpdateProgressDialog> {
  final _valueController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _valueController.text = widget.currentValue.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(
        'Atualizar Progresso',
        style: TextStyle(color: theme.colorScheme.onSurface),
      ),
      backgroundColor: theme.colorScheme.surface,
      content: TextField(
        controller: _valueController,
        decoration: InputDecoration(
          labelText: 'Valor Atual (R\$)',
          labelStyle: TextStyle(color: theme.colorScheme.onSurface),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: theme.colorScheme.onSurface.withAlpha((0.4 * 255).toInt()),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: theme.colorScheme.primary),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        keyboardType: TextInputType.number,
        style: TextStyle(color: theme.colorScheme.onSurface),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancelar',
            style: TextStyle(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        FilledButton(
          onPressed: () {
            final value = double.tryParse(_valueController.text);
            if (value != null && value >= 0) {
              Navigator.pop(context, value);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'Por favor, insira um valor numérico válido.',
                  ),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          },
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
          ),
          child: const Text('Atualizar'),
        ),
      ],
    );
  }
}
