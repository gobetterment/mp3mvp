import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.folder),
            title: const Text('음악 폴더'),
            subtitle: const Text('/storage/emulated/0/Music'),
            onTap: () {
              // TODO: Implement folder selection
            },
          ),
          ListTile(
            leading: const Icon(Icons.color_lens),
            title: const Text('테마'),
            onTap: () {
              // TODO: Implement theme selection
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('앱 정보'),
            onTap: () {
              // TODO: Show app info
            },
          ),
        ],
      ),
    );
  }
}
