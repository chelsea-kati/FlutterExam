// lib/widgets/bar_chart_card.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

// Définition des couleurs
const Color primaryColor = Color(0xFF6C63FF);
const Color accentColor = Color(0xFFE67E22);

class BarChartCard extends StatelessWidget {
  final String labelKey; // 'maladie' ou 'country'
  final List<Map<String, dynamic>> data;

  const BarChartCard({
    super.key,
    required this.labelKey,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    // Déterminer les clés de valeur en fonction du label
    final bool isCountryData = labelKey == 'country';
    final String valueKey = isCountryData ? 'local_count' : 'count';
    final String secondaryValueKey = 'who_value';

    // Prendre les 5 premières entrées pour le graphique
    final chartData = data.take(5).toList();

    if (chartData.isEmpty) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          height: 250,
          alignment: Alignment.center,
          child: const Text('Aucune donnée disponible'),
        ),
      );
    }

    // Convertir les données au format fl_chart
    List<BarChartGroupData> barGroups = [];
    List<String> labels = [];
    List<int> values = [];
    double maxLocalValue = 0;

    for (int i = 0; i < chartData.length; i++) {
      final item = chartData[i];
      // final label = item[labelKey].toString().split(' ')[0];
      final label = (item[labelKey] as String? ?? 'N/A').split(' ')[0];
      final double count = (item[valueKey] as num?)?.toDouble() ?? 0.0;

      labels.add(label);
      values.add(count.toInt());

      if (count > maxLocalValue) {
        maxLocalValue = count;
      }

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: count,
              color: primaryColor,
              width: 16,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
          ],
        ),
      );
    }

    // Calcul du maxY avec 30% d'espace au-dessus pour les labels
    final double maxY = maxLocalValue > 0 ? maxLocalValue * 1.3 : 10;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.only(
          top: 24,
          right: 24,
          bottom: 12,
          left: 12,
        ),
        child: SizedBox(
          height: 250,
          child: Stack(
            children: [
              // Le graphique à barres
              BarChart(
                BarChartData(
                  barGroups: barGroups,
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  
                  // Configuration des titres
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    // Labels en bas (noms des catégories)
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < labels.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                labels[index],
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: 30,
                      ),
                    ),
                    // Labels à gauche (échelle)
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 35,
                        getTitlesWidget: (value, meta) {
                          if (value == meta.max) return const Text('');
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                  ),
                  
                  // Grille
                  gridData: const FlGridData(
                    show: true,
                    drawVerticalLine: false,
                  ),
                  
                  // Bordures
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  
                  // Interaction tactile avec tooltip
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      // tooltipBgColor: Colors.blueGrey.withOpacity(0.9),
                      getTooltipColor: (BarChartGroupData group) {
                        return Colors.blueGrey.withOpacity(0.9);
                     },
                      tooltipRoundedRadius: 8,
                      tooltipPadding: const EdgeInsets.all(8),
                      tooltipMargin: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        if (groupIndex >= chartData.length) return null;
                        
                        final item = chartData[groupIndex];
                        final String primaryLabel = labels[groupIndex];
                        final int localCount = rod.toY.toInt();
                        
                        final double whoValue = isCountryData && 
                            item.containsKey(secondaryValueKey)
                            ? (item[secondaryValueKey] as num?)?.toDouble() ?? 0.0
                            : 0.0;
                        
                        return BarTooltipItem(
                          '$primaryLabel\n$localCount patient${localCount > 1 ? 's' : ''}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          children: isCountryData && whoValue > 0
                              ? [
                                  const TextSpan(
                                    text: '\nTaux OMS: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.normal,
                                      fontSize: 11,
                                    ),
                                  ),
                                  TextSpan(
                                    text: whoValue.toStringAsFixed(1),
                                    style: const TextStyle(
                                      color: accentColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ]
                              : null,
                        );
                      },
                    ),
                  ),
                ),
              ),
              
              // Labels au-dessus des barres (CustomPainter)
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.only(left: 35, bottom: 30),
                  child: CustomPaint(
                    painter: _BarValuePainter(
                      values: values,
                      barCount: values.length,
                      maxY: maxY,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// CustomPainter pour dessiner les valeurs au-dessus des barres
class _BarValuePainter extends CustomPainter {
  final List<int> values;
  final int barCount;
  final double maxY;

  _BarValuePainter({
    required this.values,
    required this.barCount,
    required this.maxY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || barCount == 0) return;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    final barWidth = size.width / barCount;

    for (int i = 0; i < values.length; i++) {
      final value = values[i];
      if (value == 0) continue;
      
      final barHeight = (value / maxY) * size.height;
      final x = (i + 0.5) * barWidth;
      final y = size.height - barHeight - 18;

      // Créer le texte
      textPainter.text = TextSpan(
        text: value.toString(),
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      );

      textPainter.layout();
      
      // Centrer le texte horizontalement
      final offset = Offset(
        x - (textPainter.width / 2),
        y.clamp(0.0, size.height - textPainter.height),
      );
      
      textPainter.paint(canvas, offset);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}