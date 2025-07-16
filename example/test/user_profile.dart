import 'package:test/test.dart';
import 'package:zikzak_morphy_annotation/morphy_annotation.dart';

import 'age_group.dart';
import 'demographics.dart';
import 'generation.dart';
import 'income_level.dart';

part 'user_profile.morphy.dart';
part 'user_profile.g.dart';

@Morphy(generateJson: true)
abstract class $UserProfile {
  String get userId;
  String get name;
  $Demographics? get demographics;
  Map<String, $Demographics> get demographicsHistory;
  List<$Demographics> get savedProfiles;
}

main() {
  group('Demographics with cross-file regular enums', () {
    late Demographics testDemographics;
    late UserProfile testProfile;

    setUp(() {
      testDemographics = Demographics(
        ageGroup: AgeGroup.adult,
        generation: Generation.millennial,
        locations: ['New York', 'California'],
        incomeLevel: IncomeLevel.upperMiddle,
        lifestyle: ['urban', 'tech-savvy'],
      );

      testProfile = UserProfile(
        userId: 'USER123',
        name: 'John Doe',
        demographics: testDemographics,
        demographicsHistory: {'2023': testDemographics},
        savedProfiles: [testDemographics],
      );
    });

    test('should create Demographics with regular enum values', () {
      expect(testDemographics.ageGroup, equals(AgeGroup.adult));
      expect(testDemographics.generation, equals(Generation.millennial));
      expect(testDemographics.incomeLevel, equals(IncomeLevel.upperMiddle));
      expect(testDemographics.locations, equals(['New York', 'California']));
      expect(testDemographics.lifestyle, equals(['urban', 'tech-savvy']));
    });

    test('should support basic patch operations on enum fields', () {
      final patch = DemographicsPatch.create()
        ..withAgeGroup(AgeGroup.middleAge)
        ..withGeneration(Generation.genX)
        ..withIncomeLevel(IncomeLevel.high);

      final updatedDemographics = patch.applyTo(testDemographics);

      expect(updatedDemographics.ageGroup, equals(AgeGroup.middleAge));
      expect(updatedDemographics.generation, equals(Generation.genX));
      expect(updatedDemographics.incomeLevel, equals(IncomeLevel.high));
      expect(
        updatedDemographics.locations,
        equals(['New York', 'California']),
      ); // unchanged
      expect(
        updatedDemographics.lifestyle,
        equals(['urban', 'tech-savvy']),
      ); // unchanged
    });

    test('should NOT generate patch methods for regular enum fields', () {
      final patch = DemographicsPatch.create();

      // Regular with methods should exist
      expect(() => patch.withAgeGroup(AgeGroup.senior), returnsNormally);
      expect(() => patch.withGeneration(Generation.boomer), returnsNormally);
      expect(() => patch.withIncomeLevel(IncomeLevel.low), returnsNormally);

      // But patch methods should NOT exist for regular enums
      // These would cause compilation errors if they existed:
      // patch.withAgeGroupPatch(...) // Should not exist
      // patch.withGenerationPatch(...) // Should not exist
      // patch.withIncomeLevelPatch(...) // Should not exist

      // Verify regular enum updates work
      patch
        ..withAgeGroup(AgeGroup.teen)
        ..withGeneration(Generation.genZ);

      final patchMap = patch.toPatch();
      expect(patchMap[Demographics$.ageGroup], equals(AgeGroup.teen));
      expect(patchMap[Demographics$.generation], equals(Generation.genZ));
    });

    test('should handle JSON serialization with regular enums', () {
      final json = testDemographics.toJson();

      expect(json['ageGroup'], equals('adult'));
      expect(json['generation'], equals('millennial'));
      expect(json['incomeLevel'], equals('upperMiddle'));
      expect(json['locations'], equals(['New York', 'California']));
      expect(json['lifestyle'], equals(['urban', 'tech-savvy']));

      final fromJson = Demographics.fromJson(json);
      expect(fromJson, equals(testDemographics));
      expect(fromJson.ageGroup, equals(AgeGroup.adult));
      expect(fromJson.generation, equals(Generation.millennial));
      expect(fromJson.incomeLevel, equals(IncomeLevel.upperMiddle));
    });

    test('should compare Demographics objects correctly', () {
      final demographics1 = Demographics(
        ageGroup: AgeGroup.adult,
        generation: Generation.millennial,
        locations: ['Boston'],
        incomeLevel: IncomeLevel.middle,
        lifestyle: ['suburban'],
      );

      final demographics2 = Demographics(
        ageGroup: AgeGroup.middleAge, // Different
        generation: Generation.millennial, // Same
        locations: ['Boston'], // Same
        incomeLevel: IncomeLevel.high, // Different
        lifestyle: ['urban'], // Different
      );

      final diff = demographics1.compareToDemographics(demographics2);

      expect(diff.keys, hasLength(3));
      expect(diff.keys, contains('ageGroup'));
      expect(diff.keys, contains('incomeLevel'));
      expect(diff.keys, contains('lifestyle'));
      expect(diff.keys, isNot(contains('generation')));
      expect(diff.keys, isNot(contains('locations')));

      expect(diff['ageGroup']!(), equals(AgeGroup.middleAge));
      expect(diff['incomeLevel']!(), equals(IncomeLevel.high));
      expect(diff['lifestyle']!(), equals(['urban']));
    });

    test('should create patches from compareTo results', () {
      final originalDemo = Demographics(
        ageGroup: AgeGroup.youngAdult,
        generation: Generation.genZ,
        locations: ['Austin'],
        incomeLevel: IncomeLevel.low,
        lifestyle: ['student'],
      );

      final targetDemo = Demographics(
        ageGroup: AgeGroup.adult,
        generation: Generation.genZ, // Same
        locations: ['San Francisco'], // Different
        incomeLevel: IncomeLevel.upperMiddle, // Different
        lifestyle: ['professional'], // Different
      );

      final diff = originalDemo.compareToDemographics(targetDemo);
      final patch = DemographicsPatch.create(diff);
      final updatedDemo = patch.applyTo(originalDemo);

      expect(updatedDemo.ageGroup, equals(AgeGroup.adult));
      expect(updatedDemo.generation, equals(Generation.genZ)); // preserved
      expect(updatedDemo.locations, equals(['San Francisco']));
      expect(updatedDemo.incomeLevel, equals(IncomeLevel.upperMiddle));
      expect(updatedDemo.lifestyle, equals(['professional']));
      expect(updatedDemo, equals(targetDemo));
    });

    test('should handle partial updates preserving enum values', () {
      final patch = DemographicsPatch.create()
        ..withLocations(['Miami', 'Orlando']); // Only update locations

      final updatedDemo = patch.applyTo(testDemographics);

      // Only locations should change
      expect(updatedDemo.locations, equals(['Miami', 'Orlando']));

      // All enum values should be preserved
      expect(updatedDemo.ageGroup, equals(AgeGroup.adult));
      expect(updatedDemo.generation, equals(Generation.millennial));
      expect(updatedDemo.incomeLevel, equals(IncomeLevel.upperMiddle));
      expect(updatedDemo.lifestyle, equals(['urban', 'tech-savvy']));
    });

    test('should handle null enum values correctly', () {
      final minimalDemo = Demographics(
        ageGroup: null,
        generation: null,
        locations: null,
        incomeLevel: null,
        lifestyle: null,
      );

      expect(minimalDemo.ageGroup, isNull);
      expect(minimalDemo.generation, isNull);
      expect(minimalDemo.incomeLevel, isNull);
      expect(minimalDemo.locations, isNull);
      expect(minimalDemo.lifestyle, isNull);

      // Patch null values to actual enums
      final patch = DemographicsPatch.create()
        ..withAgeGroup(AgeGroup.child)
        ..withGeneration(Generation.genZ)
        ..withIncomeLevel(IncomeLevel.veryLow);

      final updatedDemo = patch.applyTo(minimalDemo);

      expect(updatedDemo.ageGroup, equals(AgeGroup.child));
      expect(updatedDemo.generation, equals(Generation.genZ));
      expect(updatedDemo.incomeLevel, equals(IncomeLevel.veryLow));
      expect(updatedDemo.locations, isNull); // still null
      expect(updatedDemo.lifestyle, isNull); // still null
    });
  });
}
