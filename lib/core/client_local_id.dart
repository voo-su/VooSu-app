import 'package:uuid/uuid.dart';

const _uuid = Uuid();

String newClientLocalId() => _uuid.v4();
