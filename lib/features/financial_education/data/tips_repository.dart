import 'package:economize/features/financial_education/models/financial_tip.dart';
import 'package:economize/service/moedas/currency_service.dart';

class TipsRepository {
  static final CurrencyService _currencyService = CurrencyService();
  static List<FinancialTip> get tips => [
        // Dicas de Economia
        FinancialTip(
          title: 'Compras à Vista: Seu Melhor Negócio',
          description:
              'Pagar à vista pode gerar economias significativas. Muitas lojas oferecem descontos que podem chegar a 15% ou mais.',
          category: TipCategory.savingMoney,
          shortSummary: 'Economize até 15% nas suas compras pagando à vista',
          steps: [
            'Sempre pergunte o preço à vista',
            'Compare o desconto à vista com o parcelamento',
            'Negocie um desconto maior mostrando preços de concorrentes',
            'Guarde o dinheiro que economizou para futuras compras',
          ],
          examples: [
            'Em uma geladeira de ${_currencyService.formatCurrency(1500)}, você pode economizar até ${_currencyService.formatCurrency(225)} (15%) pagando à vista',
            'Use o dinheiro economizado para criar uma reserva de emergência',
          ],
        ),

        // Dicas de Compras Inteligentes
        const FinancialTip(
          title: 'Lista de Compras: Sua Aliada',
          description:
              'Fazer compras com uma lista bem planejada pode reduzir gastos desnecessários em até 30%.',
          category: TipCategory.smartShopping,
          shortSummary: 'Evite gastos por impulso usando uma lista',
          steps: [
            'Faça um levantamento do que realmente precisa',
            'Organize a lista por categorias (alimentos, limpeza, etc)',
            'Compare preços em diferentes mercados',
            'Evite ir às compras com fome',
            'Siga estritamente sua lista',
          ],
          examples: [
            'Use o app Economize\$ para criar suas listas',
            'Compare preços entre mercados diferentes',
          ],
        ),

        // Dicas de Orçamento
        FinancialTip(
          title: 'Regra 50-30-20',
          description:
              'Uma forma simples de organizar seu orçamento: 50% para necessidades básicas, 30% para gastos pessoais e 20% para economias.',
          category: TipCategory.budgeting,
          shortSummary: 'Organize seu dinheiro de forma simples e eficiente',
          steps: [
            'Some toda sua renda mensal',
            'Separe 50% para contas essenciais (aluguel, água, luz, etc)',
            'Reserve 30% para gastos flexíveis (lazer, roupas)',
            'Guarde 20% para emergências e objetivos futuros',
          ],
          examples: [
            'Com um salário de ${_currencyService.formatCurrency(2000)}: ${_currencyService.formatCurrency(1000)} para essenciais, ${_currencyService.formatCurrency(600)} para gastos pessoais, ${_currencyService.formatCurrency(400)} para guardar',
          ],
        ),

        // Dicas de Negociação
        const FinancialTip(
          title: 'Poder da Pesquisa de Preços',
          description:
              'Use a pesquisa de preços como ferramenta de negociação. Lojas geralmente igualam ofertas de concorrentes.',
          category: TipCategory.negotiation,
          shortSummary: 'Economize comparando preços e negociando',
          steps: [
            'Pesquise o produto em várias lojas',
            'Tire prints ou fotos dos preços',
            'Mostre os preços mais baixos para a loja',
            'Peça desconto adicional para pagamento à vista',
          ],
          examples: [
            'Muitas lojas oferecem 5% de desconto só por você mostrar um preço menor',
            'Em compras grandes, pode economizar centenas de reais',
          ],
        ),

        // Dicas de Investimento Básico
        FinancialTip(
          title: 'Reserva de Emergência Primeiro',
          description:
              'Antes de qualquer investimento, tenha uma reserva de emergência equivalente a 6 meses de despesas básicas.',
          category: TipCategory.investment,
          shortSummary: 'Comece sua vida financeira com segurança',
          steps: [
            'Calcule seus gastos mensais essenciais',
            'Multiplique por 6',
            'Guarde esse valor em uma poupança ou CDB de liquidez diária',
            'Só invista em outros produtos após ter sua reserva',
          ],
          examples: [
            'Se seus gastos são ${_currencyService.formatCurrency(2000)}/mês, sua reserva deve ser ${_currencyService.formatCurrency(12000)}',
            'Use uma conta digital sem taxas para guardar',
          ],
        ),
        // Adicionando as dicas do cartão de crédito
        const FinancialTip(
          title: 'Uso Inteligente do Cartão de Crédito',
          description:
              'Como usar o cartão de crédito de forma consciente e segura',
          category: TipCategory.financeiro,
          shortSummary: 'Dicas essenciais para uso do cartão de crédito',
          steps: [
            '1. Controle seus Gastos - O cartão é uma forma de pagamento, não um dinheiro extra. Seus gastos nunca devem ultrapassar sua renda. Acompanhe sua fatura regularmente e mantenha o controle do orçamento.',
            '2. Parcelamento Consciente - Escolha sempre o menor número de parcelas possível e prefira opções sem juros. Verifique se as parcelas cabem no seu orçamento futuro.',
            '3. Segurança é Fundamental - Nunca empreste seu cartão ou compartilhe informações. Em caso de perda, bloqueie imediatamente. Mantenha suas senhas seguras.',
            '4. Aproveite os Benefícios - Utilize os programas de pontos, cashback e descontos. Pesquise as vantagens oferecidas pelo seu cartão.',
            '5. Concentre seus Gastos - Use poucos cartões para facilitar o controle. Antes de contratar, avalie condições e benefícios. Concentrar gastos ajuda a acumular mais pontos.',
          ],
          examples: [
            'Configure alertas de compras no app do seu banco',
            'Anote todas as compras parceladas em um calendário',
            'Compare as vantagens entre diferentes cartões antes de escolher',
            'Use o app para acompanhar seus gastos em tempo real',
          ],
        ),
      ];
}
