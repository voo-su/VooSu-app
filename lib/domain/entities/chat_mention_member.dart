class ChatMentionMember {
  final int userId;
  final String username;
  final String displayLabel;

  const ChatMentionMember({
    required this.userId,
    required this.username,
    required this.displayLabel,
  });

  static const ChatMentionMember all = ChatMentionMember(
    userId: 0,
    username: 'all',
    displayLabel: 'Все',
  );
}
