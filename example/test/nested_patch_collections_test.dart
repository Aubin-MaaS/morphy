import 'package:zikzak_morphy_annotation/morphy_annotation.dart';
import 'package:test/test.dart';

part 'nested_patch_collections_test.morphy.dart';

@morphy
abstract class $Address {
  String get street;
  String get city;
  String get zipCode;
}

@morphy
abstract class $Contact {
  String get email;
  String? get phone;
}

@morphy
abstract class $Store {
  String get name;
  $Address get address;
  $Contact get contact;
}

@morphy
abstract class $Customer {
  String get name;
  List<$Store> get favoriteStores;
  Map<String, $Contact> get contacts;
  $Address? get homeAddress;
}

main() {
  group('Nested patch functionality with collections', () {
    late Customer testCustomer;
    late Address store1Address;
    late Address store2Address;
    late Store store1;
    late Store store2;
    late Contact primaryContact;
    late Contact workContact;
    late Address homeAddress;

    setUp(() {
      // Set up test data
      store1Address = Address(
        street: '123 Main St',
        city: 'Downtown',
        zipCode: '12345',
      );

      store2Address = Address(
        street: '456 Oak Ave',
        city: 'Uptown',
        zipCode: '67890',
      );

      store1 = Store(
        name: 'Main Store',
        address: store1Address,
        contact: Contact(email: 'main@store.com', phone: '555-0001'),
      );

      store2 = Store(
        name: 'Branch Store',
        address: store2Address,
        contact: Contact(email: 'branch@store.com', phone: '555-0002'),
      );

      primaryContact = Contact(email: 'primary@example.com', phone: '555-1001');
      workContact = Contact(email: 'work@example.com', phone: '555-1002');

      homeAddress = Address(
        street: '789 Home Ln',
        city: 'Residential',
        zipCode: '11111',
      );

      testCustomer = Customer(
        name: 'John Doe',
        favoriteStores: [store1, store2],
        contacts: {'primary': primaryContact, 'work': workContact},
        homeAddress: homeAddress,
      );
    });

    test('should generate updateFavoriteStoresAt method for List patching', () {
      // Verify the method exists and works
      CustomerPatch patch = CustomerPatch.create()
        ..updateFavoriteStoresAt(
          0,
          (storePatch) => storePatch
            ..withName('Updated Main Store')
            ..withAddressPatchFunc(
              (addrPatch) => addrPatch..withStreet('123 Updated Main St'),
            ),
        );

      final updatedCustomer = patch.applyTo(testCustomer);

      // Verify the nested updates in the list
      expect(updatedCustomer.name, equals('John Doe')); // unchanged
      expect(updatedCustomer.favoriteStores.length, equals(2)); // same length
      expect(
        updatedCustomer.favoriteStores[0].name,
        equals('Updated Main Store'),
      ); // changed
      expect(
        updatedCustomer.favoriteStores[0].address.street,
        equals('123 Updated Main St'),
      ); // nested change
      expect(
        updatedCustomer.favoriteStores[0].address.city,
        equals('Downtown'),
      ); // unchanged
      expect(
        updatedCustomer.favoriteStores[1].name,
        equals('Branch Store'),
      ); // other item unchanged
    });

    test('should generate updateContactsValue method for Map patching', () {
      // Verify the method exists and works
      CustomerPatch patch = CustomerPatch.create()
        ..updateContactsValue(
          'primary',
          (contactPatch) => contactPatch
            ..withEmail('updated.primary@example.com')
            ..withPhone('555-9999'),
        );

      final updatedCustomer = patch.applyTo(testCustomer);

      // Verify the nested updates in the map
      expect(updatedCustomer.name, equals('John Doe')); // unchanged
      expect(updatedCustomer.contacts.length, equals(2)); // same length
      expect(
        updatedCustomer.contacts['primary']!.email,
        equals('updated.primary@example.com'),
      ); // changed
      expect(
        updatedCustomer.contacts['primary']!.phone,
        equals('555-9999'),
      ); // changed
      expect(
        updatedCustomer.contacts['work']!.email,
        equals('work@example.com'),
      ); // other item unchanged
    });

    test('should handle nested object patching with function approach', () {
      CustomerPatch patch = CustomerPatch.create()
        ..withName('Jane Doe')
        ..withHomeAddressPatchFunc(
          (addrPatch) => addrPatch
            ..withStreet('999 New Home St')
            ..withCity('New City'),
        );

      final updatedCustomer = patch.applyTo(testCustomer);

      expect(updatedCustomer.name, equals('Jane Doe')); // changed
      expect(
        updatedCustomer.homeAddress!.street,
        equals('999 New Home St'),
      ); // nested change
      expect(
        updatedCustomer.homeAddress!.city,
        equals('New City'),
      ); // nested change
      expect(
        updatedCustomer.homeAddress!.zipCode,
        equals('11111'),
      ); // unchanged
    });

    test('should handle complex multi-level nested patching', () {
      CustomerPatch patch = CustomerPatch.create()
        ..withName('Complex Update Customer')
        ..updateFavoriteStoresAt(
          1,
          (storePatch) => storePatch
            ..withName('Completely New Branch')
            ..withContactPatchFunc(
              (contactPatch) => contactPatch..withEmail('new.branch@store.com'),
            )
            ..withAddressPatchFunc(
              (addrPatch) => addrPatch
                ..withStreet('999 New Branch St')
                ..withZipCode('99999'),
            ),
        )
        ..updateContactsValue(
          'work',
          (contactPatch) => contactPatch..withEmail('new.work@company.com'),
        );

      final updatedCustomer = patch.applyTo(testCustomer);

      // Verify customer level change
      expect(updatedCustomer.name, equals('Complex Update Customer'));

      // Verify store list nested changes
      expect(
        updatedCustomer.favoriteStores[1].name,
        equals('Completely New Branch'),
      );
      expect(
        updatedCustomer.favoriteStores[1].contact.email,
        equals('new.branch@store.com'),
      );
      expect(
        updatedCustomer.favoriteStores[1].contact.phone,
        equals('555-0002'),
      ); // unchanged
      expect(
        updatedCustomer.favoriteStores[1].address.street,
        equals('999 New Branch St'),
      );
      expect(
        updatedCustomer.favoriteStores[1].address.city,
        equals('Uptown'),
      ); // unchanged
      expect(
        updatedCustomer.favoriteStores[1].address.zipCode,
        equals('99999'),
      );

      // Verify other store unchanged
      expect(updatedCustomer.favoriteStores[0].name, equals('Main Store'));

      // Verify contacts map nested changes
      expect(
        updatedCustomer.contacts['work']!.email,
        equals('new.work@company.com'),
      );
      expect(
        updatedCustomer.contacts['work']!.phone,
        equals('555-1002'),
      ); // unchanged
      expect(
        updatedCustomer.contacts['primary']!.email,
        equals('primary@example.com'),
      ); // unchanged
    });

    test('should handle edge cases gracefully', () {
      // Test updating out-of-bounds list index
      CustomerPatch patch1 = CustomerPatch.create()
        ..updateFavoriteStoresAt(
          999,
          (storePatch) => storePatch..withName('Should Not Apply'),
        );

      final updatedCustomer1 = patch1.applyTo(testCustomer);
      // Should remain unchanged
      expect(updatedCustomer1.favoriteStores[0].name, equals('Main Store'));
      expect(updatedCustomer1.favoriteStores[1].name, equals('Branch Store'));

      // Test updating non-existent map key
      CustomerPatch patch2 = CustomerPatch.create()
        ..updateContactsValue(
          'nonexistent',
          (contactPatch) =>
              contactPatch..withEmail('should.not.apply@example.com'),
        );

      final updatedCustomer2 = patch2.applyTo(testCustomer);
      // Should remain unchanged
      expect(updatedCustomer2.contacts.length, equals(2));
      expect(
        updatedCustomer2.contacts['primary']!.email,
        equals('primary@example.com'),
      );
      expect(
        updatedCustomer2.contacts['work']!.email,
        equals('work@example.com'),
      );
    });

    test('should work with partial collection updates', () {
      // Update only one field in a nested object within a collection
      CustomerPatch patch = CustomerPatch.create()
        ..updateFavoriteStoresAt(
          0,
          (storePatch) => storePatch
            ..withAddressPatchFunc(
              (addrPatch) => addrPatch..withCity('New Downtown'),
            ),
        );

      final updatedCustomer = patch.applyTo(testCustomer);

      // Only the city should change, everything else should remain the same
      expect(
        updatedCustomer.favoriteStores[0].name,
        equals('Main Store'),
      ); // unchanged
      expect(
        updatedCustomer.favoriteStores[0].address.street,
        equals('123 Main St'),
      ); // unchanged
      expect(
        updatedCustomer.favoriteStores[0].address.city,
        equals('New Downtown'),
      ); // changed
      expect(
        updatedCustomer.favoriteStores[0].address.zipCode,
        equals('12345'),
      ); // unchanged
      expect(
        updatedCustomer.favoriteStores[0].contact.email,
        equals('main@store.com'),
      ); // unchanged
    });

    test('should combine direct and nested patching approaches', () {
      // Mix direct replacement with nested patching
      final newContact = Contact(
        email: 'brand.new@example.com',
        phone: '555-7777',
      );

      CustomerPatch patch = CustomerPatch.create()
        ..withContacts({
          'newKey': newContact,
        }) // Direct replacement of entire map
        ..withHomeAddressPatchFunc(
          (addrPatch) =>
              addrPatch // Nested patching
                ..withStreet('Mixed Approach Street'),
        );

      final updatedCustomer = patch.applyTo(testCustomer);

      // Contacts should be completely replaced
      expect(updatedCustomer.contacts.length, equals(1));
      expect(
        updatedCustomer.contacts['newKey']!.email,
        equals('brand.new@example.com'),
      );

      // Home address should be nested-patched
      expect(
        updatedCustomer.homeAddress!.street,
        equals('Mixed Approach Street'),
      );
      expect(
        updatedCustomer.homeAddress!.city,
        equals('Residential'),
      ); // preserved
      expect(
        updatedCustomer.homeAddress!.zipCode,
        equals('11111'),
      ); // preserved
    });
  });
}
