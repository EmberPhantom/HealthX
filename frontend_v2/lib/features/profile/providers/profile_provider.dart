import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/profile_service.dart';

final supportInfoProvider = FutureProvider<SupportInfo>((ref) async {
  return ProfileService().getSupportInfo();
});
