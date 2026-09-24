import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Homestay HHL',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF23695B)),
        scaffoldBackgroundColor: const Color(0xFFF5F7F4),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _showTeam(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nhóm Huấn — Hiếu — Long'),
        content: const Text(
          'Phạm Văn Huấn — 23010331\n\n'
          'Nguyễn Hữu Lê Hiếu — 23010985\n\n'
          'Nguyễn Hải Long — 2301872',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Homestay HHL'),
        actions: [
          IconButton(
            onPressed: () => _showTeam(context),
            tooltip: 'Thông tin nhóm',
            icon: const Icon(Icons.people_outline),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 840),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.home_work_outlined,
                      size: 48,
                      color: colors.onPrimaryContainer,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Chào mừng đến với Homestay HHL',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Ứng dụng quản lý homestay của nhóm Huấn, Hiếu, Long. '
                      'Một nơi để theo dõi phòng, lượt đặt và khách lưu trú.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Chức năng dự kiến',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Đây là khung ứng dụng ban đầu. Các chức năng bên dưới '
                'sẽ được triển khai ở giai đoạn tiếp theo.',
              ),
              const SizedBox(height: 16),
              const _FeatureCard(
                icon: Icons.bed_outlined,
                title: 'Quản lý phòng',
                description: 'Danh sách phòng, loại phòng, giá và tình trạng.',
              ),
              const _FeatureCard(
                icon: Icons.event_available_outlined,
                title: 'Quản lý đặt phòng',
                description: 'Lịch đặt, ngày nhận phòng và ngày trả phòng.',
              ),
              const _FeatureCard(
                icon: Icons.people_outline,
                title: 'Quản lý khách hàng',
                description: 'Thông tin khách và lịch sử lưu trú.',
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () => _showTeam(context),
                icon: const Icon(Icons.info_outline),
                label: const Text('Thông tin nhóm phát triển'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(description),
                  const SizedBox(height: 8),
                  const Text(
                    'Chưa triển khai',
                    style: TextStyle(fontSize: 12, color: Color(0xFF616161)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
