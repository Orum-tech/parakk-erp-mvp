import 'package:flutter/material.dart';

class BusTrackingScreen extends StatelessWidget {
  const BusTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Aesthetic Colors
    final Color primaryBlue = const Color(0xFF1565C0);
    final Color routeColor = const Color(0xFF42A5F5);

    return Scaffold(
      body: Stack(
        children: [
          // 1. Enhanced Mock Map Background
          Container(
            color: const Color(0xFFF0F4F8), // Soft map background color
            width: double.infinity,
            height: double.infinity,
            child: CustomPaint(
              painter: MapPainter(routeColor: routeColor), // Upgraded Painter
            ),
          ),
          
          // 2. Bus Marker (Center of Screen)
          // FIX: Removed 'const' keyword here to fix the constructor error
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Bus Marker Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: primaryBlue, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: primaryBlue.withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(Icons.directions_bus_rounded, size: 30, color: primaryBlue),
                ),
                
                // Triangle pointer
                Transform.translate(
                  offset: const Offset(0, -5),
                  child: Icon(Icons.arrow_drop_down, size: 40, color: primaryBlue),
                ),

                // Bus Number Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: const Offset(0, 4))]
                  ),
                  child: const Text(
                    "School Bus 12", 
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)
                  ),
                )
              ],
            ),
          ),

          // 3. Back Button (Top Left)
          Positioned(
            top: 50, left: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]
              ),
              child: IconButton(
                onPressed: () => Navigator.pop(context), 
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
              ),
            ),
          ),

          // 4. Driver & Status Sheet (Bottom)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1565C0).withOpacity(0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Time Estimation Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50], 
                          shape: BoxShape.circle
                        ),
                        child: const Icon(Icons.timelapse_rounded, color: Colors.green),
                      ),
                      const SizedBox(width: 15),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Arriving at Stop", style: TextStyle(color: Colors.grey, fontSize: 12)),
                          Text("10 Mins", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                        ],
                      ),
                      const Spacer(),
                      // Live Indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red[100]!)
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.circle, color: Colors.red, size: 8),
                            const SizedBox(width: 6),
                            Text("LIVE", style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold, fontSize: 11)),
                          ],
                        ),
                      )
                    ],
                  ),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Divider(height: 1),
                  ),

                  // Driver Details
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 24,
                        backgroundColor: Color(0xFFE3F2FD),
                        child: Icon(Icons.person, color: Color(0xFF1565C0)),
                      ),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Ramesh Kumar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                              Text(" 4.8 • Driver", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Call Button
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [primaryBlue, const Color(0xFF42A5F5)]),
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: primaryBlue.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))]
                        ),
                        child: IconButton(
                          onPressed: (){
                             ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Calling Driver...")),
                             );
                          }, 
                          icon: const Icon(Icons.call, color: Colors.white),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
          
          // 5. Coming Soon Overlay
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: Container(
                margin: const EdgeInsets.all(40),
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.directions_bus_rounded,
                        size: 48,
                        color: Colors.blueGrey,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Coming Soon",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "The Bus Track feature is under development and will be available soon!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
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

// Improved Painter to look like a Map Route
class MapPainter extends CustomPainter {
  final Color routeColor;
  
  MapPainter({required this.routeColor});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Grid (Subtle Roads)
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.15)
      ..strokeWidth = 2; // Thicker lines for roads
    
    // Vertical Roads
    for(double i = 0; i < size.width; i+=60) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    // Horizontal Roads
    for(double i = 0; i < size.height; i+=60) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }

    // 2. Draw The Bus Route (A curvy path)
    final routePaint = Paint()
      ..color = routeColor.withOpacity(0.5)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    // Start from top leftish
    path.moveTo(0, size.height * 0.2);
    // Curve to center (where bus is)
    path.quadraticBezierTo(
      size.width * 0.5, size.height * 0.2, // Control Point
      size.width * 0.5, size.height * 0.5  // Center Point
    );
    // Curve to bottom right
    path.quadraticBezierTo(
      size.width * 0.5, size.height * 0.8, // Control Point
      size.width, size.height * 0.8        // End Point
    );

    canvas.drawPath(path, routePaint);

    // 3. Draw Route Dashed Line (Overlay)
    final dashPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}