import 'dart:core';
import 'dart:convert';

part 'json_key.dart';
part 'unwrap.dart';

/// JSON解析器
class SDartJson {
  dynamic _rawValue;

  /// 解析的值
  dynamic get rawValue => _rawValue;

  /// 存储关联上一个JSON的数据 用于在设置值的时候更新最顶层的JSON
  final JSONKey? _key;

  /// 创建一个新的JSON解析器
  /// [rawValue] 解析的值 默认为空字典
  /// [key] 关联上一个JSON的数据 用于在设置值的时候更新最顶层的JSON
  SDartJson([this._rawValue = const {}, this._key]);

  factory SDartJson.fromJsonString(String str) {
    try {
      final jsonObject = jsonDecode(str);
      return SDartJson(jsonObject);
    } catch (e) {
      return SDartJson(str);
    }
  }

  /// 通过[key] 获取下一个JSON 不存在则返回空的JSON
  SDartJson operator [](dynamic key) {
    SDartJson? json;

    /// 尝试从数组获取 获取到则直接返回
    json = tryFromArray(key);
    if (json != null) return json;

    /// 尝试从字典获取 获取到则直接返回
    json = tryFromObject(key);
    if (json != null) return json;

    /// 尝试根据数组Key获取 获取到则返回
    json = tryFromKeyPath(key);
    if (json != null) return json;

    /// 获取不到返回空的JSON
    return SDartJson(null);
  }

  /// 根据[key] 更新[value]
  /// [key] 关联的键
  /// [value] 关联的值
  void operator []=(dynamic key, dynamic value) {
    /// 尝试设置到字典中
    trySetObject(key, value);

    /// 尝试设置到数组中
    trySetArray(key, value);

    /// 尝试根据Key数组进行设置
    trySetKeyPath(key, value);
  }

  /// 循环读取List中的所有值
  void forEachList(void Function(int, SDartJson) callback) {
    final list = listValue;
    for (var i = 0; i < list.length; i++) {
      callback(i, SDartJson(list[i]));
    }
  }

  /// 循环读取Map中的所有值
  void forEachMap(void Function(String, SDartJson) callback) {
    final map = mapValue;
    map.forEach((key, value) {
      callback(key, SDartJson(value));
    });
  }

  /// 检测对应Key 的值是否存在
  bool exists() => _rawValue != null;

  /// 更新值
  set _value(dynamic value) {
    _rawValue = value;

    /// 检测当前JSON是否关联了上一个JSON 如果关联了则更新最顶层的JSON 否则不更新
    final key = _key;
    if (key == null) return;
    key.parentJSON[key.key] = value;
  }

  T? as<T>() {
    if (rawValue is! T) return null;
    return (rawValue as T);
  }

  Unwrap<S> unwrap<S>() => Unwrap(as<S>());

  bool get isEmpty {
    if (isMap) return mapValue.isEmpty;
    if (isList) return listValue.isEmpty;
    return (string == null) || (string!.isEmpty);
  }
}

extension JSONGetOperations on SDartJson {
  SDartJson? tryFromArray(dynamic key) {
    if (key is List) return null;
    final list = this.list;
    if (list == null) return null;
    final index = SDartJson(key).getInt;
    if (index == null) return null;
    if (index < 0 || index >= list.length) return null;
    return SDartJson(list[index], JSONKey(this, index));
  }

  SDartJson? tryFromObject(dynamic key) {
    if (key is List) return null;
    final map = this.getMap;
    if (map == null) return null;
    return SDartJson(map[key], JSONKey(this, key));
  }

  SDartJson? tryFromKeyPath(dynamic key) {
    final keyPaths = SDartJson(key).list;
    if (keyPaths == null) return null;
    SDartJson? json = this;
    for (var i = 0; i < keyPaths.length; i++) {
      if (json == null) return null;
      json = json[keyPaths[i]];
    }
    return json;
  }
}

extension JSONSetOperations on SDartJson {
  void trySetArray(dynamic key, dynamic value) {
    if (key is List) return;
    final list = this.list;
    if (list == null) return;
    final index = SDartJson(key).getInt;
    if (index == null) return;
    if (index < 0 || index >= list.length) return;
    list[index] = value;
    _value = list;
  }

  void trySetObject(dynamic key, dynamic value) {
    if (key is List) return;
    final map = this.getMap;
    if (map == null) return;
    if (value is SDartJson) {
      value = value.rawValue;
    }
    map[key] = value;
    _value = map;
  }

  void trySetKeyPath(dynamic key, dynamic value) {
    if (key is! List) return;
    final keyPaths = SDartJson(key).list;
    if (keyPaths == null) return;
    SDartJson json = this[keyPaths];
    json._value = value;
  }
}

