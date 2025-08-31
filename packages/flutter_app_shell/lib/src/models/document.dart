/// Generic document model for NoSQL database operations
class Document {
  int? id;

  /// Document type/collection name
  late String type;

  /// JSON data as string
  late String data;

  /// Creation timestamp
  late DateTime createdAt;

  /// Last updated timestamp
  late DateTime updatedAt;

  /// Soft delete flag
  bool isDeleted = false;

  /// Version for optimistic locking
  int version = 1;

  /// Tags for querying and organization
  List<String> tags = [];

  Document();

  Document.create({
    required this.type,
    required this.data,
    this.tags = const [],
  }) {
    createdAt = DateTime.now();
    updatedAt = DateTime.now();
    isDeleted = false;
    version = 1;
  }

  /// Create a copy with updated data
  Document copyWith({
    String? type,
    String? data,
    List<String>? tags,
    bool? isDeleted,
    int? version,
  }) {
    final doc = Document();
    doc.id = id;
    doc.type = type ?? this.type;
    doc.data = data ?? this.data;
    doc.tags = tags ?? this.tags;
    doc.createdAt = createdAt;
    doc.updatedAt = DateTime.now();
    doc.isDeleted = isDeleted ?? this.isDeleted;
    doc.version = version ?? this.version;
    return doc;
  }

  /// Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isDeleted': isDeleted,
      'version': version,
      'tags': tags,
    };
  }

  /// Create from Map retrieved from database
  factory Document.fromMap(Map<String, dynamic> map) {
    final doc = Document();
    doc.id = map['id'];
    doc.type = map['type'];
    doc.data = map['data'];
    doc.createdAt = DateTime.parse(map['createdAt']);
    doc.updatedAt = DateTime.parse(map['updatedAt']);
    doc.isDeleted = map['isDeleted'] ?? false;
    doc.version = map['version'] ?? 1;
    doc.tags = List<String>.from(map['tags'] ?? []);
    return doc;
  }
}
