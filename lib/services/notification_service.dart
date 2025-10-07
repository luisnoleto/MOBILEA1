import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Serviço responsável pelo gerenciamento de push notifications
/// Utiliza Firebase Cloud Messaging (FCM) e notificações locais
class NotificationService extends ChangeNotifier {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  
  String? _fcmToken;
  List<Map<String, dynamic>> _notifications = [];
  
  // Getters
  String? get fcmToken => _fcmToken;
  List<Map<String, dynamic>> get notifications => _notifications;

  /// Inicializa o serviço de notificações
  static Future<void> initialize() async {
    // Configuração das notificações locais
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    
    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Configuração do canal de notificação para Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Solicita permissões para notificações
    await _requestPermissions();
    
    // Configura handlers para mensagens em background
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  /// Solicita permissões para notificações
  static Future<void> _requestPermissions() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('Permissão de notificação: ${settings.authorizationStatus}');
  }

  /// Inicializa o serviço para uma instância específica
  Future<void> initializeInstance() async {
    await _getFCMToken();
    await _loadNotifications();
    _setupMessageHandlers();
  }

  /// Obtém o token FCM do dispositivo
  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      print('FCM Token: $_fcmToken');
      
      // Salva o token localmente
      if (_fcmToken != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', _fcmToken!);
      }
      
      notifyListeners();
    } catch (e) {
      print('Erro ao obter FCM token: $e');
    }
  }

  /// Configura os handlers para diferentes tipos de mensagens
  void _setupMessageHandlers() {
    // Mensagens recebidas quando o app está em foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Mensagem recebida em foreground: ${message.notification?.title}');
      _handleForegroundMessage(message);
    });

    // Mensagens que abrem o app (quando clicadas)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Mensagem clicada: ${message.notification?.title}');
      _handleMessageOpenedApp(message);
    });

    // Verifica se o app foi aberto por uma notificação
    _checkInitialMessage();
  }

  /// Verifica se o app foi aberto através de uma notificação
  Future<void> _checkInitialMessage() async {
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      print('App aberto por notificação: ${initialMessage.notification?.title}');
      _handleMessageOpenedApp(initialMessage);
    }
  }

  /// Manipula mensagens recebidas em foreground
  void _handleForegroundMessage(RemoteMessage message) {
    // Adiciona à lista de notificações
    _addNotification(message);
    
    // Exibe notificação local
    _showLocalNotification(message);
  }

  /// Manipula quando uma mensagem é clicada e abre o app
  void _handleMessageOpenedApp(RemoteMessage message) {
    // Adiciona à lista de notificações se não existir
    _addNotification(message);
    
    // Aqui você pode navegar para uma tela específica baseada nos dados da mensagem
    // Por exemplo: context.go('/notification-detail/${message.messageId}');
  }

  /// Exibe uma notificação local
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'Nova Notificação',
      message.notification?.body ?? 'Você tem uma nova mensagem',
      platformChannelSpecifics,
      payload: message.messageId,
    );
  }

  /// Adiciona uma notificação à lista
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

  /// Carrega notificações salvas localmente
  Future<void> _loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getStringList('notifications') ?? [];
      
      _notifications = notificationsJson.map((json) {
        // Em uma implementação real, você usaria jsonDecode
        // Por simplicidade, estamos usando um formato básico
        return <String, dynamic>{
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'title': 'Notificação Salva',
          'body': json,
          'timestamp': DateTime.now().toIso8601String(),
          'data': {},
          'read': false,
        };
      }).toList();
      
      notifyListeners();
    } catch (e) {
      print('Erro ao carregar notificações: $e');
    }
  }

  /// Salva notificações localmente
  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = _notifications
          .take(50) // Mantém apenas as 50 mais recentes
          .map((notification) => notification['body'] as String)
          .toList();
      
      await prefs.setStringList('notifications', notificationsJson);
    } catch (e) {
      print('Erro ao salvar notificações: $e');
    }
  }

  /// Marca uma notificação como lida
  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n['id'] == notificationId);
    if (index != -1) {
      _notifications[index]['read'] = true;
      _saveNotifications();
      notifyListeners();
    }
  }

  /// Marca todas as notificações como lidas
  void markAllAsRead() {
    for (var notification in _notifications) {
      notification['read'] = true;
    }
    _saveNotifications();
    notifyListeners();
  }

  /// Remove uma notificação
  void removeNotification(String notificationId) {
    _notifications.removeWhere((n) => n['id'] == notificationId);
    _saveNotifications();
    notifyListeners();
  }

  /// Limpa todas as notificações
  void clearAllNotifications() {
    _notifications.clear();
    _saveNotifications();
    notifyListeners();
  }

  /// Envia uma notificação de teste local
  Future<void> sendTestNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'Notificação de Teste',
      'Esta é uma notificação de teste do aplicativo Flutter PDM',
      platformChannelSpecifics,
    );

    // Adiciona à lista também
    final testNotification = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': 'Notificação de Teste',
      'body': 'Esta é uma notificação de teste do aplicativo Flutter PDM',
      'timestamp': DateTime.now().toIso8601String(),
      'data': {'type': 'test'},
      'read': false,
    };

    _notifications.insert(0, testNotification);
    _saveNotifications();
    notifyListeners();
  }

  /// Obtém o número de notificações não lidas
  int get unreadCount {
    return _notifications.where((n) => n['read'] == false).length;
  }
}

/// Handler para mensagens em background
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Mensagem em background: ${message.notification?.title}');
}

/// Callback quando uma notificação local é tocada
@pragma('vm:entry-point')
void _onNotificationTapped(NotificationResponse notificationResponse) {
  print('Notificação tocada: ${notificationResponse.payload}');
}

