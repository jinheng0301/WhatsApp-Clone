class GroupChat {
  final String senderId;
  final String name;
  final String groupId;
  final String lastMessage;
  final String groupPic;
  final List<String> membersUid;
  final DateTime timeSent;
  final int unreadCount;

  GroupChat({
    required this.senderId,
    required this.name,
    required this.groupId,
    required this.lastMessage,
    required this.groupPic,
    required this.membersUid,
    required this.timeSent,
    this.unreadCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'name': name,
      'groupId': groupId,
      'lastMessage': lastMessage,
      'groupPic': groupPic,
      'membersUid': membersUid,
      'timeSent': timeSent.millisecondsSinceEpoch,
      'unreadCount': unreadCount,
    };
  }

  factory GroupChat.fromMap(Map<String, dynamic> map) {
    // Enhanced debugging
    print('GroupChat.fromMap for: ${map['name']}');
    print('  Raw data: $map');

    int parsedUnreadCount = _parseUnreadCount(map['unreadCount']);

    print('  Final unreadCount: $parsedUnreadCount');

    return GroupChat(
      senderId: map['senderId'] ?? '',
      name: map['name'] ?? '',
      groupId: map['groupId'] ?? '',
      lastMessage: map['lastMessage'] ?? '',
      groupPic: map['groupPic'] ?? '',
      membersUid: List<String>.from(map['membersUid'] ?? []),
      timeSent: DateTime.fromMillisecondsSinceEpoch(map['timeSent'] ?? 0),
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
