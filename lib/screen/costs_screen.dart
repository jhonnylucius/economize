import 'package:economize/icons/my_flutter_app_icons.dart';
import 'package:economize/model/costs.dart';
import 'package:economize/screen/responsive_screen.dart';
import 'package:economize/service/costs_service.dart';
import 'package:flutter/material.dart'; // Importa os widgets do Material Design.
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart'; // Importa o formatador de máscara para campos de texto.
import 'package:uuid/uuid.dart'; // Importa a biblioteca para gerar UUIDs.

// Define o widget CostsScreen, que é um StatefulWidget, permitindo que seu estado mude.
class CostsScreen extends StatefulWidget {
  const CostsScreen({super.key}); // Construtor da classe.

  @override
  // Cria o estado associado ao widget CostsScreen.
  State<CostsScreen> createState() => _CostsScreenState();
}

// Define a classe de estado para CostsScreen.
class _CostsScreenState extends State<CostsScreen> {
  List<Costs> listCosts = []; // Lista para armazenar as despesas carregadas.
  final GlobalKey<FormState> _formKey =
      GlobalKey<
        FormState
      >(); // Chave global para o formulário de adição/edição.
  final CostsService _costsService =
      CostsService(); // Instância do serviço de despesas.
  bool _isLoading =
      false; // Flag para indicar se os dados estão sendo carregados.

  // Lista estática com os tipos de despesa disponíveis.
  static const List<String> _tiposDespesa = [
    'Avulsa',
    'Obrigatória Mensal',
    'Obrigatória Anual',
    'Imprevisto',
  ];

  @override
  // Método chamado quando o widget é inserido na árvore de widgets.
  void initState() {
    super.initState();
    _loadCosts(); // Carrega as despesas iniciais.
  }

  // Método assíncrono para carregar as despesas do serviço.
  Future<void> _loadCosts() async {
    setState(
      () => _isLoading = true,
    ); // Define o estado de carregamento como true.
    try {
      // Tenta buscar todas as despesas usando o serviço.
      final costs = await _costsService.getAllCosts();
      // Atualiza o estado com a lista de despesas carregada.
      setState(() => listCosts = costs);
    } catch (e) {
      // Em caso de erro, exibe um diálogo de erro.
      _showErrorDialog('Erro ao carregar despesas: $e');
    } finally {
      // Garante que o estado de carregamento seja definido como false ao final.
      setState(() => _isLoading = false);
    }
  }

  @override
  // Método que constrói a interface do usuário do widget.
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Obtém o tema atual do contexto.

