import 'package:zikzak_morphy_annotation/morphy_annotation.dart';
import 'package:test/test.dart';

part 'withPatch_morphy_types_test.morphy.dart';
part 'withPatch_morphy_types_test.g.dart';

@Morphy(generateJson: true)
abstract class $Profile {
  String get name;
  int get age;
}

@Morphy(generateJson: true)
abstract class $User {
  String get email;
  $Profile get profile;
}

main() {
  group('withPatch method generation for Morphy types', () {
    test('should generate withPatch methods for Morphy type fields', () {
      // Create a Profile patch using regular with methods
      ProfilePatch profilePatch = ProfilePatch.create()
        ..withName('John Doe')
        ..withAge(30);

      // Create a User patch using withPatch method for Morphy type
      UserPatch userPatch = UserPatch.create()
        ..withEmail('john@example.com')
        ..withProfilePatch(profilePatch);

      // Verify the patch objects contain expected data
      final userPatchMap = userPatch.toPatch();

      expect(userPatchMap[User$.email], equals('john@example.com'));
      expect(userPatchMap[User$.profile], equals(profilePatch));
    });

    test(
      'should generate withPatchFunc methods for function-based patching',
      () {
        // Create a User patch using function-based patch method
        UserPatch userPatch = UserPatch.create()
          ..withEmail('jane@example.com')
          ..withProfilePatchFunc(
            (patch) => patch
              ..withName('Jane Smith')
              ..withAge(28),
          );

        // Verify the patch objects contain expected data
        final userPatchMap = userPatch.toPatch();

        expect(userPatchMap[User$.email], equals('jane@example.com'));
        expect(userPatchMap[User$.profile], isA<ProfilePatch>());

        final profilePatch = userPatchMap[User$.profile] as ProfilePatch;
        final profilePatchMap = profilePatch.toPatch();
        expect(profilePatchMap[Profile$.name], equals('Jane Smith'));
        expect(profilePatchMap[Profile$.age], equals(28));
      },
    );

    test('should apply nested patches correctly with direct patch', () {
      // Create initial objects
      final initialProfile = Profile(name: 'Jane Doe', age: 25);

      final initialUser = User(
        email: 'jane@example.com',
        profile: initialProfile,
      );

      // Create patches with withPatch methods
      ProfilePatch profilePatch = ProfilePatch.create()
        ..withName('Jane Smith')
        ..withAge(26);

      UserPatch userPatch = UserPatch.create()
        ..withEmail('jane.smith@example.com')
        ..withProfilePatch(profilePatch);

      // Apply the patch
      final updatedUser = userPatch.applyTo(initialUser);

      // Verify the nested updates worked
      expect(updatedUser.email, equals('jane.smith@example.com'));
      expect(updatedUser.profile.name, equals('Jane Smith'));
      expect(updatedUser.profile.age, equals(26));
    });

    test('should apply nested patches correctly with function-based patch', () {
      // Create initial objects
      final initialProfile = Profile(name: 'Bob Johnson', age: 35);

      final initialUser = User(
        email: 'bob@example.com',
        profile: initialProfile,
      );

      // Create patches with function-based patch methods
      UserPatch userPatch = UserPatch.create()
        ..withEmail('bob.johnson@newcompany.com')
        ..withProfilePatchFunc(
          (patch) => patch
            ..withName('Robert Johnson')
            ..withAge(36),
        );

      // Apply the patch
      final updatedUser = userPatch.applyTo(initialUser);

      // Verify the nested updates worked
      expect(updatedUser.email, equals('bob.johnson@newcompany.com'));
      expect(updatedUser.profile.name, equals('Robert Johnson'));
      expect(updatedUser.profile.age, equals(36));
    });

    test('should handle partial nested patches correctly', () {
      // Create initial objects
      final initialProfile = Profile(name: 'Alice Cooper', age: 30);

      final initialUser = User(
        email: 'alice@example.com',
        profile: initialProfile,
      );

      // Create patch that only updates profile name, not age
      UserPatch userPatch = UserPatch.create()
        ..withProfilePatchFunc((patch) => patch..withName('Alice Johnson'));

      // Apply the patch
      final updatedUser = userPatch.applyTo(initialUser);

      // Verify only the name was updated, age should remain the same
      expect(updatedUser.email, equals('alice@example.com')); // unchanged
      expect(updatedUser.profile.name, equals('Alice Johnson')); // changed
      expect(updatedUser.profile.age, equals(30)); // unchanged
    });

    test('should handle mixed patch approaches', () {
      // Create initial objects
      final initialProfile = Profile(name: 'Mixed User', age: 25);
      final initialUser = User(
        email: 'mixed@example.com',
        profile: initialProfile,
      );

      // Test using both direct profile replacement and nested patching
      UserPatch userPatch1 = UserPatch.create()
        ..withProfile(Profile(name: 'Direct Replacement', age: 99));

      UserPatch userPatch2 = UserPatch.create()
        ..withProfilePatchFunc((patch) => patch..withName('Nested Update'));

      // Apply first patch (direct replacement)
      final updatedUser1 = userPatch1.applyTo(initialUser);
      expect(updatedUser1.profile.name, equals('Direct Replacement'));
      expect(updatedUser1.profile.age, equals(99));

      // Apply second patch to original (nested update)
      final updatedUser2 = userPatch2.applyTo(initialUser);
      expect(updatedUser2.profile.name, equals('Nested Update'));
      expect(updatedUser2.profile.age, equals(25)); // preserved from original
    });
  });
}
