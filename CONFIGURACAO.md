# Guia Completo de Configuração - Flutter PDM App

Este guia fornece instruções detalhadas para configurar e executar o aplicativo Flutter PDM App no Android Studio.

## 📋 Índice

1. [Preparação do Ambiente](#preparação-do-ambiente)
2. [Configuração do Firebase](#configuração-do-firebase)
3. [Configuração do Google Maps](#configuração-do-google-maps)
4. [Configuração do Android Studio](#configuração-do-android-studio)
5. [Execução e Testes](#execução-e-testes)
6. [Solução de Problemas](#solução-de-problemas)

## 🛠️ Preparação do Ambiente

### 1. Instalação do Flutter

#### Windows:
```bash
# Baixe o Flutter SDK do site oficial
# https://docs.flutter.dev/get-started/install/windows

# Extraia para C:\flutter
# Adicione C:\flutter\bin ao PATH do sistema
```

#### macOS:
```bash
# Usando Homebrew
brew install flutter

# Ou baixe manualmente do site oficial
```

#### Linux:
```bash
# Baixe o Flutter SDK
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.16.0-stable.tar.xz

# Extraia e configure PATH
tar xf flutter_linux_3.16.0-stable.tar.xz
export PATH="$PATH:`pwd`/flutter/bin"
```

### 2. Verificação da Instalação

```bash
# Verifique se tudo está configurado corretamente
flutter doctor

# Aceite licenças do Android
flutter doctor --android-licenses
```

### 3. Instalação do Android Studio

1. Baixe o Android Studio do [site oficial](https://developer.android.com/studio)
2. Instale seguindo as instruções do sistema operacional
3. Abra o Android Studio e instale os componentes necessários:
   - Android SDK
   - Android SDK Platform-Tools
   - Android SDK Build-Tools
   - Android Emulator

### 4. Configuração do Emulador Android

1. No Android Studio, vá para **Tools > AVD Manager**
2. Clique em **Create Virtual Device**
3. Escolha um dispositivo (recomendado: Pixel 4 ou superior)
4. Selecione uma imagem do sistema (API 30 ou superior)
5. Configure as opções avançadas se necessário
6. Clique em **Finish**

## 🔥 Configuração do Firebase

### Passo 1: Criar Projeto no Firebase

1. Acesse [Firebase Console](https://console.firebase.google.com/)
2. Clique em **Adicionar projeto**
3. Digite o nome do projeto: `flutter-pdm-app`
4. Desabilite Google Analytics (opcional para este projeto)
5. Clique em **Criar projeto**

### Passo 2: Adicionar App Android

1. No painel do projeto, clique no ícone do Android
2. Preencha os dados:
   - **Package name**: `com.example.flutter_pdm_app`
   - **App nickname**: `Flutter PDM App`
   - **SHA-1**: (opcional para desenvolvimento)
3. Clique em **Registrar app**

### Passo 3: Baixar google-services.json

1. Baixe o arquivo `google-services.json`
2. Copie para `android/app/google-services.json`

```bash
# Comando para copiar (ajuste o caminho conforme necessário)
cp ~/Downloads/google-services.json android/app/
```

### Passo 4: Configurar Cloud Messaging

1. No console Firebase, vá para **Build > Cloud Messaging**
2. Clique em **Começar**
3. Anote o **Server Key** (será usado para testes)

### Passo 5: Configurar Notificações de Teste

Para testar notificações via Firebase Console:

1. Vá para **Cloud Messaging > Send your first message**
2. Digite título e texto da mensagem
3. Clique em **Send test message**
4. Cole o token FCM do app (exibido na tela principal)

## 🗺️ Configuração do Google Maps

### Passo 1: Criar Projeto no Google Cloud

1. Acesse [Google Cloud Console](https://console.cloud.google.com/)
2. Crie um novo projeto ou selecione existente
3. Anote o **Project ID**

### Passo 2: Ativar APIs Necessárias

1. No menu lateral, vá para **APIs & Services > Library**
2. Ative as seguintes APIs:
   - **Maps SDK for Android**
   - **Directions API**
   - **Geocoding API**
   - **Places API** (opcional)

### Passo 3: Criar Chave de API

1. Vá para **APIs & Services > Credentials**
2. Clique em **Create Credentials > API Key**
3. Copie a chave gerada
4. Clique em **Restrict Key** para configurar restrições

### Passo 4: Configurar Restrições da API Key

1. Em **Application restrictions**, selecione **Android apps**
2. Adicione restrição:
   - **Package name**: `com.example.flutter_pdm_app`
   - **SHA-1**: (obtenha com `keytool -list -v -keystore ~/.android/debug.keystore`)

### Passo 5: Adicionar API Key ao Projeto

Edite `android/app/src/main/AndroidManifest.xml`:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="SUA_API_KEY_AQUI" />
```

## 🔧 Configuração do Android Studio

### Passo 1: Abrir o Projeto

1. Abra o Android Studio
2. Clique em **Open an existing project**
3. Navegue até a pasta `flutter_pdm_app`
4. Clique em **OK**

### Passo 2: Configurar Flutter Plugin

1. Vá para **File > Settings** (ou **Preferences** no macOS)
2. Navegue para **Plugins**
3. Instale os plugins:
   - **Flutter**
   - **Dart**
4. Reinicie o Android Studio

### Passo 3: Configurar SDK Paths

1. Vá para **File > Project Structure**
2. Em **SDK Location**, configure:
   - **Android SDK Location**: (geralmente `~/Android/Sdk`)
   - **Android NDK Location**: (se necessário)

### Passo 4: Sincronizar Dependências

```bash
# No terminal do Android Studio ou terminal externo
cd flutter_pdm_app
flutter pub get
```

## 🚀 Execução e Testes

### Passo 1: Verificar Configuração

```bash
# Verifique se tudo está configurado
flutter doctor

# Verifique dispositivos disponíveis
flutter devices
```

### Passo 2: Executar o App

#### Via Android Studio:
1. Selecione o dispositivo/emulador na barra superior
2. Clique no botão **Run** (▶️) ou pressione **Shift+F10**

#### Via Terminal:
```bash
# Executar em modo debug
flutter run

# Executar em modo release
flutter run --release

# Executar em dispositivo específico
flutter run -d <device_id>
```

### Passo 3: Testar Funcionalidades

#### Teste de Autenticação Biométrica:
1. Abra o app
2. Na tela de login, toque em **Entrar com Biometria**
3. Use biometria ou toque em **Usar PIN como alternativa**
4. Digite `1234` como PIN

#### Teste de Notificações:
1. Na tela principal, toque no card **Teste**
2. Verifique se a notificação aparece na barra de status
3. Toque na notificação para abrir o app

#### Teste de Mapas:
1. Toque no card **Mapas**
2. Permita acesso à localização quando solicitado
3. Verifique se sua localização aparece no mapa
4. Toque em qualquer ponto para definir destino
5. Toque no botão de rota para calcular caminho

## 🐛 Solução de Problemas

### Problema: Flutter não reconhecido

**Solução:**
```bash
# Verifique se Flutter está no PATH
echo $PATH

# Adicione ao PATH (Linux/macOS)
export PATH="$PATH:/caminho/para/flutter/bin"

# Windows: Adicione via Variáveis de Ambiente do Sistema
```

### Problema: Erro de licenças Android

**Solução:**
```bash
flutter doctor --android-licenses
# Aceite todas as licenças digitando 'y'
```

### Problema: Google Maps não carrega

**Possíveis causas e soluções:**

1. **API Key incorreta:**
   - Verifique se a chave está correta no AndroidManifest.xml
   - Confirme se as APIs estão ativadas no Google Cloud

2. **Restrições da API Key:**
   - Verifique se o package name está correto
   - Confirme o SHA-1 fingerprint

3. **Cotas esgotadas:**
   - Verifique uso da API no Google Cloud Console
   - Configure billing se necessário

### Problema: Notificações não funcionam

**Soluções:**

1. **Arquivo google-services.json:**
   ```bash
   # Verifique se está no local correto
   ls android/app/google-services.json
   ```

2. **Package name:**
   - Confirme se é `com.example.flutter_pdm_app` no Firebase

3. **Teste em dispositivo físico:**
   - Emuladores podem ter limitações com notificações

### Problema: Biometria não funciona

**Soluções:**

1. **Teste em dispositivo físico:**
   - Emuladores têm suporte limitado à biometria

2. **Configurar biometria no dispositivo:**
   - Vá em Configurações > Segurança > Biometria
   - Configure impressão digital ou face unlock

3. **Permissões:**
   - Verifique se as permissões estão no AndroidManifest.xml

### Problema: Erro de build

**Soluções comuns:**

```bash
# Limpar cache e rebuildar
flutter clean
flutter pub get
flutter run

# Verificar versões das dependências
flutter pub deps

# Atualizar dependências
flutter pub upgrade
```

## 📱 Testando em Dispositivo Físico

### Passo 1: Habilitar Modo Desenvolvedor

1. Vá para **Configurações > Sobre o telefone**
2. Toque 7 vezes em **Número da versão**
3. Volte e acesse **Opções do desenvolvedor**
4. Ative **Depuração USB**

### Passo 2: Conectar Dispositivo

1. Conecte o dispositivo via USB
2. Autorize a depuração USB no dispositivo
3. Verifique se o dispositivo aparece:
   ```bash
   flutter devices
   ```

### Passo 3: Executar no Dispositivo

```bash
# Execute especificando o dispositivo
flutter run -d <device_id>
```

## 🔍 Logs e Debug

### Visualizar Logs

```bash
# Logs do Flutter
flutter logs

# Logs específicos do Android
adb logcat

# Filtrar logs por tag
adb logcat -s flutter
```

### Debug no Android Studio

1. Coloque breakpoints no código
2. Execute em modo debug
3. Use o debugger integrado para inspecionar variáveis

## 📊 Monitoramento

### Firebase Analytics (Opcional)

Para adicionar analytics:

1. No Firebase Console, ative **Analytics**
2. Adicione dependência:
   ```yaml
   firebase_analytics: ^10.7.4
   ```

### Crashlytics (Opcional)

Para monitorar crashes:

1. No Firebase Console, ative **Crashlytics**
2. Adicione dependência:
   ```yaml
   firebase_crashlytics: ^3.4.9
   ```

---

**Este guia cobre todos os aspectos necessários para configurar e executar o Flutter PDM App com sucesso. Para dúvidas específicas, consulte a documentação oficial do Flutter e Firebase.**

