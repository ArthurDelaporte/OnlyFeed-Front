// lib/features/admin/presentation/admin_dashboard_page.dart
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:onlyfeed_frontend/shared/shared.dart';
import 'package:onlyfeed_frontend/core/widgets/scaffold_with_menubar.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final _dio = DioClient().dio;
  
  // Filtres
  DateTimeRange? _selectedDateRange;
  String _selectedMetric = 'users'; // users, posts, likes, messages
  bool _isLoading = true;
  String? _error;
  
  // Données
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _evolutionData = [];
  List<Map<String, dynamic>> _distributionData = [];
  List<Map<String, dynamic>> _topUsers = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      await Future.wait([
        _loadStats(),
        _loadEvolutionData(),
        _loadDistributionData(),
        _loadTopUsers(),
      ]);
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _loadStats() async {
    try {
      final Map<String, String> queryParams = {};
      
      if (_selectedDateRange != null) {
        queryParams['start_date'] = DateFormat('yyyy-MM-dd').format(_selectedDateRange!.start);
        queryParams['end_date'] = DateFormat('yyyy-MM-dd').format(_selectedDateRange!.end);
      }

      final response = await _dio.get(
        '/api/admin/stats',
        queryParameters: queryParams,
      );
      
      if (response.statusCode == 200) {
        _stats = response.data['stats'];
      } else {
        throw Exception('Erreur lors du chargement des statistiques');
      }
    } catch (e) {
      throw Exception('Erreur stats: $e');
    }
  }

  Future<void> _loadEvolutionData() async {
    try {
      final Map<String, String> queryParams = {};
      
      if (_selectedDateRange != null) {
        queryParams['start_date'] = DateFormat('yyyy-MM-dd').format(_selectedDateRange!.start);
        queryParams['end_date'] = DateFormat('yyyy-MM-dd').format(_selectedDateRange!.end);
      }

      final response = await _dio.get(
        '/api/admin/charts/evolution',
        queryParameters: queryParams,
      );
      
      if (response.statusCode == 200) {
        _evolutionData = List<Map<String, dynamic>>.from(response.data['data']);
      } else {
        throw Exception('Erreur lors du chargement des données d\'évolution');
      }
    } catch (e) {
      throw Exception('Erreur évolution: $e');
    }
  }

  Future<void> _loadDistributionData() async {
    try {
      final Map<String, String> queryParams = {};
      
      if (_selectedDateRange != null) {
        queryParams['start_date'] = DateFormat('yyyy-MM-dd').format(_selectedDateRange!.start);
        queryParams['end_date'] = DateFormat('yyyy-MM-dd').format(_selectedDateRange!.end);
      }

      final response = await _dio.get(
        '/api/admin/charts/distribution',
        queryParameters: queryParams,
      );
      
      if (response.statusCode == 200) {
        _distributionData = List<Map<String, dynamic>>.from(response.data['data']);
      } else {
        throw Exception('Erreur lors du chargement des données de distribution');
      }
    } catch (e) {
      throw Exception('Erreur distribution: $e');
    }
  }

  Future<void> _loadTopUsers() async {
    try {
      final response = await _dio.get('/api/admin/top-users?limit=5');
      
      if (response.statusCode == 200) {
        _topUsers = List<Map<String, dynamic>>.from(response.data['top_by_posts']);
      } else {
        throw Exception('Erreur lors du chargement du top utilisateurs');
      }
    } catch (e) {
      throw Exception('Erreur top users: $e');
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );
    
    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
      });
      await _initializeData(); // Recharger avec les nouvelles dates
    }
  }

  Widget _buildStatsCards() {
    final stats = [
      {
        'title': 'Utilisateurs', 
        'value': _stats['total_users'] ?? 0, 
        'icon': Icons.people, 
        'color': Colors.blue
      },
      {
        'title': 'Posts', 
        'value': _stats['total_posts'] ?? 0, 
        'icon': Icons.photo, 
        'color': Colors.green
      },
      {
        'title': 'Likes', 
        'value': _stats['total_likes'] ?? 0, 
        'icon': Icons.favorite, 
        'color': Colors.red
      },
      {
        'title': 'Messages', 
        'value': _stats['total_messages'] ?? 0, 
        'icon': Icons.message, 
        'color': Colors.purple
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 768 ? 4 : 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Card(
          elevation: 4,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  stat['icon'] as IconData,
                  size: 32,
                  color: stat['color'] as Color,
                ),
                SizedBox(height: 8),
                Text(
                  '${stat['value']}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: stat['color'] as Color,
                  ),
                ),
                Text(
                  stat['title'] as String,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLineChart() {
    if (_evolutionData.isEmpty) {
      return Card(
        child: Container(
          height: 300,
          child: Center(child: Text('Aucune donnée disponible')),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Évolution quotidienne',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                DropdownButton<String>(
                  value: _selectedMetric,
                  items: [
                    DropdownMenuItem(value: 'users', child: Text('Utilisateurs')),
                    DropdownMenuItem(value: 'posts', child: Text('Posts')),
                    DropdownMenuItem(value: 'likes', child: Text('Likes')),
                    DropdownMenuItem(value: 'messages', child: Text('Messages')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedMetric = value;
                      });
                    }
                  },
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < _evolutionData.length) {
                            final date = DateTime.parse(_evolutionData[value.toInt()]['date']);
                            return Text(
                              DateFormat('dd/MM').format(date),
                              style: TextStyle(fontSize: 10),
                            );
                          }
                          return Text('');
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _evolutionData.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          entry.value[_selectedMetric].toDouble(),
                        );
                      }).toList(),
                      isCurved: true,
                      color: _getMetricColor(_selectedMetric),
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: _getMetricColor(_selectedMetric).withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    if (_distributionData.isEmpty) {
      return Card(
        child: Container(
          height: 300,
          child: Center(child: Text('Aucune donnée disponible')),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Répartition du contenu',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Container(
              height: 300,
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: PieChart(
                      PieChartData(
                        sections: _distributionData.asMap().entries.map((entry) {
                          final data = entry.value;
                          final color = _parseColor(data['color']);
                          return PieChartSectionData(
                            value: data['value'].toDouble(),
                            title: '${data['value']}',
                            color: color,
                            radius: 100,
                            titleStyle: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _distributionData.map((data) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: _parseColor(data['color']),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  data['name'],
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopUsers() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top utilisateurs (par posts)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            ..._topUsers.map((user) {
              return ListTile(
                leading: CircleAvatar(
                  child: Text(user['username'][0].toUpperCase()),
                ),
                title: Text(user['username']),
                trailing: Chip(
                  label: Text('${user['post_count']} posts'),
                  backgroundColor: Colors.blue.withOpacity(0.1),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filtres',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _selectDateRange,
                  icon: Icon(Icons.date_range),
                  label: Text(_selectedDateRange == null 
                    ? 'Sélectionner période' 
                    : '${DateFormat('dd/MM').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM').format(_selectedDateRange!.end)}'
                  ),
                ),
                if (_selectedDateRange != null)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedDateRange = null;
                      });
                      _initializeData();
                    },
                    icon: Icon(Icons.clear),
                    label: Text('Effacer'),
                  ),
                ElevatedButton.icon(
                  onPressed: _initializeData,
                  icon: Icon(Icons.refresh),
                  label: Text('Actualiser'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getMetricColor(String metric) {
    switch (metric) {
      case 'users': return Colors.blue;
      case 'posts': return Colors.green;
      case 'likes': return Colors.red;
      case 'messages': return Colors.purple;
      default: return Colors.blue;
    }
  }

  Color _parseColor(String colorString) {
    // Parse hex color from backend (#3B82F6 -> Color)
    if (colorString.startsWith('#')) {
      return Color(int.parse(colorString.substring(1), radix: 16) + 0xFF000000);
    }
    return Colors.blue; // fallback
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    if (_isLoading) {
      return ScaffoldWithMenubar(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return ScaffoldWithMenubar(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text('Erreur: $_error'),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initializeData,
                child: Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    return ScaffoldWithMenubar(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "admin.dashboard_title".tr(),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 24),

            // Filtres
            _buildFilters(),
            SizedBox(height: 24),

            // Stats rapides
            Text(
              "Statistiques générales",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 16),
            _buildStatsCards(),
            SizedBox(height: 32),

            // Graphiques
            if (isMobile) ...[
              // Version mobile - graphiques empilés
              _buildLineChart(),
              SizedBox(height: 24),
              _buildPieChart(),
              SizedBox(height: 24),
              _buildTopUsers(),
            ] else ...[
              // Version desktop - graphiques côte à côte
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildLineChart(),
                  ),
                  SizedBox(width: 24),
                  Expanded(
                    flex: 1,
                    child: _buildPieChart(),
                  ),
                ],
              ),
              SizedBox(height: 24),
              _buildTopUsers(),
            ],
          ],
        ),
      ),
    );
  }
}