import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/dashboard/controller/actions_controller.dart';
import 'features/dashboard/presentation/dashboard_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Create and preload controller BEFORE runApp
  final actions = ActionsController();
  await actions.load();

  runApp(MyApp(actions: actions));
}

class MyApp extends StatelessWidget {
  final ActionsController actions;
  const MyApp({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ActionsController>.value(
      value: actions, // <-- Provider is now ABOVE MaterialApp/Navigator
      child: MaterialApp(
        title: 'BhaGo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          
          useMaterial3: true, colorSchemeSeed: const Color(0xFF1DB954)),
        darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark, colorSchemeSeed: const Color(0xFF1DB954)),
        themeMode: ThemeMode.system,
        home: const DashboardView(), // no param needed now
      ),
    );
  }
}
