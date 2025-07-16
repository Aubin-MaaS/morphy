import 'package:zikzak_morphy_annotation/morphy_annotation.dart';

import 'comprehensive_test.dart';

part 'vip_user.morphy.dart';

@Morphy()
abstract class $VipUser implements $PrivateUser {
  bool get isVip;
}
