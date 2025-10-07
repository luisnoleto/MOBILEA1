import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Serviço responsável pela autenticação biométrica e gerenciamento de sessão
class AuthService extends ChangeNotifier {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isAuthenticated = false;
  bool _isBiometricAvailable = false;
  List<BiometricType> _availableBiometrics = [];
  
  // Getters para acessar o estado da autenticação
  bool get isAuthenticated => _isAuthenticated;
  bool get isBiometricAvailable => _isBiometricAvailable;
  List<BiometricType> get availableBiometrics => _availableBiometrics;

  AuthService() {
    _initializeBiometrics();
  }

  /// Inicializa e verifica a disponibilidade de biometria no dispositivo
  Future<void> _initializeBiometrics() async {
    try {
      // Verifica se o dispositivo suporta biometria
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      
      _isBiometricAvailable = isDeviceSupported && canCheckBiometrics;
      
      if (_isBiometricAvailable) {
        // Obtém os tipos de biometria disponíveis
        _availableBiometrics = await _localAuth.getAvailableBiometrics();
        print('Biometria disponível: $_availableBiometrics');
        
        // Se não há biometrias cadastradas, marca como não disponível
        if (_availableBiometrics.isEmpty) {
          _isBiometricAvailable = false;
          print('Nenhuma biometria cadastrada no dispositivo');
        }
      } else {
        print('Dispositivo não suporta biometria ou não pode verificar');
      }
      
      notifyListeners();
    } catch (e) {
      print('Erro ao inicializar biometria: $e');
      _isBiometricAvailable = false;
      notifyListeners();
    }
  }

  /// Realiza a autenticação biométrica
  Future<bool> authenticateWithBiometrics() async {
    try {
      if (!_isBiometricAvailable) {
        throw Exception('Biometria não disponível neste dispositivo');
      }

      // Verifica se há biometria disponível e configurada
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      
      if (!canCheckBiometrics || !isDeviceSupported) {
        print('Dispositivo não suporta biometria ou não está configurada');
        return false;
      }

      // Solicita a autenticação biométrica
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Por favor, autentique-se para acessar o aplicativo',
        options: const AuthenticationOptions(
          biometricOnly: false, // Permite fallback para PIN do sistema se necessário
          stickyAuth: true, // Mantém a autenticação ativa
          useErrorDialogs: true, // Mostra diálogos de erro do sistema
        ),
      );

      if (didAuthenticate) {
        _isAuthenticated = true;
        await _saveAuthenticationState(true);
        notifyListeners();
        return true;
      }
      
      return false;
    } on PlatformException catch (e) {
      print('Erro na autenticação biométrica: ${e.code} - ${e.message}');
      // Erros comuns:
      // - NotAvailable: biometria não disponível
      // - NotEnrolled: sem biometria cadastrada
      // - LockedOut: muitas tentativas falhadas
      // - PermanentlyLockedOut: bloqueado permanentemente
      return false;
    } catch (e) {
      print('Erro inesperado na autenticação biométrica: $e');
      return false;
    }
  }

  /// Autenticação com PIN personalizado (fallback)
  Future<bool> authenticateWithPin(String pin) async {
    try {
      // PIN padrão para demonstração (em produção, usar hash seguro)
      const String correctPin = '1234';
      
      if (pin == correctPin) {
        _isAuthenticated = true;
        await _saveAuthenticationState(true);
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      print('Erro na autenticação por PIN: $e');
      return false;
    }
  }

  /// Verifica se há uma sessão ativa salva
  Future<bool> checkSavedAuthentication() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isAuthenticated = prefs.getBool('is_authenticated') ?? false;
      notifyListeners();
      return _isAuthenticated;
    } catch (e) {
      print('Erro ao verificar autenticação salva: $e');
      return false;
    }
  }

  /// Salva o estado da autenticação
  Future<void> _saveAuthenticationState(bool isAuthenticated) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_authenticated', isAuthenticated);
    } catch (e) {
      print('Erro ao salvar estado da autenticação: $e');
    }
  }

  /// Realiza logout e limpa a sessão
  Future<void> logout() async {
    try {
      _isAuthenticated = false;
      await _saveAuthenticationState(false);
      notifyListeners();
    } catch (e) {
      print('Erro ao fazer logout: $e');
    }
  }

  /// Obtém uma descrição amigável dos tipos de biometria disponíveis
  String getBiometricDescription() {
    if (_availableBiometrics.isEmpty) {
      return 'Nenhuma biometria disponível';
    }

    List<String> descriptions = [];
    
    if (_availableBiometrics.contains(BiometricType.fingerprint)) {
      descriptions.add('Impressão Digital');
    }
    if (_availableBiometrics.contains(BiometricType.face)) {
      descriptions.add('Reconhecimento Facial');
    }
    if (_availableBiometrics.contains(BiometricType.iris)) {
      descriptions.add('Reconhecimento de Íris');
    }
    
    return descriptions.join(', ');
  }

  /// Verifica se o dispositivo tem biometria configurada
  Future<bool> isBiometricConfigured() async {
    try {
      return await _localAuth.isDeviceSupported() && 
             await _localAuth.canCheckBiometrics &&
             _availableBiometrics.isNotEmpty;
    } catch (e) {
      print('Erro ao verificar configuração biométrica: $e');
      return false;
    }
  }
}

