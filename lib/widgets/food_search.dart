import 'dart:async';
import 'package:flutter/material.dart';

import '../models/food_item.dart';
import '../services/enhanced_api_service.dart';
import 'package:diet_planner_app/services/api_config.dart';
import '../services/food_database_service.dart';

class FoodSearch extends StatefulWidget {
  final void Function(FoodItem) onAdd;

  const FoodSearch({super.key, required this.onAdd});

  @override
  State<FoodSearch> createState() => _FoodSearchState();
}

class _FoodSearchState extends State<FoodSearch> {
  final _api = EnhancedApiService.instance;
  final _db = FoodDatabaseService.instance;
  final _controller = TextEditingController();
  List<FoodItem> _results = [];
  List<FoodItem> _cachedResults = [];
  String _lastSearchQuery = '';
  bool _loading = false;
  String? _apiSource;
  Timer? _debounceTimer;
  String? _errorMessage;

  void _onSearchChanged(String query) {
    // Cancel previous timer
    _debounceTimer?.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _cachedResults = [];
        _lastSearchQuery = '';
        _errorMessage = null;
        _apiSource = null;
      });
      return;
    }

    // For very short queries, show nothing yet
    if (query.trim().length < 2) {
      setState(() {
        _results = [];
        _errorMessage = 'Please enter at least 2 characters';
        _loading = false;
      });
      return;
    }

    // Reduced debounce timer for faster response (300ms instead of 500ms)
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _search(query);
    });
  }

  Future<void> _search(String q) async {
    final trimmedQuery = q.trim();
    if (trimmedQuery.isEmpty) return;

    // Validate query length
    if (trimmedQuery.length < 2) {
      setState(() {
        _errorMessage = 'Please enter at least 2 characters';
        _results = [];
        _loading = false;
      });
      return;
    }

    // Check cache - if search is similar to last query, filter locally
    if (_lastSearchQuery.isNotEmpty &&
        trimmedQuery.toLowerCase().contains(_lastSearchQuery.toLowerCase()) &&
        _cachedResults.isNotEmpty) {
      // Local filtering for faster results
      final filtered = _cachedResults.where((food) {
        return food.name.toLowerCase().contains(trimmedQuery.toLowerCase());
      }).toList();

      setState(() {
        _results = filtered;
        _loading = false;
        _errorMessage = filtered.isEmpty
            ? 'No foods found for "$trimmedQuery"'
            : null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _results = [];
      _apiSource = null;
      _errorMessage = null;
    });

    try {
      // Use smart search that tries multiple APIs
      final res = await _api.smartFoodSearch(
        trimmedQuery,
        calorieNinjasKey: ApiConfig.calorieNinjasApiKey,
      );

      if (!mounted) return;

      setState(() {
        _results = res;
        _cachedResults = res; // Cache results
        _lastSearchQuery = trimmedQuery; // Remember query
        _loading = false;
        _errorMessage = res.isEmpty
            ? 'No foods found for "$trimmedQuery"'
            : null;
        if (res.isNotEmpty) {
          // Detect which API was used based on ID prefix
          if (res.first.id.startsWith('off_')) {
            _apiSource = 'OpenFoodFacts';
          } else if (res.first.id.startsWith('cn_')) {
            _apiSource = 'CalorieNinjas';
          }
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _results = [];
        _loading = false;
        _apiSource = null;
        _errorMessage =
            'Search failed. Please check your connection and try again.';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Search error: ${e.toString()}')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Info banner for web users
        if (_results.isEmpty && !_loading && _controller.text.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF14B8A6).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF14B8A6).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Color(0xFF14B8A6),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Search 2.8M+ foods from OpenFoodFacts database',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color.fromRGBO(0, 0, 0, 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: 'Search foods...',
                    prefixIcon: Icon(Icons.search),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  onChanged: _onSearchChanged,
                  onSubmitted: _search,
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _controller.clear();
                          _debounceTimer?.cancel();
                          setState(() {
                            _results.clear();
                            _errorMessage = null;
                            _apiSource = null;
                          });
                        },
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ElevatedButton(
                  onPressed: () => _search(_controller.text),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Search'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_apiSource != null &&
            ApiConfig.showApiSource &&
            _results.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 14,
                  color: const Color(0xFF06D6A0),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Found ${_results.length} matching items from $_apiSource',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (_loading)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Searching for "${_controller.text.trim()}"...',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
        if (!_loading && _errorMessage != null && _results.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Try a different search term',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _results.isEmpty
              ? const SizedBox.shrink()
              : ListView.builder(
                  key: ValueKey(_results.length), // Optimize rebuilds
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _results.length,
                  itemBuilder: (context, i) {
                    final f = _results[i];
                    return Container(
                      key: ValueKey(f.id), // Stable key for each item
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromRGBO(0, 0, 0, 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        title: Text(
                          f.name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.local_fire_department,
                                  size: 14,
                                  color: Colors.orange[700],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${f.calories.toStringAsFixed(0)} kcal',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.scale,
                                  size: 14,
                                  color: Colors.blue[700],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${f.servingSizeGrams.toStringAsFixed(0)}g',
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'P: ${f.protein.toStringAsFixed(1)}g · '
                              'C: ${f.carbs.toStringAsFixed(1)}g · '
                              'F: ${f.fat.toStringAsFixed(1)}g',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton.filledTonal(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            final loggedAt = DateTime.now();
                            final itemToLog = f; // Capture the item

                            // Log to database first
                            _db.logFood(loggedAt, itemToLog);

                            // Notify parent to refresh UI
                            widget.onAdd(itemToLog);

                            // Show success feedback
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Added ${itemToLog.name} to today\'s log',
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: const Color(0xFF06D6A0),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                duration: const Duration(seconds: 3),
                                action: SnackBarAction(
                                  label: 'UNDO',
                                  textColor: Colors.white,
                                  onPressed: () {
                                    final removed = _db.removeLoggedFood(
                                      loggedAt,
                                      itemToLog,
                                    );
                                    if (removed) {
                                      // Notify parent to refresh UI after undo
                                      widget.onAdd(itemToLog);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Row(
                                            children: [
                                              const Icon(
                                                Icons.undo,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  'Removed ${itemToLog.name}',
                                                ),
                                              ),
                                            ],
                                          ),
                                          backgroundColor: Colors.orange,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
