import 'package:test/test.dart';
import 'package:zikzak_morphy_annotation/zikzak_morphy_annotation.dart';

part 'debug_factory_test.morphy.dart';
part 'debug_factory_test.g.dart';

// Simple test to debug JSON generation for non-sealed $$ classes
@Morphy(nonSealed: true, generateJson: true)
abstract class $$SimpleResponse {
  String get message;
  String get status;
}

@Morphy(generateJson: true)
abstract class $BasicResponse implements $$SimpleResponse {
  // Basic implementation
}

@Morphy(generateJson: true)
abstract class $DetailedResponse implements $$SimpleResponse {
  Map<String, dynamic> get data;
}

@Morphy(generateJson: true)
abstract class $ConcreteResponse implements $$SimpleResponse {
  DateTime get timestamp;
  bool get isSuccess;
}

void main() {
  group('Debug JSON Generation for Non-sealed Classes', () {
    test('should create BasicResponse and generate JSON', () {
      var response = BasicResponse(message: "test message", status: "success");

      expect(response.message, "test message");
      expect(response.status, "success");
    });

    test(
      'should generate toJson method for non-sealed dollar-dollar class',
      () {
        var response = BasicResponse(message: "json test", status: "ok");

        // Test toJson - this should work with our fix
        var json = response.toJson();
        expect(json['message'], "json test");
        expect(json['status'], "ok");
        expect(json['_className_'], "BasicResponse");
      },
    );

    test(
      'should generate fromJson method for non-sealed dollar-dollar class',
      () {
        var originalResponse = BasicResponse(
          message: "restore test",
          status: "active",
        );

        var json = originalResponse.toJson();

        // Test fromJson - this should work with our fix
        var restored = BasicResponse.fromJson(json);
        expect(restored.message, "restore test");
        expect(restored.status, "active");
      },
    );

    test('should handle inheritance with non-sealed dollar-dollar classes', () {
      var detailedResponse = DetailedResponse(
        message: "detailed test",
        status: "complete",
        data: {"count": 42, "items": []},
      );

      var json = detailedResponse.toJson();
      expect(json['_className_'], "DetailedResponse");
      expect(json['message'], "detailed test");
      expect(json['data'], {"count": 42, "items": []});

      var restored = DetailedResponse.fromJson(json);
      expect(restored.data["count"], 42);
    });

    test('should work with concrete implementation class', () {
      var concreteResponse = ConcreteResponse(
        message: "concrete test",
        status: "done",
        timestamp: DateTime.parse("2023-01-01T12:00:00Z"),
        isSuccess: true,
      );

      var json = concreteResponse.toJson();
      expect(json['_className_'], "ConcreteResponse");
      expect(json['message'], "concrete test");
      expect(json['isSuccess'], true);

      var restored = ConcreteResponse.fromJson(json);
      expect(restored.isSuccess, true);
      expect(restored.message, "concrete test");
    });

    test('should handle polymorphic JSON through base class', () {
      var detailedResponse = DetailedResponse(
        message: "polymorphic test",
        status: "ready",
        data: {"key": "value"},
      );

      var json = detailedResponse.toJsonLean();

      // Should be able to deserialize as BasicResponse (polymorphic)
      var asBasicResponse = BasicResponse.fromJson(json);
      expect(asBasicResponse, isA<BasicResponse>());
      expect(asBasicResponse.message, "polymorphic test");
      expect(asBasicResponse.status, "ready");
    });
  });
}
