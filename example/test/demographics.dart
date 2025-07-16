import 'package:zikzak_morphy_annotation/zikzak_morphy_annotation.dart';
import 'age_group.dart';
import 'generation.dart';
import 'income_level.dart';

part 'demographics.morphy.dart';
part 'demographics.g.dart';

@Morphy(generateJson: true)
abstract class $Demographics {
  AgeGroup? get ageGroup;
  Generation? get generation;
  List<String>? get locations;
  IncomeLevel? get incomeLevel;
  List<String>? get lifestyle;
}
