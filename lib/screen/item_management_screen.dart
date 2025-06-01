import 'package:economize/animations/celebration_animations.dart';
import 'package:economize/animations/fade_animation.dart';
import 'package:economize/animations/glass_container.dart';
import 'package:economize/animations/interactive_animations.dart';
import 'package:economize/animations/loading_animations.dart';
import 'package:economize/animations/scale_animation.dart';
import 'package:economize/animations/slide_animation.dart';
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

class _ItemManagementScreenState extends State<ItemManagementScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedUnit = 'un';
  String _selectedCategory = 'Alimentos';
  final ItemTemplateService _service = ItemTemplateService();
  final TextEditingController _searchController = TextEditingController();
  List<ItemTemplate> _filteredItems = [];
  List<ItemTemplate> _allItems = [];
  bool _isLoading = true;
  bool _showCelebration = false;
  late AnimationController _animationController;

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

    // Inicializa o controlador de animação
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
  }

  // Método _loadItems original (sem alterações)
  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    try {
      _allItems = await _service.getAllTemplates();
      _filteredItems = _allItems;
    } catch (e) {
      debugPrint('Erro ao carregar itens: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Método _filterItems original (sem alterações)
  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = _allItems.where((item) {
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
        title: SlideAnimation.fromTop(
          child: const Text('Gerenciar Produtos'),
        ),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          SlideAnimation.fromTop(
            delay: const Duration(milliseconds: 100),
            child: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () async {
                setState(() => _isLoading = true);
                try {
                  await _loadItems();
                  _filterItems();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            AnimatedCheckmark(
                              color: theme.colorScheme.onPrimary,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            const Text('Lista atualizada!'),
                          ],
                        ),
                        backgroundColor: theme.colorScheme.primary,
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.all(12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
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
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.all(12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
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
          ),
          SlideAnimation.fromTop(
            delay: const Duration(milliseconds: 200),
            child: IconButton(
              icon: const Icon(Icons.home),
              onPressed: () => Navigator.pushReplacementNamed(context, '/'),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white, // Fundo sempre branco
      floatingActionButton: ScaleAnimation.bounceIn(
        delay: const Duration(milliseconds: 300),
        child: PressableCard(
          onPress: _showAddDialog,
          pressedScale: 0.9,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withAlpha((0.3 * 255).toInt()),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Icon(
            Icons.add,
            color: theme.colorScheme.onPrimary,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      resizeToAvoidBottomInset: true,
      child: Stack(
        children: [
          // Conteúdo principal
          Column(
            children: [
              // Barra de pesquisa com animação
              SlideAnimation.fromTop(
                delay: const Duration(milliseconds: 150),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GlassContainer(
                    blur: 3,
                    opacity: 0.1,
                    borderRadius: 24,
                    child: SearchBar(
                      controller: _searchController,
                      hintText: 'Pesquisar produtos...',
                      leading: Icon(Icons.search,
                          color: theme.colorScheme.onSurface),
                      trailing: [
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: Icon(Icons.clear,
                                color: theme.colorScheme.onSurface),
                            onPressed: () {
                              _searchController.clear();
                            },
                          ),
                      ],
                      backgroundColor: WidgetStateProperty.all(
                        theme.colorScheme.surface
                            .withAlpha((0.7 * 255).toInt()),
                      ),
                      padding: const WidgetStatePropertyAll(
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                    ),
                  ),
                ),
              ),

              Expanded(
                child: _isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SpinKitLoadingAnimation(
                              color: theme.colorScheme.primary,
                              size: 50,
                            ),
                            const SizedBox(height: 20),
                            FadeAnimation(
                              child: Text(
                                'Carregando produtos...',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : _filteredItems.isEmpty
                        ? FadeAnimation(
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 80,
                                    color: theme.colorScheme.primary
                                        .withAlpha((0.3 * 255).toInt()),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Nenhum produto encontrado',
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tente um termo diferente ou adicione um novo produto',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface
                                          .withAlpha((0.7 * 255).toInt()),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filteredItems.length,
                            itemBuilder: (context, index) {
                              final item = _filteredItems[index];

                              return SlideAnimation.fromRight(
                                delay:
                                    Duration(milliseconds: 100 * index % 500),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 4),
                                  child: PressableCard(
                                    onPress: () => _editItem(item),
                                    pressedScale: 0.98,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: theme.colorScheme.primary
                                            .withAlpha((0.2 * 255).toInt()),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withAlpha((0.3 * 255).toInt()),
                                          blurRadius: 5,
                                          offset: const Offset(0, 2),
                                        )
                                      ],
                                    ),
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    child: ListTile(
                                      leading: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary
                                              .withAlpha((0.1 * 255).toInt()),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          _getCategoryIcon(item.category),
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                      title: Text(
                                        item.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '${item.category} - ${item.defaultUnit}',
                                        style: TextStyle(
                                          color: Colors.black54,
                                        ),
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete_outline),
                                        color: theme.colorScheme.error,
                                        onPressed: () => _deleteItem(item),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),

          // Animação de celebração quando adiciona um item
          if (_showCelebration)
            Positioned.fill(
              child: IgnorePointer(
                child: ConfettiAnimation(
                  particleCount: 30,
                  direction: ConfettiDirection.down,
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                    theme.colorScheme.tertiary,
                    Colors.amber,
                  ],
                  animationController: _animationController,
                  duration: const Duration(seconds: 3),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Novo método para editar item
  void _editItem(ItemTemplate item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Implementação da edição virá em breve!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Novo método para obter ícones baseados na categoria
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'alimentos':
        return Icons.restaurant;
      case 'bebidas':
        return Icons.local_drink;
      case 'limpeza':
      case 'materiais de limpeza':
        return Icons.cleaning_services;
      case 'higiene':
      case 'higiene pessoal':
        return Icons.spa;
      case 'frutas':
      case 'verduras':
      case 'hortifruti':
        return Icons.eco;
      case 'carnes':
        return Icons.set_meal;
      case 'frios':
      case 'laticínios':
        return Icons.egg;
      case 'padaria':
        return Icons.bakery_dining;
      case 'congelados':
        return Icons.ac_unit;
      case 'farmácia':
        return Icons.medical_services;
      case 'materiais de construção':
        return Icons.construction;
      case 'utensílios de casa':
        return Icons.home;
      default:
        return Icons.shopping_basket;
    }
  }

  // Método _showAddDialog melhorado
  Future<void> _showAddDialog() async {
    final theme = Theme.of(context);
    _nameController.clear();
    _selectedCategory = 'Alimentos';
    _selectedUnit = 'un';

    bool isDuplicate(String name) {
      return _allItems.any(
        (item) => item.name.toLowerCase() == name.toLowerCase(),
      );
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha((0.1 * 255).toInt()),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add_shopping_cart,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Adicionar Produto',
              style: TextStyle(color: Colors.black87),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleAnimation(
                  delay: const Duration(milliseconds: 100),
                  fromScale: 0.9,
                  child: TextFormField(
                    controller: _nameController,
                    style: TextStyle(color: Colors.black87),
                    decoration: InputDecoration(
                      labelText: 'Nome do Produto',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      labelStyle: TextStyle(
                        color: Colors.black87,
                      ),
                      prefixIcon: Icon(
                        Icons.inventory_2,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nome é obrigatório';
                      }
                      if (isDuplicate(value.trim())) {
                        return 'Este produto já existe';
                      }
                      return null;
                    },
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                  ),
                ),
                const SizedBox(height: 16),
                SlideAnimation.fromRight(
                  delay: const Duration(milliseconds: 200),
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    dropdownColor: Colors.white,
                    style: TextStyle(color: Colors.black87),
                    decoration: InputDecoration(
                      labelText: 'Categoria',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      labelStyle: TextStyle(
                        color: Colors.black87,
                      ),
                      prefixIcon: Icon(
                        Icons.category,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    items: _allCategories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        _selectedCategory = value;
                      }
                    },
                    validator: (value) =>
                        value == null ? 'Selecione uma categoria' : null,
                  ),
                ),
                const SizedBox(height: 16),
                SlideAnimation.fromLeft(
                  delay: const Duration(milliseconds: 300),
                  child: DropdownButtonFormField<String>(
                    value: _selectedUnit,
                    dropdownColor: Colors.white,
                    style: TextStyle(color: Colors.black87),
                    decoration: InputDecoration(
                      labelText: 'Unidade',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      labelStyle: TextStyle(
                        color: Colors.black87,
                      ),
                      prefixIcon: Icon(
                        Icons.straighten,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    items: _allUnits.map((unit) {
                      return DropdownMenuItem(
                        value: unit,
                        child: Text(unit),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        _selectedUnit = value;
                      }
                    },
                    validator: (value) =>
                        value == null ? 'Selecione uma unidade' : null,
                  ),
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
          PressableCard(
            onPress: () {
              if (_formKey.currentState?.validate() ?? false) {
                _saveItem(context);
              }
            },
            pressedScale: 0.95,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Salvar',
              style: TextStyle(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Método _saveItem melhorado
  Future<void> _saveItem(BuildContext context) async {
    final theme = Theme.of(context);
    try {
      final newItem = ItemTemplate(
        name: _nameController.text.trim(),
        category: _selectedCategory,
        subcategory: '',
        defaultUnit: _selectedUnit,
        availableUnits: [],
      );

      final db = await DatabaseHelper.instance.database;
      await db.transaction((txn) async {
        final id = await txn.insert(
            'default_items',
            {
              'name': newItem.name,
              'category': newItem.category,
              'subcategory': newItem.subcategory,
              'defaultUnit': newItem.defaultUnit,
            },
            conflictAlgorithm: ConflictAlgorithm.replace);

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
            break;
          default:
            units = _allUnits;
        }

        for (var unit in units) {
          await txn.insert(
              'item_units',
              {
                'item_id': id,
                'unit': unit,
              },
              conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      });

      if (mounted) {
        Navigator.pop(context);

        // Inicia animação de celebração
        setState(() {
          _showCelebration = true;
        });

        _animationController.forward(from: 0.0);

        // Esconde celebração após 3 segundos
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _showCelebration = false;
            });
          }
        });

        // Recarrega os itens
        await _loadItems();
        _filterItems();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                AnimatedCheckmark(
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text('Produto adicionado com sucesso!'),
              ],
            ),
            backgroundColor: theme.colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: theme.colorScheme.error,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  // Método _deleteItem melhorado
  Future<void> _deleteItem(ItemTemplate item) async {
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
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withAlpha((0.1 * 255).toInt()),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete,
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Confirmar Exclusão',
              style: TextStyle(color: Colors.black87),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Deseja excluir o item:',
              style: TextStyle(color: Colors.black87),
            ),
            const SizedBox(height: 16),
            GlassContainer(
              blur: 3,
              opacity: 0.08,
              borderRadius: 12,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary
                            .withAlpha((0.1 * 255).toInt()),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getCategoryIcon(item.category),
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${item.category} - ${item.defaultUnit}',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Esta ação não pode ser desfeita.',
              style: TextStyle(
                color: theme.colorScheme.error,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: theme.colorScheme.primary),
            ),
          ),
          PressableCard(
            onPress: () => Navigator.pop(context, true),
            pressedScale: 0.95,
            decoration: BoxDecoration(
              color: theme.colorScheme.error,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.delete_outline,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Excluir',
                  style: TextStyle(
                    color: theme.colorScheme.onError,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final db = await DatabaseHelper.instance.database;
        await db.transaction((txn) async {
          await txn.delete(
            'item_units',
            where: 'item_id = ?',
            whereArgs: [item.id],
          );
          await txn.delete(
            'default_items',
            where: 'id = ?',
            whereArgs: [item.id],
          );
        });

        if (mounted) {
          setState(() {
            _allItems.removeWhere((i) => i.id == item.id);
            _filterItems();
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  const Text('Produto removido com sucesso!'),
                ],
              ),
              backgroundColor: theme.colorScheme.primary,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao excluir: $e'),
              backgroundColor: theme.colorScheme.error,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  // Método dispose com inclusão do controller de animação
  @override
  void dispose() {
    _searchController.removeListener(_filterItems);
    _searchController.dispose();
    _nameController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}
