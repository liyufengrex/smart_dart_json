### 介绍
JSON 解析工具：
+ 当解析JSON字段内不存在字段时，可返回默认值，不报错
+ 当解析字段类型不对等时，可返回默认值，不报错
  （例如：使用 json_serializable 解析，当服务端返回的字段类型为int，我们将该字段声明为string来解析时会报错，使用本库可正常解析成字符串类型）

### 使用方式参考
```dart
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
```
打印结果
```dart
title : 示例title
data : [{name: rex, age: 10}]
undefinedKey1 : 
undefinedKey2 : null
```

### Features
公司**老五**写的json解析工具类，用习惯了，为了能在自己的开源库里使用上，特此借用。
