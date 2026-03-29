abstract final class ChatMsgType {
  static const int text = 1;
  static const int code = 2;
  static const int image = 3;
  static const int location = 7;
  static const int card = 8;
  static const int forward = 9;
  static const int login = 10;
  static const int mixed = 12;

  static const int sysMin = 1000;
  static const int sysText = 1000;
  static const int sysGroupCreate = 1101;
  static const int sysGroupMemberJoin = 1102;
  static const int sysGroupMemberQuit = 1103;
  static const int sysGroupMemberKicked = 1104;
  static const int sysGroupMessageRevoke = 1105;
  static const int sysGroupDismissed = 1106;
  static const int sysGroupMuted = 1107;
  static const int sysGroupCancelMuted = 1108;
  static const int sysGroupMemberMuted = 1109;
  static const int sysGroupMemberCancelMuted = 1110;
  static const int sysGroupTransfer = 1113;
}
