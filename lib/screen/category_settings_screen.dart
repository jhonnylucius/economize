import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:economize/provider/category_provider.dart';

class CategorySettingsScreen extends StatelessWidget {
  const CategorySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar Categorias'),
      ),
      body: Consumer<CategoryProvider>(
        builder: (context, provider, child) {
          return ListView.builder(
            itemCount: provider.categories.length,
            itemBuilder: (context, index) {
              final category = provider.categories[index];
              return ListTile(
                title: Text(category.name),
                trailing: Switch(
                  value: category.isEnabled,
                  onChanged: (value) {
                    provider.toggleCategory(category.id);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
