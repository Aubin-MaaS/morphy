import 'package:zikzak_morphy_annotation/morphy_annotation.dart';
import 'package:test/test.dart';

part 'withPatch_morphy_types_advanced.morphy.dart';
part 'withPatch_morphy_types_advanced.g.dart';

@Morphy(generateJson: true)
abstract class $CustomerProfile {
  String get name;
  int get age;
}

@Morphy(generateJson: true)
abstract class $Entity {
  String? get code;
  String? get name;
  String? get id;
}

@Morphy(nonSealed: true, generateJson: true)
abstract class $$Participant implements $Entity {}

@Morphy(generateJson: true)
abstract class $Actor implements $$Participant {}

@Morphy(generateJson: true, explicitSubTypes: [$AdvancedCustomer, $Gamer])
abstract class $AdvancedUser implements $Actor {
  String get email;
}

@Morphy(generateJson: true)
abstract class $Gamer implements $AdvancedUser {
  List<String>? get games;
}

@Morphy(generateJson: true)
abstract class $AdvancedCustomer implements $AdvancedUser {
  $CustomerProfile? get profile;
}

main() {
  group('withPatch method generation for advanced Morphy types', () {
    test('should generate withProfilePatch method using field name', () {
      // Create a CustomerProfile patch
      CustomerProfilePatch customerProfilePatch = CustomerProfilePatch.create()
        ..withName('Advanced Customer')
        ..withAge(45);

      // Create an AdvancedCustomer patch using withProfilePatch method
      AdvancedCustomerPatch advancedCustomerPatch =
          AdvancedCustomerPatch.create()
            ..withEmail('advanced@example.com')
            ..withProfilePatch(customerProfilePatch);

      // Verify the patch objects contain expected data
      final advancedCustomerPatchMap = advancedCustomerPatch.toPatch();

      expect(
        advancedCustomerPatchMap[AdvancedCustomer$.email],
        equals('advanced@example.com'),
      );
      expect(
        advancedCustomerPatchMap[AdvancedCustomer$.profile],
        equals(customerProfilePatch),
      );
    });

    test('should generate withProfilePatchFunc method', () {
      // Create an AdvancedCustomer patch using function-based patch method
      AdvancedCustomerPatch advancedCustomerPatch =
          AdvancedCustomerPatch.create()
            ..withEmail('functional@example.com')
            ..withProfilePatchFunc(
              (patch) => patch
                ..withName('Functional Customer')
                ..withAge(50),
            );

      // Verify the patch objects contain expected data
      final advancedCustomerPatchMap = advancedCustomerPatch.toPatch();

      expect(
        advancedCustomerPatchMap[AdvancedCustomer$.email],
        equals('functional@example.com'),
      );
      expect(
        advancedCustomerPatchMap[AdvancedCustomer$.profile],
        isA<CustomerProfilePatch>(),
      );

      final customerProfilePatch =
          advancedCustomerPatchMap[AdvancedCustomer$.profile]
              as CustomerProfilePatch;
      final customerProfilePatchMap = customerProfilePatch.toPatch();
      expect(
        customerProfilePatchMap[CustomerProfile$.name],
        equals('Functional Customer'),
      );
      expect(customerProfilePatchMap[CustomerProfile$.age], equals(50));
    });

    test('should apply nested patches correctly with profile field', () {
      // Create initial objects
      final initialCustomerProfile = CustomerProfile(
        name: 'Initial Customer',
        age: 30,
      );
      final initialAdvancedCustomer = AdvancedCustomer(
        email: 'initial@example.com',
        code: 'CODE123',
        name: 'Initial Name',
        id: 'ID123',
        profile: initialCustomerProfile,
      );

      // Create patches with withProfilePatch method
      CustomerProfilePatch customerProfilePatch = CustomerProfilePatch.create()
        ..withName('Updated Customer')
        ..withAge(35);

      AdvancedCustomerPatch advancedCustomerPatch =
          AdvancedCustomerPatch.create()
            ..withEmail('updated@example.com')
            ..withProfilePatch(customerProfilePatch);

      // Apply the patch
      final updatedAdvancedCustomer = advancedCustomerPatch.applyTo(
        initialAdvancedCustomer,
      );

      // Verify the nested updates worked
      expect(updatedAdvancedCustomer.email, equals('updated@example.com'));
      expect(updatedAdvancedCustomer.profile?.name, equals('Updated Customer'));
      expect(updatedAdvancedCustomer.profile?.age, equals(35));
    });
  });
}
