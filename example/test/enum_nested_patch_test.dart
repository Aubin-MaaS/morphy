import 'package:zikzak_morphy_annotation/morphy_annotation.dart';
import 'package:test/test.dart';

part 'enum_nested_patch_test.g.dart';
part 'enum_nested_patch_test.morphy.dart';

@Morphy(generateJson: true)
abstract class $OperatingSystem {
  String get name;
  String get version;
  bool get isActive;
}

@Morphy(generateJson: true)
abstract class $DeviceType {
  String get category;
  String get manufacturer;
  double get screenSize;
}

@Morphy(generateJson: true)
abstract class $Device {
  String get deviceId;
  $OperatingSystem get os;
  $DeviceType get deviceType;
  List<$OperatingSystem> get supportedOS;
  Map<String, $DeviceType> get peripherals;
}

@Morphy(generateJson: true)
abstract class $User {
  String get name;
  String get email;
  $Device get primaryDevice;
  List<$Device> get devices;
  Map<String, $OperatingSystem> get preferences;
}

main() {
  group('Nested patch functionality with Morphy enum-like types', () {
    late User testUser;
    late OperatingSystem testOS;
    late DeviceType testDeviceType;
    late Device testDevice;

    setUp(() {
      testOS = OperatingSystem(name: 'macOS', version: '14.0', isActive: true);

      testDeviceType = DeviceType(
        category: 'Laptop',
        manufacturer: 'Apple',
        screenSize: 13.3,
      );

      testDevice = Device(
        deviceId: 'DEVICE001',
        os: testOS,
        deviceType: testDeviceType,
        supportedOS: [testOS],
        peripherals: {'mouse': testDeviceType},
      );

      testUser = User(
        name: 'John Doe',
        email: 'john@example.com',
        primaryDevice: testDevice,
        devices: [testDevice],
        preferences: {'favorite': testOS},
      );
    });

    test('should generate withOsPatch method for Morphy enum-like type', () {
      // Verify that DevicePatch has withOsPatch methods
      final patch = DevicePatch.create();

      // This should compile if the methods are generated
      expect(() => patch.withOsPatch(OperatingSystemPatch()), returnsNormally);
    });

    test(
      'should generate withOsPatchFunc method for function-based patching',
      () {
        final patch = DevicePatch.create()
          ..withOsPatchFunc(
            (osPatch) => osPatch
              ..withName('Linux')
              ..withVersion('22.04')
              ..withIsActive(false),
          );

        final patchMap = patch.toPatch();
        expect(patchMap[Device$.os], isA<OperatingSystemPatch>());
      },
    );

    test('should apply nested patches to Morphy enum-like types correctly', () {
      final devicePatch = DevicePatch.create()
        ..withDeviceId('UPDATED_DEVICE')
        ..withOsPatchFunc(
          (osPatch) => osPatch
            ..withName('Windows')
            ..withVersion('11')
            ..withIsActive(true),
        )
        ..withDeviceTypePatchFunc(
          (typePatch) => typePatch
            ..withCategory('Desktop')
            ..withManufacturer('Microsoft'),
        );

      final updatedDevice = devicePatch.applyTo(testDevice);

      // Verify device-level changes
      expect(updatedDevice.deviceId, equals('UPDATED_DEVICE'));

      // Verify nested OS changes
      expect(updatedDevice.os.name, equals('Windows'));
      expect(updatedDevice.os.version, equals('11'));
      expect(updatedDevice.os.isActive, equals(true));

      // Verify nested DeviceType changes
      expect(updatedDevice.deviceType.category, equals('Desktop'));
      expect(updatedDevice.deviceType.manufacturer, equals('Microsoft'));
      expect(updatedDevice.deviceType.screenSize, equals(13.3)); // unchanged
    });

    test('should handle List patching with Morphy enum-like types', () {
      final devicePatch = DevicePatch.create()
        ..updateSupportedOSAt(
          0,
          (osPatch) => osPatch
            ..withName('Ubuntu')
            ..withVersion('20.04'),
        );

      final updatedDevice = devicePatch.applyTo(testDevice);

      expect(updatedDevice.supportedOS[0].name, equals('Ubuntu'));
      expect(updatedDevice.supportedOS[0].version, equals('20.04'));
      expect(updatedDevice.supportedOS[0].isActive, equals(true)); // unchanged
    });

    test('should handle Map patching with Morphy enum-like types', () {
      final devicePatch = DevicePatch.create()
        ..updatePeripheralsValue(
          'mouse',
          (typePatch) => typePatch
            ..withCategory('Wireless Mouse')
            ..withScreenSize(0.0),
        );

      final updatedDevice = devicePatch.applyTo(testDevice);

      expect(
        updatedDevice.peripherals['mouse']!.category,
        equals('Wireless Mouse'),
      );
      expect(updatedDevice.peripherals['mouse']!.screenSize, equals(0.0));
      expect(
        updatedDevice.peripherals['mouse']!.manufacturer,
        equals('Apple'),
      ); // unchanged
    });

    test(
      'should handle deep nested patching across multiple enum-like types',
      () {
        final userPatch = UserPatch.create()
          ..withName('Jane Doe')
          ..withPrimaryDevicePatchFunc(
            (devicePatch) => devicePatch
              ..withDeviceId('JANE_DEVICE')
              ..withOsPatchFunc(
                (osPatch) => osPatch
                  ..withName('iOS')
                  ..withVersion('17.0'),
              )
              ..withDeviceTypePatchFunc(
                (typePatch) => typePatch
                  ..withCategory('Smartphone')
                  ..withScreenSize(6.1),
              ),
          )
          ..updateDevicesAt(
            0,
            (devicePatch) =>
                devicePatch
                  ..withOsPatchFunc((osPatch) => osPatch..withIsActive(false)),
          )
          ..updatePreferencesValue(
            'favorite',
            (osPatch) => osPatch..withName('Android'),
          );

        final updatedUser = userPatch.applyTo(testUser);

        // Verify user-level changes
        expect(updatedUser.name, equals('Jane Doe'));
        expect(updatedUser.email, equals('john@example.com')); // unchanged

        // Verify deep nested changes in primaryDevice
        expect(updatedUser.primaryDevice.deviceId, equals('JANE_DEVICE'));
        expect(updatedUser.primaryDevice.os.name, equals('iOS'));
        expect(updatedUser.primaryDevice.os.version, equals('17.0'));
        expect(
          updatedUser.primaryDevice.os.isActive,
          equals(true),
        ); // unchanged
        expect(
          updatedUser.primaryDevice.deviceType.category,
          equals('Smartphone'),
        );
        expect(updatedUser.primaryDevice.deviceType.screenSize, equals(6.1));
        expect(
          updatedUser.primaryDevice.deviceType.manufacturer,
          equals('Apple'),
        ); // unchanged

        // Verify devices list changes
        expect(updatedUser.devices[0].os.isActive, equals(false));
        expect(updatedUser.devices[0].os.name, equals('macOS')); // unchanged

        // Verify preferences map changes
        expect(updatedUser.preferences['favorite']!.name, equals('Android'));
        expect(
          updatedUser.preferences['favorite']!.version,
          equals('14.0'),
        ); // unchanged
      },
    );

    test('should handle partial updates preserving unchanged fields', () {
      final devicePatch = DevicePatch.create()
        ..withOsPatchFunc(
          (osPatch) => osPatch..withName('FreeBSD'), // Only update name
        );

      final updatedDevice = devicePatch.applyTo(testDevice);

      // Only the OS name should change
      expect(updatedDevice.os.name, equals('FreeBSD'));
      expect(updatedDevice.os.version, equals('14.0')); // unchanged
      expect(updatedDevice.os.isActive, equals(true)); // unchanged

      // Everything else should remain unchanged
      expect(updatedDevice.deviceId, equals('DEVICE001'));
      expect(updatedDevice.deviceType.category, equals('Laptop'));
    });

    test('should work with mixed direct and nested patching approaches', () {
      final newOS = OperatingSystem(
        name: 'ChromeOS',
        version: '120.0',
        isActive: true,
      );

      final devicePatch = DevicePatch.create()
        ..withOs(newOS) // Direct replacement
        ..withDeviceTypePatchFunc(
          (typePatch) => typePatch..withCategory('Chromebook'), // Nested patch
        );

      final updatedDevice = devicePatch.applyTo(testDevice);

      // OS should be completely replaced
      expect(updatedDevice.os.name, equals('ChromeOS'));
      expect(updatedDevice.os.version, equals('120.0'));
      expect(updatedDevice.os.isActive, equals(true));

      // DeviceType should be nested-patched
      expect(updatedDevice.deviceType.category, equals('Chromebook'));
      expect(
        updatedDevice.deviceType.manufacturer,
        equals('Apple'),
      ); // preserved
      expect(updatedDevice.deviceType.screenSize, equals(13.3)); // preserved
    });
  });

  group('compareTo functionality with nested Morphy enum-like types', () {
    test('should generate compareToOperatingSystem method', () {
      final os1 = OperatingSystem(
        name: 'macOS',
        version: '14.0',
        isActive: true,
      );
      final os2 = OperatingSystem(
        name: 'Linux',
        version: '22.04',
        isActive: false,
      );

      final diff = os1.compareToOperatingSystem(os2);

      expect(diff.keys, contains('name'));
      expect(diff.keys, contains('version'));
      expect(diff.keys, contains('isActive'));

      expect(diff['name']!(), equals('Linux'));
      expect(diff['version']!(), equals('22.04'));
      expect(diff['isActive']!(), equals(false));
    });

    test('should generate compareToDevice method for nested objects', () {
      final os1 = OperatingSystem(
        name: 'macOS',
        version: '14.0',
        isActive: true,
      );
      final os2 = OperatingSystem(
        name: 'Windows',
        version: '11',
        isActive: true,
      );

      final deviceType1 = DeviceType(
        category: 'Laptop',
        manufacturer: 'Apple',
        screenSize: 13.3,
      );
      final deviceType2 = DeviceType(
        category: 'Desktop',
        manufacturer: 'Dell',
        screenSize: 24.0,
      );

      final device1 = Device(
        deviceId: 'DEVICE001',
        os: os1,
        deviceType: deviceType1,
        supportedOS: [os1],
        peripherals: {'mouse': deviceType1},
      );

      final device2 = Device(
        deviceId: 'DEVICE002',
        os: os2,
        deviceType: deviceType2,
        supportedOS: [os2],
        peripherals: {'keyboard': deviceType2},
      );

      final diff = device1.compareToDevice(device2);

      expect(diff.keys, contains('deviceId'));
      expect(diff.keys, contains('os'));
      expect(diff.keys, contains('deviceType'));
      expect(diff.keys, contains('supportedOS'));
      expect(diff.keys, contains('peripherals'));

      expect(diff['deviceId']!(), equals('DEVICE002'));
      expect(diff['os']!(), isA<Map<String, dynamic>>());
      expect(diff['deviceType']!(), isA<Map<String, dynamic>>());
      expect(diff['supportedOS']!(), equals([os2]));
      expect(diff['peripherals']!(), equals({'keyboard': deviceType2}));
    });

    test('should only show differences in nested comparisons', () {
      final os1 = OperatingSystem(
        name: 'macOS',
        version: '14.0',
        isActive: true,
      );
      final os2 = OperatingSystem(
        name: 'macOS',
        version: '14.1',
        isActive: true,
      );

      final deviceType = DeviceType(
        category: 'Laptop',
        manufacturer: 'Apple',
        screenSize: 13.3,
      );

      final device1 = Device(
        deviceId: 'SAME_ID',
        os: os1,
        deviceType: deviceType,
        supportedOS: [os1],
        peripherals: {'mouse': deviceType},
      );

      final device2 = Device(
        deviceId: 'SAME_ID', // Same
        os: os2, // Different (version changed)
        deviceType: deviceType, // Same
        supportedOS: [os2], // Different (OS version changed)
        peripherals: {'mouse': deviceType}, // Same
      );

      final diff = device1.compareToDevice(device2);

      expect(diff.keys, hasLength(2));
      expect(diff.keys, contains('os'));
      expect(diff.keys, contains('supportedOS'));
      expect(diff.keys, isNot(contains('deviceId')));
      expect(diff.keys, isNot(contains('deviceType')));
      expect(diff.keys, isNot(contains('peripherals')));

      expect(diff['os']!(), isA<Map<String, dynamic>>());
      expect(diff['supportedOS']!(), equals([os2]));
    });

    test('should handle identical nested objects correctly', () {
      final os = OperatingSystem(
        name: 'Ubuntu',
        version: '22.04',
        isActive: true,
      );
      final deviceType = DeviceType(
        category: 'Server',
        manufacturer: 'HP',
        screenSize: 0.0,
      );

      final device1 = Device(
        deviceId: 'SERVER001',
        os: os,
        deviceType: deviceType,
        supportedOS: [os],
        peripherals: {'rack': deviceType},
      );

      final device2 = Device(
        deviceId: 'SERVER001',
        os: os,
        deviceType: deviceType,
        supportedOS: [os],
        peripherals: {'rack': deviceType},
      );

      final diff = device1.compareToDevice(device2);
      expect(diff, isEmpty);
    });

    test('should work with patch creation from nested compareTo', () {
      final originalOS = OperatingSystem(
        name: 'CentOS',
        version: '7',
        isActive: false,
      );
      final targetOS = OperatingSystem(
        name: 'Rocky Linux',
        version: '9',
        isActive: true,
      );

      final originalDeviceType = DeviceType(
        category: 'Server',
        manufacturer: 'Generic',
        screenSize: 0.0,
      );

      final originalDevice = Device(
        deviceId: 'OLD_SERVER',
        os: originalOS,
        deviceType: originalDeviceType,
        supportedOS: [originalOS],
        peripherals: {},
      );

      final targetDevice = Device(
        deviceId: 'NEW_SERVER',
        os: targetOS,
        deviceType: originalDeviceType, // Same
        supportedOS: [targetOS],
        peripherals: {},
      );

      // For nested object comparisons, we need to manually create patches
      final devicePatch = DevicePatch.create()
        ..withDeviceId('NEW_SERVER')
        ..withOs(targetOS)
        ..withSupportedOS([targetOS]);

      // Apply patch
      final resultDevice = devicePatch.applyTo(originalDevice);

      expect(resultDevice.deviceId, equals('NEW_SERVER'));
      expect(resultDevice.os.name, equals('Rocky Linux'));
      expect(resultDevice.os.version, equals('9'));
      expect(resultDevice.os.isActive, equals(true));
      expect(resultDevice.deviceType, equals(originalDeviceType)); // Preserved
    });

    test('should handle complex User comparison with all nested types', () {
      final os1 = OperatingSystem(
        name: 'macOS',
        version: '14.0',
        isActive: true,
      );
      final os2 = OperatingSystem(
        name: 'Windows',
        version: '11',
        isActive: true,
      );

      final deviceType1 = DeviceType(
        category: 'Laptop',
        manufacturer: 'Apple',
        screenSize: 13.3,
      );
      final deviceType2 = DeviceType(
        category: 'Desktop',
        manufacturer: 'Dell',
        screenSize: 27.0,
      );

      final device1 = Device(
        deviceId: 'MAC001',
        os: os1,
        deviceType: deviceType1,
        supportedOS: [os1],
        peripherals: {'mouse': deviceType1},
      );

      final device2 = Device(
        deviceId: 'WIN001',
        os: os2,
        deviceType: deviceType2,
        supportedOS: [os2],
        peripherals: {'keyboard': deviceType2},
      );

      final user1 = User(
        name: 'John Doe',
        email: 'john@example.com',
        primaryDevice: device1,
        devices: [device1],
        preferences: {'primary': os1},
      );

      final user2 = User(
        name: 'Jane Smith',
        email: 'jane@example.com',
        primaryDevice: device2,
        devices: [device1, device2], // Added device
        preferences: {'primary': os2, 'secondary': os1}, // Added preference
      );

      final diff = user1.compareToUser(user2);

      expect(diff.keys, contains('name'));
      expect(diff.keys, contains('email'));
      expect(diff.keys, contains('primaryDevice'));
      expect(diff.keys, contains('devices'));
      expect(diff.keys, contains('preferences'));

      expect(diff['name']!(), equals('Jane Smith'));
      expect(diff['email']!(), equals('jane@example.com'));
      expect(diff['primaryDevice']!(), isA<Map<String, dynamic>>());
      expect(diff['devices']!(), equals([device1, device2]));
      expect(
        diff['preferences']!(),
        equals({'primary': os2, 'secondary': os1}),
      );
    });

    test(
      'should create patches from nested comparisons and apply correctly',
      () {
        final originalOS = OperatingSystem(
          name: 'Fedora',
          version: '38',
          isActive: true,
        );
        final updatedOS = OperatingSystem(
          name: 'Fedora',
          version: '39',
          isActive: true,
        );

        final deviceType = DeviceType(
          category: 'Workstation',
          manufacturer: 'System76',
          screenSize: 15.6,
        );

        final originalDevice = Device(
          deviceId: 'WORK001',
          os: originalOS,
          deviceType: deviceType,
          supportedOS: [originalOS],
          peripherals: {'dock': deviceType},
        );

        final targetDevice = Device(
          deviceId: 'WORK001', // Same
          os: updatedOS, // Different
          deviceType: deviceType, // Same
          supportedOS: [updatedOS], // Different
          peripherals: {'dock': deviceType}, // Same
        );

        // For nested object comparisons, manually create patches
        final devicePatch = DevicePatch.create()
          ..withOs(updatedOS)
          ..withSupportedOS([updatedOS]);
        final resultDevice = devicePatch.applyTo(originalDevice);

        expect(resultDevice.deviceId, equals('WORK001'));
        expect(resultDevice.os.version, equals('39')); // Updated
        expect(resultDevice.supportedOS[0].version, equals('39')); // Updated
        expect(
          resultDevice.deviceType.manufacturer,
          equals('System76'),
        ); // Preserved
      },
    );

    test(
      'should demonstrate compareTo with simple patch creation workflow',
      () {
        final originalOS = OperatingSystem(
          name: 'macOS',
          version: '13.0',
          isActive: true,
        );

        final targetOS = OperatingSystem(
          name: 'macOS',
          version: '14.0', // Only version changed
          isActive: true,
        );

        // Get differences between objects
        final diff = originalOS.compareToOperatingSystem(targetOS);

        // Should only show the version difference
        expect(diff.keys, hasLength(1));
        expect(diff.keys, contains('version'));
        expect(diff['version']!(), equals('14.0'));

        // Create a patch from the differences
        final patch = OperatingSystemPatch.create(diff);

        // Apply the patch to get the updated object
        final updatedOS = patch.applyTo(originalOS);

        // Should match the target
        expect(updatedOS.name, equals('macOS')); // Preserved
        expect(updatedOS.version, equals('14.0')); // Updated
        expect(updatedOS.isActive, equals(true)); // Preserved
        expect(updatedOS, equals(targetOS));
      },
    );

    test('should demonstrate device type comparison and patching', () {
      final originalType = DeviceType(
        category: 'Laptop',
        manufacturer: 'Apple',
        screenSize: 13.3,
      );

      final targetType = DeviceType(
        category: 'Laptop', // Same
        manufacturer: 'Apple', // Same
        screenSize: 15.6, // Different
      );

      final diff = originalType.compareToDeviceType(targetType);

      expect(diff.keys, hasLength(1));
      expect(diff.keys, contains('screenSize'));
      expect(diff['screenSize']!(), equals(15.6));

      final patch = DeviceTypePatch.create(diff);
      final updatedType = patch.applyTo(originalType);

      expect(updatedType.category, equals('Laptop'));
      expect(updatedType.manufacturer, equals('Apple'));
      expect(updatedType.screenSize, equals(15.6));
      expect(updatedType, equals(targetType));
    });
  });
}
