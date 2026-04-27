# Conexão Saúde 🏥

Um aplicativo Flutter para gerenciamento de medicamentos e informações de saúde, com integração Firebase para sincronização em tempo real e armazenamento local com Hive.

## 📋 Sobre o Projeto

**Conexão Saúde** é um aplicativo móvel desenvolvido em Flutter que permite:
- ✅ Gerenciar listas de medicamentos personalizadas
- 📱 Sincronizar dados com Firebase
- 💾 Armazenar dados localmente com Hive para acesso offline
- 🎨 Interface intuitiva com Material Design

### Tecnologias Utilizadas
- **Flutter**: Framework de desenvolvimento
- **Firebase**: Backend e sincronização em nuvem
- **Hive**: Banco de dados local
- **Riverpod**: Gerenciamento de estado
- **Dart**: Linguagem de programação

---

## 🚀 Como Começar

### Requisitos Mínimos

#### Windows, macOS e Linux (todas as plataformas)
- **Git**: Para clonar o repositório
- **Flutter SDK**: v3.11.4 ou superior
- **Dart**: v3.11.4 ou superior (geralmente incluído com Flutter)

#### Android
- **Android Studio**: IDE recomendada
- **Android SDK**: API 21 ou superior
- **Emulador Android** ou **Dispositivo Android** conectado por USB

#### Linux
- **build-essential**: Ferramentas de compilação
- **clang**: Compilador C
- **cmake**: Ferramenta de construção
- **ninja-build**: Sistema de construção
- **pkg-config**: Ferramenta para detectar dependências

---

## 💻 Instalação Detalhada

### 1️⃣ Instalar Flutter SDK

#### No Linux

**Opção A: Download Manual**

```bash
# Crie um diretório para o Flutter
mkdir -p ~/development
cd ~/development

# Download do Flutter SDK (versão estável)
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.0-stable.tar.xz

# Extrair
tar xf flutter_linux_3.24.0-stable.tar.xz

# Adicionar ao PATH permanentemente
echo 'export PATH="$PATH:$HOME/development/flutter/bin"' >> ~/.bashrc
source ~/.bashrc

# Verificar a instalação
flutter --version
```

**Opção B: Usando apt (em distribuições baseadas em Debian/Ubuntu)**

```bash
# Adicionar repositório
sudo apt update
sudo apt install -y git xz-utils zip libglu1-mesa

# Clonar o Flutter do GitHub
git clone https://github.com/flutter/flutter.git ~/development/flutter

# Adicionar ao PATH
echo 'export PATH="$PATH:$HOME/development/flutter/bin"' >> ~/.bashrc
source ~/.bashrc
```

#### No Android

1. Baixar do site oficial: [flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install)
2. Descompactar em um diretório (`C:\dev\flutter` é comum no Windows)
3. Adicionar ao PATH do sistema
4. No PowerShell (como Administrador):
```powershell
$env:PATH += ";C:\dev\flutter\bin"
```

### 2️⃣ Instalar Dependências do Sistema

#### Linux

```bash
# Instalar dependências obrigatórias
sudo apt update
sudo apt install -y build-essential clang cmake git ninja-build pkg-config libgtk-3-dev

# Instalar Java (necessário para Android)
sudo apt install -y default-jdk

# Instalar Android SDK (via Android Studio é mais fácil)
# Após instalar Android Studio, as dependências serão instaladas automaticamente
```

#### Android (Windows/macOS/Linux)

```bash
# Depois de instalar Android Studio, configure o SDK:
flutter config --android-sdk /caminho/para/android/sdk

# Ou deixe Flutter autodetectar:
flutter doctor
```

### 3️⃣ Verificar Instalação

Execute o comando abaixo para verificar se tudo está pronto:

```bash
flutter doctor
```

**Saída esperada (você pode ignorar as plataformas que não vai usar):**

```
Doctor summary (to see all details run flutter doctor -v):
[✓] Flutter (Channel stable, 3.24.0, on Linux, locale pt_BR.UTF-8)
[✓] Android toolchain - develop for Android devices (Android SDK version 35.0.0)
[✓] Linux toolchain - develop for Linux
[✓] Android Studio (version 2024.1)
[✓] VS Code (version 1.95.0)
[✓] Connected device (1 available)

• No issues found!
```

---

