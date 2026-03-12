import 'package:flutter/material.dart';
import 'package:servis_kontrol/core/network/api_client.dart';
import 'package:servis_kontrol/core/presentation/state_panel.dart';
import 'package:servis_kontrol/core/theme/app_palette.dart';
import 'package:servis_kontrol/features/help/application/help_controller.dart';
import 'package:servis_kontrol/features/help/domain/help_center_snapshot.dart';

class HelpCenterPage extends StatefulWidget {
  const HelpCenterPage({
    super.key,
    required this.apiClient,
  });

  final ApiClient apiClient;

  @override
  State<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends State<HelpCenterPage> {
  late final HelpController _controller;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = HelpController(apiClient: widget.apiClient);
    _searchController.addListener(() {
      _controller.updateQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (_controller.isLoading) {
          return const StatePanel.loading(
            title: 'Yardım merkezi yükleniyor',
            message: 'Makale ve destek bağlantıları sunucudan alınıyor.',
          );
        }
        if (_controller.errorMessage != null) {
          return StatePanel.error(
            message: _controller.errorMessage!,
            onRetry: _controller.load,
          );
        }

        final snapshot = _controller.snapshot;
        if (snapshot == null || snapshot.articles.isEmpty) {
          return const StatePanel.empty(
            title: 'Makale bulunamadı',
            message: 'Yardım merkezi için henüz yayınlanmış makale yok.',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Header(
              title: 'Yardım Merkezi',
              subtitle:
                  'Canlı makaleler, destek e-postası ve şirket içi kullanım rehberleri.',
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Makale veya kategori ara...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 18),
            _SupportCard(
              contactEmail: snapshot.contactEmail,
              responseSla: snapshot.responseSla,
            ),
            const SizedBox(height: 18),
            for (final article in snapshot.articles)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ArticleCard(article: article),
              ),
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppPalette.text,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(color: AppPalette.muted, height: 1.5),
        ),
      ],
    );
  }
}

class _SupportCard extends StatelessWidget {
  const _SupportCard({
    required this.contactEmail,
    required this.responseSla,
  });

  final String contactEmail;
  final String responseSla;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppPalette.border),
        boxShadow: const [
          BoxShadow(
            color: AppPalette.shadow,
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Wrap(
        spacing: 14,
        runSpacing: 14,
        children: [
          _SupportInfo(label: 'Destek e-postası', value: contactEmail),
          _SupportInfo(label: 'Yanıt SLA', value: responseSla),
        ],
      ),
    );
  }
}

class _SupportInfo extends StatelessWidget {
  const _SupportInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppPalette.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppPalette.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppPalette.text,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({required this.article});

  final HelpArticle article;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            article.category,
            style: const TextStyle(
              color: AppPalette.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            article.title,
            style: const TextStyle(
              color: AppPalette.text,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            article.summary,
            style: const TextStyle(color: AppPalette.muted, height: 1.5),
          ),
        ],
      ),
    );
  }
}
