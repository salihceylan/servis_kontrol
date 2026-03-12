import 'package:servis_kontrol/features/help/domain/help_center_snapshot.dart';

abstract class HelpRepository {
  Future<HelpCenterSnapshot> load({String? query});
}
