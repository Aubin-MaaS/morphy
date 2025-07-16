import 'package:zikzak_morphy_annotation/morphy_annotation.dart';

part 'cross_file_user.g.dart';
part 'cross_file_user.morphy.dart';

@Morphy(generateJson: true)
abstract class $User {
  String get name;
  String get email;
}
