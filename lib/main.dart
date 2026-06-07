import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:async';

void main() {
  runApp(const AirMonitoringApp());
}

class AirMonitoringApp extends StatelessWidget {
  const AirMonitoringApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LoRa Air Quality Monitor',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      // Menghilangkan banner debug di pojok kanan atas
      debugShowCheckedModeBanner: false,
      home: const DashboardScreen(),
    );
  }
}

// Model data point untuk grafik (menyimpan data historis setiap 10 menit)
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
    List<SensorDataPoint>? dataHistory,
  }) : dataHistory = dataHistory ?? [];
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Mock Data: Simulasi data masuk dari beberapa node LoRa via Gateway
  late List<SensorNode> dummyNodes;

  @override
  void initState() {
    super.initState();
    // Inisialisasi data dengan beberapa data point historis
    final now = DateTime.now();
    dummyNodes = [
      SensorNode(
        id: 'node_01',
        name: 'Area Parkir',
        temperature: 32.5,
        humidity: 60.0,
        co2: 400,
        co: 10,
        status: 'Aman',
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
        status: 'Waspada',
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
        status: 'Bahaya',
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

  // Fungsi untuk menentukan warna border dan chip berdasarkan status udara
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Aman':
        return Colors.green;
      case 'Waspada':
        return Colors.orange;
      case 'Bahaya':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text(
          'Monitoring Udara LoRa',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active),
            onPressed: () {
              // TODO: Tambahkan halaman notifikasi riwayat peringatan gas/suhu
            },
          ),
        ],
      ),
      // Menggunakan ListView.builder agar ringan saat me-render puluhan node
      body: ListView.builder(
        padding: const EdgeInsets.all(12.0),
        itemCount: dummyNodes.length,
        itemBuilder: (context, index) {
          final node = dummyNodes[index];

          return Card(
            elevation: 4,
            margin: const EdgeInsets.only(bottom: 16.0),
            shape: RoundedRectangleBorder(
              // Memberikan border warna sesuai status agar mudah dipantau sekilas
              side: BorderSide(color: _getStatusColor(node.status), width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                // Navigasi ke halaman detail node dengan grafik chart
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SensorDetailScreen(node: node),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Card: Nama Node dan Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: _getStatusColor(node.status),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              node.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Chip(
                          label: Text(
                            node.status,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundColor: _getStatusColor(node.status),
                        ),
                      ],
                    ),
                    const Divider(height: 24, thickness: 1),

                    // Body Card: Nilai Sensor (DHT11, MQ135, MQ9)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSensorIndicator(
                          Icons.thermostat,
                          '${node.temperature}°C',
                          'Suhu',
                        ),
                        _buildSensorIndicator(
                          Icons.water_drop,
                          '${node.humidity}%',
                          'Lembab',
                        ),
                        _buildSensorIndicator(
                          Icons.cloud,
                          '${node.co2}',
                          'CO2 (ppm)',
                        ),
                        _buildSensorIndicator(
                          Icons.warning_amber,
                          '${node.co}',
                          'CO (ppm)',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Widget bantuan agar kode tidak repetitif saat merender nilai sensor
  Widget _buildSensorIndicator(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 28, color: Colors.blueGrey[700]),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

// Halaman Detail Sensor dengan Grafik
class SensorDetailScreen extends StatefulWidget {
  final SensorNode node;

  const SensorDetailScreen({super.key, required this.node});

  @override
  State<SensorDetailScreen> createState() => _SensorDetailScreenState();
}

class _SensorDetailScreenState extends State<SensorDetailScreen> {
  late List<SensorDataPoint> sensorData;
  late Timer _updateTimer;
  int _dataUpdateCounter = 0;

  @override
  void initState() {
    super.initState();
    sensorData = List.from(widget.node.dataHistory);
    
    // Timer untuk update data setiap 10 menit (600 detik)
    // Untuk testing, ubah duration menjadi Duration(seconds: 10) atau lebih pendek
    _updateTimer = Timer.periodic(
      const Duration(minutes: 10), // Ubah ke Duration(seconds: 10) untuk testing cepat
      (_) {
        _addNewDataPoint();
      },
    );
  }

  // Fungsi untuk menambahkan data point baru dengan nilai simulasi
  void _addNewDataPoint() {
    setState(() {
      _dataUpdateCounter++;
      
      // Simulasi data baru dengan variasi kecil dari data terakhir
      final lastData = sensorData.last;
      final newTemperature = lastData.temperature + ((_dataUpdateCounter % 2) == 0 ? 0.5 : -0.3);
      final newHumidity = lastData.humidity + ((_dataUpdateCounter % 2) == 0 ? -1.0 : 1.5);
      final newCo2 = lastData.co2 + (_dataUpdateCounter * 5) % 50;
      final newCo = lastData.co + ((_dataUpdateCounter % 3) * 2) % 10;

      final newDataPoint = SensorDataPoint(
        timestamp: DateTime.now(),
        temperature: newTemperature,
        humidity: newHumidity,
        co2: newCo2,
        co: newCo,
      );

      sensorData.add(newDataPoint);

      // Batasi data history maksimal 48 data point (jika 10 menit = 480 menit = 8 jam)
      if (sensorData.length > 48) {
        sensorData.removeAt(0);
      }

      // Tampilkan notifikasi bahwa data telah diupdate
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Data sensor telah diupdate!'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  @override
  void dispose() {
    _updateTimer.cancel();
    super.dispose();
  }

  // Fungsi untuk menentukan warna berdasarkan status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Aman':
        return Colors.green;
      case 'Waspada':
        return Colors.orange;
      case 'Bahaya':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Fungsi untuk membuat grafik line chart
  LineChartData _buildLineChartData(
    List<double> values,
    Color lineColor,
    double minY,
    double maxY,
  ) {
    final spots = sensorData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), values[entry.key]);
    }).toList();

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: (maxY - minY) / 5,
        verticalInterval: 1,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey[300]!,
            strokeWidth: 0.5,
          );
        },
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: Colors.grey[300]!,
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
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              if (value.toInt() < sensorData.length) {
                final time = sensorData[value.toInt()].timestamp;
                return Text(
                  DateFormat('HH:mm').format(time),
                  style: const TextStyle(fontSize: 10),
                );
              }
              return const Text('');
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toStringAsFixed(1),
                style: const TextStyle(fontSize: 10),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: true),
      minX: 0,
      maxX: (sensorData.length - 1).toDouble(),
      minY: minY,
      maxY: maxY,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: lineColor,
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            color: lineColor.withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final temperatureValues =
        sensorData.map((d) => d.temperature).toList();
    final humidityValues = sensorData.map((d) => d.humidity).toList();
    final co2Values = sensorData.map((d) => d.co2.toDouble()).toList();
    final coValues = sensorData.map((d) => d.co.toDouble()).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(
          widget.node.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: _getStatusColor(widget.node.status),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Status Terakhir',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.node.status,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(widget.node.status),
                          ),
                        ),
                      ],
                    ),
                    Chip(
                      label: Text(
                        'Node ID: ${widget.node.id}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor:
                          _getStatusColor(widget.node.status),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Grafik Suhu (Temperature)
            Text(
              'Grafik Suhu (°C)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  height: 250,
                  child: LineChart(
                    _buildLineChartData(
                      temperatureValues,
                      Colors.red,
                      temperatureValues.reduce((a, b) => a < b ? a : b) - 2,
                      temperatureValues.reduce((a, b) => a > b ? a : b) + 2,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Grafik Kelembaban (Humidity)
            Text(
              'Grafik Kelembaban (%)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  height: 250,
                  child: LineChart(
                    _buildLineChartData(
                      humidityValues,
                      Colors.blue,
                      humidityValues.reduce((a, b) => a < b ? a : b) - 5,
                      humidityValues.reduce((a, b) => a > b ? a : b) + 5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Grafik CO2
            Text(
              'Grafik CO2 (ppm)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  height: 250,
                  child: LineChart(
                    _buildLineChartData(
                      co2Values,
                      Colors.orange,
                      co2Values.reduce((a, b) => a < b ? a : b) - 50,
                      co2Values.reduce((a, b) => a > b ? a : b) + 50,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Grafik CO
            Text(
              'Grafik CO (ppm)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  height: 250,
                  child: LineChart(
                    _buildLineChartData(
                      coValues,
                      Colors.purple,
                      coValues.reduce((a, b) => a < b ? a : b) - 10,
                      coValues.reduce((a, b) => a > b ? a : b) + 10,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Info Waktu Update
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blueGrey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informasi Data',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total Data Point: ${sensorData.length}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    'Data Terbaru: ${DateFormat('dd MMM yyyy HH:mm').format(sensorData.last.timestamp)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    'Rentang Waktu: ${sensorData.length > 1 ? '${(sensorData.last.timestamp.difference(sensorData.first.timestamp).inMinutes)} menit' : 'N/A'}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
