import 'package:flutter/material.dart';
import '../services/food_database_service.dart';

/// Debug widget to view current food log state
class DebugFoodLogViewer extends StatelessWidget {
  const DebugFoodLogViewer({super.key});

  @override
  Widget build(BuildContext context) {
    final db = FoodDatabaseService.instance;
    final today = DateTime.now();
    final logged = db.getLoggedFoods(today);

    return IconButton(
      icon: const Icon(Icons.bug_report),
      tooltip: 'Debug: View Food Logs',
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Debug: Food Logs'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Date: ${today.year}-${today.month}-${today.day}'),
                  const SizedBox(height: 8),
                  Text('Total items logged: ${logged.length}'),
                  const Divider(),
                  const SizedBox(height: 8),
                  if (logged.isEmpty)
                    const Text('No foods logged today')
                  else
                    ...logged.map(
                      (food) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              food.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'ID: ${food.id}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              '${food.calories.toStringAsFixed(0)} kcal, '
                              'P: ${food.protein.toStringAsFixed(1)}g',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                            const Divider(),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }
}
