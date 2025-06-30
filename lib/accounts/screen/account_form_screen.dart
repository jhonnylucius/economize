import 'package:economize/accounts/enum/account_type.dart';
import 'package:economize/accounts/model/account_model.dart';
import 'package:economize/accounts/service/account_service.dart';
import 'package:economize/accounts/widgets/icon_picker.dart';
import 'package:economize/animations/glass_container.dart';
import 'package:economize/features/financial_education/utils/currency_input_formatter.dart';
import 'package:economize/model/revenues.dart';
import 'package:economize/service/revenues_service.dart';
import 'package:economize/theme/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class AccountFormScreen extends StatefulWidget {
  final Account? account;

  const AccountFormScreen({super.key, this.account});

  @override
  AccountFormScreenState createState() => AccountFormScreenState();
}

class AccountFormScreenState extends State<AccountFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _balanceController;
  late AccountType _selectedType;
  late int _selectedIcon;

  final AccountService _service = AccountService();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.account?.name);

    // Formata o saldo inicial como moeda
    final balance = widget.account?.balance ?? 0.0;
    final formattedBalance =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(balance);
    _balanceController = TextEditingController(
        text: widget.account != null ? formattedBalance : '');

    _selectedType = widget.account?.type ?? AccountType.checking;
    _selectedIcon = widget.account?.icon ?? Icons.account_balance.codePoint;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  final RevenuesService _revenuesService = RevenuesService();

  Future<void> _saveAccount() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text;

      String valorTexto = _balanceController.text
          .replaceAll('R\$', '')
          .replaceAll('.', '')
          .replaceAll(',', '.')
          .replaceAll(' ', '')
          .trim();
      final balance = double.tryParse(valorTexto) ?? 0.0;

      final isNewAccount = widget.account == null;

      final account = Account(
        id: widget.account?.id,
        name: name,
        balance: balance,
        type: _selectedType,
        icon: _selectedIcon,
      );

      // Salva a conta e obtém a conta salva com id
      final savedAccount = await _service.saveAccount(account);

      // Se for nova conta e saldo > 0, cria receita de saldo inicial
      if (isNewAccount && balance > 0) {
        final now = DateTime.now();
        final revenue = Revenues(
          id: const Uuid().v4(),
          accountId: savedAccount.id,
          data: now,
          preco: balance,
          descricaoDaReceita: 'Saldo Inicial',
          tipoReceita: 'Saldo Inicial',
        );
        await _revenuesService.saveRevenue(revenue);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = context.watch<ThemeManager>();
    final isEditing = widget.account != null;
    final textColor = Colors.black87;
    final borderColor =
        const Color.fromARGB(255, 216, 78, 196).withAlpha((0.3 * 255).toInt());
    final fieldBackgroundColor = Colors.grey.shade50;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Conta' : 'Nova Conta'),
        backgroundColor: themeManager.getCurrentPrimaryColor(),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SizedBox.expand(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 24),
          child: GlassContainer(
            frostedEffect: true,
            borderRadius: 24,
            opacity: 0.1,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEditing ? 'Editar Conta' : 'Nova Conta',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Nome da Conta',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.account_balance,
                            color: textColor.withAlpha((0.6 * 255).toInt())),
                        hintText: 'Ex: Conta Corrente',
                        hintStyle: TextStyle(
                          color: textColor.withAlpha((0.4 * 255).toInt()),
                        ),
                        filled: true,
                        fillColor: fieldBackgroundColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: borderColor,
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: borderColor,
                            width: 1,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira um nome';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isEditing ? 'Saldo Atual' : 'Saldo Inicial',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _balanceController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        CurrencyInputFormatter(), // <-- igual ao formulário de despesas
                      ],
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.attach_money,
                            color: textColor.withAlpha((0.6 * 255).toInt())),
                        hintText: 'R\$ 0,00',
                        hintStyle: TextStyle(
                          color: textColor.withAlpha((0.4 * 255).toInt()),
                        ),
                        filled: true,
                        fillColor: fieldBackgroundColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: borderColor,
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: borderColor,
                            width: 1,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira um saldo';
                        }
                        // Validação igual ao formulário de despesas
                        final cleanValue =
                            value.replaceAll(RegExp(r'[^\d]'), '');
                        if (cleanValue.isEmpty ||
                            double.tryParse(cleanValue) == null) {
                          return 'Por favor, insira um número válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tipo de Conta',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<AccountType>(
                      value: _selectedType,
                      items: AccountType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type.displayName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedType = value);
                        }
                      },
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.category,
                            color: textColor.withAlpha((0.6 * 255).toInt())),
                        filled: true,
                        fillColor: fieldBackgroundColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: borderColor,
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: borderColor,
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Ícone da Conta',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: fieldBackgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: borderColor,
                          width: 1,
                        ),
                      ),
                      child: IconPicker(
                        selectedIcon: _selectedIcon,
                        onIconSelected: (icon) {
                          setState(() => _selectedIcon = icon);
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: textColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: borderColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: FilledButton(
                            onPressed: _saveAccount,
                            style: FilledButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 216, 78, 196),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(isEditing
                                ? 'Salvar Alterações'
                                : 'Criar Conta'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
