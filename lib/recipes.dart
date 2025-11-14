import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Recipe {
  final String title;
  final List<String> ingredients;
  final List<String> tags; // e.g. 'halal','vegan','quick','healthy'
  final int minutes;

  Recipe({required this.title, required this.ingredients, required this.tags, required this.minutes});
}

final List<Recipe> _mockRecipes = [
  Recipe(title: 'Tomaat-pasta', ingredients: ['Pasta', 'Tomaat', 'Olijfolie'], tags: ['vegetarian', 'quick'], minutes: 10),
  Recipe(title: 'Kikkererwt curry', ingredients: ['Kikkererwt', 'Kokosmelk', 'Ui'], tags: ['vegan', 'halal', 'healthy'], minutes: 25),
  Recipe(title: 'Snel omelet', ingredients: ['Ei', 'Melk', 'Kruiden'], tags: ['quick'], minutes: 5),
  Recipe(title: 'Gegrilde kip salade', ingredients: ['Kip', 'Sla', 'Tomaat'], tags: ['halal', 'healthy'], minutes: 15),
  Recipe(title: 'Vegan smoothie', ingredients: ['Banaan', 'Spinazie', 'Amandelmelk'], tags: ['vegan', 'quick', 'healthy'], minutes: 5),
];

class RecipesPage extends StatefulWidget {
  const RecipesPage({super.key});

  @override
  State<RecipesPage> createState() => _RecipesPageState();
}

class _RecipesPageState extends State<RecipesPage> {
  List<String> _ingredients = [];
  List<Recipe> _results = [];

  // Filters
  bool _filterHalal = false;
  bool _filterVegan = false;
  bool _filterQuick = false; // <10 min
  bool _filterHealthy = false;

  @override
  void initState() {
    super.initState();
    _loadIngredients();
  }

  Future<void> _loadIngredients() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('ingredients') ?? <String>[];
    setState(() {
      _ingredients = list.map((s) => s.toLowerCase()).toList();
    });
    _computeResults();
  }

  void _computeResults() {
    final results = <Recipe>[];
    for (final r in _mockRecipes) {
      final req = r.ingredients.map((s) => s.toLowerCase()).toList();
      final matched = req.where((i) => _ingredients.contains(i)).length;
      final score = matched; // simple metric: more matching ingredients -> better

      // apply tag filters
      if (_filterHalal && !r.tags.contains('halal')) continue;
      if (_filterVegan && !r.tags.contains('vegan')) continue;
      if (_filterQuick && r.minutes >= 10) continue;
      if (_filterHealthy && !r.tags.contains('healthy')) continue;

      if (score > 0) results.add(r);
    }

    // sort by number of matched ingredients (desc) then time
    results.sort((a, b) {
      final aMatch = a.ingredients.map((s) => s.toLowerCase()).where((i) => _ingredients.contains(i)).length;
      final bMatch = b.ingredients.map((s) => s.toLowerCase()).where((i) => _ingredients.contains(i)).length;
      final cmp = bMatch.compareTo(aMatch);
      if (cmp != 0) return cmp;
      return a.minutes.compareTo(b.minutes);
    });

    setState(() => _results = results);
  }

  Widget _chip(String label, bool value, void Function(bool?) onChanged) {
    return FilterChip(
      label: Text(label),
      selected: value,
      onSelected: (v) {
        onChanged(v);
        _computeResults();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receptsuggesties'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(spacing: 8, children: [
              _chip('Halal', _filterHalal, (v) => setState(() => _filterHalal = v ?? false)),
              _chip('Vegan', _filterVegan, (v) => setState(() => _filterVegan = v ?? false)),
              _chip('Snel (<10m)', _filterQuick, (v) => setState(() => _filterQuick = v ?? false)),
              _chip('Gezond', _filterHealthy, (v) => setState(() => _filterHealthy = v ?? false)),
            ]),
            const SizedBox(height: 12),
            Text('Jouw voorraad: ${_ingredients.isEmpty ? 'leeg' : _ingredients.join(', ')}'),
            const SizedBox(height: 12),
            Expanded(
              child: _results.isEmpty
                  ? const Center(child: Text('Geen suggesties gevonden. Voeg meer ingrediënten toe.'))
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final r = _results[index];
                        return Card(
                          child: ListTile(
                            title: Text(r.title),
                            subtitle: Text('${r.ingredients.join(', ')} • ${r.minutes} min'),
                            trailing: Wrap(spacing: 6, children: r.tags.map((t) => Chip(label: Text(t))).toList()),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
