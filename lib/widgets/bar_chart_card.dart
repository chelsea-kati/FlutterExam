// lib/widgets/bar_chart_card.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/metric_card.dart';

// Définition des couleurs (assurez-vous qu'elles correspondent à vos AppColors)
const Color primaryColor = Colors.blue;
const Color accentColor = Colors.orange;

class BarChartCard extends StatelessWidget {
  final String labelKey; // 'maladie' ou 'pays'
  final List<Map<String, dynamic>> data;

  const BarChartCard({super.key, required this.labelKey, required this.data});

  @override
  Widget build(BuildContext context) {
    // Prendre les 5 premières entrées pour le graphique
    final chartData = data.take(5).toList();

    // Convertir les données de la base de données au format de fl_chart
    List<BarChartGroupData> barGroups = [];
    List<String> labels = [];

    for (int i = 0; i < chartData.length; i++) {
      final item = chartData[i];
      final label = item[labelKey].toString().split(
        ' ',
      )[0]; // Prendre le premier mot si trop long
      final count = item['count'] as int;
      labels.add(label);

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: count.toDouble(),
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
          child: BarChart(
            BarChartData(
              barGroups: barGroups,
              alignment: BarChartAlignment.spaceAround,
              maxY: chartData.isNotEmpty
                  ? (chartData.first['count'] as int) * 1.2
                  : 10, // Max Y un peu plus grand que le max
              titlesData: FlTitlesData(
                show: true,
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                // Libellés sur l'axe X (en bas)
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
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      }
                      return const Text('');
                    },
                    reservedSize: 30,
                  ),
                ),
                // Libellés sur l'axe Y (gauche)
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
              gridData: const FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 1,
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              // Optionnel : Ajouter un touch event
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${labels[groupIndex]} : ${rod.toY.toInt()}',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
