import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';

/// Tela de login com autenticação biométrica e fallback para PIN
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _pinController = TextEditingController();
  bool _showPinInput = false;
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  /// Realiza a autenticação biométrica
  Future<void> _authenticateWithBiometrics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    
    try {
      // Verifica novamente se a biometria está disponível
      if (!authService.isBiometricAvailable) {
        setState(() {
          _errorMessage = 'Biometria não está disponível neste dispositivo';
          _showPinInput = true;
          _isLoading = false;
        });
        return;
      }

      final success = await authService.authenticateWithBiometrics();
      
      if (success) {
        if (mounted) {
          context.go('/home');
        }
      } else {
        setState(() {
          _errorMessage = 'Autenticação biométrica cancelada ou falhou. Por favor, use o PIN como alternativa.';
          _showPinInput = true;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao processar biometria: ${e.toString()}';
        _showPinInput = true;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Realiza a autenticação com PIN
  Future<void> _authenticateWithPin() async {
    if (_pinController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Por favor, digite o PIN';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    
    try {
      final success = await authService.authenticateWithPin(_pinController.text);
      
      if (success) {
        if (mounted) {
          context.go('/home');
        }
      } else {
        setState(() {
          _errorMessage = 'PIN incorreto. Tente novamente.';
          _pinController.clear();
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Mostra o input de PIN como alternativa
  void _showPinAlternative() {
    setState(() {
      _showPinInput = true;
      _errorMessage = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 40), // Adicionado para dar um espaço no topo
              // Logo e título
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.security,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
              ),
            
            const SizedBox(height: 30),
            
            const Text(
              'Bem-vindo!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            
            const SizedBox(height: 10),
            
            const Text(
              'Faça login para continuar',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            
            const SizedBox(height: 50),
            
            // Informações sobre biometria disponível
            Consumer<AuthService>(
              builder: (context, authService, child) {
                if (authService.isBiometricAvailable) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green[600]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Biometria Disponível',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                authService.getBiometricDescription(),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange[600]),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Biometria não disponível neste dispositivo',
                            style: TextStyle(color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
            
            const SizedBox(height: 30),
            
            // Botão de autenticação biométrica
            Consumer<AuthService>(
              builder: (context, authService, child) {
                return SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: authService.isBiometricAvailable && !_isLoading
                        ? _authenticateWithBiometrics
                        : null,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.fingerprint),
                    label: Text(
                      _isLoading
                          ? 'Autenticando...'
                          : 'Entrar com Biometria',
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 20),
            
            // Botão para mostrar alternativa de PIN
            Center(
              child: TextButton(
                onPressed: _isLoading ? null : _showPinAlternative,
                child: const Text('Usar PIN como alternativa'),
              ),
            ),
            
            // Input de PIN (mostrado quando necessário)
            if (_showPinInput) ...[
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Digite seu PIN',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _pinController,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        letterSpacing: 8,
                      ),
                      decoration: const InputDecoration(
                        hintText: '••••',
                        border: OutlineInputBorder(),
                        counterText: '',
                      ),
                      onSubmitted: (_) => _authenticateWithPin(),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _authenticateWithPin,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('Confirmar PIN'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Mensagem de erro
            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 30),
            
            // Informação sobre o PIN padrão
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue[600]),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'PIN padrão para demonstração: 1234',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
             const SizedBox(height: 40), // Adicionado para dar um espaço no final
            ],
          ),
        ),
      ),
    );
  }
}
