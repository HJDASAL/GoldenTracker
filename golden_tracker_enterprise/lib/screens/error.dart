import 'package:flutter/material.dart';


/// Error Page Sateless widget
class ErrorPage extends StatelessWidget {
  const ErrorPage({super.key});

  /// Initialize Error Page Widget
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('404 Page')),
      body: StreamBuilder(stream: Stream.value('value'), builder: (context, snapshot) {
        return Text(snapshot.data ?? 'No data');
      }),
      // body: Center(child: Text('Page does not exist.')),
    );
  }
}
