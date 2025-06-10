class EditAction {
  final String type; // 'crop', 'filter', 'trim', etc.
  final Map<String, dynamic> parameters;
  final DateTime timestamp;

  EditAction({
    required this.type,
    this.parameters = const {},
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'parameters': parameters,
        'timestamp': timestamp.toIso8601String(),
      };

  factory EditAction.fromJson(Map<String, dynamic> json) => EditAction(
        type: json['type'] as String,
        parameters: Map<String, dynamic>.from(json['parameters'] as Map),
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

class Project {
  final String id;
  final String name;
  final String mediaPath;
  final String originalMediaPath; // Keep track of original file
  final bool isVideo;
  final DateTime createdAt;
  final DateTime lastModified;
  final List<EditAction> edits;
  final Map<String, dynamic> metadata; // Additional project metadata

  Project({
    required this.id,
    required this.name,
    required this.mediaPath,
    required this.originalMediaPath,
    required this.isVideo,
    required this.createdAt,
    required this.lastModified,
    this.edits = const [],
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'mediaPath': mediaPath,
        'originalMediaPath': originalMediaPath,
        'isVideo': isVideo,
        'createdAt': createdAt.toIso8601String(),
        'lastModified': lastModified.toIso8601String(),
        'edits': edits.map((e) => e.toJson()).toList(),
        'metadata': metadata,
      };

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id'] as String,
        name: json['name'] as String,
        mediaPath: json['mediaPath'] as String,
        originalMediaPath: json['originalMediaPath'] as String,
        isVideo: json['isVideo'] as bool,
        createdAt: DateTime.parse(json['createdAt'] as String),
        lastModified: DateTime.parse(json['lastModified'] as String),
        edits: (json['edits'] as List)
            .map((e) => EditAction.fromJson(e as Map<String, dynamic>))
            .toList(),
        metadata: Map<String, dynamic>.from(json['metadata'] as Map),
      );
}
