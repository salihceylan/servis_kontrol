class HelpArticle {
  const HelpArticle({
    required this.id,
    required this.title,
    required this.category,
    required this.summary,
  });

  final String id;
  final String title;
  final String category;
  final String summary;

  factory HelpArticle.fromJson(Map<String, dynamic> json) {
    return HelpArticle(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      category: json['category'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
    );
  }
}

class HelpCenterSnapshot {
  const HelpCenterSnapshot({
    required this.contactEmail,
    required this.responseSla,
    required this.articles,
  });

  final String contactEmail;
  final String responseSla;
  final List<HelpArticle> articles;

  factory HelpCenterSnapshot.fromJson(Map<String, dynamic> json) {
    final articles = (json['articles'] as List<dynamic>? ?? const [])
        .map((item) => HelpArticle.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
    return HelpCenterSnapshot(
      contactEmail: json['contact_email'] as String? ?? '',
      responseSla: json['response_sla'] as String? ?? '',
      articles: articles,
    );
  }
}
