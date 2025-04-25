import 'package:economize/controller/item_search_controller.dart';
import 'package:economize/model/budget/item_template.dart';
import 'package:flutter/material.dart';

class ItemSearchBar extends StatefulWidget {
  final Function(ItemTemplate) onItemSelected;
  final String? category;

  const ItemSearchBar({super.key, required this.onItemSelected, this.category});

  @override
  State<ItemSearchBar> createState() => _ItemSearchBarState();
}

class _ItemSearchBarState extends State<ItemSearchBar> {
  late ItemSearchController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = ItemSearchController();
    _controller.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SearchAnchor(
            builder: (context, controller) {
              return SearchBar(
                controller: _controller.searchController,
                focusNode: _focusNode,
                hintText: 'Buscar item...',
                leading: const Icon(Icons.search),
                trailing: [
                  if (_controller.searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _controller.clear();
                        _focusNode.unfocus();
                      },
                    ),
                ],
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _trySelectFirstMatch(),
              );
            },
            suggestionsBuilder: (context, controller) {
              if (_controller.isLoading) {
                return [
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ];
              }

              if (_controller.error != null) {
                return [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        _controller.error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ];
              }

              if (_controller.filteredItems.isEmpty) {
                return [
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('Nenhum item encontrado'),
                    ),
                  ),
                ];
              }

              return _controller.filteredItems.map((item) {
                return ListTile(
                  leading: Icon(
                    _getCategoryIcon(item.category),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(item.name),
                  subtitle: Text('${item.category} • ${item.defaultUnit}'),
                  trailing:
                      item.defaultUnit != 'un'
                          ? Text(
                            item.defaultUnit,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          )
                          : null,
                  onTap: () {
                    widget.onItemSelected(item);
                    _controller.clear();
                    _focusNode.unfocus();
                  },
                );
              }).toList();
            },
          ),
        ),
        if (_controller.isLoading) const LinearProgressIndicator(),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'alimentos':
        return Icons.restaurant;
      case 'bebidas':
        return Icons.local_drink;
      case 'limpeza':
        return Icons.cleaning_services;
      case 'higiene':
        return Icons.sanitizer;
      case 'frutas':
        return Icons.apple;
      case 'verduras':
        return Icons.eco;
      default:
        return Icons.shopping_cart;
    }
  }

  void _trySelectFirstMatch() {
    if (_controller.filteredItems.isNotEmpty) {
      widget.onItemSelected(_controller.filteredItems.first);
      _controller.clear();
      _focusNode.unfocus();
    }
  }
}
