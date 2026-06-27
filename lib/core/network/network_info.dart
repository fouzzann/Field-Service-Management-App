import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:connectivity_plus/connectivity_plus.dart';

// This class is a helper to check if the app has a working internet connection.
abstract class NetworkInfo {
  // Checks if the device is currently connected to the internet.
  // Returns true if connected, false if offline.
  Future<bool> get isConnected;

  // A stream (stream of updates) that tells the app whenever the connection changes
  // (for example, if the user turns off Wi-Fi or mobile data).
  Stream<List<ConnectivityResult>> get onConnectivityChanged;
}

// This is the actual implementation of the NetworkInfo helper.
class NetworkInfoImpl implements NetworkInfo {
  // connectivity_plus is a package we use to check the device's network status.
  final Connectivity connectivity;

  NetworkInfoImpl(this.connectivity);

  @override
  Future<bool> get isConnected async {
    // 1. Check if the device is connected to a network (Wi-Fi, Mobile, etc.)
    final result = await connectivity.checkConnectivity();
    
    // If the list of connections is empty, or the status says "none", we are offline.
    if (result.isEmpty || result.any((element) => element == ConnectivityResult.none)) {
      return false;
    }
    
    // 2. Web check vs Mobile check
    if (kIsWeb) {
      // If we are running in a web browser, we assume we have connection if the browser says so.
      return true;
    } else {
      try {
        // If we are on Android/iOS, just being connected to a router/tower is not enough.
        // We try to ping 'google.com' to make sure the internet actually works.
        final lookup = await InternetAddress.lookup('google.com')
            .timeout(const Duration(seconds: 2));
        
        // If the lookup finds a valid IP address, we are fully online!
        return lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty;
      } catch (_) {
        // If the lookup fails (e.g. timeout or no route), we don't have real internet.
        return false;
      }
    }
  }

  @override
  // Expose the connectivity change stream so other parts of the app can listen to it.
  Stream<List<ConnectivityResult>> get onConnectivityChanged => connectivity.onConnectivityChanged;
}
