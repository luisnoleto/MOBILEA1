# Flutter PDM App - Aplicativo para Programação para Dispositivos Móveis II

Este é um aplicativo Flutter completo desenvolvido para a disciplina de Programação para Dispositivos Móveis II, implementando as três funcionalidades obrigatórias solicitadas: **Autenticação Biométrica**, **Push Notifications** e **Geolocalização com Google Maps**.

## 📱 Funcionalidades Implementadas

### 1. Autenticação por Biometria
- ✅ Suporte a impressão digital (fingerprint)
- ✅ Suporte a reconhecimento facial (face ID)
- ✅ Detecção automática dos tipos de biometria disponíveis
- ✅ Fallback para PIN personalizado quando biometria não está disponível
- ✅ Persistência de sessão de autenticação

### 2. Push Notifications
- ✅ Integração completa com Firebase Cloud Messaging (FCM)
- ✅ Recebimento de notificações em foreground e background
- ✅ Exibição de notificações na barra de status
- ✅ Gerenciamento de notificações com histórico
- ✅ Notificações de teste integradas

### 3. Geolocalização e Google Maps
- ✅ Integração com Google Maps Flutter
- ✅ Exibição da localização atual do usuário
- ✅ Marcadores personalizados no mapa
- ✅ Cálculo de rotas entre dois pontos
- ✅ Informações detalhadas de locais selecionados
- ✅ Interface intuitiva para seleção de destinos

## 🛠️ Tecnologias Utilizadas

- **Flutter**: Framework principal (versão 3.x)
- **Dart**: Linguagem de programação
- **Firebase**: Backend para notificações
- **Google Maps**: Serviços de mapas e geolocalização
- **Android Studio**: IDE de desenvolvimento

## 📋 Dependências Principais

```yaml
dependencies:
  # Autenticação Biométrica
  local_auth: ^2.1.6
  local_auth_android: ^1.0.34
  local_auth_ios: ^1.1.4
  
  # Firebase e Push Notifications
  firebase_core: ^2.24.2
  firebase_messaging: ^14.7.10
  flutter_local_notifications: ^16.3.2
  
  # Google Maps e Geolocalização
  google_maps_flutter: ^2.5.0
  geolocator: ^10.1.0
  geocoding: ^2.1.1
  
  # Utilitários
  provider: ^6.1.1
  go_router: ^12.1.3
  shared_preferences: ^2.2.2
  permission_handler: ^11.2.0
  http: ^1.1.2
```

## 🚀 Instalação e Configuração

### Pré-requisitos

1. **Flutter SDK** (versão 3.0 ou superior)
2. **Android Studio** com Android SDK
3. **Conta Google** para Firebase e Google Maps
4. **Dispositivo Android** ou emulador (API 21+)

### Passo 1: Clonar e Configurar o Projeto

```bash
# Clone o projeto
git clone <url-do-repositorio>
cd flutter_pdm_app

# Instale as dependências
flutter pub get
```

### Passo 2: Configurar Firebase

