class AppNotification {
  final int    id;
  final String type;          // new_need | need_status_update | vehicle_match | new_order | tip
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final bool   isRead;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    required this.isRead,
    this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
    id:        j['id']    as int,
    type:      j['type']  as String,
    title:     j['title'] as String,
    body:      j['body']  as String,
    data:      j['data']  as Map<String, dynamic>?,
    isRead:    j['read_at'] != null,
    createdAt: j['created_at'] != null
        ? DateTime.tryParse(j['created_at'] as String)
        : null,
  );

  // ── Labels et icônes ─────────────────────────────────────────────

  static const _icons = {
    'new_need':           0xe91d, // Icons.inbox
    'need_status_update': 0xe875, // Icons.info_outline
    'vehicle_match':      0xe531, // Icons.directions_car
    'new_order':          0xe8cc, // Icons.shopping_bag
    'tip':                0xe90f, // Icons.lightbulb_outline
  };

  static const _colors = {
    'new_need':           0xFF1565C0, // bleu
    'need_status_update': 0xFF2E7D32, // vert
    'vehicle_match':      0xFF6A1B9A, // violet
    'new_order':          0xFFE65100, // orange
    'tip':                0xFFF9A825, // jaune/ambre
  };

  int get iconCode  => _icons[type]  ?? 0xe88e;  // Icons.notifications
  int get iconColor => _colors[type] ?? 0xFF757575;
}
