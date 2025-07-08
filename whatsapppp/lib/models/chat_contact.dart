class ChatContact {
  final String name;
  final String profilePic;
  final String contactId;
  final DateTime timeSent;
  final String lastMessage;
  final int unreadCount;

  ChatContact({
    required this.name,
    required this.profilePic,
    required this.contactId,
    required this.timeSent,
    required this.lastMessage,
    this.unreadCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'profilePic': profilePic,
      'contactId': contactId,
      'timeSent': timeSent.millisecondsSinceEpoch,
      'lastMessage': lastMessage,
      'unreadCount': unreadCount,
    };
  }

  factory ChatContact.fromMap(Map<String, dynamic> map) {
    // Enhanced debugging
    print('ChatContact.fromMap for: ${map['name']}');
    print('  Raw data: $map');

    int parsedUnreadCount = _parseUnreadCount(map['unreadCount']);

    print('  Final unreadCount: $parsedUnreadCount');

    return ChatContact(
      name: map['name'] ?? '',
      profilePic: map['profilePic'] ?? '',
      contactId: map['contactId'] ?? '',
      timeSent: DateTime.fromMillisecondsSinceEpoch(map['timeSent'] ?? 0),
      lastMessage: map['lastMessage'] ?? '',
      unreadCount: parsedUnreadCount,
    );
  }

  // Helper method to parse unread count
  static int _parseUnreadCount(dynamic value) {
    if (value == null) return 0;

    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;

    print(
        'Warning: Unexpected unreadCount type: ${value.runtimeType}, value: $value');
    return 0;
  }
}
