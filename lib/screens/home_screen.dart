import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('찰칵! 약알림'),
        automaticallyImplyLeading: false, // Hide back button on home
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Text(
              '안녕하세요!\n오늘도 건강하세요.',
              style: Theme.of(context).textTheme.displayMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 60),
            _buildLargeButton(
              context,
              icon: Icons.camera_alt,
              label: '약 봉투 찍기',
              color: Colors.orange,
              onTap: () => Navigator.pushNamed(context, '/camera'),
            ),
            const SizedBox(height: 24),
            _buildLargeButton(
              context,
              icon: Icons.mic,
              label: '말로 등록하기',
              color: Colors.blue,
              onTap: () => Navigator.pushNamed(context, '/voice'),
            ),
            const SizedBox(height: 24),
            _buildLargeButton(
              context,
              icon: Icons.list_alt,
              label: '내 약 확인하기',
              color: Colors.green,
              onTap: () => Navigator.pushNamed(context, '/alarms'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLargeButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 4,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48),
            const SizedBox(width: 24),
            Text(
              label,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
