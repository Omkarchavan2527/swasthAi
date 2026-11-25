import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/i18n/app_translations.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/sw_card.dart';

class HospitalsScreen extends ConsumerStatefulWidget {
  const HospitalsScreen({super.key});

  @override
  ConsumerState<HospitalsScreen> createState() => _HospitalsScreenState();
}

class _HospitalsScreenState extends ConsumerState<HospitalsScreen> {
  String _selectedFilter = 'All'; // 'All', 'Government', 'Private', '24/7 Emergency'
  String _searchQuery = '';

  final List<Map<String, dynamic>> _hospitals = [
    {
      'name': 'Baramati Sub-District Govt Hospital',
      'type': 'Government',
      'distance': '1.8 km away',
      'address': 'Near Court, Bhigwan Road, Baramati',
      'phone': '108',
      'directPhone': '02112222108',
      'isOpen24': true,
      'beds': '100+ Beds',
      'facilities': ['24/7 ICU', 'Free Deliveries', 'Blood Bank', 'Trauma'],
    },
    {
      'name': 'Sanjeevani Multispeciality Hospital',
      'type': 'Private',
      'distance': '2.5 km away',
      'address': 'Station Road, Baramati',
      'phone': '02112222333',
      'directPhone': '02112222333',
      'isOpen24': true,
      'beds': '50 Beds',
      'facilities': ['Cardiology', 'ICU', 'CT Scan', 'Pharmacy'],
    },
    {
      'name': 'Silver Jubilee Rural Hospital',
      'type': 'Government',
      'distance': '3.2 km away',
      'address': 'MIDC Main Road, Baramati',
      'phone': '108',
      'directPhone': '02112244222',
      'isOpen24': true,
      'beds': '80 Beds',
      'facilities': ['General Medicine', 'Pediatrics', '24/7 Ambulance'],
    },
    {
      'name': 'Giriraj Heart & Trauma Hospital',
      'type': 'Private',
      'distance': '3.8 km away',
      'address': 'Kasba Peth, Baramati',
      'phone': '02112224455',
      'directPhone': '02112224455',
      'isOpen24': true,
      'beds': '40 Beds',
      'facilities': ['Cath Lab', 'Cardiac ICU', 'Ventilators'],
    },
    {
      'name': 'Shrikrupa Children Hospital',
      'type': 'Private',
      'distance': '4.1 km away',
      'address': 'Indapur Road, Baramati',
      'phone': '02112226789',
      'directPhone': '02112226789',
      'isOpen24': false,
      'beds': '25 Beds',
      'facilities': ['NICU', 'Pediatric Care', 'Vaccination'],
    },
  ];

  Future<void> _callHospital(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot initiate call to $phone')),
        );
      }
    }
  }

  Future<void> _openDirections(String name, String address) async {
    final query = Uri.encodeComponent('$name, $address');
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open map directions')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);

    final filtered = _hospitals.where((h) {
      final matchesType = _selectedFilter == 'All' ||
          (_selectedFilter == 'Government' && h['type'] == 'Government') ||
          (_selectedFilter == 'Private' && h['type'] == 'Private') ||
          (_selectedFilter == '24/7 Emergency' && h['isOpen24'] == true);

      final matchesQuery = _searchQuery.isEmpty ||
          (h['name'] as String).toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (h['address'] as String).toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (h['facilities'] as List<String>).any((f) => f.toLowerCase().contains(_searchQuery.toLowerCase()));

      return matchesType && matchesQuery;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          AppTranslations.tr(lang, 'hospitalsTitle'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF121C2A)),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: const InputDecoration(
                  hintText: 'Search hospital, address, or facility (ICU, Cardiac)...',
                  hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  prefixIcon: Icon(Icons.search, color: Color(0xFF00685F), size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // Filter Chips
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip('All'),
                const SizedBox(width: 8),
                _buildFilterChip('Government'),
                const SizedBox(width: 8),
                _buildFilterChip('Private'),
                const SizedBox(width: 8),
                _buildFilterChip('24/7 Emergency'),
              ],
            ),
          ),

          const SizedBox(height: 6),

          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_hospital_outlined, size: 56, color: Color(0xFFCBD5E1)),
                        SizedBox(height: 10),
                        Text(
                          'No hospitals match your search criteria',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final h = filtered[index];
                      final isGov = h['type'] == 'Government';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SWCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      h['name'],
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF121C2A)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isGov ? const Color(0xFFCCFBF1) : const Color(0xFFEFF4FF),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      h['type'],
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isGov ? const Color(0xFF006F67) : const Color(0xFF0284C7),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 14, color: Color(0xFF64748B)),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '${h['distance']} • ${h['address']}',
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    h['isOpen24'] ? Icons.access_time_filled : Icons.access_time,
                                    size: 14,
                                    color: h['isOpen24'] ? const Color(0xFF00685F) : const Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    h['isOpen24'] ? 'Open 24 Hours • Emergency & ICU Ready' : 'Day Clinic (8 AM - 8 PM)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: h['isOpen24'] ? const Color(0xFF00685F) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              // Facilities chips
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: (h['facilities'] as List<String>)
                                    .map(
                                      (f) => Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(f, style: const TextStyle(fontSize: 10, color: Color(0xFF475569))),
                                      ),
                                    )
                                    .toList(),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF00685F),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      onPressed: () => _callHospital(h['directPhone']),
                                      icon: const Icon(Icons.call, size: 16),
                                      label: Text(
                                        AppTranslations.tr(lang, 'callHospital'),
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFF00685F),
                                        side: const BorderSide(color: Color(0xFF00685F)),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      onPressed: () => _openDirections(h['name'], h['address']),
                                      icon: const Icon(Icons.directions, size: 16),
                                      label: Text(
                                        AppTranslations.tr(lang, 'directions'),
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFF00685F),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 12,
        color: isSelected ? Colors.white : const Color(0xFF1E293B),
      ),
      side: BorderSide(
        color: isSelected ? const Color(0xFF00685F) : const Color(0xFFE2E8F0),
      ),
      onSelected: (val) => setState(() => _selectedFilter = label),
    );
  }
}
