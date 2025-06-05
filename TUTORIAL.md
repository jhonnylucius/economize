# **Plano para Tutorial Interativo no App Economize**

## **1. Visão Geral**

Vamos criar um sistema de tutorial interativo que:

- Seja exibido automaticamente na primeira vez que o usuário abrir o app
- Possa ser acessado novamente através dos ícones de ajuda em cada tela
- Destaque os elementos importantes da interface com animações
- Forneça instruções claras sobre como usar cada funcionalidade
- Seja independente do tema do app (mesmo visual em temas claro e escuro)
- Permita ao usuário pular o tutorial ou avançar em seu próprio ritmo

## **2. Arquitetura do Tutorial**

### 2.1 Componentes Principais

1. **TutorialOverlay**: Um widget de sobreposição transparente que cobre toda a tela
2. **TutorialSpotlight**: Destaca um elemento específico da interface
3. **TutorialTooltip**: Exibe texto explicativo próximo ao elemento destacado
4. **TutorialController**: Gerencia o estado e a navegação do tutorial
5. **TutorialStorage**: Armazena se o tutorial já foi visualizado

### 2.2 Fluxo de Dados

TutorialController (estado) → TutorialOverlay (visual) → Interação do Usuário → TutorialController (atualização)

```` 
TutorialController (estado) → TutorialOverlay (visual) → Interação do Usuário → TutorialController (atualização)
````

## **3. Implementação Passo a Passo**

### 3.1 Preparação da Infraestrutura

1. **Serviço de Tutorial**:
    - Criar `TutorialService` singleton para gerenciar o estado global do tutorial
    - Implementar métodos para verificar se o tutorial já foi exibido
    - Utilizar SharedPreferences para persistência
2. **Modelo de Passo do Tutorial**:
    - Criar classe `TutorialStep` com campos para:
        - GlobalKey (referência ao widget)
        - Título da dica
        - Descrição
        - Posição da dica (cima, baixo, esquerda, direita)
        - Widget customizado (opcional)
3. **Controlador de Tutorial**:
    - Implementar `TutorialController` com:
        - Lista de passos do tutorial
        - Índice do passo atual
        - Métodos para avançar, retroceder, pular o tutorial

### 3.2 Componentes Visuais

1. **Overlay do Tutorial**:
    - Widget que cobre toda a tela com fundo semi-transparente
    - Usa `IgnorePointer` seletivamente para permitir interação apenas com elementos relevantes
2. **Spotlight (Destaque)**:
    - Usa `ClipPath` com um `Path` customizado para criar um "buraco" transparente no overlay
    - Animação de pulsação sutil para atrair atenção
    - Efeito de brilho ao redor da área destacada
3. **Tooltip (Dica)**:
    - Card flutuante com cantos arredondados
    - Animações de entrada/saída (fade, escala)
    - Seta apontando para o elemento destacado
    - Botões para navegação (Anterior, Próximo, Pular)

### 3.3 Integração nas Telas

1. **Classe Auxiliar para Definição dos Tutoriais**:
    - Criar `TutorialDefinitions` com métodos estáticos para cada tela
    - Cada método retorna lista de `TutorialStep` específica para a tela
2. **Modificação dos Ícones de Ajuda**:
    - Implementar `onPressed` nos ícones de ajuda existentes para chamar o tutorial específico da tela
3. **Verificação de Primeira Execução**:
    - Na tela inicial, verificar se é a primeira execução do app
    - Se for, iniciar o tutorial automaticamente

## **4. Estrutura dos Tutoriais por Tela**

### 4.1 Tela Inicial (Home)

1. Apresentação do app e navegação básica
2. Explicação do painel de saldo e progresso
3. Como usar as abas de categorias
4. Navegação para outras funcionalidades

### 4.2 Telas Financeiras (Receitas, Despesas)

1. Como adicionar novos registros
2. Explicação das categorias
3. Como filtrar e buscar
4. Funcionalidades de edição e exclusão

### 4.3 Telas de Orçamentos

1. Como criar um orçamento
2. Adição de itens e locais
3. Comparação de preços
4. Análise de economia

### 4.4 Outras Telas

Definir passos específicos para cada tela (Metas, Relatórios, etc.)

## **5. Recursos de Animação**

Aproveitar as animações existentes no projeto:

- **FadeAnimation**: Para entrada/saída suave dos elementos do tutorial
- **ScaleAnimation**: Para destaque e ênfase
- **SlideAnimation**: Para transição entre passos
- **GlassContainer**: Para tooltips com visual moderno e sofisticado

## **6. Personalização e Acessibilidade**

1. **Configurações do Tutorial**:
    - Permitir personalização da velocidade do tutorial
    - Opção para desativar animações (acessibilidade)
2. **Considerações de Acessibilidade**:
    - Garantir contraste adequado no texto
    - Tamanho de fonte ajustável
    - Compatibilidade com leitores de tela

## **7. Testes e Validação**

1. **Testes em Diferentes Dispositivos**:
    - Testar em telefones de diferentes tamanhos
    - Validar comportamento em tablets
2. **Testes de Usabilidade**:
    - Coletar feedback de usuários sobre clareza das instruções
    - Verificar se os usuários conseguem completar o tutorial sem confusão

## **8. Exemplos de Implementação Visual**

**Estilo Visual do Tutorial:**

- Fundo: Semi-transparente (50% de opacidade)
- Destaque: Círculo ou forma adaptativa com borda brilhante
- Tooltip: Card com efeito glass (como seus GlassContainers)
- Texto: Branco ou preto de alto contraste, independente do tema
- Botões: Estilo minimalista, com ícones intuitivos

## **9. Cronograma Sugerido**

1. **Fase 1**: Implementação da infraestrutura básica (1-2 dias)
2. **Fase 2**: Desenvolvimento dos componentes visuais (2-3 dias)
3. **Fase 3**: Definição dos passos do tutorial para cada tela (2-3 dias)
4. **Fase 4**: Integração e testes (1-2 dias)
5. **Fase 5**: Refinamentos baseados em feedback (1-2 dias)

Este plano fornece uma estrutura completa para implementar um sistema de tutorial interativo elegante e eficaz no seu aplicativo, aproveitando os elementos que você já adicionou (GlobalKeys e ícones de ajuda) e as animações existentes no projeto.

## **Como Implementar**

1. Comece criando os modelos (`tutorial_step.dart` e `tutorial_position.dart`)
2. Depois implemente os componentes visuais básicos (widgets)
3. Em seguida, crie o controlador e os serviços
4. Por fim, defina os tutoriais específicos para cada tela

Esta estrutura segue o plano completo e mantém tudo organizado em uma única pasta `tutorial`, facilitando a manutenção e expansão futura do sistema.