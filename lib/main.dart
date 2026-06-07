import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const AirMonitoringApp());
}

class AirMonitoringApp extends StatefulWidget {
  const AirMonitoringApp({super.key});

  @override
  State<AirMonitoringApp> createState() => _AirMonitoringAppState();
}

class _AirMonitoringAppState extends State<AirMonitoringApp> {
  @override
  void initState() {
    super.initState();
    globalAppState = AppState();
  }

  @override
  void dispose() {
    globalAppState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LoRa Air Quality Monitor',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A), // Deep Slate Navy
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF0D9488), // Teal Accent
          secondary: Color(0xFF3B82F6), // Blue Accent
          surface: Color(0xFF1E293B), // Dark Slate Grey
          error: Color(0xFFEF4444),
          onPrimary: Colors.white,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E293B),
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const DashboardScreen(),
    );
  }
}

// Model data point untuk grafik (menyimpan data historis)
class SensorDataPoint {
  final DateTime timestamp;
  final double temperature;
  final double humidity;
  final int co2;
  final int co;

  SensorDataPoint({
    required this.timestamp,
    required this.temperature,
    required this.humidity,
    required this.co2,
    required this.co,
  });
}

// Model data sederhana untuk merepresentasikan tiap Node Sensor
class SensorNode {
  final String id;
  final String name;
  final double temperature;
  final double humidity;
  final int co2;
  final int co;
  final String status; // 'Aman', 'Waspada', 'Bahaya', 'Offline'
  final List<SensorDataPoint> dataHistory;

  SensorNode({
    required this.id,
    required this.name,
    required this.temperature,
    required this.humidity,
    required this.co2,
    required this.co,
    required this.status,
    required this.dataHistory,
  });
}

// Global App State untuk manajemen data dan timer otomatis
class AppState extends ChangeNotifier {
  List<SensorNode> nodes = [];
  Timer? _timer;
  StreamSubscription? _dbSubscription;
  bool _isDemoMode = false;
  DateTime _lastUpdateTime = DateTime.now();

  bool get isDemoMode => _isDemoMode;
  DateTime get lastUpdateTime => _lastUpdateTime;

  AppState() {
    _initializeData();
    _setupFirebaseListener();
    _startTimer();
  }

  void _initializeData() {
    final now = DateTime.now();
    nodes = [
      SensorNode(
        id: 'node_01',
        name: 'Area Parkir',
        temperature: 32.5,
        humidity: 60.0,
        co2: 400,
        co: 10,
        status: 'Good',
        dataHistory: [
          SensorDataPoint(
            timestamp: now.subtract(const Duration(minutes: 30)),
            temperature: 31.0,
            humidity: 62.0,
            co2: 380,
            co: 8,
          ),
          SensorDataPoint(
            timestamp: now.subtract(const Duration(minutes: 20)),
            temperature: 31.8,
            humidity: 61.0,
            co2: 390,
            co: 9,
          ),
          SensorDataPoint(
            timestamp: now.subtract(const Duration(minutes: 10)),
            temperature: 32.2,
            humidity: 60.5,
            co2: 395,
            co: 9,
          ),
          SensorDataPoint(
            timestamp: now,
            temperature: 32.5,
            humidity: 60.0,
            co2: 400,
            co: 10,
          ),
        ],
      ),
      SensorNode(
        id: 'node_02',
        name: 'Ruang Produksi',
        temperature: 35.0,
        humidity: 55.0,
        co2: 800,
        co: 45,
        status: 'Unhealthy',
        dataHistory: [
          SensorDataPoint(
            timestamp: now.subtract(const Duration(minutes: 30)),
            temperature: 33.5,
            humidity: 57.0,
            co2: 750,
            co: 40,
          ),
          SensorDataPoint(
            timestamp: now.subtract(const Duration(minutes: 20)),
            temperature: 34.2,
            humidity: 56.0,
            co2: 770,
            co: 42,
          ),
          SensorDataPoint(
            timestamp: now.subtract(const Duration(minutes: 10)),
            temperature: 34.6,
            humidity: 55.5,
            co2: 790,
            co: 44,
          ),
          SensorDataPoint(
            timestamp: now,
            temperature: 35.0,
            humidity: 55.0,
            co2: 800,
            co: 45,
          ),
        ],
      ),
      SensorNode(
        id: 'node_03',
        name: 'Gudang Kimia',
        temperature: 38.2,
        humidity: 40.0,
        co2: 1200,
        co: 150,
        status: 'Hazardous',
        dataHistory: [
          SensorDataPoint(
            timestamp: now.subtract(const Duration(minutes: 30)),
            temperature: 36.5,
            humidity: 42.0,
            co2: 1050,
            co: 120,
          ),
          SensorDataPoint(
            timestamp: now.subtract(const Duration(minutes: 20)),
            temperature: 37.3,
            humidity: 41.0,
            co2: 1120,
            co: 135,
          ),
          SensorDataPoint(
            timestamp: now.subtract(const Duration(minutes: 10)),
            temperature: 37.8,
            humidity: 40.5,
            co2: 1160,
            co: 145,
          ),
          SensorDataPoint(
            timestamp: now,
            temperature: 38.2,
            humidity: 40.0,
            co2: 1200,
            co: 150,
          ),
        ],
      ),
      SensorNode(
        id: 'node_04',
        name: 'Ruang Server',
        temperature: 22.0,
        humidity: 50.0,
        co2: 350,
        co: 5,
        status: 'Offline',
        dataHistory: [
          SensorDataPoint(
            timestamp: now.subtract(const Duration(minutes: 30)),
            temperature: 21.5,
            humidity: 51.0,
            co2: 340,
            co: 5,
          ),
          SensorDataPoint(
            timestamp: now.subtract(const Duration(minutes: 20)),
            temperature: 21.8,
            humidity: 50.5,
            co2: 345,
            co: 5,
          ),
          SensorDataPoint(
            timestamp: now.subtract(const Duration(minutes: 10)),
            temperature: 21.9,
            humidity: 50.2,
            co2: 348,
            co: 5,
          ),
          SensorDataPoint(
            timestamp: now,
            temperature: 22.0,
            humidity: 50.0,
            co2: 350,
            co: 5,
          ),
        ],
      ),
    ];
  }

