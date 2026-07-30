import 'package:flutter/material.dart';
import '../../models/BookingEntry.dart';

class LiveTrackingScreen extends StatelessWidget {
  final BookingEntry booking;

  const LiveTrackingScreen({Key? key, required this.booking}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Technician Tracking'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Map Placeholder / Stream View
          Container(
            color: Colors.blueGrey.shade100,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_rounded, size: 80, color: Colors.blue.shade300),
                  const SizedBox(height: 12),
                  Text(
                    'Live Map View',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Technician Lat: ${booking.latitude ?? 12.9716}, Lng: ${booking.longitude ?? 77.5946}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Technician Card
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.blue.shade100,
                          child: const Icon(Icons.person_rounded, size: 30, color: Colors.blue),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                booking.providerName.isNotEmpty ? booking.providerName : 'Assigned Technician',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: const [
                                  Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                                  SizedBox(width: 4),
                                  Text('4.9 (120+ jobs)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.directions_run_rounded, size: 14, color: Colors.green),
                              SizedBox(width: 4),
                              Text('On The Way', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Start OTP Verification', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            const SizedBox(height: 2),
                            Text(
                              booking.startOtp.isNotEmpty ? booking.startOtp : '4829',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.blue, letterSpacing: 2),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            // Call Provider
                          },
                          icon: const Icon(Icons.phone_rounded, size: 18),
                          label: const Text('Call Tech'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
