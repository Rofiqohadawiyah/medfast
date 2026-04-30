import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  final int selectedTab;

  const SearchPage({
    super.key,
    this.selectedTab = 0,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late int selectedIndex;

  final List<Map<String, String>> products = [
    {
      'name': 'Sakatonik',
      'location': 'Jl. Jawa,\nSumbersari',
      'price': 'Rp 15.000',
      'image': 'assets/images/sakatonik.jpg',
    },
    {
      'name': 'Vitamin C',
      'location': 'Jl. Jawa,\nSumbersari',
      'price': 'Rp 15.000',
      'image': 'assets/images/vitamin_c.jpg',
    },
    {
      'name': 'Polysiline',
      'location': 'Jl. Karimata,\nSumbersari',
      'price': 'Rp 15.000',
      'image': 'assets/images/polysilane.jpg',
    },
    {
      'name': 'Paracetamol',
      'location': 'Jl. Karimata,\nSumbersari',
      'price': 'Rp 15.000',
      'image': 'assets/images/paracetamol.jpg',
    },
    {
      'name': 'Mylanta',
      'location': 'Jl. Karimata,\nSumbersari',
      'price': 'Rp 15.000',
      'image': 'assets/images/mylanta.png',
    },
    {
      'name': 'Bodrexin',
      'location': 'Jl. Karimata,\nSumbersari',
      'price': 'Rp 6.000',
      'image': 'assets/images/bodrexin.jpg',
    },
  ];

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.selectedTab;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(context),
              const SizedBox(height: 22),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _tabButton('Semua', 0),
                    const SizedBox(width: 12),
                    _tabButton('Apotek Terdekat', 1),
                    const SizedBox(width: 12),
                    _tabButton('Obat', 2),
                  ],
                ),
              ),

              const SizedBox(height: 34),

              if (selectedIndex == 1) _nearbyPharmacySection(),

              if (selectedIndex != 1) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Pencarian Terbaru',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9D9D9),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Text(
                      selectedIndex == 2
                          ? 'Obat Stress Semester 4'
                          : 'Media Farma Kaliurang',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 42),
              ],

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  selectedIndex == 1 ? 'Direkomendasikan' : 'Direkomendasikan',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: GridView.builder(
                  itemCount: products.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.62,
                  ),
                  itemBuilder: (context, index) {
                    final item = products[index];
                    return SearchProductCard(
                      name: item['name']!,
                      location: item['location']!,
                      price: item['price']!,
                      image: item['image']!,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      decoration: const BoxDecoration(
        color: Color(0xFFCFEAFF),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(34),
          bottomRight: Radius.circular(34),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back, size: 32),
              ),
              const Spacer(),
              const Icon(Icons.location_on_outlined, size: 22),
              const SizedBox(width: 4),
              const Text(
                'Jalan Jawa 4c',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
            ),
            child: const Row(
              children: [
                Icon(Icons.search, color: Colors.grey, size: 30),
                SizedBox(width: 14),
                Text(
                  'Cari obat atau apotek',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton(String title, int index) {
    final bool active = selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedIndex = index;
          });
        },
        child: Container(
          height: 38,
          decoration: BoxDecoration(
            color: active
                ? const Color(0xFF1E88E5)
                : const Color(0xFFCFEAFF),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Center(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _nearbyPharmacySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Apotek Terdekat',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFEF8),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Column(
              children: [
                PharmacyItem(title: 'Media Farma Jl. Imam Bonjol'),
                SizedBox(height: 8),
                PharmacyItem(title: 'Media Farma Jl. Kalimantan'),
                SizedBox(height: 8),
                PharmacyItem(title: 'Media Farma Jl. Kaliurang'),
              ],
            ),
          ),
          const SizedBox(height: 34),
        ],
      ),
    );
  }
}

class PharmacyItem extends StatelessWidget {
  final String title;

  const PharmacyItem({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Icon(Icons.location_on_outlined, size: 20, color: Colors.black87),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Media Farma Jl. Imam Bonjol\n0.5 km - Jl. Imam Bonjol - Sumberjambe, Kencong, Jember, Jawa Timur, Indonesia, 11231',
            style: TextStyle(
              fontSize: 9,
              height: 1.25,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}

class SearchProductCard extends StatelessWidget {
  final String name;
  final String location;
  final String price;
  final String image;

  const SearchProductCard({
    super.key,
    required this.name,
    required this.location,
    required this.price,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFEF8),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 74,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Image.asset(
                image,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 18,
                color: Colors.grey,
              ),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  location,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Center(
            child: Text(
              price,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF1E88E5),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}