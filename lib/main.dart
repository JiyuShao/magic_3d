import 'package:flutter/material.dart';
import 'package:web_app/pages/home.dart';
import 'package:web_app/pages/webview.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web_app/utils/logger.dart';

void main() async {
  await dotenv.load(fileName: '.env');
  logger.i('ENVS: ${dotenv.env}');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Magic 3D',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AppContent(),
    );
  }
}

class TabItem {
  final String title;

  final IconData icon;
  final Widget body;

  TabItem({required this.title, required this.icon, required this.body});
}

class AppContent extends StatefulWidget {
  const AppContent({super.key});

  @override
  State<AppContent> createState() => _AppContentState();
}

class _AppContentState extends State<AppContent> {
  int _currentIndex = 0;

  final List<TabItem> _tabs = [
    TabItem(title: '首页', icon: Icons.home, body: const HomePage()),
    TabItem(
        title: '百度',
        icon: Icons.web,
        body: const WebViewPage(url: 'https://www.baidu.com', title: '百度')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tabs[_currentIndex].title),
      ),
      body: _tabs[_currentIndex].body,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: _tabs
            .map((tab) => BottomNavigationBarItem(
                  icon: Icon(tab.icon),
                  label: tab.title,
                ))
            .toList(),
      ),
    );
  }
}
