import 'package:example/test.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final tc = TextEditingController();
  // final tc = MarkupEditingController();

  @override
  void initState() {
    tc.addListener(() => setState(() {}));
    super.initState();
  }

  @override
  void dispose() {
    tc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Container(
        color: const Color.fromARGB(255, 249, 213, 255),
        child: Column(
          children: [
            Expanded(
              child: TextField(
                maxLines: 10,
                controller: tc,
              ),
            ),
            Expanded(
              child: MarkupText(controller: tc),
            ),
          ],
        ),
      ),
    );
  }
}
