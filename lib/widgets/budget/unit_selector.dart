import 'dart:async';

import 'package:economize/data/default_items.dart';
import 'package:economize/theme/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class UnitSelector extends StatefulWidget {
  final String initialUnit;
  final double initialQuantity;
  final Function(String, double) onUnitChanged;
  final String? category; // Opcional: para filtrar unidades por categoria

  const UnitSelector({
    super.key,
    required this.initialUnit,
    required this.initialQuantity,
    required this.onUnitChanged,
    this.category,
  });

  @override
  State<UnitSelector> createState() => _UnitSelectorState();
}

class _UnitSelectorState extends State<UnitSelector> {
  late TextEditingController _quantityController;
  late String _currentUnit;
  final _debouncer = Debouncer(milliseconds: 500);
  bool _hasError = false;

  // Lista de unidades filtrada por categoria
  List<String> get _availableUnits {
    if (widget.category == null) {
      return [
        ...defaultUnits['Peso']!,
        ...defaultUnits['Volume']!,
        ...defaultUnits['Unidade']!,
      ];
    }

    switch (widget.category?.toLowerCase()) {
      case 'bebidas':
      case 'líquidos':
        return defaultUnits['Volume']!;
      case 'frutas':
      case 'verduras':
      case 'carnes':
        return [...defaultUnits['Peso']!, ...defaultUnits['Unidade']!];
      case 'limpeza':
      case 'higiene':
        return [...defaultUnits['Volume']!, ...defaultUnits['Unidade']!];
      default:
        return defaultUnits['Unidade']!;
    }
  }

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(
      text: widget.initialQuantity.toString(),
    );
    _currentUnit =
        _availableUnits.contains(widget.initialUnit)
            ? widget.initialUnit
            : _availableUnits.first;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _updateValues(String? unit, String? quantity) {
    setState(() {
      if (unit != null) {
        _currentUnit = unit;
      }

      if (quantity != null) {
        final newQuantity = double.tryParse(quantity);
        _hasError = newQuantity == null || newQuantity <= 0;
      }
    });

    if (!_hasError) {
      final newQuantity =
          double.tryParse(quantity ?? _quantityController.text) ??
          widget.initialQuantity;

      _debouncer.run(() {
        widget.onUnitChanged(_currentUnit, newQuantity);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = context.watch<ThemeManager>();
    final theme = themeManager.currentTheme;

    return Card(
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _quantityController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Quantidade',
                      hintText: 'Ex: 1.5',
                      labelStyle: TextStyle(color: theme.colorScheme.onSurface),
                      border: const OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: theme.colorScheme.error),
                      ),
                      errorText: _hasError ? 'Quantidade inválida' : null,
                      errorStyle: TextStyle(color: theme.colorScheme.error),
                      suffixIcon:
                          _quantityController.text.isNotEmpty
                              ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: theme.colorScheme.onSurface,
                                ),
                                onPressed: () {
                                  _quantityController.clear();
                                  _updateValues(null, '1');
                                },
                              )
                              : null,
                    ),
                    style: TextStyle(color: theme.colorScheme.onSurface),
                    onChanged: (value) => _updateValues(null, value),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _currentUnit,
                    decoration: InputDecoration(
                      labelText: 'Unidade',
                      labelStyle: TextStyle(color: theme.colorScheme.onSurface),
                      border: const OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    dropdownColor: theme.colorScheme.surface,
                    style: TextStyle(color: theme.colorScheme.onSurface),
                    items:
                        _availableUnits.map((unit) {
                          return DropdownMenuItem(
                            value: unit,
                            child: Text(unit),
                          );
                        }).toList(),
                    onChanged: (value) => _updateValues(value, null),
                  ),
                ),
              ],
            ),
            if (_hasError)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'A quantidade deve ser maior que zero',
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void dispose() {
    _timer?.cancel();
  }
}
