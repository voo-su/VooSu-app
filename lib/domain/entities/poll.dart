class PollOptionResult {
  final int optionId;
  final String text;
  final int position;
  final int voteCount;
  final List<int> voterUserIds;

  const PollOptionResult({
    required this.optionId,
    required this.text,
    required this.position,
    required this.voteCount,
    this.voterUserIds = const [],
  });
}

class Poll {
  final int id;
  final String question;
  final bool anonymous;
  final List<PollOptionResult> options;

  const Poll({
    required this.id,
    required this.question,
    required this.anonymous,
    required this.options,
  });
}
