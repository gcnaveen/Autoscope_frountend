// import 'package:flutter/material.dart';
// import 'app/app.dart';

// void main() {
//   runApp(const AutoScopeApp());
// }

import 'package:flutter/material.dart';
import 'app/app.dart';
import 'services/service_locator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Restore session from localStorage (web) / shared prefs (mobile)
  await authService.init();

  runApp(const AutoScopeApp());
}

