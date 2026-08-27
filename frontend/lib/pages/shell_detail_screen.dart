import 'package:flutter/material.dart';

class ShellDetailScreen extends StatelessWidget {
  const ShellDetailScreen({super.key, required this.shell});

  final Map<String, dynamic> shell;

  String _safeString(dynamic value, [String fallback = 'Unknown']) {
    if (value == null) return fallback;
    return value.toString();
  }

  String _resolveAssetPath(dynamic value) {
    final raw = (value ?? '').toString().trim();
    if (raw.isEmpty) return 'lib/assets/images/logo.png';
    if (raw.startsWith('lib/assets/images/shells/')) return raw;
    if (raw.contains('/')) {
      final fileName = raw.split('/').last;
      return 'lib/assets/images/shells/$fileName';
    }
    return 'lib/assets/images/shells/$raw';
  }

  Widget _buildInfoTile(String title, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFA9D0DF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF24627D),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF173F5A),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rawJson = shell['data'] is Map ? shell['data'] as Map<String, dynamic> : shell;
    final basic = Map<String, dynamic>.from(rawJson['basic_identification'] is Map ? rawJson['basic_identification'] as Map : {});
    final appearance = Map<String, dynamic>.from(rawJson['appearance'] is Map ? rawJson['appearance'] as Map : {});
    final habitat = Map<String, dynamic>.from(rawJson['habitat'] is Map ? rawJson['habitat'] as Map : {});
    final edibility = Map<String, dynamic>.from(rawJson['edibility_and_safety'] is Map ? rawJson['edibility_and_safety'] as Map : {});
    final similarSpecies = (rawJson['similar_species'] is List ? rawJson['similar_species'] as List : []).map((e) => e.toString()).toList();

    final imagePath = _resolveAssetPath(rawJson['image_path'] ?? shell['image'] ?? 'lib/assets/images/logo.png');
    final commonName = _safeString(basic['common_name'] ?? shell['name'] ?? 'Unknown shell');
    final scientificName = _safeString(basic['scientific_name'] ?? 'Unknown');
    final family = _safeString(basic['family'] ?? 'Unknown');
    final genus = _safeString(basic['genus'] ?? 'Unknown');
    final classification = _safeString(basic['classification'] ?? shell['category'] ?? 'Unknown');
    final shellShape = _safeString(appearance['shell_shape'] ?? 'Unknown');
    final shellColor = _safeString(appearance['shell_color'] ?? 'Unknown');
    final pattern = _safeString(appearance['pattern'] ?? 'Unknown');
    final surfaceTexture = _safeString(appearance['surface_texture'] ?? 'Unknown');
    final size = _safeString(appearance['size'] ?? 'Unknown');
    final distinctiveMarkings = _safeString(appearance['distinctive_markings'] ?? 'Unknown');

    final habitatType = _safeString(habitat['habitat_type'] ?? 'Unknown');
    final waterType = _safeString(habitat['water_type'] ?? 'Unknown');
    final depthRange = _safeString(habitat['depth_range'] ?? 'Unknown');
    final geographicDistribution = _safeString(habitat['geographic_distribution'] ?? 'Unknown');
    final typicalEnvironment = _safeString(habitat['typical_environment'] ?? 'Unknown');

    final edibilityStatus = _safeString(edibility['edibility'] ?? 'Unknown');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF176B87)),
        centerTitle: true,
        title: const Text(
          'View shell Details',
          style: TextStyle(
            color: Color(0xFF123B5D),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 220,
                  height: 220,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: const Color(0xFFA9D0DF)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'lib/assets/images/logo.png',
                          fit: BoxFit.contain,
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Divider(
                color: Color(0xFFA9D0DF),
                thickness: 1,
                height: 1,
              ),
              const SizedBox(height: 18),
              Text(
                commonName,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF123B5D),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                scientificName,
                style: const TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF24627D),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _chip('Classification', classification),
                  _chip('Family', family),
                  _chip('Genus', genus),
                  _chip('Edibility', edibilityStatus),
                ],
              ),
              const SizedBox(height: 20),
              _buildInfoTile('Habitat',
                  'Type: $habitatType\nWater type: $waterType\nDepth: $depthRange\nDistribution: $geographicDistribution\nEnvironment: $typicalEnvironment'),
              const SizedBox(height: 12),

              _buildInfoTile('Appearance',
                  'Shape: $shellShape\nColor: $shellColor\nPattern: $pattern\nTexture: $surfaceTexture\nSize: $size\nDistinctive markings: $distinctiveMarkings'),
              const SizedBox(height: 12),
              
              if (similarSpecies.isNotEmpty)
                _buildInfoTile('Similar species', similarSpecies.join(', ')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFDCECF4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF35627F),
        ),
      ),
    );
  }
}
