import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'shell_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key, this.initialFilter = 'All'});

  final String initialFilter;

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _filters = ['All'];
  String _selectedFilter = 'All';
  bool _isLoading = true;

  final List<Map<String, dynamic>> _shells = [];
  List<Map<String, dynamic>> _filteredShells = [];

  @override
  void initState() {
    super.initState();
    _selectedFilter = _normalizeFilter(widget.initialFilter);
    _searchController.addListener(_updateShellFilter);
    _loadShellData();
  }

  String _resolveAssetPath(String imagePath) {
    final value = imagePath.trim();
    if (value.isEmpty) return 'lib/assets/images/logo.png';
    if (value.startsWith('lib/assets/images/shells/')) return value;
    final fileName = value.split('/').last;
    return 'lib/assets/images/shells/$fileName';
  }

  Future<void> _loadShellData() async {
    try {
      final rawData = await rootBundle.loadString('lib/assets/images/shell-json.json');
      final decoded = jsonDecode(rawData) as List<dynamic>;

      final shells = decoded.map<Map<String, dynamic>>((entry) {
        final item = entry as Map<String, dynamic>;
        final basic = item['basic_identification'] as Map<String, dynamic>? ?? {};
        final commonName = (basic['common_name'] ?? 'Unknown shell').toString();
        final imagePath = _resolveAssetPath((item['image_path'] ?? '').toString());
        final classification = (basic['classification'] ?? 'Unknown').toString();

        return {
          'name': commonName,
          'image': imagePath,
          'category': classification,
          'data': item,
        };
      }).toList();

      final uniqueCategories = shells
          .map((shell) => shell['category'] ?? 'Unknown')
          .toSet()
          .toList()
        ..sort();

      if (!mounted) return;

      setState(() {
        _shells.clear();
        _shells.addAll(shells);
        _filters = ['All', ...uniqueCategories];
        if (!_filters.contains(_selectedFilter)) {
          _selectedFilter = 'All';
        }
        _isLoading = false;
      });
      _updateShellFilter();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _normalizeFilter(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty || normalized.toLowerCase() == 'all') return 'All';

    final map = {
      'bivalves': 'Bivalve',
      'bivalve': 'Bivalve',
      'cephalopods': 'Cephalopod',
      'cephalopod': 'Cephalopod',
      'gastropods': 'Gastropod',
      'gastropod': 'Gastropod',
      'scaphopods': 'Scaphopod',
      'scaphopod': 'Scaphopod',
      'polyplacophora': 'Polyplacophora',
    };

    return map[normalized.toLowerCase()] ?? normalized;
  }

  @override
  void dispose() {
    _searchController.removeListener(_updateShellFilter);
    _searchController.dispose();
    super.dispose();
  }

  void _updateShellFilter() {
    final query = _searchController.text.toLowerCase();
    final selected = _normalizeFilter(_selectedFilter);

    setState(() {
      _filteredShells = _shells.where((shell) {
        final name = (shell['name'] ?? '').toString().toLowerCase();
        final matchesSearch = name.contains(query);
        final matchesFilter = selected == 'All' || (shell['category'] ?? '') == selected;
        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  void _selectFilter(String filter) {
    setState(() {
      _selectedFilter = _normalizeFilter(filter);
      _updateShellFilter();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            const Text(
              'Explore Seashells',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF123B5D),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 1,
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Search seashells',
                    hintStyle: const TextStyle(color: Color(0xFF6D8795)),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF2F86A5)),
                    filled: true,
                    fillColor: const Color(0xFFE5F2F7),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filters.map((filter) {
                    final selected = _normalizeFilter(filter) == _selectedFilter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10.0),
                      child: GestureDetector(
                        onTap: () => _selectFilter(filter),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
                          decoration: BoxDecoration(
                            color: selected ? const Color(0xFF176B87) : const Color(0xFFDCECF4),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            filter,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: selected ? Colors.white : const Color(0xFF35627F),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _filteredShells.isEmpty
                    ? Center(
                        child: const Text(
                          'No shells match your search.',
                          style: TextStyle(fontSize: 13, color: Color(0xFF35627F)),
                        ),
                      )
                    : GridView.builder(
                        itemCount: _filteredShells.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.75,
                        ),
                        itemBuilder: (context, index) {
                          final shell = _filteredShells[index];
                          final rawShell = (shell['data'] is Map)
                              ? Map<String, dynamic>.from(shell['data'] as Map)
                              : <String, dynamic>{};
                          return GestureDetector(
                            onTap: () {
                              final selectedShell = rawShell.isNotEmpty
                                  ? rawShell
                                  : Map<String, dynamic>.from(shell);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ShellDetailScreen(
                                    shell: selectedShell,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFA9D0DF)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                      child: Image.asset(
                                        (shell['image'] ?? '').toString(),
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Image.asset(
                                            'lib/assets/images/logo.png',
                                            fit: BoxFit.contain,
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      (shell['name'] ?? 'Unknown shell').toString(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
            ],
          ),
        ),
      ),
    );
  }
}
