import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'recipes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final seenOnboarding = prefs.getBool('seenOnboarding') ?? false;
  runApp(MyApp(seenOnboarding: seenOnboarding));
}

class IngredientsPage extends StatefulWidget {
  const IngredientsPage({super.key});

  @override
  State<IngredientsPage> createState() => _IngredientsPageState();
}

class _IngredientsPageState extends State<IngredientsPage> {
  final List<String> _ingredients = [];

  @override
  void initState() {
    super.initState();
    _loadIngredients();
  }

  Future<void> _loadIngredients() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('ingredients') ?? <String>[];
    setState(() => _ingredients.addAll(list));
  }

  Future<void> _saveIngredients() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('ingredients', _ingredients);
  }

  Future<void> _addIngredientDialog() async {
    final controller = TextEditingController();
    final res = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nieuw ingrediënt'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Bv. Tomaat'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuleer')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Toevoegen')),
        ],
      ),
    );

    if (res != null && res.isNotEmpty) {
      setState(() => _ingredients.add(res));
      await _saveIngredients();
    }
  }

  Future<void> _removeIngredient(int index) async {
    setState(() => _ingredients.removeAt(index));
    await _saveIngredients();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ILove2Cook — Ingrediënten'),
        actions: [
          IconButton(
            tooltip: 'Receptsuggesties',
            icon: const Icon(Icons.restaurant_menu),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RecipesPage()),
            ),
          ),
        ],
      ),
      body: _ingredients.isEmpty
          ? const Center(child: Text('Geen ingrediënten — tik + om toe te voegen'))
          : ListView.builder(
              itemCount: _ingredients.length,
              itemBuilder: (context, index) {
                final item = _ingredients[index];
                return Dismissible(
                  key: ValueKey(item + index.toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.redAccent,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => _removeIngredient(index),
                  child: ListTile(
                    title: Text(item),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addIngredientDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  final bool seenOnboarding;
  const MyApp({super.key, required this.seenOnboarding});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ILove2Cook',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF7AB6), // pink seed
          primary: const Color(0xFFFF7AB6),
          secondary: const Color(0xFF8EE0A9),
          tertiary: const Color(0xFFFFE082),
        ),
        textTheme: TextTheme(
          headlineSmall: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600),
          bodyMedium: GoogleFonts.inter(fontSize: 14),
        ),
        useMaterial3: true,
      ),
      home: seenOnboarding ? const IngredientsPage() : const OnboardingScreen(),
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;
  double _logoScale = 1.0;

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const IngredientsPage()),
    );
  }

  void _next() {
    if (_page < 2) {
      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _buildPage(
                    title: 'Welkom bij ILove2Cook',
                    subtitle: 'Maak maaltijden met wat je al in huis hebt.',
                    color: theme.colorScheme.primary,
                  ),
                  _buildPage(
                    title: 'Halal & Gezond',
                    subtitle: 'Filter op halal, vegan, snel en gezond.',
                    color: theme.colorScheme.secondary,
                  ),
                  _buildPage(
                    title: 'Community & Premium',
                    subtitle: 'Deel recepten, win badges en upgrade voor extra functies.',
                    color: theme.colorScheme.tertiary,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _completeOnboarding,
                    child: const Text('Sla over'),
                  ),
                  Row(
                    children: List.generate(3, (i) => _indicator(i == _page)),
                  ),
                  ElevatedButton(
                    onPressed: _next,
                    child: Text(_page < 2 ? 'Volgende' : 'Start'),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _indicator(bool active) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: active ? 14 : 8,
        height: 8,
        decoration: BoxDecoration(
          color: active ? Colors.black87 : Colors.black26,
          borderRadius: BorderRadius.circular(8),
        ),
      );

  Widget _buildPage({required String title, required String subtitle, required Color color}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedScale(
            scale: _logoScale,
            duration: const Duration(milliseconds: 400),
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SvgPicture.asset('assets/logo.svg', width: 88, height: 88, semanticsLabel: 'ILove2Cook logo'),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(title, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(subtitle, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

