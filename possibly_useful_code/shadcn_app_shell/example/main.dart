// import 'package:shadcn_app_shell/app_shell.dart';
// import 'package:shadcn_flutter/shadcn_flutter.dart';

// void main() {
//   runShellApp(() async {
//     return AppConfig(
//       routes: [
//         AppRoute(
//           title: 'Home',
//           path: '/',
//           icon: Icons.home,
//           builder: (context, state) => const HomePage(),
//         ),
//         AppRoute(
//           title: 'Counter',
//           path: '/counter',
//           icon: Icons.add,
//           builder: (context, state) => const CounterPage(),
//         ),
//         AppRoute(
//           title: 'Settings',
//           path: '/settings',
//           icon: Icons.settings,
//           builder: (context, state) => const SettingsPage(),
//         ),
//       ],
//       title: 'Example App',
//       subtitle: 'Using App Shell Package',
//     );
//   });
// }

// class CounterPage extends StatefulWidget {
//   const CounterPage({super.key});

//   @override
//   CounterPageState createState() => CounterPageState();
// }

// class CounterPageState extends State<CounterPage> {
//   int _counter = 0;

//   void _incrementCounter() {
//     setState(() {
//       _counter++;
//       logger.i('$_counter');
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.all(32.0),
//       child: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             const Text(
//               'You have pushed the button this many times:',
//               textAlign: TextAlign.center,
//             ).p(),
//             Text(
//               '$_counter',
//             ).h1(),
//             PrimaryButton(
//               onPressed: _incrementCounter,
//               density: ButtonDensity.icon,
//               child: const Icon(Icons.add),
//             ).p(),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class SettingsPage extends StatelessWidget {
//   const SettingsPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const Center(child: Text('Settings Page'));
//   }
// }

// class HomePage extends StatelessWidget {
//   const HomePage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const Center(child: Text('Home Page'));
//   }
// }
