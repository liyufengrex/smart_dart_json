import 'package:smart_dart_json/smart_dart_json.dart';

void main() {
  const json =
      '{\"title\": \"示例title\", 	\"data\": [{ 		\"name\": \"rex\", 		\"age\": 10 	}] }';
  final sJson = SDartJson(json);
  final title = sJson['title'].stringValue;
  final data = sJson['data'].arrayValue.map((e) => e.mapValue).toList();

  //模拟未定义的字段获取 （方式一）
  final undefinedKey1 = sJson['undefinedKey1'].stringValue;
  //模拟未定义的字段获取 （方式二）
  final undefinedKey2 = sJson['undefinedKey2'].string;

  print('title : $title');
  print('data : $data');
  print('undefinedKey1 : $undefinedKey1');
  print('undefinedKey2 : $undefinedKey2');
}
