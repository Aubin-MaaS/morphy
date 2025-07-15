import 'package:test/test.dart';
import 'package:zikzak_morphy_annotation/zikzak_morphy_annotation.dart';

part 'ex60_nonsealed_methods_test.morphy.dart';

// Base interface
@Morphy()
abstract class $ChatMessage {
  String get id;
  DateTime get createdAt;
  String get conversationId;
  String? get content;
}

// Non-sealed class that should generate its own copyWith/patchWith methods
@Morphy(nonSealed: true)
abstract class $$SystemMessage implements $ChatMessage {
  String? get systemType;
  String? get metadata;
}

@Morphy()
abstract class $SparkMessage implements $$SystemMessage {
  String get spark;
}

void main() {
  group('Non-sealed class method generation', () {
    test('should generate copyWithSystemMessage method', () {
      final message = SystemMessage(
        id: 'test-id',
        createdAt: DateTime.now(),
        conversationId: 'conv-123',
        content: 'Hello',
        systemType: 'notification',
        metadata: 'meta-data',
      );

      // This should compile - copyWithSystemMessage should be generated
      final copied = message.copyWithSystemMessage(
        content: 'Updated content',
        systemType: 'alert',
      );

      expect(copied.id, equals('test-id'));
      expect(copied.content, equals('Updated content'));
      expect(copied.systemType, equals('alert'));
      expect(copied.metadata, equals('meta-data')); // unchanged
    });

    test('should generate patchWithSystemMessage method', () {
      final message = SystemMessage(
        id: 'test-id',
        createdAt: DateTime.now(),
        conversationId: 'conv-123',
        content: 'Hello',
        systemType: 'notification',
        metadata: 'meta-data',
      );

      final patch = SystemMessagePatch()
        ..withContent('Patched content')
        ..withSystemType('warning');

      // This should compile - patchWithSystemMessage should be generated
      final patched = message.patchWithSystemMessage(patchInput: patch);

      expect(patched.id, equals('test-id'));
      expect(patched.content, equals('Patched content'));
      expect(patched.systemType, equals('warning'));
      expect(patched.metadata, equals('meta-data')); // unchanged
    });

    test('should also generate inherited interface methods', () {
      final message = SystemMessage(
        id: 'test-id',
        createdAt: DateTime.now(),
        conversationId: 'conv-123',
        content: 'Hello',
        systemType: 'notification',
        metadata: 'meta-data',
      );

      // Should also have methods for the inherited ChatMessage interface
      final copiedChatMessage = message.copyWithChatMessage(
        content: 'Updated via ChatMessage',
      );

      expect(copiedChatMessage.content, equals('Updated via ChatMessage'));
      expect(copiedChatMessage.systemType, equals('notification')); // unchanged
    });
  });
}
