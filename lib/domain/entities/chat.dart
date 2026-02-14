class Chat {
  final int id;
  final int peerUserId;
  final String title;
  final String userUsername;
  final String userName;
  final String userSurname;
  final DateTime createdAt;
  final int unreadCount;
  final int? avatarFileId;
  final String? lastMessagePreview;

  Chat({
    required this.id,
    required this.peerUserId,
    required this.title,
    this.userUsername = '',
    this.userName = '',
    this.userSurname = '',
    required this.createdAt,
    this.unreadCount = 0,
    this.avatarFileId,
    this.lastMessagePreview,
  });

  Chat copyWith({
    int? unreadCount,
    int? avatarFileId,
    String? lastMessagePreview,
  }) {
    return Chat(
      id: id,
      peerUserId: peerUserId,
      title: title,
      userUsername: userUsername,
      userName: userName,
      userSurname: userSurname,
      createdAt: createdAt,
      unreadCount: unreadCount ?? this.unreadCount,
      avatarFileId: avatarFileId ?? this.avatarFileId,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
    );
  }
}
