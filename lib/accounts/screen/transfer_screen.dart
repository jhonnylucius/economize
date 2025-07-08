import 'package:economize/features/financial_education/utils/currency_input_formatter.dart';
import 'package:economize/service/moedas/currency_service.dart';
import 'package:flutter/material.dart';
import 'package:economize/accounts/model/account_model.dart';
import 'package:economize/accounts/service/account_service.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class TransferScreen extends StatefulWidget {
  final List<Account> accounts;
  final AccountService accountService;

  const TransferScreen({
    super.key,
    required this.accounts,
    required this.accountService,
  });

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  int? _fromAccountId;
  int? _toAccountId;
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  final CurrencyService _currencyService = CurrencyService();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // fundo branco
      appBar: AppBar(
        title: const Text('Transferir entre Contas',
            style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<int>(
                value: _fromAccountId,
                style: const TextStyle(color: Colors.black), // texto preto
                dropdownColor: Colors.white, // fundo branco
                iconEnabledColor: Colors.black, // ícone preto
                decoration: const InputDecoration(
                  labelText: 'Conta de origem',
                  labelStyle: TextStyle(color: Colors.black), // label preta
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black54),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                ),
                items: widget.accounts
                    .map((a) => DropdownMenuItem(
                          value: a.id,
                          child: Text(a.name,
                              style: const TextStyle(color: Colors.black)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _fromAccountId = v),
                validator: (v) =>
                    v == null ? 'Selecione a conta de origem' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _toAccountId,
                style: const TextStyle(color: Colors.black),
                dropdownColor: Colors.white,
                iconEnabledColor: Colors.black,
                decoration: const InputDecoration(
                  labelText: 'Conta de destino',
                  labelStyle: TextStyle(color: Colors.black),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black54),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                ),
                items: widget.accounts
                    .map((a) => DropdownMenuItem(
                          value: a.id,
                          child: Text(a.name,
                              style: const TextStyle(color: Colors.black)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _toAccountId = v),
                validator: (v) {
                  if (v == null) return 'Selecione a conta de destino';
                  if (v == _fromAccountId) return 'Contas devem ser diferentes';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: 'Valor',
                  labelStyle: const TextStyle(color: Colors.black),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black54),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  prefixIcon:
                      const Icon(Icons.attach_money, color: Colors.black),
                  hintText: _currencyService.formatCurrency(0),
                  hintStyle: const TextStyle(color: Colors.black26),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CurrencyInputFormatter(), // igual ao formulário de contas
                ],
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Informe o valor';
                  final cleanValue = v.replaceAll(RegExp(r'[^\d]'), '');
                  final value = double.tryParse(cleanValue) ?? 0;
                  if (value <= 0) return 'Valor inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(
                  labelText: 'Descrição (opcional)',
                  labelStyle: TextStyle(color: Colors.black),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black54),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Data da transferência',
                    style: TextStyle(color: Colors.black)),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(_selectedDate),
                    style: const TextStyle(color: Colors.black)),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today, color: Colors.black),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setState(() => _selectedDate = picked);
                  },
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black))
                    : const Icon(Icons.swap_horiz, color: Colors.black),
                label: const Text('Transferir',
                    style: TextStyle(color: Colors.black)),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color.fromARGB(255, 216, 78, 196), // botão rosa
                  foregroundColor: Colors.black, // texto preto
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _loading
                    ? null
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() => _loading = true);
                          try {
                            await widget.accountService
                                .transferBetweenAccountsWithServices(
                              fromAccountId: _fromAccountId!,
                              toAccountId: _toAccountId!,
                              amount: double.parse(
                                    _amountController.text
                                        .replaceAll(RegExp(r'[^0-9]'), ''),
                                  ) /
                                  100,
                              description: _descController.text,
                              date: _selectedDate,
                            );
                            if (mounted) {
                              Navigator.pop(context, true);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Transferência realizada com sucesso!',
                                    style: TextStyle(color: Colors.black),
                                  ),
                                  backgroundColor: Colors.pinkAccent,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Erro: Transferência não realizada',
                                    style: TextStyle(color: Colors.black),
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                          setState(() => _loading = false);
                        }
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