## 🔧 Configuração Inicial do Projeto

### 1️⃣ Clonar o Repositório

```bash
cd ~/Documentos
git clone <URL_DO_REPOSITORIO> conexao_saude
cd conexao_saude
```

### 2️⃣ Restaurar Dependências

```bash
# Baixar todas as dependências do pubspec.yaml
flutter pub get

# Gerar arquivos de código necessários (Hive, etc)
flutter pub run build_runner build
```

Se houver erro com `build_runner`, execute novamente com força:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3️⃣ Configurar Firebase (Importante!)

O projeto utiliza Firebase. Você precisa configurar:

#### Android Firebase Setup

1. **Criar projeto no Firebase Console:**
   - Acesse [console.firebase.google.com](https://console.firebase.google.com)
   - Clique em "Criar Projeto"
   - Nome: "conexao_saude"
   - Ative Google Analytics (opcional)
   - Clique "Criar Projeto"

2. **Adicionar aplicativo Android:**
   - No Firebase Console, clique em "+ Adicionar app"
   - Selecione "Android"
   - Package name: `com.conexao_saude` (verificar em `android/app/build.gradle`)
   - Clique em "Registrar app"
   - Baixe o arquivo `google-services.json`
   - Coloque em: `android/app/google-services.json`

3. **Habilitar Firestore Database:**
   - No Firebase Console, vá para "Firestore Database"
   - Clique em "Criar banco de dados"
   - Selecione "Modo Teste" (para desenvolvimento)
   - Escolha localidade mais próxima
   - Clique em "Criar"

4. **Configurar regras de segurança (temporário para testes):**
   ```
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /{document=**} {
         allow read, write: if true;
       }
     }
   }
   ```

---

## 📱 Executar no Android

### Opção 1: Usando Emulador Android

#### Criar Emulador (primeira vez)

```bash
# Listar dispositivos virtuais disponíveis
flutter emulators

# Criar um novo emulador (se não houver nenhum)
# No Android Studio: Tools > Device Manager > Create Virtual Device
# Ou via CLI:
# flutter emulators --create --name android_emulator
```

#### Iniciar Emulador

```bash
# Se já tem emulador criado
flutter emulators --launch android_emulator

# Ou abra pelo Android Studio
```

#### Rodar Aplicativo

```bash
# Com emulador ligado
flutter run

# Ou especificar o dispositivo
flutter run -d emulator-5554
```

### Opção 2: Usando Dispositivo Android Real

#### Habilitar Debug Mode no Telefone

1. Vá para **Configurações** > **Sobre o telefone**
2. Toque em **Número da compilação** 7 vezes
3. Volte para **Configurações** > **Opções de desenvolvedor**
4. Ative **Depuração USB**
5. Conecte o telefone ao computador com USB

#### Executar

```bash
# Listar dispositivos conectados
flutter devices

# Rodar no dispositivo
flutter run

# Ou rodar em modo release (mais rápido)
flutter run --release
```

### Monitorar Logs

```bash
# Ver logs em tempo real
flutter logs

# Ver apenas mensagens importantes
flutter logs -c
```

---

## 🐧 Executar no Linux

### Requisitos Adicionais Linux

```bash
# Instalar dependências de desenvolvimento
sudo apt install -y \
  libgtk-3-dev \
  libgl1-mesa-dev \
  libxss-dev \
  libudev-dev \
  pkg-config \
  cmake \
  ninja-build
```

### Executar Aplicativo

```bash
# No diretório do projeto
flutter run -d linux

# Ou em modo release (mais rápido)
flutter run -d linux --release
```

### Build para Linux Desktop

```bash
# Criar executável
flutter build linux --release

# Executável será criado em:
# build/linux/x64/release/bundle/conexao_saude
```

---

## 📦 Gerenciar Dependências

### Ver Dependências

```bash
# Listar todas as dependências
flutter pub pubspec

# Ver versões disponíveis de um pacote
flutter pub outdated
```

### Atualizar Dependências

```bash
# Atualizar para versões compatíveis
flutter pub upgrade

# Atualizar para versões maiores (cuidado!)
flutter pub upgrade --major-versions
```

### Adicionar Nova Dependência

```bash
# Exemplo: adicionar um novo pacote
flutter pub add nome_do_pacote

# Com versão específica
flutter pub add nome_do_pacote:^1.0.0
```

---

## 🏗️ Estrutura do Projeto

```
lib/
├── main.dart                 # Ponto de entrada do app
├── firebase_options.dart     # Configurações Firebase
├── core/
│   └── theme/               # Temas e estilos globais
├── data/
│   └── models/              # Modelos de dados (Hive)
└── presentation/
    └── home/
        └── pages/           # Páginas da aplicação

android/                     # Código Android nativo
linux/                       # Código Linux nativo
```

---

## 🐛 Resolução de Problemas

### Problema: "Flutter command not found"

```bash
# Adicione ao PATH permanentemente
echo 'export PATH="$PATH:$HOME/development/flutter/bin"' >> ~/.bashrc
source ~/.bashrc

# Verifique
flutter --version
```

### Problema: Erro ao executar "flutter doctor"

```bash
# Limpe cache do Dart
dart pub cache clean

# Tente novamente
flutter doctor
```

### Problema: Build falha no Android

```bash
# Limpe builds anteriores
flutter clean

# Restaure dependências
flutter pub get

# Tente novamente
flutter run
```

### Problema: Firebase não funciona

```bash
# Verifique se google-services.json está em android/app/
ls android/app/google-services.json

# Regenere arquivos de código
flutter pub run build_runner build --delete-conflicting-outputs
```

### Problema: Hive com erro "Adapter not registered"

```bash
# Regenere adaptadores
flutter pub run build_runner build --delete-conflicting-outputs

# Se persistir, limpe e tente novamente
flutter clean
flutter pub get
flutter pub run build_runner build
```

### Problema: Emulador não aparece

```bash
# Listar emuladores
flutter emulators

# Se nenhum emulador aparecer, crie um via Android Studio
# Tools > Device Manager > Create Virtual Device
```

---

## 📊 Monitorar Performance

### Usar DevTools

```bash
# Iniciar DevTools (interface gráfica para debugging)
flutter pub global activate devtools
devtools

# Ou durante a execução
flutter run
# Pressione 'd' durante a execução para abrir DevTools
```

### Comandos Úteis Durante Execução

Com o app rodando via `flutter run`, você pode:

| Tecla | Ação |
|-------|------|
| `r` | Hot Reload (recarregar código) |
| `R` | Hot Restart (reiniciar app) |
| `p` | Mostrar performance |
| `i` | Informações do widget |
| `w` | Mostrar widget tree |
| `q` | Sair |

---

## 🔄 Workflow de Desenvolvimento

### Ciclo de Desenvolvimento Recomendado

```bash
# 1. Iniciar emulador (ou conectar dispositivo)
flutter emulators --launch android_emulator

# 2. Executar o app em modo debug
flutter run

# 3. Durante desenvolvimento:
# - Editar arquivos
# - Pressionar 'r' no terminal para Hot Reload
# - Ver mudanças em tempo real

# 4. Testar mudanças significativas
# - Pressionar 'R' para Hot Restart completo

# 5. Quando terminar
# - Pressionar 'q' para sair
```

### Boas Práticas

✅ Use Hot Reload frequentemente para desenvolvimento rápido
✅ Teste em um dispositivo real regularmente
✅ Execute `flutter analyze` para verificar código
✅ Use `flutter format` para formatar código
✅ Mantenha dependências atualizadas

---

## 📚 Recursos Adicionais

- [Documentação Flutter](https://flutter.dev/docs)
- [Firebase para Flutter](https://firebase.flutter.dev/)
- [Hive Database](https://docs.hivedb.dev/)
- [Riverpod](https://riverpod.dev/)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)

---

## 🤝 Contribuindo

Para contribuir com o projeto:

1. Crie uma branch: `git checkout -b feature/MinhaFeature`
2. Commit suas mudanças: `git commit -am 'Adiciona MinhaFeature'`
3. Push para a branch: `git push origin feature/MinhaFeature`
4. Abra um Pull Request

---

## 📝 Licença

Este projeto está sob licença MIT. Veja o arquivo LICENSE para mais detalhes.

---

## ✉️ Contato

Para dúvidas ou sugestões, abra uma issue no repositório ou entre em contato com o desenvolvedor.

---

**Última atualização:** 20 de abril de 2026
**Versão do Flutter:** 3.11.4+
