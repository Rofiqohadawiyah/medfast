import 'package:flutter/material.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

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
                  children: [
                    // Header biru
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                      decoration: const BoxDecoration(
                        color: Color(0xFFCFEAFF),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(28),
                          bottomRight: Radius.circular(28),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // top row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _circleIcon(Icons.menu),
                              const Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 18,
                                    color: Colors.black54,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Jember',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              _circleIcon(Icons.notifications_none),
                            ],
                          ),
                          const SizedBox(height: 28),
                          const Text(
                            'MedFast',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Pesan obat dan cari apotek terdekat dengan cepat.',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.black54,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 22),

                          // Search bar
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.search, color: Colors.grey),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Cari obat atau apotek',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Kategori Obat',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 18),

                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: const [
                                CategoryItem(
                                  icon: Icons.thermostat,
                                  label: 'Demam',
                                  color: Color(0xFFE0F7FA),
                                ),
                                SizedBox(width: 14),
                                CategoryItem(
                                  icon: Icons.air,
                                  label: 'Batuk',
                                  color: Color(0xFFE8F5E9),
                                ),
                                SizedBox(width: 14),
                                CategoryItem(
                                  icon: Icons.health_and_safety,
                                  label: 'Vitamin',
                                  color: Color(0xFFFFF3E0),
                                ),
                                SizedBox(width: 14),
                                CategoryItem(
                                  icon: Icons.medical_services,
                                  label: 'P3K',
                                  color: Color(0xFFF3E5F5),
                                ),
                                SizedBox(width: 14),
                                CategoryItem(
                                  icon: Icons.child_care,
                                  label: 'Ibu & Anak',
                                  color: Color(0xFFFFEBEE),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 28),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text(
                                'Rekomendasi',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              Text(
                                'Lihat Semua',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          Row(
                            children: const [
                              Expanded(
                                child: ProductCard(
                                  title: 'Paracetamol',
                                  subtitle: 'Apotek Sehat',
                                  price: 'Rp10.000',
                                  color: Color(0xFFDDEFFF),
                                  icon: Icons.medication,
                                ),
                              ),
                              SizedBox(width: 14),
                              Expanded(
                                child: ProductCard(
                                  title: 'Vitamin C',
                                  subtitle: 'Apotek Medika',
                                  price: 'Rp15.000',
                                  color: Color(0xFFE7F8E8),
                                  icon: Icons.local_hospital,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          Row(
                            children: const [
                              Expanded(
                                child: ProductCard(
                                  title: 'OBH Combi',
                                  subtitle: 'Apotek Farma',
                                  price: 'Rp18.000',
                                  color: Color(0xFFFFF1D6),
                                  icon: Icons.healing,
                                ),
                              ),
                              SizedBox(width: 14),
                              Expanded(
                                child: ProductCard(
                                  title: 'Termometer',
                                  subtitle: 'Apotek Care',
                                  price: 'Rp35.000',
                                  color: Color(0xFFFFE1E7),
                                  icon: Icons.device_thermostat,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // bottom navbar
            Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 18),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF5FB),
                borderRadius: BorderRadius.circular(26),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  NavItem(
                    icon: Icons.home,
                    label: 'Home',
                    active: true,
                  ),
                  NavItem(
                    icon: Icons.local_pharmacy_outlined,
                    label: 'Apotek',
                    active: false,
                  ),
                  NavItem(
                    icon: Icons.shopping_bag_outlined,
                    label: 'Pesanan',
                    active: false,
                  ),
                  NavItem(
                    icon: Icons.person_outline,
                    label: 'Profil',
                    active: false,
                  ),
                ],
              ),
            ),
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

class CategoryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const CategoryItem({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 32, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class ProductCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String price;
  final Color color;
  final IconData icon;

  const ProductCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF7),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 110,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Icon(
                icon,
                size: 52,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            price,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E88E5),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;

  const NavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return active
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E88E5),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.black87),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          );
  }
}