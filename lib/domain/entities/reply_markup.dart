class InlineKeyboardButton {
  final String text;
  final String callbackData;

  const InlineKeyboardButton({
    required this.text,
    this.callbackData = '',
  });
}

class InlineKeyboardRow {
  final List<InlineKeyboardButton> buttons;

  const InlineKeyboardRow({required this.buttons});
}

class ReplyMarkup {
  final List<InlineKeyboardRow> inlineKeyboard;

  const ReplyMarkup({required this.inlineKeyboard});

  bool get isEmpty => inlineKeyboard.isEmpty;
  bool get isNotEmpty => inlineKeyboard.isNotEmpty;
}
