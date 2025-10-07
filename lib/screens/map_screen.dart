import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';

/// Tela de mapas com Google Maps integrado
/// Permite visualizar localização atual e traçar rotas
class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng? _currentLocation;
  LatLng? _selectedDestination;
  bool _isLoadingRoute = false;
  String? _routeInfo;

  // Posição inicial padrão (São Paulo)
  static const LatLng _defaultLocation = LatLng(-23.5505, -46.6333);

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  /// Obtém a localização atual do usuário
  Future<void> _getCurrentLocation() async {
    final locationService = Provider.of<LocationService>(context, listen: false);
    
    final position = await locationService.getCurrentLocation();
    if (position != null) {
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _addCurrentLocationMarker();
      });
      
      // Move a câmera para a localização atual
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_currentLocation!, 15),
        );
      }
    }
  }

  /// Adiciona marcador da localização atual
  void _addCurrentLocationMarker() {
    if (_currentLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: _currentLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: 'Sua Localização',
            snippet: 'Você está aqui',
          ),
        ),
      );
    }
  }

  /// Adiciona marcador de destino
  void _addDestinationMarker(LatLng position) {
    setState(() {
      _selectedDestination = position;
      
      // Remove marcador de destino anterior
      _markers.removeWhere((marker) => marker.markerId.value == 'destination');
      
      // Adiciona novo marcador de destino
      _markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: position,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(
            title: 'Destino',
            snippet: 'Toque para traçar rota',
          ),
          onTap: () => _calculateRoute(),
        ),
      );
    });
  }

  /// Calcula e exibe a rota entre dois pontos
  Future<void> _calculateRoute() async {
    if (_currentLocation == null || _selectedDestination == null) {
      _showSnackBar('Selecione um ponto de origem e destino');
      return;
    }

    setState(() {
      _isLoadingRoute = true;
      _routeInfo = null;
    });

    try {
      final locationService = Provider.of<LocationService>(context, listen: false);
      
      // Converte LatLng para Position
      final startPosition = Position(
        latitude: _currentLocation!.latitude,
        longitude: _currentLocation!.longitude,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
      
      final endPosition = Position(
        latitude: _selectedDestination!.latitude,
        longitude: _selectedDestination!.longitude,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );

      // Calcula distância direta
      final distance = locationService.calculateDistance(
        startPosition.latitude,
        startPosition.longitude,
        endPosition.latitude,
        endPosition.longitude,
      );

      // Simula uma rota (em produção, use a API do Google Directions)
      _createSimulatedRoute(startPosition, endPosition);
      
      setState(() {
        _routeInfo = 'Distância: ${locationService.formatDistance(distance)}';
      });

      _showSnackBar('Rota calculada com sucesso!');
    } catch (e) {
      _showSnackBar('Erro ao calcular rota: $e');
    } finally {
      setState(() {
        _isLoadingRoute = false;
      });
    }
  }

  /// Cria uma rota simulada entre dois pontos
  void _createSimulatedRoute(Position start, Position end) {
    List<LatLng> routePoints = [
      LatLng(start.latitude, start.longitude),
      // Adiciona alguns pontos intermediários para simular uma rota
      LatLng(
        start.latitude + (end.latitude - start.latitude) * 0.3,
        start.longitude + (end.longitude - start.longitude) * 0.2,
      ),
      LatLng(
        start.latitude + (end.latitude - start.latitude) * 0.7,
        start.longitude + (end.longitude - start.longitude) * 0.8,
      ),
      LatLng(end.latitude, end.longitude),
    ];

    setState(() {
      _polylines.clear();
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: routePoints,
          color: Colors.blue,
          width: 5,
          patterns: [],
        ),
      );
    });

    // Ajusta a câmera para mostrar toda a rota
    _fitCameraToRoute(routePoints);
  }

  /// Ajusta a câmera para mostrar toda a rota
  void _fitCameraToRoute(List<LatLng> points) {
    if (_mapController == null || points.isEmpty) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (LatLng point in points) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        100.0, // padding
      ),
    );
  }

  /// Limpa marcadores e rotas
  void _clearMap() {
    setState(() {
      _markers.clear();
      _polylines.clear();
      _selectedDestination = null;
      _routeInfo = null;
    });
    
    _addCurrentLocationMarker();
    _showSnackBar('Mapa limpo');
  }

  /// Mostra informações sobre um ponto no mapa
  Future<void> _showLocationInfo(LatLng position) async {
    final locationService = Provider.of<LocationService>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Informações do Local'),
        content: FutureBuilder<Map<String, dynamic>?>(
          future: locationService.getPlaceDetails(
            position.latitude,
            position.longitude,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Carregando informações...'),
                ],
              );
            }
            
            if (snapshot.hasError || snapshot.data == null) {
              return const Text('Erro ao carregar informações do local');
            }
            
            final data = snapshot.data!;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Coordenadas: ${locationService.formatCoordinates(
                  position.latitude,
                  position.longitude,
                )}'),
                const SizedBox(height: 8),
                if (data['address'] != null)
                  Text('Endereço: ${data['address']}'),
                const SizedBox(height: 8),
                if (data['distance'] != null)
                  Text('Distância: ${locationService.formatDistance(data['distance'])}'),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _addDestinationMarker(position);
            },
            child: const Text('Definir como Destino'),
          ),
        ],
      ),
    );
  }

  /// Exibe uma mensagem na parte inferior da tela
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
            tooltip: 'Minha Localização',
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearMap,
            tooltip: 'Limpar Mapa',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Google Maps
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              
              // Move para localização atual se disponível
              if (_currentLocation != null) {
                controller.animateCamera(
                  CameraUpdate.newLatLngZoom(_currentLocation!, 15),
                );
              }
            },
            initialCameraPosition: CameraPosition(
              target: _currentLocation ?? _defaultLocation,
              zoom: 15,
            ),
            markers: _markers,
            polylines: _polylines,
            onTap: (LatLng position) {
              _showLocationInfo(position);
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),
          
          // Painel de informações
          if (_routeInfo != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
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
                child: Row(
                  children: [
                    const Icon(Icons.route, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _routeInfo!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (_isLoadingRoute)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),
            ),
          
          // Botões de ação
          Positioned(
            bottom: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Botão de calcular rota
                if (_selectedDestination != null)
                  FloatingActionButton(
                    heroTag: 'route',
                    onPressed: _isLoadingRoute ? null : _calculateRoute,
                    backgroundColor: Colors.blue,
                    child: _isLoadingRoute
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.directions),
                  ),
                
                const SizedBox(height: 16),
                
                // Botão de localização atual
                FloatingActionButton(
                  heroTag: 'location',
                  onPressed: _getCurrentLocation,
                  backgroundColor: Colors.green,
                  child: const Icon(Icons.gps_fixed),
                ),
              ],
            ),
          ),
          
          // Instruções
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Toque no mapa para selecionar destino',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

