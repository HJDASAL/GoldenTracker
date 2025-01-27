import 'package:flutter/material.dart';

import '../widgets/responsive_layout.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.title = 'Home Page'});
  final String title;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() => _counter++);
  }

  void _changeTheme(BuildContext context, Layout layout) {
    String newScheme;
    if (layout.colorSchemeName == 'light') {
      newScheme = 'light-high-contrast';
    } else if (layout.colorSchemeName == 'light-high-contrast') {
      newScheme = 'dark';
    } else if (layout.colorSchemeName == 'dark') {
      newScheme = 'dark-high-contrast';
    } else {
      newScheme = 'light';
    }

    ResponsiveLayout.of(context).changeColorScheme(newScheme);
  }

  Widget _responsiveBuild(BuildContext context, Layout layout) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          TextButton(
            onPressed: () => _changeTheme(context, layout),
            child: Text('Change Theme'),
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  @override
  Widget build(BuildContext context) {
    return _responsiveBuild(context, ResponsiveLayout.of(context).layout);
  }
}
