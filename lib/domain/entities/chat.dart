class Chat {
  final int id;
  final bool isGroup;
  final int peerUserId;
  final int peerGroupId;
  final String title;
  final String userUsername;
  final String userName;
  final String userSurname;
  final DateTime createdAt;
  final int unreadCount;
  final int memberCount;
  final int? avatarFileId;
  final String? lastMessagePreview;
  final bool notificationsMuted;
  final int listId;
  final bool isPinned;

  Chat({
    required this.id,
    required this.isGroup,
    required this.peerUserId,
    required this.peerGroupId,
    required this.title,
    this.userUsername = '',
    this.userName = '',
    this.userSurname = '',
    required this.createdAt,
    this.unreadCount = 0,
    this.memberCount = 0,
    this.avatarFileId,
    this.lastMessagePreview,
    this.notificationsMuted = false,
    this.listId = 0,
    this.isPinned = false,
  });

  Chat copyWith({
    int? unreadCount,
    int? memberCount,
    int? avatarFileId,
    String? lastMessagePreview,
    bool? notificationsMuted,
    int? listId,
    bool? isPinned,
  }) {
    return Chat(
      id: id,
      isGroup: isGroup,
      peerUserId: peerUserId,
      peerGroupId: peerGroupId,
      title: title,
      userUsername: userUsername,
      userName: userName,
      userSurname: userSurname,
      createdAt: createdAt,
      unreadCount: unreadCount ?? this.unreadCount,
      memberCount: memberCount ?? this.memberCount,
      avatarFileId: avatarFileId ?? this.avatarFileId,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      notificationsMuted: notificationsMuted ?? this.notificationsMuted,
      listId: listId ?? this.listId,
      isPinned: isPinned ?? this.isPinned,
    );
  }
}

List<Chat> sortChatsForList(List<Chat> chats) {
  final out = List<Chat>.from(chats);
  out.sort((a, b) {
    if (a.isPinned != b.isPinned) {
      return a.isPinned ? -1 : 1;
    }

    return b.createdAt.compareTo(a.createdAt);
  });

  return out;
}
