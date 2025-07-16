import 'package:zikzak_morphy_annotation/morphy_annotation.dart';
import 'package:test/test.dart';
import 'cross_file_user.dart';

part 'cross_file_customer_profile.g.dart';
part 'cross_file_customer_profile.morphy.dart';

@Morphy(generateJson: true)
abstract class $CustomerProfile {
  // Basic Demographics
  int? get yearOfBirth;
  String? get occupation;
  String? get operatingSystem;
}

@Morphy(generateJson: true)
abstract class $Customer implements $User {
  $CustomerProfile? get profile;
  List<$CustomerProfile> get profiles;
  Map<String, $CustomerProfile> get profileHistory;
}

main() {
  group('Cross-file nested patch functionality', () {
    late Customer testCustomer;
    late CustomerProfile testProfile;

    setUp(() {
      testProfile = CustomerProfile(
        yearOfBirth: 1990,
        occupation: 'Engineer',
        operatingSystem: 'macOS',
      );

      testCustomer = Customer(
        name: 'John Doe',
        email: 'john@example.com',
        profile: testProfile,
        profiles: [testProfile],
        profileHistory: {'current': testProfile},
      );
    });

    test(
      'should generate withProfilePatch method for cross-file Morphy type',
      () {
        // Verify that CustomerPatch has withProfilePatch methods
        final patch = CustomerPatch.create();

        // This should compile if the methods are generated
        expect(
          () => patch.withProfilePatch(CustomerProfilePatch()),
          returnsNormally,
        );
      },
    );

    test(
      'should generate withProfilePatchFunc method for function-based patching',
      () {
        final patch = CustomerPatch.create()
          ..withProfilePatchFunc(
            (profilePatch) => profilePatch
              ..withYearOfBirth(1985)
              ..withOccupation('Senior Engineer'),
          );

        final patchMap = patch.toPatch();
        expect(patchMap[Customer$.profile], isA<CustomerProfilePatch>());
      },
    );

    test('should apply cross-file nested patches correctly', () {
      final customerPatch = CustomerPatch.create()
        ..withName('Jane Doe')
        ..withProfilePatchFunc(
          (profilePatch) => profilePatch
            ..withYearOfBirth(1985)
            ..withOccupation('Senior Engineer')
            ..withOperatingSystem('Linux'),
        );

      final updatedCustomer = customerPatch.applyTo(testCustomer);

      // Verify customer-level changes
      expect(updatedCustomer.name, equals('Jane Doe'));
      expect(updatedCustomer.email, equals('john@example.com')); // unchanged

      // Verify nested profile changes
      expect(updatedCustomer.profile!.yearOfBirth, equals(1985));
      expect(updatedCustomer.profile!.occupation, equals('Senior Engineer'));
      expect(updatedCustomer.profile!.operatingSystem, equals('Linux'));
    });

    test('should handle List patching across files', () {
      final customerPatch = CustomerPatch.create()
        ..updateProfilesAt(
          0,
          (profilePatch) => profilePatch..withOccupation('Updated Engineer'),
        );

      final updatedCustomer = customerPatch.applyTo(testCustomer);

      expect(
        updatedCustomer.profiles[0].occupation,
        equals('Updated Engineer'),
      );
      expect(
        updatedCustomer.profiles[0].yearOfBirth,
        equals(1990),
      ); // unchanged
    });

    test('should handle Map patching across files', () {
      final customerPatch = CustomerPatch.create()
        ..updateProfileHistoryValue(
          'current',
          (profilePatch) => profilePatch..withOperatingSystem('Windows'),
        );

      final updatedCustomer = customerPatch.applyTo(testCustomer);

      expect(
        updatedCustomer.profileHistory['current']!.operatingSystem,
        equals('Windows'),
      );
      expect(
        updatedCustomer.profileHistory['current']!.yearOfBirth,
        equals(1990),
      ); // unchanged
    });

    test('should handle partial cross-file nested updates', () {
      final customerPatch = CustomerPatch.create()
        ..withProfilePatchFunc(
          (profilePatch) => profilePatch..withYearOfBirth(1995),
        ); // Only update year, leave other fields

      final updatedCustomer = customerPatch.applyTo(testCustomer);

      expect(updatedCustomer.profile!.yearOfBirth, equals(1995)); // changed
      expect(
        updatedCustomer.profile!.occupation,
        equals('Engineer'),
      ); // unchanged
      expect(
        updatedCustomer.profile!.operatingSystem,
        equals('macOS'),
      ); // unchanged
    });

    test('should work with complex cross-file multi-level patching', () {
      final customerPatch = CustomerPatch.create()
        ..withName('Complex Update')
        ..withProfilePatchFunc(
          (profilePatch) => profilePatch..withOccupation('Architect'),
        )
        ..updateProfilesAt(
          0,
          (profilePatch) => profilePatch..withOperatingSystem('Ubuntu'),
        )
        ..updateProfileHistoryValue(
          'current',
          (profilePatch) => profilePatch..withYearOfBirth(1988),
        );

      final updatedCustomer = customerPatch.applyTo(testCustomer);

      // Verify all changes applied correctly
      expect(updatedCustomer.name, equals('Complex Update'));
      expect(updatedCustomer.profile!.occupation, equals('Architect'));
      expect(updatedCustomer.profiles[0].operatingSystem, equals('Ubuntu'));
      expect(
        updatedCustomer.profileHistory['current']!.yearOfBirth,
        equals(1988),
      );

      // Verify unchanged fields
      expect(updatedCustomer.email, equals('john@example.com'));
      expect(updatedCustomer.profile!.yearOfBirth, equals(1990));
      expect(updatedCustomer.profiles[0].yearOfBirth, equals(1990));
    });
  });
}
