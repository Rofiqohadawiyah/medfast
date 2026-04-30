import 'package:flutter/material.dart';
import 'landing_page.dart';

class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        Image.asset(
                          'assets/images/paracetamol.jpg',
                          width: double.infinity,
                          height: 210,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          left: 20,
                          top: 20,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: _circleIcon(Icons.menu),
                          ),
                        ),
                      ],
                    ),

                    Transform.translate(
                      offset: const Offset(0, -28),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF8FF),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: const Color(0xFF8BC5F4),
                            width: 2.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Paracetamol',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Jl. Mastrip No.15 Jember, Jawa Timur',
                              style: TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Rp 15.000',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Row(
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  color: Colors.pinkAccent,
                                  size: 22,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Gratis Ongkir',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.pinkAccent,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                const Column(
                                  children: [
                                    Text(
                                      '3.5',
                                      style: TextStyle(
                                        fontSize: 38,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      '★★★★☆',
                                      style: TextStyle(
                                        fontSize: 22,
                                        color: Colors.amber,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      '1724 Penilaian',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    children: const [
                                      RatingBar(label: '5', widthFactor: 0.70),
                                      RatingBar(label: '4', widthFactor: 0.32),
                                      RatingBar(label: '3', widthFactor: 0.18),
                                      RatingBar(label: '2', widthFactor: 0.05),
                                      RatingBar(label: '1', widthFactor: 0.00),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    Transform.translate(
                      offset: const Offset(0, -10),
                      child: Container(
                        width: double.infinity,
                        color: const Color(0xFFE5E5E5),
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Text(
                                  'Review',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Spacer(),
                                CircleAvatar(
                                  backgroundColor: Colors.white,
                                  child: Icon(Icons.arrow_forward),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(28),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Pelayanannya bagus, kurirnya ramah bangett.\nObatnya paling murah di banding yang lain',
                                    style: TextStyle(
                                      fontSize: 16,
                                      height: 1.4,
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    '★★★★★  Ofii',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.amber,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Tentang apotek',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    Container(
                      width: double.infinity,
                      color: const Color(0xFFEFF8FF),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 24,
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Jam Buka',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Senin - Minggu',
                                style: TextStyle(fontSize: 17),
                              ),
                              Text(
                                '10:00am - 10:45pm',
                                style: TextStyle(fontSize: 17),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            const BottomNavBar(),
          ],
        ),
      ),
    );
  }

  static Widget _circleIcon(IconData icon) {
    return Container(
      width: 42,
      height: 42,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.black87),
    );
  }
}

class RatingBar extends StatelessWidget {
  final String label;
  final double widthFactor;

  const RatingBar({
    super.key,
    required this.label,
    required this.widthFactor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            child: Text(label, style: const TextStyle(fontSize: 14)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: widthFactor,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}