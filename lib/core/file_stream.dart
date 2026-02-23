import 'dart:io';

Stream<List<int>> streamFromPath(
  String path,
  int size, {
  int chunkSize = 256 * 1024,
}) {
  return File(path).openRead(0, size);
}

Future<List<int>> readFileBytes(String path) {
  return File(path).readAsBytes().then((v) => v);
}
