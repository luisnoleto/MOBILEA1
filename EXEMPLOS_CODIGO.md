# Exemplos de Código e Explicações - Flutter PDM App

Este documento contém exemplos detalhados de código com explicações sobre como cada funcionalidade foi implementada.

## 📱 1. Autenticação Biométrica

### Como Funciona a Autenticação

A autenticação biométrica utiliza o plugin `local_auth` que fornece uma interface unificada para diferentes tipos de biometria:

```dart
// Exemplo de uso do serviço de autenticação
final authService = AuthService();

// Verifica se biometria está disponível
bool isAvailable = await authService.isBiometricConfigured();

if (isAvailable) {
    // Realiza autenticação biométrica
    bool success = await authService.authenticateWithBiometrics();
    
    if (success) {
        // Usuário autenticado com sucesso
        Navigator.pushReplacementNamed(context, '/home');
    }
} else {
    // Fallback para PIN
    bool success = await authService.authenticateWithPin('1234');
}
```

### Detecção de Tipos de Biometria

O código detecta automaticamente quais tipos de biometria estão disponíveis:

```dart
// No AuthService
Future<void> _initializeBiometrics() async {
    // Verifica se o dispositivo suporta biometria
    _isBiometricAvailable = await _localAuth.canCheckBiometrics;
    
    if (_isBiometricAvailable) {
        // Obtém os tipos disponíveis
        _availableBiometrics = await _localAuth.getAvailableBiometrics();
        
        // Tipos possíveis:
        // - BiometricType.fingerprint (impressão digital)
        // - BiometricType.face (reconhecimento facial)
        // - BiometricType.iris (reconhecimento de íris)
    }
}
```

### Persistência de Sessão

A sessão de autenticação é salva usando `SharedPreferences`:

```dart
// Salva estado da autenticação
Future<void> _saveAuthenticationState(bool isAuthenticated) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_authenticated', isAuthenticated);
}

// Verifica sessão salva
Future<bool> checkSavedAuthentication() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_authenticated') ?? false;
}
```

## 🔔 2. Push Notifications

### Configuração do Firebase Cloud Messaging

O serviço de notificações é inicializado no `main.dart`:

```dart
void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Inicializa Firebase
    await Firebase.initializeApp();
    
    // Inicializa notificações
    await NotificationService.initialize();
    
    runApp(MyApp());
}
```

### Handlers para Diferentes Estados

O app trata notificações em três estados diferentes:

```dart
void _setupMessageHandlers() {
    // 1. App em foreground (primeiro plano)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Mensagem em foreground: ${message.notification?.title}');
        _handleForegroundMessage(message);
    });

    // 2. App em background, usuário toca na notificação
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('App aberto por notificação: ${message.notification?.title}');
        _handleMessageOpenedApp(message);
    });

    // 3. App fechado, aberto por notificação
    _checkInitialMessage();
}
```

### Exibição de Notificações Locais

Quando o app está em foreground, exibimos notificações locais:

```dart
Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            importance: Importance.high,
            priority: Priority.high,
        );

    await _localNotifications.show(
        message.hashCode,
        message.notification?.title ?? 'Nova Notificação',
        message.notification?.body ?? 'Você tem uma nova mensagem',
        NotificationDetails(android: androidDetails),
    );
}
```

### Gerenciamento de Histórico

As notificações são armazenadas localmente para histórico:

```dart
void _addNotification(RemoteMessage message) {
    final notification = {
        'id': message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'title': message.notification?.title ?? 'Sem título',
        'body': message.notification?.body ?? 'Sem conteúdo',
        'timestamp': DateTime.now().toIso8601String(),
        'data': message.data,
        'read': false,
    };

    _notifications.insert(0, notification);
    _saveNotifications();
    notifyListeners();
}
```

## 🗺️ 3. Google Maps e Geolocalização

### Obtenção da Localização Atual

O serviço de localização verifica permissões antes de obter a posição:

