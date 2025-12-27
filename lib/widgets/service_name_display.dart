import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../models/massage.dart';
import '../services/firebase_service.dart';

/// Widget that displays the service name and label for a booking
/// Fetches the actual service name from Firestore based on serviceType and massageType
class ServiceNameDisplay extends StatelessWidget {
  final Booking booking;
  final TextStyle? textStyle;

  const ServiceNameDisplay({
    super.key,
    required this.booking,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final serviceType = booking.serviceType ?? 'massage';
    final massageType = booking.massageType;
    
    // Extract service ID from massageType (format: "serviceId_duration")
    final parts = massageType.split('_');
    final serviceId = parts.isNotEmpty ? parts[0] : massageType;
    
    // Determine the label
    final label = serviceType == 'soins' ? 'Type de soins' : 'Type de massage';
    
    // Fetch service name from Firestore
    return FutureBuilder<String>(
      future: _getServiceName(serviceId, serviceType),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Text(
            '$label: Chargement...',
            style: textStyle,
          );
        }
        
        if (snapshot.hasError || !snapshot.hasData) {
          // Fallback to service ID if fetch fails
          return Text(
            '$label: $serviceId',
            style: textStyle,
          );
        }
        
        return Text(
          '$label: ${snapshot.data!}',
          style: textStyle,
        );
      },
    );
  }

  Future<String> _getServiceName(String serviceId, String serviceType) async {
    try {
      final firebaseService = FirebaseService();
      final collection = serviceType == 'soins' 
          ? await firebaseService.getTreatmentsOnce()
          : await firebaseService.getMassagesOnce();
      
      final service = collection.firstWhere(
        (m) => m.id == serviceId,
        orElse: () => Massage(
          id: serviceId,
          name: serviceId, // Fallback to ID if not found
          description: '',
          zones: '',
          prices: [],
          createdAt: DateTime.now(),
          order: 0,
        ),
      );
      
      return service.name;
    } catch (e) {
      // Return service ID as fallback
      return serviceId;
    }
  }
}

/// Helper function to get service name and label as a string
/// Returns a Future that resolves to a tuple of (label, serviceName)
Future<Map<String, String>> getServiceNameAndLabel(Booking booking) async {
  final serviceType = booking.serviceType ?? 'massage';
  final massageType = booking.massageType;
  
  // Extract service ID from massageType (format: "serviceId_duration")
  final parts = massageType.split('_');
  final serviceId = parts.isNotEmpty ? parts[0] : massageType;
  
  // Determine the label
  final label = serviceType == 'soins' ? 'Type de soins' : 'Type de massage';
  
  // Fetch service name from Firestore
  try {
    final firebaseService = FirebaseService();
    final collection = serviceType == 'soins' 
        ? await firebaseService.getTreatmentsOnce()
        : await firebaseService.getMassagesOnce();
    
    final service = collection.firstWhere(
      (m) => m.id == serviceId,
      orElse: () => Massage(
        id: serviceId,
        name: serviceId, // Fallback to ID if not found
        description: '',
        zones: '',
        prices: [],
        createdAt: DateTime.now(),
        order: 0,
      ),
    );
    
    return {
      'label': label,
      'name': service.name,
    };
  } catch (e) {
    // Return service ID as fallback
    return {
      'label': label,
      'name': serviceId,
    };
  }
}

