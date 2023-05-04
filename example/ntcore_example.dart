import 'package:ntcore/ntcore.dart';

void main() {
  final val = nt.getDouble('/SmartDashboard/val');
  nt.setDouble('/SmartDashboard/val', val + 1);
}
