import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '多页面浏览器',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<TabInfo> _tabs = [
    TabInfo('百度', 'https://www.baidu.com'),
    TabInfo('谷歌', 'https://www.google.com'),
    TabInfo('必应', 'https://www.bing.com'),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('多页面浏览器'),
          bottom: TabBar(
            tabs: _tabs.map((tab) => Tab(text: tab.title)).toList(),
          ),
        ),
        body: TabBarView(
          children: _tabs.map((tab) => WebViewTab(url: tab.url)).toList(),
        ),
      ),
    );
  }
}

class WebViewTab extends StatefulWidget {
  final String url;

  const WebViewTab({super.key, required this.url});

  @override
  State<WebViewTab> createState() => _WebViewTabState();
}

class _WebViewTabState extends State<WebViewTab> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: controller);
  }
}

class TabInfo {
  final String title;
  final String url;

  TabInfo(this.title, this.url);
} 