  String _determineStatus(double temp, int co2, int co) {
    if (temp > 40.0 || co > 100 || co2 > 1500) {
      return 'Hazardous';
    } else if (temp > 37.0 || co > 80 || co2 > 1000) {
      return 'Very Unhealthy';
    } else if (temp > 35.0 || co > 40 || co2 > 700) {
      return 'Unhealthy';
    } else if (temp > 33.0 || co > 15 || co2 > 500) {
      return 'Moderate';
    } else {
      return 'Good';
    }
  }

  void _setupFirebaseListener() {
    final ref = FirebaseDatabase.instance.ref('aqms/nodes');
    _dbSubscription = ref.onValue.listen((event) {
      final snapshot = event.snapshot;
      if (snapshot.exists) {
        final data = snapshot.value;
        if (data is Map) {
          final List<SensorNode> newNodes = [];
          bool needToUpdateHistoryOnFirebase = false;
          final Map<String, dynamic> historyUpdates = {};

          data.forEach((key, val) {
            if (val is Map) {
              final id = val['id']?.toString() ?? key.toString();
              final name = val['name']?.toString() ?? 'Sensor Node';
              
              final sensors = val['sensors'] as Map?;
              final temp = (sensors?['suhu'] as num?)?.toDouble() ?? 0.0;
              final hum = (sensors?['kelembapan'] as num?)?.toDouble() ?? 0.0;
              final co2 = (sensors?['CO2'] as num?)?.toInt() ?? 0;
              final co = (sensors?['CO'] as num?)?.toInt() ?? 0;

              String status = val['status']?.toString() ?? '';
              if (status.isEmpty) {
                status = _determineStatus(temp, co2, co);
              }

              List<SensorDataPoint> history = _parseHistory(val['dataHistory']);
              
              // Cek apakah history kosong. Jika ya, atau jika data terbaru berbeda dari titik terakhir di history, tambahkan titik baru.
              bool isNewDataPoint = false;
              if (history.isEmpty) {
                isNewDataPoint = true;
              } else {
                final lastPoint = history.last;
                final timeDiff = DateTime.now().difference(lastPoint.timestamp);
                final valueChanged = lastPoint.temperature != temp ||
                                     lastPoint.humidity != hum ||
                                     lastPoint.co2 != co2 ||
                                     lastPoint.co != co;
                if (valueChanged && timeDiff.inSeconds > 10) {
                  isNewDataPoint = true;
                }
              }

              if (isNewDataPoint) {
                final newPoint = SensorDataPoint(
                  timestamp: DateTime.now(),
                  temperature: temp,
                  humidity: hum,
                  co2: co2,
                  co: co,
                );
                history.add(newPoint);
                if (history.length > 48) {
                  history.removeAt(0);
                }

                needToUpdateHistoryOnFirebase = true;
                historyUpdates['$id/dataHistory'] = history.map((p) => {
                  'timestamp': p.timestamp.millisecondsSinceEpoch,
                  'temperature': p.temperature,
                  'humidity': p.humidity,
                  'co2': p.co2,
                  'co': p.co,
                }).toList();
                
                historyUpdates['$id/id'] = id;
                if (val['status'] == null || val['status'].toString().isEmpty) {
                  historyUpdates['$id/status'] = status;
                }
              }

              newNodes.add(SensorNode(
                id: id,
                name: name,
                temperature: temp,
                humidity: hum,
                co2: co2,
                co: co,
                status: status,
                dataHistory: history,
              ));
            }
          });

          // Urutkan berdasarkan ID agar konsisten
          newNodes.sort((a, b) => a.id.compareTo(b.id));

          nodes = newNodes;
          _lastUpdateTime = DateTime.now();
          notifyListeners();

          // Lakukan batch update history ke Firebase jika ada data point baru
          if (needToUpdateHistoryOnFirebase) {
            ref.update(historyUpdates);
          }
        }
      } else {
        // Jika database kosong, upload data default ke Firebase
        _initializeAndUploadDefaultData();
      }
    }, onError: (error) {
      debugPrint("Firebase Database Error: $error");
    });
  }

