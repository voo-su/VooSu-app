import 'package:equatable/equatable.dart';

class UserTypingPayload extends Equatable {
  final int userId;
  final int peerType;
  final int peerId;

  const UserTypingPayload({
    required this.userId,
    this.peerType = 1,
    this.peerId = 0,
  });

  @override
  List<Object?> get props => [userId, peerType, peerId];
}
