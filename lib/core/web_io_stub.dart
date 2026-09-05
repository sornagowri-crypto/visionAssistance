// Web stub for dart:io — provides a minimal File class so camera_screen.dart
// compiles on web without errors. On web, camera capture returns Uint8List,
// so File.path is never actually called.

class File {
  final String path;
  const File(this.path);
  Future<List<int>> readAsBytes() async => [];
}