    // Usa o ResponsiveScreen para adaptar a tela a diferentes tamanhos.
    return ResponsiveScreen(
      // Define a AppBar da tela.
      appBar: AppBar(
        title: const Text('Despesas'), // Título da AppBar.
        backgroundColor: theme.colorScheme.primary, // Cor de fundo da AppBar.
        foregroundColor:
            theme.colorScheme.onPrimary, // Cor do texto e ícones na AppBar.
        elevation: 0, // Remove a sombra da AppBar.
        // Ações disponíveis na AppBar.
        actions: [
          // Botão para recarregar as despesas.
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadCosts),
          // Botão para navegar para a tela inicial.
          IconButton(
            icon: const Icon(Icons.home),
            onPressed:
                () => Navigator.of(context).pushReplacementNamed('/home'),
          ),
        ],
      ),
      // Define a cor de fundo da tela principal.
      backgroundColor: theme.scaffoldBackgroundColor,
      // Define os botões flutuantes na parte inferior.
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16.0,
        ), // Espaçamento horizontal para os botões.
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment
                  .spaceBetween, // Alinha os botões nas extremidades.
          children: [
            // Botão flutuante estendido para adicionar despesas.
            FloatingActionButton.extended(
              heroTag:
                  'add_costs', // Tag única para o Hero animation (evita conflitos).
              onPressed:
                  () =>
                      _showFormModal(), // Abre o modal de formulário ao ser pressionado.
              icon: const Icon(Icons.add), // Ícone do botão.
              label: const Text('Add Despesas'), // Texto do botão.
              backgroundColor:
                  theme.colorScheme.onPrimary, // Cor de fundo do botão.
              foregroundColor:
                  theme.colorScheme.primary, // Cor do texto e ícone do botão.
            ),
            // Botão flutuante estendido para navegar para a tela de receitas.
            FloatingActionButton.extended(
              heroTag: 'goto_revenues', // Tag única para o Hero animation.
              onPressed:
                  () => Navigator.pushNamed(
                    context,
                    '/revenues',
                  ), // Navega para a rota '/revenues'.
              icon: const Icon(Icons.arrow_forward), // Ícone do botão.
              label: const Text('Ir p/ Receitas'), // Texto do botão.
              backgroundColor:
                  theme.colorScheme.onPrimary, // Cor de fundo do botão.
              foregroundColor:
                  theme.colorScheme.primary, // Cor do texto e ícone do botão.
            ),
          ],
        ),
      ),
      // Define a localização dos botões flutuantes.
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      // Define se a tela deve redimensionar para evitar o teclado.
      resizeToAvoidBottomInset: true,
      // Define o conteúdo principal da tela.
      child:
          _buildBody(), // Mantém o valor padrão ou ajuste conforme necessário
    );
  }

  // Método que constrói o corpo principal da tela.
  Widget _buildBody() {
    final theme = Theme.of(context); // Obtém o tema atual.

    // Se estiver carregando, exibe um indicador de progresso.
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Se a lista de despesas estiver vazia, exibe uma mensagem inicial.
    if (listCosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min, // Ocupa o mínimo de espaço vertical.
          children: [
            // Exibe uma imagem.
            Image.asset('assets/icon_removedbg.png', width: 180, height: 180),
            const SizedBox(height: 16), // Espaçamento vertical.
            // Texto principal da mensagem inicial.
            Text(
              'Vamos começar?',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8), // Espaçamento vertical.
            // Texto secundário da mensagem inicial.
            Text(
              'Registre suas Despesas',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      );
    }

    // Se houver despesas, exibe uma lista delas.
    return ListView.builder(
      padding: const EdgeInsets.only(
        bottom: 80,
      ), // Espaçamento inferior para não cobrir com FABs.
      itemCount: listCosts.length, // Número de itens na lista.
      // Constrói cada item da lista.
      itemBuilder: (context, index) {
        final cost = listCosts[index]; // Obtém a despesa atual.
        return _buildCostCard(cost); // Constrói o card para a despesa.
      },
    );
  }

  // Método que constrói um card para exibir uma despesa.
  Widget _buildCostCard(Costs cost) {
    final theme = Theme.of(context); // Obtém o tema atual.

    // Widget que permite descartar o card arrastando-o.
    return Dismissible(
      key: ValueKey(cost.id), // Chave única para identificar o item.
      direction:
          DismissDirection
              .endToStart, // Permite descartar da direita para a esquerda.
      // Fundo exibido ao arrastar o card.
      background: Container(
        alignment: Alignment.centerRight, // Alinha o conteúdo à direita.
        padding: const EdgeInsets.only(right: 12), // Espaçamento à direita.
        color: theme.colorScheme.error, // Cor de fundo de erro.
        child: Icon(
          Icons.delete,
          color: theme.colorScheme.onError,
        ), // Ícone de lixeira.
      ),
      // Função chamada quando o card é descartado.
      onDismissed: (_) => _removeCost(cost),
      // O conteúdo principal do card.
      child: Card(
        elevation: 2, // Sombra do card.
        color: theme.colorScheme.surface, // Cor de fundo do card.
        // ListTile para organizar o conteúdo do card.
        child: ListTile(
          // Ação ao pressionar longamente o item (abre o modal de edição).
          onLongPress: () => _showFormModal(model: cost),
          // Ícone à esquerda do ListTile.
          leading: Icon(
            Icons.attach_money,
            size: 40,
            color: theme.colorScheme.primary,
          ),
          // Título principal (data da despesa).
          title: Text(
            cost.data,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          // Subtítulo (informações adicionais).
          subtitle: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start, // Alinha o texto à esquerda.
            children: [
              // Preço da despesa.
              Text(
                'R\$ ${cost.preco.toStringAsFixed(2)}', // Formata o preço com 2 casas decimais.
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              // Descrição da despesa.
              Text(
                cost.descricaoDaDespesa ??
                    'Sem descrição', // Usa 'Sem descrição' se for nulo.
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(
                    (0.8 * 255).toInt(), // Cor com 80% de opacidade.
                  ),
                ),
              ),
              // Tipo da despesa.
              Text(
                cost.tipoDespesa,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(
                    (0.8 * 255).toInt(), // Cor com 80% de opacidade.
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Método assíncrono para exibir o modal de formulário para adicionar ou editar uma despesa.
  Future<void> _showFormModal({Costs? model}) async {
    // Controladores para os campos de texto, inicializados com os dados do modelo (se houver).
    final dataController = TextEditingController(text: model?.data ?? '');
    final precoController = TextEditingController(
      text: model?.preco.toString() ?? '',
    );
    final descricaoController = TextEditingController(
      text: model?.descricaoDaDespesa ?? '',
    );
    // Variável para armazenar o tipo de despesa selecionado.
    String selectedTipo = model?.tipoDespesa ?? _tiposDespesa[0];

    // Formatador para o campo de data (DD/MM/AAAA).
    final dateFormatter = MaskTextInputFormatter(
      mask: '##/##/####',
      filter: {"#": RegExp(r'[0-9]')}, // Permite apenas números.
    );

    // Exibe um BottomSheet modal.
    await showModalBottomSheet(
      context: context,
      isScrollControlled:
          true, // Permite que o modal ocupe mais espaço vertical se necessário.
      backgroundColor:
          Theme.of(context).colorScheme.surface, // Cor de fundo do modal.
      // Define a forma do modal com cantos superiores arredondados.
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      // Constrói o conteúdo do modal.
      builder: (context) {
        // Usa StatefulBuilder para permitir atualizações de estado dentro do modal (para o Dropdown).
        return StatefulBuilder(
          builder: (context, setState) {
            final theme = Theme.of(context); // Obtém o tema atual.
            // Adiciona padding ao redor do conteúdo do modal.
            return Padding(
              padding: EdgeInsets.only(
                bottom:
                    MediaQuery.of(context).viewInsets.bottom +
                    24, // Ajusta o padding inferior com base no teclado.
                left: 16,
                right: 16,
                top: 16,
              ),
              // Formulário para agrupar e validar os campos.
              child: Form(
                key: _formKey, // Associa a chave global ao formulário.
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min, // Ocupa o mínimo de espaço vertical.
                  children: [
                    // Campo de texto para a data.
                    TextFormField(
                      controller: dataController,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                      ), // Cor do texto digitado.
                      decoration: InputDecoration(
                        labelText: 'Data',
                        labelStyle: TextStyle(
                          color: theme.colorScheme.onSurface,
                        ), // Cor do label.
                        hintText: '01/01/2025',
                        hintStyle: TextStyle(
                          color: theme.colorScheme.onSurface.withAlpha(
                            (0.6 * 255)
                                .toInt(), // Cor da dica com 60% de opacidade.
                          ),
                        ),
                        // Ícone de calendário para abrir o seletor de data.
                        suffixIcon: IconButton(
                          icon: Icon(
                            MyFlutterApp.calendar_check,
                            color: theme.colorScheme.primary,
                          ),
                          onPressed: () async {
                            // Exibe o DatePicker.
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                              locale: const Locale(
                                'pt',
                                'BR',
                              ), // Define o local para português.
                            );
                            // Se uma data for selecionada, atualiza o campo de texto.
                            if (date != null) {
                              dataController.text =
                                  "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
                            }
                          },
                        ),
                        filled: true, // Preenche o fundo do campo.
                        fillColor: theme.colorScheme.surface, // Cor de fundo.
                        // Borda quando o campo não está em foco.
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: theme.colorScheme.onSurface.withAlpha(
                              (0.4 * 255)
                                  .toInt(), // Cor da borda com 40% de opacidade.
                            ),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        // Borda quando o campo está em foco.
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color:
                                theme
                                    .colorScheme
                                    .primary, // Cor da borda primária.
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      inputFormatters: [
                        dateFormatter,
                      ], // Aplica o formatador de máscara.
                      // Validação do campo.
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira a data';
                        }
                        return null; // Retorna null se a validação passar.
                      },
                    ),
                    const SizedBox(height: 16), // Espaçamento vertical.
                    // Campo de texto para o valor (preço).
                    TextFormField(
                      controller: precoController,
                      keyboardType: TextInputType.number, // Teclado numérico.
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                      ), // Cor do texto digitado.
                      decoration: InputDecoration(
                        labelText: 'Valor',
                        labelStyle: TextStyle(
                          color: theme.colorScheme.onSurface,
                        ), // Cor do label.
                        hintText: '100.00',
                        hintStyle: TextStyle(
                          color: theme.colorScheme.onSurface.withAlpha(
                            (0.6 * 255)
                                .toInt(), // Cor da dica com 60% de opacidade.
                          ),
                        ),
                        helperText: 'Use ponto ao invés de vírgula',
                        helperStyle: TextStyle(
                          color: theme.colorScheme.onSurface.withAlpha(
                            (0.6 * 255)
                                .toInt(), // Cor do texto de ajuda com 60% de opacidade.
                          ),
                        ),
                        filled: true, // Preenche o fundo do campo.
                        fillColor: theme.colorScheme.surface, // Cor de fundo.
                        // Borda quando o campo não está em foco.
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: theme.colorScheme.onSurface.withAlpha(
                              (0.4 * 255)
                                  .toInt(), // Cor da borda com 40% de opacidade.
                            ),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        // Borda quando o campo está em foco.
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color:
                                theme
                                    .colorScheme
                                    .primary, // Cor da borda primária.
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      // Validação do campo.
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira o valor';
                        }
                        // Verifica se o valor pode ser convertido para double.
                        if (double.tryParse(value) == null) {
                          return 'Por favor, insira um valor válido';
                        }
                        return null; // Retorna null se a validação passar.
                      },
                    ),
                    const SizedBox(height: 16), // Espaçamento vertical.
                    // Campo de texto para a descrição.
                    TextFormField(
                      controller: descricaoController,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                      ), // Cor do texto digitado.
                      decoration: InputDecoration(
                        labelText: 'Descrição',
                        labelStyle: TextStyle(
                          color: theme.colorScheme.onSurface,
                        ), // Cor do label.
                        hintText: 'Qual a despesa que você pagou?',
                        hintStyle: TextStyle(
                          color: theme.colorScheme.onSurface.withAlpha(
                            (0.6 * 255)
                                .toInt(), // Cor da dica com 60% de opacidade.
                          ),
                        ),
                        filled: true, // Preenche o fundo do campo.
                        fillColor: theme.colorScheme.surface, // Cor de fundo.
                        // Borda quando o campo não está em foco.
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: theme.colorScheme.onSurface.withAlpha(
                              (0.6 * 255)
                                  .toInt(), // Cor da borda com 60% de opacidade.
                            ),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        // Borda quando o campo está em foco.
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color:
                                theme
                                    .colorScheme
                                    .primary, // Cor da borda primária.
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      // Validação do campo.
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira a descrição';
                        }
                        return null; // Retorna null se a validação passar.
                      },
                    ),
                    const SizedBox(height: 16), // Espaçamento vertical.
                    // Dropdown para selecionar o tipo de despesa.
                    DropdownButtonFormField<String>(
                      value: selectedTipo, // Valor atualmente selecionado.
                      decoration: InputDecoration(
                        labelText: 'Tipo da Despesa',
                        border:
                            const OutlineInputBorder(), // Borda padrão do campo.
                        filled: true, // Preenche o fundo do campo.
                        fillColor: theme.colorScheme.surface, // Cor de fundo.
                      ),
                      // Mapeia a lista de tipos de despesa para itens do Dropdown.
                      items:
                          _tiposDespesa.map((tipo) {
                            return DropdownMenuItem(
                              value: tipo, // Valor associado ao item.
                              // Conteúdo visual do item do Dropdown.
                              child: Row(
                                children: [
                                  // Caixa de seleção visual (checkbox simulado).
                                  Container(
                                    width: 24,
                                    height: 24,
                                    margin: const EdgeInsets.only(right: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: theme.colorScheme.primary,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    // Exibe um ícone de check se o item estiver selecionado.
                                    child:
                                        selectedTipo == tipo
                                            ? Icon(
                                              Icons.check,
                                              size: 18,
                                              color: theme.colorScheme.primary,
                                            )
                                            : null,
                                  ),
                                  // Texto do tipo de despesa.
                                  Text(
                                    tipo,
                                    style: TextStyle(
                                      // Estiliza o texto do item selecionado de forma diferente.
                                      color:
                                          selectedTipo == tipo
                                              ? theme.colorScheme.primary
                                              : Colors.black87,
                                      fontWeight:
                                          selectedTipo == tipo
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(), // Converte o mapa em uma lista.
                      // Função chamada quando um novo item é selecionado.
                      onChanged: (value) {
                        if (value != null) {
                          // Usa o setState do StatefulBuilder para atualizar a UI do modal.
                          setState(() {
                            selectedTipo = value;
                          });
                        }
                      },
                      // Ícone do Dropdown.
                      icon: Icon(
                        Icons.arrow_drop_down_circle,
                        color: theme.colorScheme.primary,
                      ),
                      // Validação do campo.
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, selecione o tipo de despesa';
                        }
                        return null; // Retorna null se a validação passar.
                      },
                    ),
                    const SizedBox(height: 24), // Espaçamento vertical.
                    // Linha com os botões de ação (Cancelar e Salvar/Atualizar).
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.end, // Alinha os botões à direita.
                      children: [
                        // Botão para cancelar e fechar o modal.
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Cancelar',
                            style: TextStyle(color: theme.colorScheme.primary),
                          ),
                        ),
                        const SizedBox(width: 16), // Espaçamento horizontal.
                        // Botão para salvar ou atualizar a despesa.
                        FilledButton(
                          onPressed: () async {
                            // Valida o formulário antes de prosseguir.
                            if (_formKey.currentState!.validate()) {
                              // Cria um objeto Costs com os dados do formulário.
                              final cost = Costs(
                                // Usa o ID existente se estiver editando (model != null), senão gera um novo UUID.
                                id: model?.id ?? const Uuid().v4(),
                                data: dataController.text,
                                preco: double.parse(precoController.text),
                                descricaoDaDespesa: descricaoController.text,
                                tipoDespesa: selectedTipo,
                              );

                              try {
                                // Salva a despesa usando o serviço.
                                await _costsService.saveCost(cost);
                                // Recarrega a lista de despesas para refletir a alteração.
                                await _loadCosts();
                                // Verifica se o widget ainda está montado antes de interagir com o contexto.
                                if (mounted) {
                                  Navigator.pop(context); // Fecha o modal.
                                  // Exibe uma SnackBar de sucesso.
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Despesa salva com sucesso!',
                                        style: TextStyle(
                                          color: theme.colorScheme.onPrimary,
                                        ),
                                      ),
                                      backgroundColor:
                                          theme.colorScheme.primary,
                                    ),
                                  );
                                }
                              } catch (e) {
                                // Em caso de erro ao salvar, exibe um diálogo de erro.
                                if (mounted) {
                                  _showErrorDialog(
                                    'Erro ao salvar despesa: $e',
                                  );
                                }
                              }
                            }
                          },
                          // Define o estilo do botão preenchido.
                          style: FilledButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                          ),
                          // Texto do botão (Salvar ou Atualizar).
                          child: Text(model == null ? 'Salvar' : 'Atualizar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Método assíncrono para remover uma despesa.
  Future<void> _removeCost(Costs cost) async {
    try {
      // 1. Exclui a despesa do banco de dados usando o serviço.
      await _costsService.deleteCost(cost.id);

      // 2. Pequeno atraso para garantir que a exclusão seja processada antes de recarregar.
      await Future.delayed(const Duration(milliseconds: 300));

      // 3. Recarrega a lista de despesas atualizada do serviço.
      final updatedCosts = await _costsService.getAllCosts();

      // 4. Verifica se o widget ainda está montado.
      if (mounted) {
        // 5. Atualiza o estado com a nova lista de despesas.
        setState(() {
          listCosts = updatedCosts;
        });

        // 6. Exibe uma SnackBar de confirmação da exclusão.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Despesa excluída com sucesso!',
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      // Em caso de erro ao remover, exibe um diálogo de erro.
      if (mounted) {
        _showErrorDialog('Erro ao remover despesa: $e');
      }
    }
  }

  // Método para exibir um diálogo de erro genérico.
  void _showErrorDialog(String message) {
    final theme = Theme.of(context); // Obtém o tema atual.
    // Exibe um AlertDialog.
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor:
                theme.colorScheme.surface, // Cor de fundo do diálogo.
            // Título do diálogo.
            title: Text(
              'Erro',
              style: TextStyle(
                color: theme.colorScheme.error, // Cor de erro para o título.
                fontWeight: FontWeight.bold,
              ),
            ),
            // Conteúdo do diálogo (mensagem de erro).
            content: Text(
              message,
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
            // Ações do diálogo.
            actions: [
              // Botão "OK" para fechar o diálogo.
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'OK',
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
              ),
            ],
          ),
    );
  }
}