```dart
Future<Position?> getCurrentLocation() async {
    // 1. Verifica se o serviço está habilitado
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
        throw Exception('Serviço de localização desabilitado');
    }

    // 2. Verifica permissões
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
    }

    // 3. Obtém a posição
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
    );

    return position;
}
```

### Integração com Google Maps

O mapa é configurado com callbacks para interação:

```dart
GoogleMap(
    onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
    },
    initialCameraPosition: CameraPosition(
        target: _currentLocation ?? _defaultLocation,
        zoom: 15,
    ),
    markers: _markers,
    polylines: _polylines,
    onTap: (LatLng position) {
        // Usuário tocou no mapa
        _showLocationInfo(position);
    },
    myLocationEnabled: true,
)
```

### Cálculo de Rotas

Para calcular rotas, usamos a distância direta e simulamos pontos intermediários:

```dart
Future<void> _calculateRoute() async {
    // Calcula distância direta
    final distance = locationService.calculateDistance(
        startPosition.latitude,
        startPosition.longitude,
        endPosition.latitude,
        endPosition.longitude,
    );

    // Cria rota simulada
    List<LatLng> routePoints = [
        LatLng(start.latitude, start.longitude),
        // Pontos intermediários
        LatLng(
            start.latitude + (end.latitude - start.latitude) * 0.3,
            start.longitude + (end.longitude - start.longitude) * 0.2,
        ),
        LatLng(end.latitude, end.longitude),
    ];

    // Adiciona polyline ao mapa
    _polylines.add(
        Polyline(
            polylineId: const PolylineId('route'),
            points: routePoints,
            color: Colors.blue,
            width: 5,
        ),
    );
}
```

### Geocodificação

Conversão entre coordenadas e endereços:

```dart
// Coordenadas para endereço
Future<String?> getAddressFromCoordinates(double lat, double lng) async {
    List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
    
    if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return '${place.street}, ${place.locality}, ${place.country}';
    }
    return null;
}

// Endereço para coordenadas
Future<Position?> getCoordinatesFromAddress(String address) async {
    List<Location> locations = await locationFromAddress(address);
    
    if (locations.isNotEmpty) {
        Location location = locations[0];
        return Position(
            latitude: location.latitude,
            longitude: location.longitude,
            // ... outros campos obrigatórios
        );
    }
    return null;
}
```

## 🎨 4. Interface do Usuário

### Gerenciamento de Estado com Provider

O app usa Provider para gerenciamento de estado reativo:

```dart
// No main.dart
MultiProvider(
    providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => LocationService()),
        ChangeNotifierProvider(create: (_) => NotificationService()),
    ],
    child: MaterialApp.router(
        // configuração do app
    ),
)

// Nas telas, consumindo o estado
Consumer<AuthService>(
    builder: (context, authService, child) {
        return Text(authService.isAuthenticated ? 'Logado' : 'Não logado');
    },
)
```

### Navegação com GoRouter

Sistema de navegação declarativo:

```dart
final GoRouter _router = GoRouter(
    initialLocation: '/',
    routes: [
        GoRoute(
            path: '/',
            builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
            path: '/login',
            builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
        ),
    ],
);

// Para navegar
context.go('/home');
```

### Widgets Reutilizáveis

Exemplo de card de funcionalidade:

```dart
Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
}) {
    return Card(
        elevation: 4,
        child: InkWell(
            onTap: onTap,
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    children: [
                        Icon(icon, size: 32, color: color),
                        const SizedBox(height: 12),
                        Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(subtitle, style: TextStyle(color: Colors.grey)),
                    ],
                ),
            ),
        ),
    );
}
```

## 🔧 5. Configurações e Permissões

### AndroidManifest.xml Explicado

