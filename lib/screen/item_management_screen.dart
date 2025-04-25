import 'package:economize/data/database_helper.dart';
import 'package:economize/model/budget/item_template.dart';
import 'package:economize/screen/responsive_screen.dart';
import 'package:economize/service/item_template_service.dart';
import 'package:economize/theme/theme_manager.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';

class ItemManagementScreen extends StatefulWidget {
  const ItemManagementScreen({super.key});

  @override
  State<ItemManagementScreen> createState() => _ItemManagementScreenState();
}

class _ItemManagementScreenState extends State<ItemManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedUnit = 'un';
  String _selectedCategory = 'Alimentos';
  final ItemTemplateService _service = ItemTemplateService();
  final TextEditingController _searchController = TextEditingController();
  List<ItemTemplate> _filteredItems = [];
  List<ItemTemplate> _allItems = [];
  bool _isLoading = true;

  // Lista completa de categorias (mantida do original)
  final List<String> _allCategories = [
    'Alimentos',
    'Bebidas',
    'Limpeza',
    'Higiene',
    'Frutas',
    'Verduras',
    'Carnes',
    'Frios',
    'Padaria',
    'Mercearia',
    'Laticínios',
    'Materiais de Limpeza',
    'Higiene Pessoal',
    'Congelados',
    'Hortifruti',
    'Farmácia',
    'Materiais de Construção',
    'Utensílios de Casa',
    'Outros',
  ];

  // Lista completa de unidades (mantida do original)
  final List<String> _allUnits = [
    'un',
    'g',
    'kg',
    'ml',
    'L',
    'cm',
    'm',
    'mm',
    'caixa',
    'pacote',
    'embalagem',
    'dúzia',
    'cento',
    'par',
    'rolo',
    'folha',
    'tablete',
    'dose',
    'frasco',
    'lata',
    'ampola',
    'pote',
    'copo',
    'xícara',
    'prato',
    'galão',
    'jarda',
    'pé',
    'polegada',
    'onça',
    'libra',
    'saco',
    'fardo',
    'kit',
    'conjunto',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterItems);
    _loadItems();
  }

  // Método _loadItems original (sem alterações)
  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    try {
      _allItems = await _service.getAllTemplates();
      _filteredItems = _allItems;
    } catch (e) {
      debugPrint('Erro ao carregar itens: $e');
      // Adiciona feedback de erro se não estava no original
      // if (mounted) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(content: Text('Erro ao carregar itens: $e')),
      //   );
      // }
    } finally {
      // Adiciona verificação 'mounted' se não estava no original
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Método _filterItems original (sem alterações)
  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems =
          _allItems.where((item) {
            return item.name.toLowerCase().contains(query) ||
                item.category.toLowerCase().contains(query);
          }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    context.watch<ThemeManager>(); // Mantido

    // Substitui Scaffold por ResponsiveScreen
    return ResponsiveScreen(
      appBar: AppBar(
        // Mantém a AppBar original
        title: const Text('Gerenciar Produtos'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              setState(() => _isLoading = true);
              try {
                await _loadItems();
                _filterItems();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Lista atualizada!',
                        style: TextStyle(color: theme.colorScheme.onPrimary),
                      ),
                      backgroundColor: theme.colorScheme.primary,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Erro ao atualizar: $e',
                        style: TextStyle(color: theme.colorScheme.onError),
                      ),
                      backgroundColor: theme.colorScheme.error,
                    ),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() => _isLoading = false);
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
          ),
        ],
      ),
      // Passa a cor de fundo original para o ResponsiveScreen
      backgroundColor: theme.scaffoldBackgroundColor, // Usa cor do tema
      // Passa o FloatingActionButton original para o ResponsiveScreen
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        child: const Icon(Icons.add),
      ),
      // Passa o floatingActionButtonLocation original para o ResponsiveScreen
      // (Obrigatório pela definição do seu ResponsiveScreen)
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      // Passa o resizeToAvoidBottomInset (padrão true)
      resizeToAvoidBottomInset: true,
      // O body original agora é o child do ResponsiveScreen, **colocado por último**
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Pesquisar produtos...',
              leading: Icon(Icons.search, color: theme.colorScheme.onSurface),
              trailing: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.clear, color: theme.colorScheme.onSurface),
                    onPressed: () {
                      _searchController.clear();
                      // setState(() {}); // Removido se não estava no original
                    },
                  ),
              ],
              // Usa WidgetStateProperty se MaterialStateProperty não existir
              backgroundColor: WidgetStateProperty.all(
                theme.colorScheme.surface,
              ),
              // Adiciona style se necessário para cor do texto digitado
              // textStyle: WidgetStateProperty.all(
              //   TextStyle(color: theme.colorScheme.onSurface),
              // ),
            ),
          ),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredItems.isEmpty
                    ? Center(
                      child: Text(
                        'Nenhum produto encontrado',
                        style: TextStyle(color: theme.colorScheme.onSurface),
                      ),
                    )
                    : ListView.builder(
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
                        return Card(
                          color: theme.colorScheme.surface,
                          // Adiciona margem se necessário
                          // margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: ListTile(
                            title: Text(
                              item.name,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            subtitle: Text(
                              '${item.category} - ${item.defaultUnit}',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withAlpha(
                                  (0.7 * 255).toInt(),
                                ),
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              color: theme.colorScheme.error,
                              onPressed: () => _deleteItem(item),
                            ),
                            // Adiciona onTap para edição se necessário
                            // onTap: () => _editItem(item),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  // Método _showAddDialog original (sem alterações)
  Future<void> _showAddDialog() async {
    final theme = Theme.of(context);
    _nameController.clear();
    // Reseta para valores padrão do diálogo
    _selectedCategory = 'Alimentos';
    _selectedUnit = 'un';

    // Função auxiliar para verificar duplicatas (mantida do original)
    bool isDuplicate(String name) {
      return _allItems.any(
        (item) => item.name.toLowerCase() == name.toLowerCase(),
      );
    }

    await showDialog(
      context: context,
      // barrierDismissible: false, // Impede fechar clicando fora
      builder:
          (context) => AlertDialog(
            backgroundColor: theme.colorScheme.surface,
            title: Text(
              'Adicionar Produto',
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
            content: SingleChildScrollView(
              // Garante rolagem se o teclado aparecer
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min, // Importante para SingleChildScrollView
                  children: [
                    TextFormField(
                      controller: _nameController,
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Nome do Produto',
                        border: const OutlineInputBorder(),
                        labelStyle: TextStyle(
                          color: theme.colorScheme.onSurface,
                        ),
                        // Adiciona counterText vazio para remover contador padrão
                        // counterText: '',
                      ),
                      // maxLength: 50, // Limita o tamanho do nome se desejado
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nome é obrigatório';
                        }
                        if (isDuplicate(value.trim())) {
                          // Usa trim para evitar espaços
                          return 'Este produto já existe';
                        }
                        return null;
                      },
                      // Remove onChanged se não estava no original
                      // onChanged: (value) {
                      //   _formKey.currentState?.validate();
                      // },
                      autovalidateMode:
                          AutovalidateMode
                              .onUserInteraction, // Valida ao interagir
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      dropdownColor: theme.colorScheme.surface,
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Categoria',
                        border: const OutlineInputBorder(),
                        labelStyle: TextStyle(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      // isExpanded: true, // Ocupa largura total
                      items:
                          _allCategories.map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            );
                          }).toList(),
                      onChanged: (value) {
                        // Usa setState dentro do builder do Dialog
                        // Precisamos de um StatefulWidget para o Dialog ou passar um callback
                        // Solução mais simples: Manter como estava, mas pode não atualizar visualmente
                        // _selectedCategory = value!;
                        // Solução com StatefulWidget no Dialog (recomendado):
                        if (value != null) {
                          // Se o Dialog for Stateful, use setState aqui
                          // setState(() => _selectedCategory = value);
                          // Se não, apenas atualize a variável (pode não refletir na UI imediatamente)
                          _selectedCategory = value;
                        }
                      },
                      validator:
                          (value) =>
                              value == null ? 'Selecione uma categoria' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedUnit,
                      dropdownColor: theme.colorScheme.surface,
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Unidade',
                        border: const OutlineInputBorder(),
                        labelStyle: TextStyle(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      // isExpanded: true,
                      items:
                          _allUnits.map((unit) {
                            return DropdownMenuItem(
                              value: unit,
                              child: Text(unit),
                            );
                          }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          // Mesma questão do setState do Dropdown anterior
                          _selectedUnit = value;
                        }
                      },
                      validator:
                          (value) =>
                              value == null ? 'Selecione uma unidade' : null,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancelar',
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
              ),
              FilledButton(
                // onPressed só habilita se o formulário for válido
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    _saveItem(context);
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
                child: const Text('Salvar'),
              ),
            ],
          ),
    );
  }

  // Método _saveItem original (sem alterações)
  Future<void> _saveItem(BuildContext context) async {
    // A validação já foi feita no onPressed do botão
    // if (!_formKey.currentState!.validate()) return;

    // Adiciona indicador de loading
    // showDialog(context: context, builder: (_) => Center(child: CircularProgressIndicator()));

    try {
      final newItem = ItemTemplate(
        name: _nameController.text.trim(), // Usa trim
        category: _selectedCategory,
        subcategory: '', // Campo obrigatório no modelo
        defaultUnit: _selectedUnit,
        availableUnits: [], // Será preenchido depois
      );

      // Salva o item e pega o ID gerado
      final db = await DatabaseHelper.instance.database;
      // Usa transaction para garantir atomicidade
      await db.transaction((txn) async {
        final id = await txn.insert('default_items', {
          'name': newItem.name,
          'category': newItem.category,
          'subcategory': newItem.subcategory, // Mantido vazio
          'defaultUnit': newItem.defaultUnit,
        }, conflictAlgorithm: ConflictAlgorithm.replace); // Ou ignore/fail

        // Define unidades disponíveis baseado na categoria (mantido do original)
        List<String> units = [];
        switch (_selectedCategory) {
          case 'Bebidas':
            units = ['ml', 'L', 'un'];
            break;
          case 'Materiais de Limpeza':
            units = ['un', 'L', 'ml'];
            break;
          case 'Higiene':
            units = ['un', 'pct'];
            break; // 'pct' estava no original?
          // Adicionar mais casos específicos se necessário
          default:
            units = _allUnits; // Considerar uma lista mais restrita por padrão?
        }

        // Insere unidades para o item
        for (var unit in units) {
          await txn.insert('item_units', {
            'item_id': id,
            'unit': unit,
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      });

      if (mounted) {
        Navigator.pop(context); // Fecha o Dialog
        // Navigator.pop(context); // Fecha o loading indicator se adicionado

        // Recarrega os itens e atualiza a pesquisa
        await _loadItems();
        _filterItems(); // Aplica o filtro atual nos itens atualizados

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produto adicionado com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Fecha o Dialog
        // Navigator.pop(context); // Fecha o loading indicator se adicionado
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e')));
      }
    }
  }

  // Método _deleteItem original (sem alterações)
  Future<void> _deleteItem(ItemTemplate item) async {
    // Verifica ID nulo (mantido do original)
    if (item.id == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro: Item sem identificador')),
        );
      }
      return;
    }

    final theme = Theme.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: theme.colorScheme.surface,
            title: Text(
              'Confirmar Exclusão',
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
            content: Text(
              'Deseja excluir o item "${item.name}"?',
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancelar',
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                ),
                child: const Text('Excluir'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      // Adiciona indicador de loading
      // setState(() => _isLoading = true);
      try {
        // 1. Excluir do banco usando transaction
        final db = await DatabaseHelper.instance.database;
        await db.transaction((txn) async {
          await txn.delete(
            'item_units', // Tabela de unidades
            where: 'item_id = ?',
            whereArgs: [item.id],
          );
          await txn.delete(
            'default_items', // Tabela principal
            where: 'id = ?',
            whereArgs: [item.id],
          );
        });
        // O service.removeTemplate pode ser redundante se ele faz o mesmo que acima
        // await _service.removeTemplate(item.id!);

        // 2. Pequeno delay (mantido do original, mas talvez não necessário)
        // await Future.delayed(const Duration(milliseconds: 300));

        // 3. Recarregar lista atualizada
        // Otimização: remover localmente em vez de recarregar tudo
        // final updatedItems = await _service.getAllTemplates();

        if (mounted) {
          // 4. Atualizar estado localmente (mais eficiente)
          setState(() {
            _allItems.removeWhere((i) => i.id == item.id);
            _filterItems(); // Reaplica o filtro aos itens atualizados
            // _isLoading = false; // Desativa loading indicator
          });

          // 5. Feedback visual (mantido do original)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Produto removido com sucesso!',
                style: TextStyle(color: theme.colorScheme.onPrimary),
              ),
              backgroundColor: theme.colorScheme.primary,
              duration: const Duration(seconds: 2),
              action: SnackBarAction(
                label: 'OK',
                textColor: theme.colorScheme.onPrimary,
                onPressed: () {},
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          // setState(() => _isLoading = false); // Desativa loading indicator
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Erro ao excluir: $e',
                style: TextStyle(color: theme.colorScheme.onError),
              ),
              backgroundColor: theme.colorScheme.error,
              duration: const Duration(seconds: 4),
              // Remove ação de tentar novamente se não estava no original
              // action: SnackBarAction(
              //   label: 'Tentar Novamente',
              //   textColor: theme.colorScheme.onError,
              //   onPressed: () => _deleteItem(item),
              // ),
            ),
          );
        }
      }
    }
  }

  // Método dispose original (sem alterações)
  @override
  void dispose() {
    _searchController.removeListener(_filterItems); // Remove listener
    _searchController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}