1. **Criar projeto no Firebase Console**:
   - Acesse [Firebase Console](https://console.firebase.google.com/)
   - Clique em "Adicionar projeto"
   - Siga as instruções para criar o projeto

2. **Adicionar app Android**:
   - No console do Firebase, clique em "Adicionar app" > Android
   - Package name: `com.example.flutter_pdm_app`
   - Baixe o arquivo `google-services.json`

3. **Configurar google-services.json**:
   ```bash
   # Copie o arquivo para o diretório correto
   cp google-services.json android/app/
   ```

4. **Ativar Firebase Cloud Messaging**:
   - No console Firebase, vá para "Cloud Messaging"
   - Ative o serviço

### Passo 3: Configurar Google Maps

1. **Obter API Key do Google Maps**:
   - Acesse [Google Cloud Console](https://console.cloud.google.com/)
   - Crie um novo projeto ou selecione existente
   - Ative as APIs: "Maps SDK for Android" e "Directions API"
   - Crie uma chave de API

2. **Configurar API Key no projeto**:
   ```xml
   <!-- Em android/app/src/main/AndroidManifest.xml -->
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="SUA_API_KEY_AQUI" />
   ```

### Passo 4: Configurar Permissões

As permissões já estão configuradas no `AndroidManifest.xml`, incluindo:

- **Internet**: Para Firebase e Google Maps
- **Localização**: Para GPS e geolocalização
- **Biometria**: Para autenticação biométrica
- **Notificações**: Para push notifications

### Passo 5: Executar o Aplicativo

```bash
# Verificar dispositivos conectados
flutter devices

# Executar em modo debug
flutter run

# Ou executar em modo release
flutter run --release
```

## 📱 Como Testar as Funcionalidades

### Testando Autenticação Biométrica

1. **Com Biometria Disponível**:
   - Abra o app
   - Toque em "Entrar com Biometria"
   - Use sua impressão digital ou face ID

2. **Fallback para PIN**:
   - Toque em "Usar PIN como alternativa"
   - Digite o PIN padrão: `1234`

### Testando Push Notifications

1. **Notificação de Teste**:
   - Na tela principal, toque no card "Teste"
   - Uma notificação local será exibida

2. **Notificações Firebase**:
   - Use o Firebase Console para enviar notificações
   - Ou use o token FCM exibido na tela principal

### Testando Google Maps

1. **Visualizar Localização**:
   - Toque no card "Mapas"
   - Permita acesso à localização
   - Sua posição será exibida no mapa

2. **Traçar Rota**:
   - Toque em qualquer ponto do mapa
   - Selecione "Definir como Destino"
   - Toque no botão de rota (ícone de direções)

## 🏗️ Estrutura do Projeto

```
lib/
├── main.dart                 # Ponto de entrada da aplicação
├── screens/                  # Telas da aplicação
│   ├── splash_screen.dart    # Tela de splash
│   ├── login_screen.dart     # Tela de login com biometria
│   ├── home_screen.dart      # Tela principal
│   └── map_screen.dart       # Tela de mapas
├── services/                 # Serviços da aplicação
│   ├── auth_service.dart     # Serviço de autenticação
│   ├── notification_service.dart # Serviço de notificações
│   └── location_service.dart # Serviço de localização
├── widgets/                  # Widgets reutilizáveis
├── models/                   # Modelos de dados
└── utils/                    # Utilitários
```

## 🔧 Configurações Importantes

### AndroidManifest.xml

O arquivo `android/app/src/main/AndroidManifest.xml` contém todas as permissões necessárias:

```xml
<!-- Permissões para Internet -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

<!-- Permissões para Localização -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

<!-- Permissões para Biometria -->
<uses-permission android:name="android.permission.USE_FINGERPRINT" />
<uses-permission android:name="android.permission.USE_BIOMETRIC" />

<!-- Permissões para Notificações -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.VIBRATE" />
```

### build.gradle

O arquivo `android/app/build.gradle` está configurado com:

- **minSdkVersion**: 21 (necessário para biometria)
- **targetSdkVersion**: 34 (mais recente)
- **Dependências Firebase**: Incluídas automaticamente
- **Google Play Services**: Para Maps e Location

## 🐛 Solução de Problemas

### Erro de Permissões

Se o app não conseguir acessar localização ou biometria:

1. Verifique se as permissões estão no AndroidManifest.xml
2. Teste em dispositivo físico (emulador pode ter limitações)
3. Vá em Configurações > Apps > Flutter PDM App > Permissões

### Erro do Google Maps

Se o mapa não carregar:

1. Verifique se a API Key está correta
2. Confirme se as APIs estão ativadas no Google Cloud
3. Verifique se há cotas disponíveis na API

### Erro do Firebase

Se as notificações não funcionarem:

1. Verifique se o google-services.json está no local correto
2. Confirme se o package name está correto
3. Teste em dispositivo físico

## 📚 Recursos Adicionais

### Documentação Oficial

- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase for Flutter](https://firebase.flutter.dev/)
- [Google Maps Flutter](https://pub.dev/packages/google_maps_flutter)

### Tutoriais Relacionados

- [Local Authentication](https://pub.dev/packages/local_auth)
- [Geolocator](https://pub.dev/packages/geolocator)
- [Firebase Messaging](https://firebase.flutter.dev/docs/messaging/overview/)

## 👨‍💻 Desenvolvimento

### Comandos Úteis

```bash
# Limpar cache
flutter clean && flutter pub get

# Verificar problemas
flutter doctor

# Gerar APK
flutter build apk --release

# Executar testes
flutter test
```

### Próximas Melhorias

- [ ] Implementar autenticação com servidor
- [ ] Adicionar mais tipos de notificações
- [ ] Melhorar interface do usuário
- [ ] Adicionar testes unitários
- [ ] Implementar modo offline

## 📄 Licença

Este projeto foi desenvolvido para fins educacionais como parte da disciplina de Programação para Dispositivos Móveis II.

---

**Desenvolvido com ❤️ usando Flutter**

