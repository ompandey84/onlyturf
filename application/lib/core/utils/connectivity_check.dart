import 'package:application/core/services/connectivity_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Returns `true` if online, `false` if offline (and shows a SnackBar warning).
/// Use this before any Supabase / network call:
///
/// ```dart
/// if (!checkConnectivity(context)) return;
/// ```
bool checkConnectivity(BuildContext context) {
  final connectivity = Provider.of<ConnectivityService>(context, listen: false);
  if (connectivity.isOnline) return true;

  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Row(
        children: [
          Icon(Icons.wifi_off, color: Colors.white, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'No internet connection. Please check your network.',
              style: TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.red.shade600,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
    ),
  );
  return false;
}