  List<SensorDataPoint> _parseHistory(dynamic historyData) {
    final List<SensorDataPoint> history = [];
    if (historyData == null) return history;

    if (historyData is List) {
      for (var element in historyData) {
        if (element != null) {
          history.add(_parsePoint(element));
        }
      }
    } else if (historyData is Map) {
      // Sort keys to maintain chronological order
      final sortedKeys = historyData.keys.toList()..sort((a, b) => a.toString().compareTo(b.toString()));
      for (var key in sortedKeys) {
        history.add(_parsePoint(historyData[key]));
      }
    }
    return history;
  }

  SensorDataPoint _parsePoint(dynamic element) {
    final map = element as Map;
    DateTime ts;
    if (map['timestamp'] is int) {
      ts = DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int);
    } else if (map['timestamp'] is String) {
      ts = DateTime.tryParse(map['timestamp'] as String) ?? DateTime.now();
    } else {
      ts = DateTime.now();
    }

    return SensorDataPoint(
      timestamp: ts,
      temperature: (map['temperature'] as num?)?.toDouble() ?? 0.0,
      humidity: (map['humidity'] as num?)?.toDouble() ?? 0.0,
      co2: (map['co2'] as num?)?.toInt() ?? 0,
      co: (map['co'] as num?)?.toInt() ?? 0,
    );
  }

  Future<void> _initializeAndUploadDefaultData() async {
    final ref = FirebaseDatabase.instance.ref('aqms/nodes');
    final Map<String, dynamic> uploadData = {};

    for (var node in nodes) {
      uploadData[node.id] = {
        'id': node.id,
        'name': node.name,
        'sensors': {
          'suhu': node.temperature,
          'kelembapan': node.humidity,
          'CO2': node.co2,
          'CO': node.co,
        },
        'status': node.status,
        'dataHistory': node.dataHistory.map((p) => {
          'timestamp': p.timestamp.millisecondsSinceEpoch,
          'temperature': p.temperature,
          'humidity': p.humidity,
          'co2': p.co2,
          'co': p.co,
        }).toList(),
      };
    }

    await ref.set(uploadData);
  }

  void toggleDemoMode() {
    _isDemoMode = !_isDemoMode;
    _startTimer();
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    final duration = _isDemoMode
        ? const Duration(seconds: 10) // Demo Mode: update setiap 10 detik
        : const Duration(minutes: 10); // Normal Mode: update setiap 10 menit
    _timer = Timer.periodic(duration, (timer) {
      simulateStep();
    });
  }

  // Menambahkan data point baru secara global untuk simulasi berkala
  void simulateStep() {
    _lastUpdateTime = DateTime.now();
    final ref = FirebaseDatabase.instance.ref('aqms/nodes');

    for (int i = 0; i < nodes.length; i++) {
      final node = nodes[i];

      // Ruang Server (Node 4) disimulasikan offline, nilainya relatif stabil/tetap
      if (node.id == 'node_04') {
        if (node.dataHistory.isEmpty) continue;
        final lastPoint = node.dataHistory.last;
        final newPoint = SensorDataPoint(
          timestamp: _lastUpdateTime,
          temperature: lastPoint.temperature,
          humidity: lastPoint.humidity,
          co2: lastPoint.co2,
          co: lastPoint.co,
        );
        final updatedHistory = List<SensorDataPoint>.from(node.dataHistory)..add(newPoint);
        if (updatedHistory.length > 48) updatedHistory.removeAt(0);

        ref.child(node.id).update({
          'status': 'Offline',
          'dataHistory': updatedHistory.map((p) => {
            'timestamp': p.timestamp.millisecondsSinceEpoch,
            'temperature': p.temperature,
            'humidity': p.humidity,
            'co2': p.co2,
            'co': p.co,
          }).toList(),
        });
        continue;
      }

      if (node.dataHistory.isEmpty) continue;
      final lastPoint = node.dataHistory.last;

      // Variasi nilai simulasi sensor (suhu, kelembaban, CO2, CO)
      double deltaTemp = (i == 0) ? 0.3 : (i == 1) ? -0.2 : 0.4;
      if (_lastUpdateTime.second % 3 == 0) deltaTemp = -deltaTemp;
      double newTemp = double.parse((lastPoint.temperature + deltaTemp).toStringAsFixed(1));
      if (newTemp < 15.0) newTemp = 18.0;
      if (newTemp > 45.0) newTemp = 40.0;

      double deltaHum = (i == 0) ? -0.8 : (i == 1) ? 1.2 : -0.5;
      if (_lastUpdateTime.second % 2 == 0) deltaHum = -deltaHum;
      double newHum = double.parse((lastPoint.humidity + deltaHum).toStringAsFixed(1));
      if (newHum < 20.0) newHum = 30.0;
      if (newHum > 95.0) newHum = 85.0;

      int deltaCo2 = (i == 0) ? 15 : (i == 1) ? 35 : -25;
      int newCo2 = lastPoint.co2 + deltaCo2;
      if (newCo2 < 300) newCo2 = 350;
      if (newCo2 > 2000) newCo2 = 1800;

      int deltaCo = (i == 0) ? 1 : (i == 1) ? 4 : -3;
      int newCo = lastPoint.co + deltaCo;
      if (newCo < 0) newCo = 2;
      if (newCo > 300) newCo = 250;

      // Logika Penentuan Status
      String newStatus = _determineStatus(newTemp, newCo2, newCo);

      final newPoint = SensorDataPoint(
        timestamp: _lastUpdateTime,
        temperature: newTemp,
        humidity: newHum,
        co2: newCo2,
        co: newCo,
      );

      final updatedHistory = List<SensorDataPoint>.from(node.dataHistory)..add(newPoint);
      if (updatedHistory.length > 48) {
        updatedHistory.removeAt(0);
      }

      ref.child(node.id).update({
        'sensors': {
          'suhu': newPoint.temperature,
          'kelembapan': newPoint.humidity,
          'CO2': newPoint.co2,
          'CO': newPoint.co,
        },
        'status': newStatus,
        'dataHistory': updatedHistory.map((p) => {
          'timestamp': p.timestamp.millisecondsSinceEpoch,
          'temperature': p.temperature,
          'humidity': p.humidity,
          'co2': p.co2,
          'co': p.co,
        }).toList(),
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _dbSubscription?.cancel();
    super.dispose();
  }
}

// Global state instance
late AppState globalAppState;

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Good':
        return const Color(0xFF10B981); // Emerald Green
      case 'Moderate':
        return const Color(0xFF06B6D4); // Cyan Blue
      case 'Unhealthy':
        return const Color(0xFFF59E0B); // Amber Orange
      case 'Very Unhealthy':
        return const Color(0xFFEF4444); // Bright Red
      case 'Hazardous':
        return const Color(0xFFB91C1C); // Crimson Dark Red
      case 'Offline':
      default:
        return const Color(0xFF64748B); // Slate Grey
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: globalAppState,
      builder: (context, child) {
        final nodes = globalAppState.nodes;

        // Hitung statistik ringkasan
        int total = nodes.length;
        int goodCount = nodes.where((n) => n.status == 'Good').length;
        int moderateCount = nodes.where((n) => n.status == 'Moderate').length;
        int unhealthyCount = nodes.where((n) => n.status == 'Unhealthy').length;
        int veryUnhealthyCount = nodes.where((n) => n.status == 'Very Unhealthy').length;
        int hazardousCount = nodes.where((n) => n.status == 'Hazardous').length;
        int offlineCount = nodes.where((n) => n.status == 'Offline').length;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFF0F172A),
            elevation: 0,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.settings_input_antenna, color: Color(0xFF0D9488)),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'LoRa AQMS',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                    ),
                    Text(
                      'Air Quality Monitoring System',
                      style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              // Panel Simulasi Waktu
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF0D9488).withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  globalAppState.isDemoMode ? Icons.bolt : Icons.access_time_filled,
                                  color: globalAppState.isDemoMode ? Colors.greenAccent : const Color(0xFF0D9488),
                                  size: 20,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  globalAppState.isDemoMode ? 'Demo Mode: AKTIF' : 'Mode Waktu Normal',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: globalAppState.isDemoMode ? Colors.greenAccent : Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              globalAppState.isDemoMode
                                  ? 'Data sensor diupdate setiap 10 detik.'
                                  : 'Data sensor diupdate setiap 10 menit.',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                            Text(
                              'Terakhir: ${DateFormat('HH:mm:ss').format(globalAppState.lastUpdateTime)}',
                              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          // Tombol manual step
                          IconButton.filled(
                            onPressed: () {
                              globalAppState.simulateStep();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Simulasi 10 menit berikutnya berhasil ditambahkan!'),
                                  duration: Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            icon: const Icon(Icons.skip_next, size: 20),
                            tooltip: 'Langkah manual +10 Menit',
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFF0D9488),
                              foregroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Switch Demo Mode
                          Switch(
                            value: globalAppState.isDemoMode,
                            onChanged: (value) {
                              globalAppState.toggleDemoMode();
                            },
                            activeTrackColor: const Color(0xFF0D9488),
                            activeThumbColor: Colors.white,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Summary Statistik (Scrollable Row)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildSummaryCard('Total', total, const Color(0xFF3B82F6)),
                      const SizedBox(width: 8),
                      _buildSummaryCard('Good', goodCount, const Color(0xFF10B981)),
                      const SizedBox(width: 8),
                      _buildSummaryCard('Moderate', moderateCount, const Color(0xFF06B6D4)),
                      const SizedBox(width: 8),
                      _buildSummaryCard('Unhealthy', unhealthyCount, const Color(0xFFF59E0B)),
                      const SizedBox(width: 8),
                      _buildSummaryCard('Very Unhealthy', veryUnhealthyCount, const Color(0xFFEF4444)),
                      const SizedBox(width: 8),
                      _buildSummaryCard('Hazardous', hazardousCount, const Color(0xFFB91C1C)),
                      const SizedBox(width: 8),
                      _buildSummaryCard('Offline', offlineCount, const Color(0xFF64748B)),
                    ],
                  ),
                ),
              ),

              // Title list
              const Padding(
                padding: EdgeInsets.only(left: 18.0, top: 16.0, bottom: 8.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Node Sensor Aktif',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),

              // List of nodes
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  itemCount: nodes.length,
                  itemBuilder: (context, index) {
                    final node = nodes[index];
                    final statusColor = _getStatusColor(node.status);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: statusColor.withValues(alpha: 0.5), width: 1.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          // Navigasi ke halaman detail sensor dengan membawa ID
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SensorDetailScreen(nodeId: node.id),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF1E293B),
                                const Color(0xFF1E293B).withValues(alpha: 0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header Node: Nama, ID, Status
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.location_on, color: statusColor, size: 20),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            node.name,
                                            style: const TextStyle(
                                                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                          ),
                                          Text(
                                            'ID: ${node.id}',
                                            style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: statusColor),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: statusColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          node.status,
                                          style: TextStyle(
                                              color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24, thickness: 1, color: Color(0xFF334155)),

                              // Grid Sensor
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildMiniSensorVal(Icons.thermostat, '${node.temperature}°C', 'Suhu', Colors.orangeAccent),
                                  _buildMiniSensorVal(Icons.water_drop, '${node.humidity}%', 'Lembab', Colors.blueAccent),
                                  _buildMiniSensorVal(Icons.cloud, '${node.co2}', 'CO2 ppm', Colors.tealAccent),
                                  _buildMiniSensorVal(Icons.warning, '${node.co}', 'CO ppm', Colors.purpleAccent),
                                ],
                              ),

                              const SizedBox(height: 12),
                              // Panduan Klik Card
                              const Align(
                                alignment: Alignment.centerRight,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Lihat Grafik & Riwayat',
                                      style: TextStyle(fontSize: 11, color: Color(0xFF0D9488), fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(Icons.arrow_forward_ios, size: 10, color: Color(0xFF0D9488)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(String title, int count, Color color) {
    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniSensorVal(IconData icon, String value, String label, Color iconColor) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 9, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}

// Halaman Detail Sensor yang menampilkan detail grafik dan tabel perbandingan data per 10 menit
class SensorDetailScreen extends StatefulWidget {
  final String nodeId;

  const SensorDetailScreen({super.key, required this.nodeId});

  @override
  State<SensorDetailScreen> createState() => _SensorDetailScreenState();
}

class _SensorDetailScreenState extends State<SensorDetailScreen> {
  // Pilihan sensor yang sedang ditampilkan grafiknya
  // 0 = Suhu, 1 = Kelembaban, 2 = CO2, 3 = CO
  int _selectedSensorIndex = 0;
  int _tablePageIndex = 0;

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Good':
        return const Color(0xFF10B981); // Emerald Green
      case 'Moderate':
        return const Color(0xFF06B6D4); // Cyan Blue
      case 'Unhealthy':
        return const Color(0xFFF59E0B); // Amber Orange
      case 'Very Unhealthy':
        return const Color(0xFFEF4444); // Bright Red
      case 'Hazardous':
        return const Color(0xFFB91C1C); // Crimson Dark Red
      case 'Offline':
      default:
        return const Color(0xFF64748B); // Slate Grey
    }
  }

  // Membuat data LineChart yang disesuaikan
  LineChartData _buildLineChartData(
    List<SensorDataPoint> sensorData,
    List<double> values,
    Color lineColor,
  ) {
    final spots = sensorData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), values[entry.key]);
    }).toList();

    // Hitung Min & Max Y dengan padding aman
    double minVal = values.isEmpty ? 0 : values.reduce((a, b) => a < b ? a : b);
    double maxVal = values.isEmpty ? 100 : values.reduce((a, b) => a > b ? a : b);

    double padding = (maxVal - minVal) * 0.25;
    if (padding == 0) padding = 2; // Jika nilainya sama semua

    double minY = double.parse((minVal - padding).toStringAsFixed(1));
    if (minY < 0 && _selectedSensorIndex >= 2) minY = 0; // CO & CO2 tidak boleh minus
    double maxY = double.parse((maxVal + padding).toStringAsFixed(1));

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: ((maxY - minY) / 4).clamp(0.1, 500),
        verticalInterval: 1,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: const Color(0xFF334155),
            strokeWidth: 0.5,
          );
        },
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: const Color(0xFF334155),
            strokeWidth: 0.5,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            getTitlesWidget: (value, meta) {
              int index = value.toInt();
              if (index >= 0 && index < sensorData.length) {
                // Tampilkan label waktu dengan interval tertentu jika data terlalu banyak
                if (sensorData.length > 8 && index % 2 != 0) {
                  return const SizedBox();
                }
                final time = sensorData[index].timestamp;
                return Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(
                    DateFormat('HH:mm').format(time),
                    style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 42,
            getTitlesWidget: (value, meta) {
              return Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: Text(
                  value.toStringAsFixed(_selectedSensorIndex >= 2 ? 0 : 1),
                  style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.right,
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: const Color(0xFF475569), width: 1),
      ),
      minX: 0,
      maxX: (sensorData.length - 1).toDouble().clamp(1.0, 48.0),
      minY: minY,
      maxY: maxY,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: lineColor,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: lineColor,
                strokeWidth: 1.5,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                lineColor.withValues(alpha: 0.35),
                lineColor.withValues(alpha: 0.01),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) => const Color(0xFF1E293B).withValues(alpha: 0.9),
          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
            return touchedBarSpots.map((barSpot) {
              final val = barSpot.y;
              String unit = '';
              if (_selectedSensorIndex == 0) unit = ' °C';
              if (_selectedSensorIndex == 1) unit = ' %';
              if (_selectedSensorIndex == 2) unit = ' ppm';
              if (_selectedSensorIndex == 3) unit = ' ppm';

              return LineTooltipItem(
                '$val$unit',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: globalAppState,
      builder: (context, child) {
        // Cari data node sensor secara real-time dari AppState
        final node = globalAppState.nodes.firstWhere(
          (n) => n.id == widget.nodeId,
          orElse: () => globalAppState.nodes.first,
        );

        final sensorData = node.dataHistory;
        final reversedData = sensorData.reversed.toList();
        final totalItems = reversedData.length;
        const itemsPerPage = 5;
        final totalPages = (totalItems / itemsPerPage).ceil();

        int activePageIndex = _tablePageIndex;
        if (totalPages > 0) {
          if (activePageIndex >= totalPages) {
            activePageIndex = totalPages - 1;
          }
        } else {
          activePageIndex = 0;
        }
        if (activePageIndex < 0) {
          activePageIndex = 0;
        }

        final startIndex = totalItems == 0 ? 0 : activePageIndex * itemsPerPage;
        final endIndex = totalItems == 0 ? 0 : (startIndex + itemsPerPage).clamp(0, totalItems);
        final paginatedData = totalItems == 0 ? <SensorDataPoint>[] : reversedData.sublist(startIndex, endIndex);

        final statusColor = _getStatusColor(node.status);

        // Ekstrak nilai spesifik untuk chart
        final temperatureValues = sensorData.map((d) => d.temperature).toList();
        final humidityValues = sensorData.map((d) => d.humidity).toList();
        final co2Values = sensorData.map((d) => d.co2.toDouble()).toList();
        final coValues = sensorData.map((d) => d.co.toDouble()).toList();

        // Tentukan data aktif sesuai sensor yang dipilih
        List<double> activeValues = [];
        String sensorTitle = '';
        String sensorUnit = '';
        Color sensorColor = Colors.teal;
        IconData sensorIcon = Icons.thermostat;

        switch (_selectedSensorIndex) {
          case 0:
            activeValues = temperatureValues;
            sensorTitle = 'Suhu';
            sensorUnit = '°C';
            sensorColor = Colors.orangeAccent;
            sensorIcon = Icons.thermostat;
            break;
          case 1:
            activeValues = humidityValues;
            sensorTitle = 'Kelembaban';
            sensorUnit = '%';
            sensorColor = Colors.blueAccent;
            sensorIcon = Icons.water_drop;
            break;
          case 2:
            activeValues = co2Values;
            sensorTitle = 'CO2';
            sensorUnit = 'ppm';
            sensorColor = const Color(0xFF14B8A6); // Teal
            sensorIcon = Icons.cloud;
            break;
          case 3:
            activeValues = coValues;
            sensorTitle = 'CO';
            sensorUnit = 'ppm';
            sensorColor = Colors.purpleAccent;
            sensorIcon = Icons.warning;
            break;
        }

        // Hitung Statistik (Min, Max, Rata-rata)
        double minVal = activeValues.isEmpty ? 0 : activeValues.reduce((a, b) => a < b ? a : b);
        double maxVal = activeValues.isEmpty ? 0 : activeValues.reduce((a, b) => a > b ? a : b);
        double avgVal = activeValues.isEmpty ? 0 : activeValues.reduce((a, b) => a + b) / activeValues.length;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFF0F172A),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              node.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.skip_next_outlined),
                tooltip: 'Simulasikan +10 Menit',
                onPressed: () {
                  globalAppState.simulateStep();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Simulasi 10 menit berikutnya berhasil ditambahkan!'),
                      duration: Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Node Status Ringkasan
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Kondisi Udara Node', style: TextStyle(color: Colors.grey, fontSize: 11)),
                          const SizedBox(height: 4),
                          Text(
                            node.status,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: statusColor),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          'ID: ${node.id}',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: statusColor),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Grid Nilai Sensor Terbaru & Pemilih Grafik (Interactive Tabs)
                const Text(
                  'Pilih Sensor untuk Detail Grafik:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildInteractiveTabCard(0, 'Suhu', '${node.temperature}°C', Icons.thermostat, Colors.orangeAccent),
                    _buildInteractiveTabCard(1, 'Lembab', '${node.humidity}%', Icons.water_drop, Colors.blueAccent),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildInteractiveTabCard(2, 'CO2', '${node.co2} ppm', Icons.cloud, const Color(0xFF14B8A6)),
                    _buildInteractiveTabCard(3, 'CO', '${node.co} ppm', Icons.warning, Colors.purpleAccent),
                  ],
                ),

                const SizedBox(height: 24),

                // Card Box Grafik
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF334155), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(sensorIcon, color: sensorColor, size: 22),
                              const SizedBox(width: 8),
                              Text(
                                'Perkembangan Data $sensorTitle ($sensorUnit)',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.teal.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Per 10 Menit',
                              style: TextStyle(fontSize: 9, color: Color(0xFF0D9488), fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Line Chart
                      SizedBox(
                        height: 220,
                        child: activeValues.isEmpty
                            ? const Center(child: Text('Tidak ada data history'))
                            : LineChart(
                                _buildLineChartData(sensorData, activeValues, sensorColor),
                              ),
                      ),
                      const SizedBox(height: 16),
                      // Ringkasan Statistik data grafik
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatValue('TERENDAH', minVal.toStringAsFixed(1) + sensorUnit, sensorColor),
                            Container(width: 1, height: 28, color: const Color(0xFF334155)),
                            _buildStatValue('RATA-RATA', avgVal.toStringAsFixed(1) + sensorUnit, sensorColor),
                            Container(width: 1, height: 28, color: const Color(0xFF334155)),
                            _buildStatValue('TERTINGGI', maxVal.toStringAsFixed(1) + sensorUnit, sensorColor),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Tabel Riwayat Perbandingan Data Sensor
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tabel Riwayat Perbandingan Data',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      'Last 8 Hours (${sensorData.length} pts)',
                      style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Membandingkan perubahan nilai tiap parameter per 10 menit sekali.',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 12),

                // Widget Table comparison
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        child: Table(
                          columnWidths: const {
                            0: FlexColumnWidth(1.2),
                            1: FlexColumnWidth(1.0),
                            2: FlexColumnWidth(1.0),
                            3: FlexColumnWidth(1.2),
                            4: FlexColumnWidth(1.0),
                          },
                          border: const TableBorder(
                            horizontalInside: BorderSide(color: Color(0xFF334155), width: 1),
                            verticalInside: BorderSide(color: Color(0xFF334155), width: 0.5),
                          ),
                          children: [
                            // Header Table
                            const TableRow(
                              decoration: BoxDecoration(
                                color: Color(0xFF0F172A),
                              ),
                              children: [
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                                  child: Text('Waktu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey), textAlign: TextAlign.center),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                                  child: Text('Suhu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.orangeAccent), textAlign: TextAlign.center),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                                  child: Text('Lembab', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.blueAccent), textAlign: TextAlign.center),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                                  child: Text('CO2', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF14B8A6)), textAlign: TextAlign.center),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                                  child: Text('CO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.purpleAccent), textAlign: TextAlign.center),
                                ),
                              ],
                            ),
                            // Row data (Dari yang terbaru di paling atas)
                            ...paginatedData.map((data) {
                              Color? rowColor;
                              if (data.co2 > 1500 || data.co > 100 || data.temperature > 40.0) {
                                rowColor = const Color(0xFFB91C1C).withValues(alpha: 0.12); // Hazardous
                              } else if (data.co2 > 1000 || data.co > 80 || data.temperature > 37.0) {
                                rowColor = const Color(0xFFEF4444).withValues(alpha: 0.08); // Very Unhealthy
                              } else if (data.co2 > 700 || data.co > 40 || data.temperature > 35.0) {
                                rowColor = const Color(0xFFF59E0B).withValues(alpha: 0.06); // Unhealthy
                              } else if (data.co2 > 500 || data.co > 15 || data.temperature > 33.0) {
                                rowColor = const Color(0xFF06B6D4).withValues(alpha: 0.04); // Moderate
                              }

                              return TableRow(
                                decoration: rowColor != null
                                    ? BoxDecoration(color: rowColor)
                                    : null,
                                children: [
                                  // Waktu
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
                                    child: Text(
                                      DateFormat('HH:mm:ss').format(data.timestamp),
                                      style: const TextStyle(fontSize: 10, color: Colors.white70),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  // Suhu
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
                                    child: Text(
                                      '${data.temperature}°C',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: data.temperature > 38.0 ? Colors.redAccent : data.temperature > 34.0 ? Colors.orangeAccent : Colors.white70,
                                        fontWeight: data.temperature > 34.0 ? FontWeight.bold : FontWeight.normal,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  // Lembab
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
                                    child: Text(
                                      '${data.humidity}%',
                                      style: const TextStyle(fontSize: 10, color: Colors.white70),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  // CO2
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
                                    child: Text(
                                      '${data.co2}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: data.co2 > 1000 ? Colors.redAccent : data.co2 > 700 ? Colors.orangeAccent : Colors.white70,
                                        fontWeight: data.co2 > 700 ? FontWeight.bold : FontWeight.normal,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  // CO
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
                                    child: Text(
                                      '${data.co}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: data.co > 100 ? Colors.redAccent : data.co > 40 ? Colors.orangeAccent : Colors.white70,
                                        fontWeight: data.co > 40 ? FontWeight.bold : FontWeight.normal,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFF334155)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Tombol Baru (Kiri)
                            TextButton(
                              onPressed: activePageIndex > 0
                                  ? () {
                                      setState(() {
                                        _tablePageIndex = activePageIndex - 1;
                                      });
                                    }
                                  : null,
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.tealAccent,
                                disabledForegroundColor: Colors.white24,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.chevron_left, size: 20),
                                  SizedBox(width: 2),
                                  Text('Baru', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            // Info Halaman
                            Text(
                              totalItems == 0
                                  ? '0-0 dari 0 data'
                                  : '${startIndex + 1}-$endIndex dari $totalItems data',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            // Tombol Lama (Kanan)
                            TextButton(
                              onPressed: endIndex < totalItems
                                  ? () {
                                      setState(() {
                                        _tablePageIndex = activePageIndex + 1;
                                      });
                                    }
                                  : null,
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.tealAccent,
                                disabledForegroundColor: Colors.white24,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Lama', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  SizedBox(width: 2),
                                  Icon(Icons.chevron_right, size: 20),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInteractiveTabCard(int index, String label, String value, IconData icon, Color activeColor) {
    bool isSelected = _selectedSensorIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedSensorIndex = index;
          });
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withValues(alpha: 0.12) : const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? activeColor : const Color(0xFF334155),
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: isSelected
                ? [BoxShadow(color: activeColor.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2))]
                : [],
          ),
          child: Row(
            children: [
              Icon(icon, color: isSelected ? activeColor : Colors.grey[400], size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? activeColor : Colors.grey[400]
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatValue(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
