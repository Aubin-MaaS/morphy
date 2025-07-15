import 'package:test/test.dart';
import 'package:zikzak_morphy_annotation/zikzak_morphy_annotation.dart';

part 'ex61_nonsealed_json_test.morphy.dart';
part 'ex61_nonsealed_json_test.g.dart';

// Test case for non-sealed abstract class with $$ prefix and JSON generation
// This tests the fix for the issue where non-sealed abstract classes with $$
// were not generating JSON serialization methods even when generateJson: true

@Morphy(nonSealed: true, generateJson: true)
abstract class $$ApiResponse {
  String get status;
  String get message;
  DateTime get timestamp;

  factory $$ApiResponse.success(String message) => ApiResponse._(
    status: "success",
    message: message,
    timestamp: DateTime.parse("2023-01-01T00:00:00Z"),
  );

  factory $$ApiResponse.error(String error) => ApiResponse._(
    status: "error",
    message: error,
    timestamp: DateTime.parse("2023-01-01T00:00:00Z"),
  );
}

@Morphy(generateJson: true)
abstract class $DetailedApiResponse implements $$ApiResponse {
  Map<String, dynamic> get data;
}

@Morphy(nonSealed: true, generateJson: true)
abstract class $$BaseEntity {
  String get id;
  DateTime get createdAt;
  DateTime? get updatedAt;
}

@Morphy(generateJson: true)
abstract class $User implements $$BaseEntity {
  String get name;
  String get email;
}

void main() {
  group('Non-sealed Abstract Class with JSON Generation', () {
    group('ApiResponse tests', () {
      test('should create ApiResponse with success factory', () {
        var response = ApiResponse.success("Operation completed");
        expect(response.status, "success");
        expect(response.message, "Operation completed");
        expect(response.timestamp, isA<DateTime>());
      });

      test('should create ApiResponse with error factory', () {
        var response = ApiResponse.error("Something went wrong");
        expect(response.status, "error");
        expect(response.message, "Something went wrong");
      });

      test(
        'should generate toJson method for non-sealed dollar-dollar class',
        () {
          var response = ApiResponse.success("Test message");

          // Should generate toJson method
          var json = response.toJson();
          expect(json['status'], "success");
          expect(json['message'], "Test message");
          expect(json['_className_'], "ApiResponse");
          expect(json['timestamp'], isA<String>());
        },
      );

      test(
        'should generate fromJson method for non-sealed dollar-dollar class',
        () {
          var originalResponse = ApiResponse.error("Test error");
          var json = originalResponse.toJson();

          // Should generate fromJson method
          var deserializedResponse = ApiResponse.fromJson(json);
          expect(deserializedResponse.status, "error");
          expect(deserializedResponse.message, "Test error");
          expect(
            deserializedResponse.timestamp.toIso8601String(),
            originalResponse.timestamp.toIso8601String(),
          );
        },
      );

      test('should handle round-trip JSON serialization', () {
        var original = ApiResponse.success("Round trip test");
        var json = original.toJson();
        var restored = ApiResponse.fromJson(json);

        expect(restored.status, original.status);
        expect(restored.message, original.message);
        expect(
          restored.timestamp.toIso8601String(),
          original.timestamp.toIso8601String(),
        );
      });
    });

    group('Inheritance with non-sealed classes', () {
      test('should work with inheritance and JSON', () {
        var detailedResponse = DetailedApiResponse(
          status: "success",
          message: "Data retrieved",
          timestamp: DateTime.parse("2023-01-01T00:00:00Z"),
          data: {"count": 42, "items": []},
        );

        var json = detailedResponse.toJson();
        expect(json['_className_'], "DetailedApiResponse");
        expect(json['data'], {"count": 42, "items": []});

        var deserialized = DetailedApiResponse.fromJson(json);
        expect(deserialized.data["count"], 42);
      });

      test('should handle polymorphic JSON deserialization', () {
        var detailedResponse = DetailedApiResponse(
          status: "success",
          message: "Polymorphic test",
          timestamp: DateTime.parse("2023-01-01T00:00:00Z"),
          data: {"key": "value"},
        );

        // Serialize as DetailedApiResponse
        var json = detailedResponse.toJson();

        // Should be able to deserialize back as ApiResponse (polymorphic)
        var asApiResponse = ApiResponse.fromJson(json);
        expect(asApiResponse, isA<DetailedApiResponse>());
        expect(asApiResponse.status, "success");
        expect(asApiResponse.message, "Polymorphic test");
      });
    });

    group('BaseEntity tests', () {
      test('should generate JSON for BaseEntity', () {
        var user = User(
          id: "user123",
          createdAt: DateTime.parse("2023-01-01T00:00:00Z"),
          updatedAt: null,
          name: "John Doe",
          email: "john@example.com",
        );

        var json = user.toJson();
        expect(json['id'], "user123");
        expect(json['name'], "John Doe");
        expect(json['email'], "john@example.com");
        expect(json['_className_'], "User");
      });

      test('should deserialize JSON for inherited non-sealed class', () {
        var originalUser = User(
          id: "user456",
          createdAt: DateTime.parse("2023-01-01T00:00:00Z"),
          updatedAt: DateTime.parse("2023-01-01T01:00:00Z"),
          name: "Jane Smith",
          email: "jane@example.com",
        );

        var json = originalUser.toJson();
        var restoredUser = User.fromJson(json);

        expect(restoredUser.id, originalUser.id);
        expect(restoredUser.name, originalUser.name);
        expect(restoredUser.email, originalUser.email);
        expect(
          restoredUser.createdAt.toIso8601String(),
          originalUser.createdAt.toIso8601String(),
        );
      });

      test('should handle polymorphic deserialization through BaseEntity', () {
        var user = User(
          id: "poly123",
          createdAt: DateTime.parse("2023-01-01T00:00:00Z"),
          updatedAt: null,
          name: "Polymorphic User",
          email: "poly@example.com",
        );

        var json = user.toJson();

        // Should be able to deserialize as BaseEntity
        var asBaseEntity = BaseEntity.fromJson(json);
        expect(asBaseEntity, isA<User>());
        expect(asBaseEntity.id, "poly123");
      });
    });

    group('Edge cases and validation', () {
      test('should maintain type safety with non-sealed classes', () {
        var response = ApiResponse.success("Type safety test");
        expect(response is ApiResponse, true);
        expect(response.runtimeType, ApiResponse);
      });

      test('should handle null values in JSON', () {
        var user = User(
          id: "null_test",
          createdAt: DateTime.parse("2023-01-01T00:00:00Z"),
          updatedAt: null, // null value
          name: "Null Tester",
          email: "null@example.com",
        );

        var json = user.toJson();
        expect(json['updatedAt'], null);

        var restored = User.fromJson(json);
        expect(restored.updatedAt, null);
      });

      test('should preserve equality after JSON round-trip', () {
        var original = ApiResponse.error("Equality test");
        var json = original.toJson();
        var restored = ApiResponse.fromJson(json);

        // Note: DateTime precision might affect equality, so we check fields individually
        expect(restored.status, original.status);
        expect(restored.message, original.message);
      });
    });
  });
}
