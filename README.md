<p align="center">
  <img src=".github/assets/landing-v2.png" alt="Church Hub" width="800"/>
</p>

<h1 align="center">Church Hub</h1>

<p align="center">
  Plataforma open source para gestão de igrejas — gratuita, moderna e feita com Flutter.
</p>

<p align="center">
  <a href="https://church-hub-prod.web.app/" target="_blank"><strong>🌐 Versão Web</strong></a> &nbsp;|&nbsp;
  <a href="https://apps.apple.com/br/app/church-hub/id6766631440" target="_blank"><strong>🍎 App Store</strong></a> &nbsp;|&nbsp;
  <strong>🤖 Google Play</strong> &nbsp;|&nbsp;
  <a href="#-contribuindo">Contribuir</a> &nbsp;|&nbsp;
  <a href="#-doações">Apoiar o projeto</a>
</p>

<p align="center">
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter"/>
  <img alt="Firebase" src="https://img.shields.io/badge/Firebase-enabled-FFCA28?logo=firebase"/>
  <img alt="License" src="https://img.shields.io/badge/license-AGPL--3.0-blue"/>
  <img alt="Platform" src="https://img.shields.io/badge/platform-Android%20%7C%20iOS%20%7C%20Web-lightgrey"/>
</p>

---

## ✨ Sobre o projeto

O **Church Hub** nasceu da vontade de ajudar igrejas a se modernizarem e organizarem melhor o seu dia a dia — sem custo algum. É um app gratuito e open source, construído com Flutter e Firebase, disponível para **Android, iOS e Web**.

Funcionalidades principais:
- 🏛️ Cadastro e gestão da igreja
- 👥 Gestão de pessoas e membros
- 📅 Agenda de eventos
- 🎵 Biblioteca de músicas e letras (Holyrics)
- 🎼 Avaliações musicais
- 📋 Sociedades e grupos internos
- 💳 Gestão de planos e billing
- 🔔 Notificações push
- 🔐 Autenticação com Google e Apple

---

## 🚀 Rodando localmente

### Pré-requisitos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (versão `^3.x`)
- [Firebase CLI](https://firebase.google.com/docs/cli)
- Conta no [Firebase](https://firebase.google.com/) com um projeto criado
- [Node.js](https://nodejs.org/) (para as Cloud Functions)

### 1. Clone o repositório

```bash
git clone https://github.com/arcenojackson/church-hub.git
cd church-hub
```

### 2. Configure o Firebase

Crie um projeto no [Firebase Console](https://console.firebase.google.com/) e adicione os apps para Android, iOS e Web. Depois, configure os arquivos necessários:

- **Android:** coloque o `google-services.json` em `android/app/`
- **iOS:** coloque o `GoogleService-Info.plist` em `ios/Runner/`
- **Web / geral:** crie o arquivo `lib/src/core/config/app_secrets.dart` com base no exemplo abaixo:

```dart
// lib/src/core/config/app_secrets.dart
class AppSecrets {
  static const String firebaseApiKey = 'SUA_API_KEY';
  static const String firebaseProjectId = 'SEU_PROJECT_ID';
  // ... demais configurações do Firebase
}
```

> ⚠️ Este arquivo está no `.gitignore` e **nunca deve ser commitado**.

### 3. Instale as dependências

```bash
flutter pub get
```

### 4. Instale as dependências das Cloud Functions

```bash
cd functions && npm install && cd ..
```

### 5. Rode o app

```bash
# Web
flutter run -d chrome

# Android (com dispositivo/emulador conectado)
flutter run -d android

# iOS (somente macOS)
flutter run -d ios
```

> 💡 Dica: use o script `build.sh` para gerar os builds de produção para Android e iOS de uma vez só.

---

## 🗂️ Estrutura do projeto

```
lib/
└── src/
    ├── core/           # Configurações, utilitários e rede
    ├── shared/         # Widgets, tema, serviços e estado compartilhados
    ├── modules/        # Módulos de funcionalidade
    │   ├── auth/       # Autenticação (Google, Apple)
    │   ├── church/     # Gestão da igreja
    │   ├── events/     # Eventos e agenda
    │   ├── holyrics/   # Letras e músicas
    │   ├── musics/     # Biblioteca musical
    │   ├── people/     # Membros e pessoas
    │   ├── societies/  # Grupos e sociedades
    │   ├── billing/    # Planos e pagamentos
    │   ├── notifications/ # Notificações push
    │   └── ...
    └── web/            # Páginas exclusivas da versão web
```

---

## 🤝 Contribuindo

Contribuições são muito bem-vindas! Seja corrigindo um bug, sugerindo uma feature ou melhorando a documentação — toda ajuda conta.

1. Faça um **fork** do repositório
2. Crie uma branch para sua feature ou correção: `git checkout -b feature/minha-feature`
3. Faça suas alterações e commit: `git commit -m 'feat: minha feature'`
4. Envie para o seu fork: `git push origin feature/minha-feature`
5. Abra um **Pull Request** explicando o que foi feito

Por favor, siga o padrão de commits [Conventional Commits](https://www.conventionalcommits.org/) e mantenha o código alinhado com as convenções do projeto.

---

## 💙 Doações

O Church Hub é e sempre será gratuito. Se ele te ajudou ou você quer apoiar o desenvolvimento, qualquer contribuição faz a diferença!

> **[💳 Fazer uma doação](https://donate.stripe.com/5kQeVddXg5ZpfOdezO87K00)**

---

## 📄 Licença

Distribuído sob a licença [GNU AGPL v3](LICENSE). Ao usar, modificar ou hospedar este software, você é obrigado a disponibilizar o código-fonte das suas modificações.
