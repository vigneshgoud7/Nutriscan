import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';

class HealthProfileScreen extends ConsumerStatefulWidget {
  const HealthProfileScreen({super.key});
  @override
  ConsumerState<HealthProfileScreen> createState() => _HealthProfileScreenState();
}

class _HealthProfileScreenState extends ConsumerState<HealthProfileScreen> {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;

  // Form state
  String? _sex;
  final _ageCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  String? _goal;
  final List<String> _diseases = [];
  final List<String> _allergies = [];
  String? _dietType;
  bool _saving = false;

  static const _goalOptions = [
    ('weight_loss', 'Weight Loss', Icons.trending_down_rounded),
    ('muscle_gain', 'Muscle Gain', Icons.fitness_center_rounded),
    ('maintenance', 'Maintenance', Icons.balance_rounded),
    ('manage_condition', 'Manage Condition', Icons.monitor_heart_rounded),
  ];

  static const _diseaseOptions = [
    'Type 2 Diabetes', 'Hypertension', 'High Cholesterol',
    'Heart Disease', 'PCOS', 'Thyroid', 'Kidney Disease', 'Celiac Disease',
  ];

  static const _allergyOptions = [
    'Gluten', 'Dairy/Lactose', 'Nuts', 'Peanuts',
    'Eggs', 'Soy', 'Shellfish', 'Fish',
  ];

  static const _dietOptions = [
    ('none', 'No preference'),
    ('vegetarian', 'Vegetarian'),
    ('vegan', 'Vegan'),
    ('keto', 'Keto'),
    ('paleo', 'Paleo'),
    ('mediterranean', 'Mediterranean'),
  ];

  Future<void> _save() async {
    setState(() => _saving = true);
    final profile = HealthProfile(
      age: int.tryParse(_ageCtrl.text),
      sex: _sex,
      weightKg: double.tryParse(_weightCtrl.text),
      heightCm: double.tryParse(_heightCtrl.text),
      goal: _goal,
      diseases: _diseases,
      allergies: _allergies,
      dietType: _dietType,
    );
    final success = await ref.read(profileProvider.notifier).save(profile);
    if (success) {
      ref.read(authProvider.notifier).clearNewUserFlag();
      if (mounted) context.go('/home');
    } else {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildChip(String label, bool selected, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primary.withOpacity(0.15) : AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? AppTheme.primary : AppTheme.border, width: selected ? 1.5 : 1),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppTheme.primary : AppTheme.onSurfaceMuted,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              fontSize: 14,
            ),
          ),
        ),
      );

  Widget _page1BasicInfo() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Basic information', style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 8),
          Text("This helps us personalize your nutrition advice", style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 32),
          Text('Sex', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Row(children: [
            for (final s in ['Male', 'Female', 'Other']) ...[
              Expanded(child: _buildChip(s, _sex == s.toLowerCase(), () => setState(() => _sex = s.toLowerCase()))),
              if (s != 'Other') const SizedBox(width: 10),
            ],
          ]),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: TextFormField(
              controller: _ageCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Age', suffixText: 'yrs'),
            )),
            const SizedBox(width: 16),
            Expanded(child: TextFormField(
              controller: _weightCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Weight', suffixText: 'kg'),
            )),
          ]),
          const SizedBox(height: 16),
          TextFormField(
            controller: _heightCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Height', suffixText: 'cm'),
          ),
        ],
      );

  Widget _page2GoalDiet() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your goal', style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 8),
          Text("What are you working towards?", style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),
          ...(_goalOptions.map((opt) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () => setState(() => _goal = opt.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _goal == opt.$1 ? AppTheme.primary.withOpacity(0.12) : AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _goal == opt.$1 ? AppTheme.primary : AppTheme.border, width: _goal == opt.$1 ? 1.5 : 1),
                    ),
                    child: Row(children: [
                      Icon(opt.$3, color: _goal == opt.$1 ? AppTheme.primary : AppTheme.onSurfaceMuted, size: 24),
                      const SizedBox(width: 14),
                      Text(opt.$2, style: TextStyle(
                        color: _goal == opt.$1 ? AppTheme.primary : AppTheme.onSurface,
                        fontWeight: FontWeight.w500, fontSize: 15,
                      )),
                      const Spacer(),
                      if (_goal == opt.$1) const Icon(Icons.check_circle, color: AppTheme.primary, size: 20),
                    ]),
                  ),
                ),
              ))),
          const SizedBox(height: 24),
          Text('Diet preference', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(spacing: 10, runSpacing: 10, children: [
            for (final d in _dietOptions)
              _buildChip(d.$2, _dietType == d.$1, () => setState(() => _dietType = d.$1)),
          ]),
        ],
      );

  Widget _page3Health() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Health conditions', style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 8),
          Text("Select any conditions you have (optional)", style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),
          Wrap(spacing: 10, runSpacing: 10, children: [
            for (final d in _diseaseOptions)
              _buildChip(d, _diseases.contains(d), () => setState(() {
                _diseases.contains(d) ? _diseases.remove(d) : _diseases.add(d);
              })),
          ]),
          const SizedBox(height: 32),
          Text('Allergies & intolerances', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text("We will always warn you if a product contains these", style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          Wrap(spacing: 10, runSpacing: 10, children: [
            for (final a in _allergyOptions)
              _buildChip(a, _allergies.contains(a), () => setState(() {
                _allergies.contains(a) ? _allergies.remove(a) : _allergies.add(a);
              })),
          ]),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final pages = [_page1BasicInfo(), _page2GoalDiet(), _page3Health()];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                children: [
                  if (context.canPop() && !ref.watch(authProvider).isNewUser) ...[
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          for (int i = 0; i < pages.length; i++) ...[
                            Expanded(child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              height: 4,
                              decoration: BoxDecoration(
                                color: i <= _currentPage ? AppTheme.primary : AppTheme.border,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            )),
                            if (i < pages.length - 1) const SizedBox(width: 8),
                          ],
                        ]),
                        const SizedBox(height: 8),
                        Text('Step ${_currentPage + 1} of ${pages.length}', style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: PageView(
              controller: _pageCtrl,
              physics: const NeverScrollableScrollPhysics(),
              children: pages.map((page) => SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: page,
              )).toList(),
            )),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(children: [
                if (_currentPage > 0) ...[
                  Expanded(child: OutlinedButton(
                    onPressed: () {
                      _pageCtrl.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                      setState(() => _currentPage--);
                    },
                    child: const Text('Back'),
                  )),
                  const SizedBox(width: 12),
                ],
                Expanded(child: ElevatedButton(
                  onPressed: _saving ? null : () {
                    if (_currentPage < pages.length - 1) {
                      _pageCtrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                      setState(() => _currentPage++);
                    } else {
                      _save();
                    }
                  },
                  child: _saving
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(_currentPage < pages.length - 1 ? 'Continue' : 'Get Started'),
                )),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
