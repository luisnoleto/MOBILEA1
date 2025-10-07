import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Serviço responsável pela geolocalização e integração com APIs de mapas
class LocationService extends ChangeNotifier {
  Position? _currentPosition;
  String? _currentAddress;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Getters
  Position? get currentPosition => _currentPosition;
  String? get currentAddress => _currentAddress;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Verifica e solicita permissões de localização
  Future<bool> checkAndRequestPermissions() async {
    try {
      // Verifica se o serviço de localização está habilitado
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _errorMessage = 'Serviço de localização está desabilitado';
        notifyListeners();
        return false;
      }

      // Verifica a permissão atual
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        // Solicita permissão
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _errorMessage = 'Permissão de localização negada';
          notifyListeners();
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _errorMessage = 'Permissão de localização negada permanentemente';
        notifyListeners();
        return false;
      }

      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao verificar permissões: $e';
      notifyListeners();
      return false;
    }
  }

  /// Obtém a localização atual do usuário
  Future<Position?> getCurrentLocation() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Verifica permissões primeiro
      bool hasPermission = await checkAndRequestPermissions();
      if (!hasPermission) {
        _isLoading = false;
        notifyListeners();
        return null;
      }

      // Obtém a posição atual
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Obtém o endereço da posição atual
      await _getAddressFromPosition(_currentPosition!);

      _isLoading = false;
      notifyListeners();
      return _currentPosition;
    } catch (e) {
      _errorMessage = 'Erro ao obter localização: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Converte coordenadas em endereço legível
  Future<void> _getAddressFromPosition(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        _currentAddress = '${place.street}, ${place.subLocality}, '
            '${place.locality}, ${place.administrativeArea}, ${place.country}';
      }
    } catch (e) {
      print('Erro ao obter endereço: $e');
      _currentAddress = 'Endereço não disponível';
    }
  }

  /// Obtém endereço de coordenadas específicas
  Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return '${place.street}, ${place.subLocality}, '
            '${place.locality}, ${place.administrativeArea}, ${place.country}';
      }
      return null;
    } catch (e) {
      print('Erro ao obter endereço: $e');
      return null;
    }
  }

  /// Obtém coordenadas de um endereço
  Future<Position?> getCoordinatesFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      
      if (locations.isNotEmpty) {
        Location location = locations[0];
        return Position(
          latitude: location.latitude,
          longitude: location.longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      }
      return null;
    } catch (e) {
      print('Erro ao obter coordenadas: $e');
      return null;
    }
  }

  /// Calcula a distância entre duas posições
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Obtém rota entre dois pontos usando Google Directions API
  Future<Map<String, dynamic>?> getDirections(
    Position start,
    Position end, {
    String travelMode = 'driving',
  }) async {
    try {
      // Nota: Em produção, você deve usar uma chave de API válida
      const String apiKey = 'YOUR_GOOGLE_MAPS_API_KEY';
      
      final String url = 'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=${start.latitude},${start.longitude}&'
          'destination=${end.latitude},${end.longitude}&'
          'mode=$travelMode&'
          'key=$apiKey';

      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          return data;
        } else {
          print('Erro na API Directions: ${data['status']}');
          return null;
        }
      } else {
        print('Erro HTTP: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Erro ao obter direções: $e');
      return null;
    }
  }

  /// Decodifica polyline para pontos da rota
  List<Position> decodePolyline(String polyline) {
    List<Position> points = [];
    int index = 0;
    int len = polyline.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      
      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      
      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(Position(
        latitude: lat / 1E5,
        longitude: lng / 1E5,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      ));
    }

    return points;
  }

  /// Monitora mudanças de localização em tempo real
  Stream<Position> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Atualiza a cada 10 metros
      ),
    );
  }

  /// Verifica se uma posição está dentro de uma área específica
  bool isWithinArea(
    Position position,
    Position center,
    double radiusInMeters,
  ) {
    double distance = calculateDistance(
      position.latitude,
      position.longitude,
      center.latitude,
      center.longitude,
    );
    
    return distance <= radiusInMeters;
  }

  /// Obtém informações detalhadas sobre um local
  Future<Map<String, dynamic>?> getPlaceDetails(
    double latitude,
    double longitude,
  ) async {
    try {
      // Obtém o endereço
      String? address = await getAddressFromCoordinates(latitude, longitude);
      
      // Calcula distância da posição atual (se disponível)
      double? distance;
      if (_currentPosition != null) {
        distance = calculateDistance(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          latitude,
          longitude,
        );
      }

      return {
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'distance': distance,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('Erro ao obter detalhes do local: $e');
      return null;
    }
  }

  /// Limpa dados de localização
  void clearLocationData() {
    _currentPosition = null;
    _currentAddress = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Formata distância para exibição
  String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} m';
    } else {
      double distanceInKm = distanceInMeters / 1000;
      return '${distanceInKm.toStringAsFixed(1)} km';
    }
  }

  /// Formata coordenadas para exibição
  String formatCoordinates(double latitude, double longitude) {
    return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }
}

