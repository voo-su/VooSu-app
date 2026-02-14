abstract final class AppServerConstants {
  static const String grpcHost = '127.0.0.1';
  static const int grpcPort = 50051;

  static String get grpcAddress => '$grpcHost:$grpcPort';
}
