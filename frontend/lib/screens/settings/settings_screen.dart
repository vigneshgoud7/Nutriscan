import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;

  Widget _tile(BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    VoidCallback? onTap,
    Widget? trailing,
  }) =>
      ListTile(
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: (iconColor ?? AppTheme.primary).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor ?? AppTheme.primary, size: 20),
        ),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: subtitle != null ? Text(subtitle, style: Theme.of(context).textTheme.bodyMedium) : null,
        trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right_rounded, color: AppTheme.onSurfaceMuted) : null),
        onTap: onTap,
      );

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primary.withOpacity(0.15), AppTheme.primary.withOpacity(0.05)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
            ),
            child: Row(children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.primary.withOpacity(0.2),
                child: Text(
                  (auth.userName ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(color: AppTheme.primary, fontSize: 22, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(auth.userName ?? 'User', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: auth.plan == 'premium' ? AppTheme.warning.withOpacity(0.15) : AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    auth.plan == 'premium' ? '⭐ Premium' : 'Free Plan',
                    style: TextStyle(
                      color: auth.plan == 'premium' ? AppTheme.warning : AppTheme.primary,
                      fontSize: 12, fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ])),
            ]),
          ),

          const SizedBox(height: 24),

          // Health profile summary
          profileAsync.when(
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
            data: (profile) => profile != null && !profile.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        const Icon(Icons.monitor_heart_outlined, color: AppTheme.primary, size: 18),
                        const SizedBox(width: 8),
                        Text('Health Profile', style: Theme.of(context).textTheme.titleMedium),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => context.push('/onboarding/profile'),
                          child: const Text('Edit', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        if (profile.age != null) _infoChip(context, '${profile.age} yrs'),
                        if (profile.sex != null) _infoChip(context, profile.sex!),
                        if (profile.goal != null) _infoChip(context, profile.goal!.replaceAll('_', ' ')),
                        for (final d in profile.diseases) _infoChip(context, d, color: AppTheme.warning),
                        for (final a in profile.allergies) _infoChip(context, a, color: AppTheme.danger),
                      ]),
                    ]),
                  )
                : ListTile(
                    leading: Container(width: 40, height: 40,
                      decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.person_outline, color: AppTheme.primary, size: 20)),
                    title: const Text('Set up Health Profile'),
                    subtitle: const Text('Get personalized nutrition advice'),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.onSurfaceMuted),
                    onTap: () => context.push('/onboarding/profile'),
                  ),
          ),

          const SizedBox(height: 16),

          if (auth.plan != 'premium')
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7B2FF7), Color(0xFF3A86FF)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Upgrade to Premium', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 4),
                const Text('500 analyses/day · Priority AI · No limits', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white, foregroundColor: const Color(0xFF7B2FF7),
                    minimumSize: const Size(double.infinity, 44),
                  ),
                  child: const Text('Upgrade Now'),
                ),
              ]),
            ),

          Container(
            decoration: BoxDecoration(color: AppTheme.surfaceCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border)),
            child: Column(children: [
              _tile(context, icon: Icons.person_outline, title: 'Edit Health Profile', onTap: () => context.push('/onboarding/profile')),
              Divider(height: 1, color: AppTheme.border),
              _tile(context, icon: Icons.notifications_outlined, title: 'Notifications', trailing: Switch(
                value: _notificationsEnabled, 
                onChanged: (val) {
                  setState(() {
                    _notificationsEnabled = val;
                  });
                }, 
                activeColor: AppTheme.primary
              )),
              Divider(height: 1, color: AppTheme.border),
              _tile(context, icon: Icons.info_outlined, title: 'About NutriScan', subtitle: 'Version 1.0.0', onTap: () {}),
              Divider(height: 1, color: AppTheme.border),
              _tile(
                context,
                icon: Icons.logout_rounded,
                iconColor: AppTheme.danger,
                title: 'Sign Out',
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      backgroundColor: AppTheme.surfaceCard,
                      title: const Text('Sign Out'),
                      content: const Text('Are you sure you want to sign out?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Sign Out', style: TextStyle(color: AppTheme.danger))),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await ref.read(authProvider.notifier).signOut();
                    ref.invalidate(profileProvider);
                    ref.invalidate(chatProvider);
                    ref.invalidate(historyProvider);
                    if (context.mounted) context.go('/signin');
                  }
                },
              ),
            ]),
          ),

          const SizedBox(height: 32),
          Center(child: Text('NutriScan AI © 2025', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12))),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _infoChip(BuildContext context, String label, {Color? color}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: (color ?? AppTheme.primary).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: TextStyle(color: color ?? AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w500)),
      );
}