/// 转换为Double类型
extension JSONToDouble on SDartJson {
  /// 转换为一个可能为空的double类型
  double? get getDouble {
    if (rawValue is bool) return rawValue ? 1 : 0;
    return num.tryParse(stringValue)?.toDouble();
  }

  /// 转换为一个默认为为0 不为空的double类型
  double get doubleValue {
    return getDouble ?? 0;
  }

  bool get isDouble => getDouble != null;
}

/// 转换为Int类型
extension JSONToInt on SDartJson {
  /// 转换为一个可能为空的int类型
  int? get getInt {
    if (rawValue is bool) return rawValue ? 1 : 0;
    return num.tryParse(stringValue)?.toInt();
  }

  /// 转换为一个默认为为0 不为空的int类型
  int get intValue {
    return getInt ?? 0;
  }

  bool get isInt => getInt != null;
}

/// 转换为Bool类型
extension JSONToBool on SDartJson {
  /// 转换为一个可能为空的bool类型
  bool? get getBool {
    final intValue = this.getInt;
    if (intValue == null) return null;
    return intValue == 1;
  }

  /// 转换为一个默认为为false 不为空的bool类型
  bool get boolValue {
    return getBool ?? false;
  }

  bool get isBool => getBool != null;
}

/// 转换为Number类型
extension JSONToNumber on SDartJson {
  /// 转换为一个可能为空的Number类型
  num? get getNum {
    if (rawValue is bool) return rawValue ? 1 : 0;
    return num.tryParse('$rawValue');
  }

  /// 转换为一个默认为为0 不为空的Number类型
  num get numValue {
    return getNum ?? 0;
  }

  bool get isNum => getNum != null;
}

/// 转换为Array类型
extension JSONToArray on SDartJson {
  /// 转换为一个可能为空的Array类型
  List<dynamic>? get list {
    if (rawValue is String) {
      var decodeResult;
      try {
        decodeResult = jsonDecode(rawValue);
      } catch (e) {}
      if (decodeResult == null) return null;
      return SDartJson(decodeResult).list;
    }
    if (rawValue is! List<dynamic>) return null;
    return rawValue;
  }

  /// 转换为一个默认为为空的Array类型
  List<dynamic> get listValue {
    return list ?? [];
  }

  List<SDartJson> get arrayValue {
    return listValue.map((e) => SDartJson(e)).toList();
  }

  List<SDartJson>? get getArray {
    return list?.map((e) => SDartJson(e)).toList();
  }

  bool get isList => list != null;
}

/// 转换为 Map类型
extension JSONToMap on SDartJson {
  /// 转换为一个可能为空的Map类型
  Map<String, dynamic>? get getMap {
    if (rawValue is String) {
      var decodeResult;
      try {
        decodeResult = jsonDecode(rawValue);
      } catch (e) {}
      if (decodeResult == null) return null;
      return SDartJson(decodeResult).getMap;
    }
    if (rawValue is! Map<dynamic, dynamic>) return null;
    final m = rawValue as Map<dynamic, dynamic>;
    return m.map(
      (key, value) => MapEntry<String, dynamic>(
        key.toString(),
        value,
      ),
    );
  }

  /// 转换为一个默认为为空的Map类型
  Map<String, dynamic> get mapValue {
    return getMap ?? <String, dynamic>{};
  }

  bool get isMap => getMap != null;
}

extension JSONToString on SDartJson {
  /// 转换为一个可能为空的String类型
  String? get string {
    if (rawValue is double) return '$rawValue';
    if (rawValue is int) return '$rawValue';
    if (rawValue is bool) return '$rawValue';
    if (rawValue is num) return '$rawValue';
    if (rawValue is String) return rawValue;
    if (rawValue is List<dynamic>) return jsonEncode(rawValue);
    if (rawValue is Map<dynamic, dynamic>) return jsonEncode(rawValue);
    return null;
  }

  /// 转换为一个默认为为空的String类型
  String get stringValue {
    return string ?? "";
  }

  String? get getString {
    if (rawValue is! String) return null;
    return rawValue;
  }

  // bool get isString => string != null;
}

extension IntToJSON on int {
  SDartJson get json {
    return SDartJson(this);
  }
}

extension DoubleToJSON on double {
  SDartJson get json {
    return SDartJson(this);
  }
}

extension BoolToJSON on bool {
  SDartJson get json {
    return SDartJson(this);
  }
}

extension NumberToJSON on num {
  SDartJson get json {
    return SDartJson(this);
  }
}

extension StringToJSON on String {
  SDartJson get json {
    return SDartJson(this);
  }
}

extension ListToJSON on List {
  SDartJson get json {
    return SDartJson(this);
  }
}

extension MapToJSON on Map {
  SDartJson get json {
    return SDartJson(this);
  }
}
