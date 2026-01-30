import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Service for checking internet connectivity
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  /// Check if device has internet connection
  Future<bool> hasInternetConnection() async {
    try {
      final List<ConnectivityResult> result = await _connectivity.checkConnectivity();
      
      // Check if any connection type is available (not none)
      // In connectivity_plus 6.x, result is a List<ConnectivityResult>
      if (result.isEmpty) {
        return false;
      }
      
      // Check if we have any active connection (not ConnectivityResult.none)
      final hasConnection = result.any((result) => 
        result != ConnectivityResult.none
      );
      
      return hasConnection;
    } catch (e) {
      debugPrint('ConnectivityService: Error checking connectivity: $e');
      // On error, assume no connection to be safe
      return false;
    }
  }

  /// Stream of connectivity changes
  Stream<List<ConnectivityResult>> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged;
  }
}

