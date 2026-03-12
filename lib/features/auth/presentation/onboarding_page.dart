import 'package:flutter/material.dart';
import 'package:servis_kontrol/core/theme/app_palette.dart';
import 'package:servis_kontrol/features/auth/application/auth_controller.dart';
import 'package:servis_kontrol/features/auth/domain/app_user.dart';
import 'package:servis_kontrol/features/auth/domain/user_role.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({
    super.key,
    required this.user,
    required this.controller,
    required this.onLogout,
  });

  final AppUser user;
  final AuthController controller;
  final Future<void> Function() onLogout;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pageController = PageController();
  late final TextEditingController _fullNameController;
  late final TextEditingController _departmentController;
  late final TextEditingController _jobTitleController;
  late String _workPreference;
  late Set<NotificationChannel> _channels;
  late bool _wantsQuickTour;
  int _step = 0;
  String? _message;

  @override
  void initState() {
    super.initState();
    final profile = OnboardingProfile.fromUser(widget.user);
    _fullNameController = TextEditingController(text: profile.fullName);
    _departmentController = TextEditingController(text: profile.department);
    _jobTitleController = TextEditingController(text: profile.jobTitle);
    _workPreference = profile.workPreference;
    _channels = {...profile.notificationChannels};
    _wantsQuickTour = profile.wantsQuickTour;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fullNameController.dispose();
    _departmentController.dispose();
    _jobTitleController.dispose();
    super.dispose();
  }

  void _goToStep(int value) {
    setState(() => _step = value);
    _pageController.animateToPage(
      value,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  Future<void> _nextStep() async {
    if (_step < 3) {
      _goToStep(_step + 1);
      return;
    }

    final result = await widget.controller.completeOnboarding(
      OnboardingProfile(
        fullName: _fullNameController.text.trim(),
        department: _departmentController.text.trim(),
        jobTitle: _jobTitleController.text.trim(),
        workPreference: _workPreference,
        notificationChannels: _channels,
        wantsQuickTour: _wantsQuickTour,
      ),
    );

    if (!mounted) {
      return;
    }

    if (!result.isSuccess) {
      setState(() => _message = result.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7F9FC), Color(0xFFEAF0FA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 1000;
              return Row(
                children: [
                  if (wide) _OnboardingRail(step: _step, user: widget.user),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(wide ? 28 : 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'İlk giriş kurulumu',
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    color: AppPalette.text,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 28,
                                  ),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: widget.onLogout,
                                icon: const Icon(Icons.logout_rounded),
                                label: const Text('Çıkış Yap'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: (_step + 1) / 4,
                              minHeight: 10,
                              backgroundColor: AppPalette.primarySoft,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppPalette.primary,
                              ),
                            ),
                          ),
                          if (_message != null) ...[
                            const SizedBox(height: 18),
                            Text(
                              _message!,
                              style: const TextStyle(
                                color: AppPalette.danger,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),
                          Expanded(
                            child: PageView(
                              controller: _pageController,
                              physics: const NeverScrollableScrollPhysics(),
                              children: [
                                _OnboardingCard(
                                  title: '1. Profil tamamlama',
                                  subtitle: 'Ad, departman ve unvan bilgilerini güncelle.',
                                  child: Column(
                                    children: [
                                      TextField(
                                        controller: _fullNameController,
                                        decoration: const InputDecoration(labelText: 'Ad Soyad'),
                                      ),
                                      const SizedBox(height: 14),
                                      TextField(
                                        controller: _departmentController,
                                        decoration: const InputDecoration(labelText: 'Departman'),
                                      ),
                                      const SizedBox(height: 14),
                                      TextField(
                                        controller: _jobTitleController,
                                        decoration: const InputDecoration(labelText: 'Pozisyon'),
                                      ),
                                    ],
                                  ),
                                ),
                                _OnboardingCard(
                                  title: '2. Çalışma tercihi',
                                  subtitle: 'Rolüne uygun çalışma modelini seç.',
                                  child: Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: [
                                      for (final option in const [
                                        'Saha odaklı',
                                        'Saha + ofis hibrit',
                                        'Merkez ofis',
                                        'Karma operasyon',
                                      ])
                                        ChoiceChip(
                                          label: Text(option),
                                          selected: _workPreference == option,
                                          onSelected: (_) => setState(
                                            () => _workPreference = option,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                _OnboardingCard(
                                  title: '3. Bildirim kanalları',
                                  subtitle: 'Yeni kullanıcı tercihini kaydet.',
                                  child: Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: [
                                      for (final channel in NotificationChannel.values)
                                        FilterChip(
                                          label: Text(channel.label),
                                          selected: _channels.contains(channel),
                                          onSelected: (selected) {
                                            setState(() {
                                              if (selected) {
                                                _channels.add(channel);
                                              } else {
                                                _channels.remove(channel);
                                              }
                                            });
                                          },
                                        ),
                                    ],
                                  ),
                                ),
                                _OnboardingCard(
                                  title: '4. Son kontrol',
                                  subtitle: 'Kurulumu tamamlamadan önce özeti kontrol et.',
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SwitchListTile(
                                        value: _wantsQuickTour,
                                        onChanged: (value) =>
                                            setState(() => _wantsQuickTour = value),
                                        title: const Text('Hızlı ürün turunu göster'),
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      const SizedBox(height: 12),
                                      _SummaryRow(
                                        label: 'Kullanıcı',
                                        value: _fullNameController.text.trim(),
                                      ),
                                      _SummaryRow(
                                        label: 'Departman',
                                        value: _departmentController.text.trim(),
                                      ),
                                      _SummaryRow(
                                        label: 'Pozisyon',
                                        value: _jobTitleController.text.trim(),
                                      ),
                                      _SummaryRow(
                                        label: 'Çalışma modeli',
                                        value: _workPreference,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              OutlinedButton(
                                onPressed: _step == 0
                                    ? null
                                    : () => _goToStep(_step - 1),
                                child: const Text('Geri'),
                              ),
                              const Spacer(),
                              FilledButton.icon(
                                onPressed: widget.controller.busy ? null : _nextStep,
                                icon: Icon(
                                  _step == 3
                                      ? Icons.check_rounded
                                      : Icons.arrow_forward_rounded,
                                ),
                                label: Text(
                                  widget.controller.busy
                                      ? 'Kaydediliyor...'
                                      : (_step == 3 ? 'Panele Geç' : 'Devam Et'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _OnboardingRail extends StatelessWidget {
  const _OnboardingRail({required this.step, required this.user});

  final int step;
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    const labels = ['Profil', 'Tercihler', 'Bildirim', 'Onay'];

    return Container(
      width: 320,
      padding: const EdgeInsets.all(28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppPalette.sidebar, AppPalette.sidebarSoft],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppPalette.primarySoft,
            child: Text(
              user.initials,
              style: const TextStyle(
                color: AppPalette.primary,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            user.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${user.role.label} • ${user.email}',
            style: const TextStyle(color: Color(0xB7FFFFFF)),
          ),
          const SizedBox(height: 24),
          for (var index = 0; index < labels.length; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: index <= step
                        ? AppPalette.primary
                        : Colors.white12,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    labels[index],
                    style: TextStyle(
                      color: index == step
                          ? Colors.white
                          : const Color(0xB7FFFFFF),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _OnboardingCard extends StatelessWidget {
  const _OnboardingCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppPalette.border),
        boxShadow: const [
          BoxShadow(
            color: AppPalette.shadow,
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppPalette.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: AppPalette.muted, height: 1.5),
          ),
          const SizedBox(height: 24),
          Expanded(child: SingleChildScrollView(child: child)),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: AppPalette.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                color: AppPalette.text,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
