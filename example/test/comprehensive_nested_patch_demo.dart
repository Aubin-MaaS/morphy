import 'package:zikzak_morphy_annotation/morphy_annotation.dart';

part 'comprehensive_nested_patch_demo.morphy.dart';

/// A person's profile information
@morphy
abstract class $PersonProfile {
  String get firstName;
  String get lastName;
  String? get bio;
  int get age;
}

/// Contact information
@morphy
abstract class $ContactInfo {
  String get email;
  String? get phone;
}
