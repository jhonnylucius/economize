Vou ajudar a melhorar seu README para torná-lo detalhado e adequado para um projeto que será compartilhado como exemplo para estudantes. Aqui está uma versão completa com links para gráficos, imagens e vídeos:

# Economize$

![Logo do app](assets/icon_removedbg.png)

## 📱 Sobre o Projeto

**Economize$** é um aplicativo Flutter completo para controle financeiro pessoal, desenvolvido para auxiliar usuários a gerenciar suas finanças de forma simples e eficiente. O projeto foi criado como um exemplo prático e educacional para estudantes e desenvolvedores Flutter.

O aplicativo oferece ferramentas para:
- Controle de receitas e despesas
- Planejamento de orçamentos
- Comparação de preços entre estabelecimentos
- Análise de tendências financeiras
- Dicas de educação financeira
- Calculadora de metas

[![Vídeo de demonstração](https://img.shields.io/badge/YouTube-Assista_ao_vídeo_de_demonstração-FF0000?style=for-the-badge&logo=youtube&logoColor=white)](https://youtu.be/Hlzw3-Sy5Bg)

## 🛠️ Tecnologias e Pacotes Utilizados

- **Flutter** (Material 3)
- **Provider** para gerenciamento de tema e estados
- **Sqflite** para banco de dados local
- **Intl** para formatação de datas e moedas
- **Percent Indicator** para gráficos circulares
- **FL Chart** para gráficos de linha e pizza
- **PDF** e **Share Plus** para exportação de relatórios
- **Logger** para debug
- **Path Provider** para manipulação de arquivos
- **Mask Text Input Formatter** para máscaras de campos
- **UUID** para geração de IDs únicos

## 📊 Arquitetura e Estrutura do Projeto

O projeto segue uma arquitetura limpa e organizada, ideal para estudo e expansão:

```
lib/
├── data/                # DAOs e helpers para banco de dados SQLite
├── controller/          # Controladores para gerenciamento de estados
├── features/            # Funcionalidades especiais (ex: educação financeira)
├── icons/               # Ícones customizados
├── model/               # Modelos de dados (Cost, Revenue, Budget, etc)
├── provider/            # Providers para gerenciamento de estado
├── screen/              # Telas principais do app
├── service/             # Serviços de negócio (ex: PDF, relatórios)
├── theme/               # Gerenciamento e definição de temas
├── utils/               # Utilitários e helpers
├── widgets/             # Componentes reutilizáveis
└── main.dart            # Ponto de entrada do app
```



## 🧩 Funcionalidades

### Dashboard e Saldo Mensal
Visão geral das suas finanças com gráficos intuitivos:

<p float="left">
<img src="https://raw.githubusercontent.com/jhonnylucius/economize/main/docs/foto8.jpg" width="45%" />
<img src="https://raw.githubusercontent.com/jhonnylucius/economize/main/docs/foto7.jpg" width="45%" />
</p>

### Lançamentos
Cadastre receitas e despesas com categorias personalizáveis:

<p float="left">
  <img src="https://raw.githubusercontent.com/jhonnylucius/economize/main/docs/foto6.jpg" width="45%" />
  <img src="https://raw.githubusercontent.com/jhonnylucius/economize/main/docs/foto5.jpg" width="45%" />
</p>

### Orçamentos
Crie orçamentos e compare preços entre estabelecimentos:

<p float="left">
  <img src="https://raw.githubusercontent.com/jhonnylucius/economize/main/docs/foto3.jpg" width="40%" />
  <img src="https://raw.githubusercontent.com/jhonnylucius/economize/main/docs/foto4.jpg" width="40%" />
</p>

### Tendência de Finanças
Visualize gráficos de evolução de receitas e despesas ao longo do tempo:

<p float="left">
  <img src="https://raw.githubusercontent.com/jhonnylucius/economize/main/docs/capa1.png" width="60%" />
  </p>

### Ferramentas Educacionais
Dicas financeiras e calculadora de metas para planejamento:

<p float="left">
  <img src="https://raw.githubusercontent.com/jhonnylucius/economize/main/docs/foto11.jpg" width="45%" />
</p>

## 🚀 Como Executar o Projeto

### Pré-requisitos
- Flutter 3.10.0 ou superior
- Dart 3.0.0 ou superior

### Passos para executar
```bash
# Clone este repositório
git clone https://github.com/jhonnylucius/economize.git

# Entre na pasta do projeto
cd economize

# Instale as dependências
flutter pub get

# Execute o aplicativo
flutter run
```

## 📋 Fluxo do Aplicativo

O diagrama abaixo ilustra o fluxo principal do aplicativo e como as telas se comunicam:

![Fluxo do aplicativo](https://raw.githubusercontent.com/jhonnylucius/economize/main/docs/graficogoogle.jpg)

## 📊 Recursos Adicionais

- **Temas**: Suporte a tema claro e tema roxo escuro (padrão)
- **Persistência**: Dados salvos localmente, sem necessidade de internet
- **Responsividade**: Interface adaptável a diferentes tamanhos de tela
- **Acessibilidade**: Elementos com tamanhos adequados para melhor interação
- **Performance**: Otimizado para carregamento rápido e baixo consumo de memória

## 🧪 Testes

O projeto inclui testes unitários e de interface. Para executá-los:

```bash
# Executar todos os testes
flutter test

# Executar apenas testes unitários
flutter test test/unit/

# Executar testes de widget
flutter test test/widget/
```

## 🤝 Como Contribuir

Se você é estudante ou desenvolvedor e deseja contribuir com o projeto:

1. Faça um Fork do repositório
2. Crie uma branch para sua feature (`git checkout -b feature/MinhaFeature`)
3. Faça commit das alterações (`git commit -m 'Adiciona MinhaFeature'`)
4. Faça push para a branch (`git push origin feature/MinhaFeature`)
5. Abra um Pull Request

### Convenções de código
- Utilize análise estática com `flutter analyze`
- Siga os padrões de nomenclatura do Flutter/Dart
- Documente classes e métodos públicos
- Mantenha os testes atualizados

## 📝 Licença

Este projeto está sob a licença MIT. Veja o arquivo LICENSE para mais detalhes.

## 📸 Galeria Completa

Acesse nossa [galeria completa de screenshots](https://github.com/jhonnylucius/economize/main/docs) para ver todas as telas do aplicativo.


## 🙏 Agradecimentos

Agradecemos a todos os estudantes e professores que contribuíram para este projeto educacional.

---

Desenvolvido com 💜 para a comunidade Flutter brasileira.  
© 2025 Union Dev Team

## 📞 Contato

Para dúvidas, sugestões ou parcerias, entre em contato através do e-mail: [contato@union.dev.br](mailto:contato@union.dev.br)