```xml
<!-- Permissões básicas para internet -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

<!-- Permissões de localização -->
<!-- FINE_LOCATION: GPS preciso -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<!-- COARSE_LOCATION: localização aproximada (rede) -->
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

<!-- Permissões de biometria -->
<!-- USE_FINGERPRINT: para Android < 9 -->
<uses-permission android:name="android.permission.USE_FINGERPRINT" />
<!-- USE_BIOMETRIC: para Android 9+ -->
<uses-permission android:name="android.permission.USE_BIOMETRIC" />

<!-- Permissões de notificação -->
<!-- POST_NOTIFICATIONS: para Android 13+ -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

### build.gradle Configurações

```gradle
android {
    compileSdkVersion 34  // Versão mais recente
    
    defaultConfig {
        minSdkVersion 21   // Mínimo para biometria
        targetSdkVersion 34
        multiDexEnabled true  // Para Firebase
    }
}

dependencies {
    // Firebase BOM gerencia versões automaticamente
    implementation platform('com.google.firebase:firebase-bom:32.7.0')
    implementation 'com.google.firebase:firebase-messaging'
    
    // Google Play Services
    implementation 'com.google.android.gms:play-services-maps:18.2.0'
    implementation 'com.google.android.gms:play-services-location:21.0.1'
}
```

## 🧪 6. Testes e Debug

### Testando Biometria

```dart
// Teste de disponibilidade
void testBiometricAvailability() async {
    final authService = AuthService();
    
    print('Biometria disponível: ${authService.isBiometricAvailable}');
    print('Tipos: ${authService.getBiometricDescription()}');
    
    if (authService.isBiometricAvailable) {
        bool success = await authService.authenticateWithBiometrics();
        print('Autenticação: ${success ? "Sucesso" : "Falhou"}');
    }
}
```

### Testando Notificações

```dart
// Teste de notificação local
void testLocalNotification() async {
    final notificationService = NotificationService();
    await notificationService.sendTestNotification();
    print('Notificação de teste enviada');
}

// Teste de token FCM
void printFCMToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    print('FCM Token: $token');
}
```

### Testando Localização

```dart
// Teste de localização
void testLocation() async {
    final locationService = LocationService();
    
    final position = await locationService.getCurrentLocation();
    if (position != null) {
        print('Lat: ${position.latitude}, Lng: ${position.longitude}');
        
        final address = await locationService.getAddressFromCoordinates(
            position.latitude, 
            position.longitude
        );
        print('Endereço: $address');
    }
}
```

## 📱 7. Boas Práticas Implementadas

### Tratamento de Erros

```dart
Future<Position?> getCurrentLocation() async {
    try {
        // Código de localização
        return position;
    } catch (e) {
        print('Erro ao obter localização: $e');
        _errorMessage = 'Erro: ${e.toString()}';
        notifyListeners();
        return null;
    }
}
```

### Loading States

```dart
// Indicador de carregamento
bool _isLoading = false;

Future<void> _authenticateWithBiometrics() async {
    setState(() {
        _isLoading = true;
    });
    
    try {
        // Lógica de autenticação
    } finally {
        setState(() {
            _isLoading = false;
        });
    }
}
```

### Feedback ao Usuário

```dart
// SnackBar para feedback
void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 3),
        ),
    );
}
```

## 🔍 8. Debugging e Logs

### Logs Estruturados

```dart
// Logs informativos
print('FCM Token obtido: $token');

// Logs de erro
print('Erro na autenticação biométrica: $e');

// Logs de debug
debugPrint('Estado da autenticação: $_isAuthenticated');
```

### Verificação de Estado

```dart
// Debug do estado dos serviços
void debugServices() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final locationService = Provider.of<LocationService>(context, listen: false);
    
    print('Auth: ${authService.isAuthenticated}');
    print('Location: ${locationService.currentPosition}');
    print('Biometric: ${authService.isBiometricAvailable}');
}
```

---

**Estes exemplos mostram como cada funcionalidade foi implementada com comentários explicativos. Use-os como referência para entender o funcionamento do código e para implementar melhorias.**

