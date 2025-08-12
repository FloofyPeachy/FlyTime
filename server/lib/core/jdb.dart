import 'dart:convert';
import 'dart:io';

class JsonDatabase<T> {
  final String path;
  final T Function(Map<String, dynamic>) fromJson;
  final Map<String, dynamic> Function(T) toJson;
  final Map<String, T> _data = {};

  JsonDatabase(this.path, this.fromJson, this.toJson) {
    final file = File(path);
    if (file.existsSync()) {
      final Map<String, dynamic> jsonMap = jsonDecode(file.readAsStringSync());
      jsonMap.forEach((key, value) {
        _data[key] = fromJson(value as Map<String, dynamic>);
      });
    }
  }

  void save() {
    final output = _data.map((key, value) => MapEntry(key, toJson(value)));
    File(path).writeAsStringSync(jsonEncode(output));
  }

  Map<String, T> get data => _data;

  void add(String key, T value) {
    _data[key] = value;
  }

  T? get(String key) => _data[key];

  void remove(String key) {
    _data.remove(key);
  }

  Map<String, T> getAll() => _data;

  bool contains(String key) => _data.containsKey(key);
}
