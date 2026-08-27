import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';

class AdvisoryScreen extends StatefulWidget {
  const AdvisoryScreen({super.key, this.onBackPressed});

  final VoidCallback? onBackPressed;

  @override
  State<AdvisoryScreen> createState() => _AdvisoryScreenState();
}

class _AdvisoryScreenState extends State<AdvisoryScreen> {
  static const _defaultBackendUrl = 'http://10.0.0.77:8000';
  static const _backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: _defaultBackendUrl,
  );
  static const _historyPageSize = 5;

  Map<String, dynamic>? _advisory;
  String? _lastUpdated;
  String? _error;
  bool _loading = true;
  bool _syncRunning = false;
  String? _syncStatusMessage;
  Timer? _syncStatusTimer;

  List<Map<String, dynamic>> _historyBulletins = [];
  bool _loadingHistory = false;
  String? _historyError;
  int _currentPage = 1;
  int _totalPages = 1;
  int _historyTotal = 0;
  String? _selectedHistoricalPdfUrl;
  File? _cachedPdfFile;

  String get _baseUrl {
    if (_backendUrl.trim().isNotEmpty) return _backendUrl;
    return Platform.isAndroid
        ? 'http://10.0.0.77:8000'
        : 'http://localhost:8000';
  }

  Uri get _apiUri => Uri.parse('$_baseUrl/api/advisories/shellfish/');
  Uri _pdfUri({String? bulletinNumber, int? year}) {
    return Uri.parse('$_baseUrl/api/advisories/shellfish/pdf/').replace(
      queryParameters:
          bulletinNumber == null
              ? null
              : {
                'bulletin_number': bulletinNumber,
                if (year != null) 'year': year.toString(),
              },
    );
  }

  Uri _historyUri({int page = 1, int pageSize = _historyPageSize}) {
    return Uri.parse('$_baseUrl/api/advisories/shellfish/history/').replace(
      queryParameters: {
        'page': page.toString(),
        'page_size': pageSize.toString(),
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    await _restoreCache();
    if (!mounted) return;
    await Future.wait([_loadAdvisory(), _loadHistory(page: _currentPage)]);
  }

  Future<void> _restoreCache() async {
    final preferences = await SharedPreferences.getInstance();
    final advisoryJson = preferences.getString('bfar_advisory_latest');
    final historyJson = preferences.getString('bfar_advisory_history_page_1');

    if (advisoryJson != null) {
      try {
        final cached = jsonDecode(advisoryJson) as Map<String, dynamic>;
        _advisory = cached['advisory'] as Map<String, dynamic>?;
        _lastUpdated = cached['last_updated'] as String?;
      } catch (_) {}
    }

    if (historyJson != null) {
      try {
        final cached = jsonDecode(historyJson) as Map<String, dynamic>;
        final items = cached['bulletins'];
        if (items is List) {
          _historyBulletins =
              items
                  .whereType<Map>()
                  .map((item) => Map<String, dynamic>.from(item))
                  .toList();
        }
        final pagination = cached['pagination'];
        if (pagination is Map) {
          _currentPage = pagination['page'] as int? ?? 1;
          _totalPages = pagination['total_pages'] as int? ?? 1;
          _historyTotal =
              pagination['total'] as int? ?? _historyBulletins.length;
        }
      } catch (_) {}
    }

    if (_advisory != null) {
      final cachedPdf = await _cachedPdfFor(_advisory!);
      if (cachedPdf != null && await cachedPdf.exists()) {
        _cachedPdfFile = cachedPdf;
      }
    }

    if (mounted) setState(() {});
  }

  Future<File?> _cachedPdfFor(Map<String, dynamic> bulletin) async {
    final number = bulletin['bulletin_number']?.toString();
    final year =
        bulletin['year'] ??
        bulletin['bulletin_year'] ??
        DateTime.tryParse(bulletin['date']?.toString() ?? '')?.year;
    if (number == null || year == null) return null;
    final directory = await getApplicationDocumentsDirectory();
    final safeNumber = number.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    return File('${directory.path}/bfar_${safeNumber}_$year.pdf');
  }

  Future<void> _cachePdf(String url, Map<String, dynamic> bulletin) async {
    final target = await _cachedPdfFor(bulletin);
    if (target == null || await target.exists()) return;
    final response = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 60));
    if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
      await target.writeAsBytes(response.bodyBytes, flush: true);
      if (mounted) setState(() => _cachedPdfFile = target);
    }
  }

  Future<void> _loadAdvisory({bool refresh = false}) async {
    _syncStatusTimer?.cancel();
    setState(() {
      _loading = true;
      _error = null;
      _syncStatusMessage = null;
      _syncRunning = false;
    });

    try {
      final response =
          refresh
              ? await http.post(_apiUri).timeout(const Duration(seconds: 30))
              : await http.get(_apiUri).timeout(const Duration(seconds: 30));

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final syncInfo =
          payload['sync'] is Map
              ? Map<String, dynamic>.from(payload['sync'] as Map)
              : <String, dynamic>{};
      final isSyncRunning = syncInfo['running'] == true;

      if (!mounted) return;

      setState(() {
        _syncRunning = isSyncRunning;
        _syncStatusMessage =
            isSyncRunning
                ? (syncInfo['error'] ?? 'BFAR sync is already running. Please wait.')
                : null;
        _advisory = payload['advisory'] as Map<String, dynamic>?;
        _lastUpdated = payload['last_updated'] as String?;
        _selectedHistoricalPdfUrl = null;
        _cachedPdfFile = null;
      });

      if (isSyncRunning) {
        _syncStatusTimer = Timer(const Duration(seconds: 3), () {
          if (!mounted) return;
          setState(() {
            _syncRunning = false;
            _syncStatusMessage = null;
          });
        });
      }

      if (response.statusCode >= 400 && payload['advisory'] == null && !isSyncRunning) {
        throw Exception(
          syncInfo['error'] ?? 'No advisory is available yet.',
        );
      }

      final preferences = await SharedPreferences.getInstance();
      await preferences.setString('bfar_advisory_latest', jsonEncode(payload));
      if (_advisory != null) {
        unawaited(_cachePdf(_pdfUri().toString(), _advisory!));
      }

      if (refresh) {
        await _loadHistory(page: 1);
      }
    } catch (exception) {
      if (mounted) {
        setState(
          () => _error = exception.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _syncStatusTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadHistory({int page = 1}) async {
    if (page < 1) return;

    setState(() {
      _loadingHistory = true;
      _historyError = null;
    });

    try {
      final response = await http
          .get(_historyUri(page: page))
          .timeout(const Duration(seconds: 30));

      final payload = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 400) {
        throw Exception(payload['error'] ?? 'Could not load bulletin history.');
      }

      final bulletins = <Map<String, dynamic>>[];
      final bulletinData = payload['bulletins'];

      if (bulletinData is List) {
        for (final item in bulletinData) {
          if (item is Map) {
            bulletins.add(Map<String, dynamic>.from(item));
          }
        }
      }

      final pagination = payload['pagination'];
      final paginationData =
          pagination is Map
              ? Map<String, dynamic>.from(pagination)
              : <String, dynamic>{};

      if (!mounted) return;

      setState(() {
        _historyBulletins = bulletins;
        _currentPage = (paginationData['page'] as int?) ?? page;
        _totalPages = (paginationData['total_pages'] as int?) ?? 1;
        _historyTotal = (paginationData['total'] as int?) ?? bulletins.length;
        if (_totalPages < 1) _totalPages = 1;
      });

      if (page == 1) {
        final preferences = await SharedPreferences.getInstance();
        await preferences.setString(
          'bfar_advisory_history_page_1',
          jsonEncode(payload),
        );
      }
    } catch (exception) {
      if (mounted) {
        setState(
          () =>
              _historyError = exception.toString().replaceFirst(
                'Exception: ',
                '',
              ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loadingHistory = false);
      }
    }
  }

  Future<void> _openPdf([String? pdfUrl]) async {
    final url =
        pdfUrl?.trim().isNotEmpty == true ? pdfUrl! : _pdfUri().toString();
    final uri = Uri.tryParse(url);

    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the advisory PDF.')),
        );
      }
    }
  }

  String _dateLabel() {
    final date = DateTime.tryParse(_lastUpdated ?? '');
    if (date == null) return 'Not synced yet';

    final localDate = date.toLocal();
    return 'Last Updated ${localDate.toString().substring(0, 16)}';
  }

  String _formatDate(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    if (date == null) return 'Date unavailable';

    final localDate = date.toLocal();
    return '${_monthName(localDate.month)} ${localDate.day}, ${localDate.year}';
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    if (month < 1 || month > 12) return '';
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF123B5D);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'BFAR Shellfish Advisory',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: navy,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        iconTheme: const IconThemeData(color: Color(0xFF176B87)),
        leading:
            widget.onBackPressed == null
                ? null
                : IconButton(
                  onPressed: widget.onBackPressed,
                  icon: const Icon(Icons.arrow_back),
                ),
        actions: [
          IconButton(
            onPressed: _loading ? null : () => _loadAdvisory(refresh: true),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh advisory',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadAdvisory(refresh: true),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 32),
          children: [
            Text(
              _dateLabel(),
              style: TextStyle(
                color: navy.withValues(alpha: .65),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 18),
            if (_syncRunning && _syncStatusMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sync, color: Colors.orange),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _syncStatusMessage!,
                        style: const TextStyle(
                          color: Color(0xFF7A4D00),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (_loading && _advisory == null)
              const Center(child: CircularProgressIndicator()),
            if (_error != null && _advisory == null)
              _Message(icon: Icons.cloud_off, text: _error!),
            if (_advisory != null) _advisoryContent(navy),
            const SizedBox(height: 28),
            _redTideUpdateSection(navy),
          ],
        ),
      ),
    );
  }

  Widget _advisoryContent(Color navy) {
    final advisory = _advisory!;

    final bulletinNumber =
        advisory['bulletin_number']?.toString() ?? 'Unavailable';
    final advisoryDate = advisory['date'] ?? advisory['advisory_date'];
    final advisoryYear =
        DateTime.tryParse(advisoryDate?.toString() ?? '')?.year ??
        DateTime.now().year;
    final displayedPdfUrl = _selectedHistoricalPdfUrl ?? _pdfUri().toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFE1F1F3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Shellfish Bulletin No. $bulletinNumber — Series of $advisoryYear',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: navy,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (displayedPdfUrl.isNotEmpty)
          SizedBox(
            height: 520,
            child:
                _cachedPdfFile != null
                    ? SfPdfViewer.file(_cachedPdfFile!)
                    : SfPdfViewer.network(displayedPdfUrl),
          ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD7E6E9)),
          ),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _openPdf(displayedPdfUrl),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text(
                    'Download PDF',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      () => launchUrl(
                        Uri.parse('https://www.bfar.da.gov.ph/'),
                        mode: LaunchMode.externalApplication,
                      ),
                  icon: const Icon(Icons.language),
                  label: const Text(
                    'BFAR Website',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _redTideUpdateSection(Color navy) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RED TIDE UPDATE',
          style: TextStyle(
            color: navy,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 12),
        if (_loadingHistory && _historyBulletins.isEmpty)
          const Center(child: CircularProgressIndicator()),
        if (_historyError != null && _historyBulletins.isEmpty)
          _Message(icon: Icons.cloud_off, text: _historyError!),
        if (!_loadingHistory &&
            _historyError == null &&
            _historyBulletins.isEmpty)
          const _Message(
            icon: Icons.inbox_outlined,
            text: 'No historical bulletins are available.',
          ),
        if (_historyBulletins.isNotEmpty) _bulletinTable(navy),
        if (_historyBulletins.isNotEmpty || _totalPages > 1)
          _paginationControls(navy),
      ],
    );
  }

  Widget _bulletinTable(Color navy) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD7E6E9)),
      ),
      child: Column(
        children: [
          Container(
            color: const Color(0xFFEAF4F5),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Bulletin No.',
                    style: TextStyle(color: navy, fontWeight: FontWeight.w600),
                  ),
                ),
                SizedBox(
                  width: 125,
                  child: Text(
                    'Date',
                    style: TextStyle(color: navy, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          ..._historyBulletins.map((bulletin) {
            final bulletinNumber =
                bulletin['bulletin_number']?.toString() ?? 'Unavailable';
            final date = bulletin['date'];
            final year = bulletin['year'] as int?;

            return InkWell(
              onTap: () {
                if (bulletinNumber != 'Unavailable' &&
                    bulletinNumber.isNotEmpty) {
                  final selectedBulletin = Map<String, dynamic>.from(bulletin);
                  final pdfUrl =
                      _pdfUri(
                        bulletinNumber: bulletinNumber,
                        year: year,
                      ).toString();
                  setState(() {
                    _selectedHistoricalPdfUrl = pdfUrl;
                    _cachedPdfFile = null;
                  });
                  unawaited(_cachePdf(pdfUrl, selectedBulletin));
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFE4EEF0))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        bulletinNumber,
                        style: TextStyle(
                          color: navy,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 125,
                      child: Text(
                        _formatDate(date),
                        style: TextStyle(color: navy.withValues(alpha: .75)),
                      ),
                    ),
                    Icon(
                      Icons.picture_as_pdf_outlined,
                      size: 20,
                      color: navy.withValues(alpha: .7),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _paginationControls(Color navy) {
    final canGoPrevious = _currentPage > 1 && !_loadingHistory;
    final canGoNext = _currentPage < _totalPages && !_loadingHistory;

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        children: [
          OutlinedButton(
            onPressed:
                canGoPrevious
                    ? () => _loadHistory(page: _currentPage - 1)
                    : null,
            child: const Text('Previous'),
          ),
          Expanded(
            child: Center(
              child:
                  _loadingHistory
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : Text(
                        'Page $_currentPage of $_totalPages  |  $_historyTotal total',
                        style: TextStyle(
                          color: navy,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
            ),
          ),
          OutlinedButton(
            onPressed:
                canGoNext ? () => _loadHistory(page: _currentPage + 1) : null,
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.blueGrey),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
