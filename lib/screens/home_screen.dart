import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

/// Tela principal do aplicativo após o login
/// Exibe funcionalidades principais e permite navegação
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Inicializa o serviço de notificações para esta instância
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationService>(context, listen: false)
          .initializeInstance();
    });
  }

  /// Realiza logout do usuário
  Future<void> _logout() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.logout();
    
    if (mounted) {
      context.go('/login');
    }
  }

  /// Mostra diálogo de confirmação para logout
  Future<void> _showLogoutDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Logout'),
          content: const Text('Tem certeza que deseja sair do aplicativo?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Sair'),
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter PDM App'),
        actions: [
          // Badge de notificações
          Consumer<NotificationService>(
            builder: (context, notificationService, child) {
              final unreadCount = notificationService.unreadCount;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () => _showNotificationsBottomSheet(),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _showLogoutDialog,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Boas-vindas
            const Text(
              'Bem-vindo!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Explore as funcionalidades do aplicativo',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Cards de funcionalidades
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  // Card de Notificações
                  _buildFeatureCard(
                    icon: Icons.notifications_active,
                    title: 'Notificações',
                    subtitle: 'Push Notifications',
                    color: Colors.orange,
                    onTap: () => _showNotificationsBottomSheet(),
                  ),
                  
                  // Card de Mapas
                  _buildFeatureCard(
                    icon: Icons.map,
                    title: 'Mapas',
                    subtitle: 'Geolocalização',
                    color: Colors.green,
                    onTap: () => context.go('/map'),
                  ),
                  
                  // Card de Biometria
                  _buildFeatureCard(
                    icon: Icons.fingerprint,
                    title: 'Biometria',
                    subtitle: 'Autenticação',
                    color: Colors.blue,
                    onTap: () => _showBiometricInfo(),
                  ),
                  
                  // Card de Teste
                  _buildFeatureCard(
                    icon: Icons.science,
                    title: 'Teste',
                    subtitle: 'Notificação',
                    color: Colors.purple,
                    onTap: () => _sendTestNotification(),
                  ),
                ],
              ),
            ),
            
            // Informações do FCM Token
            Consumer<NotificationService>(
              builder: (context, notificationService, child) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'FCM Token:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        notificationService.fcmToken ?? 'Carregando...',
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói um card de funcionalidade
  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Mostra informações sobre biometria
  void _showBiometricInfo() {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Informações de Biometria'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Disponível: ${authService.isBiometricAvailable ? "Sim" : "Não"}'),
            const SizedBox(height: 8),
            Text('Tipos: ${authService.getBiometricDescription()}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Envia uma notificação de teste
  void _sendTestNotification() {
    final notificationService = Provider.of<NotificationService>(context, listen: false);
    notificationService.sendTestNotification();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notificação de teste enviada!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Mostra o bottom sheet com as notificações
  void _showNotificationsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return Consumer<NotificationService>(
            builder: (context, notificationService, child) {
              return Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Handle do bottom sheet
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Cabeçalho
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Notificações',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (notificationService.notifications.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              notificationService.markAllAsRead();
                            },
                            child: const Text('Marcar todas como lidas'),
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Lista de notificações
                    Expanded(
                      child: notificationService.notifications.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.notifications_none,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Nenhuma notificação',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: notificationService.notifications.length,
                              itemBuilder: (context, index) {
                                final notification = notificationService.notifications[index];
                                final isRead = notification['read'] as bool;
                                
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  color: isRead ? null : Colors.blue[50],
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.notifications,
                                      color: isRead ? Colors.grey : Colors.blue,
                                    ),
                                    title: Text(
                                      notification['title'] as String,
                                      style: TextStyle(
                                        fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(notification['body'] as String),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatTimestamp(notification['timestamp'] as String),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: PopupMenuButton(
                                      itemBuilder: (context) => [
                                        if (!isRead)
                                          PopupMenuItem(
                                            value: 'read',
                                            child: const Text('Marcar como lida'),
                                          ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: const Text('Excluir'),
                                        ),
                                      ],
                                      onSelected: (value) {
                                        if (value == 'read') {
                                          notificationService.markAsRead(notification['id'] as String);
                                        } else if (value == 'delete') {
                                          notificationService.removeNotification(notification['id'] as String);
                                        }
                                      },
                                    ),
                                    onTap: () {
                                      if (!isRead) {
                                        notificationService.markAsRead(notification['id'] as String);
                                      }
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Formata o timestamp para exibição
  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inMinutes < 1) {
        return 'Agora';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m atrás';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h atrás';
      } else {
        return '${difference.inDays}d atrás';
      }
    } catch (e) {
      return 'Data inválida';
    }
  }
}

