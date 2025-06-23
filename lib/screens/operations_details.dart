import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:work_line/qr_scanner/qr_result_page.dart';

class OperationDetailsPage extends StatefulWidget {
  final String detailId;

  const OperationDetailsPage({super.key, required this.detailId});

  @override
  _OperationDetailsPageState createState() => _OperationDetailsPageState();
}

class _OperationDetailsPageState extends State<OperationDetailsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Список продукции"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          unselectedLabelColor: Colors.white,
          labelColor: Colors.red,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: "Все"),
            Tab(text: "Готовая"),
            Tab(text: "В работе"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProductList(), 
          _buildReadyProductList(),
          _buildInProgressProductList(),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('details').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Нет доступных данных"));
        }

        final details = snapshot.data!.docs;

        return ListView.builder(
          itemCount: details.length,
          itemBuilder: (context, index) {
            final detail = details[index];
            final detailName = detail['detail_name'] ?? 'Без названия';
            final detailId = detail['detail_id'] ?? 'Нет ID';
            final status = detail['status'] ?? 'Неизвестно';

            return ListTile(
              title: Text(detailName),
              subtitle: Text("ID: $detailId | Статус: $status"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QrResultPage(detailId: detailId), 
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildReadyProductList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('details')
          .where('status', isEqualTo: 'Completed')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Нет готовой продукции"));
        }

        final details = snapshot.data!.docs;

        return ListView.builder(
          itemCount: details.length,
          itemBuilder: (context, index) {
            final detail = details[index];
            final detailName = detail['detail_name'] ?? 'Без названия';
            final detailId = detail['detail_id'] ?? 'Нет ID';

            return ListTile(
              title: Text(detailName),
              subtitle: Text("ID: $detailId"),
              trailing: const Icon(Icons.check_circle_outline, color: Colors.green),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QrResultPage(detailId: detailId),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildInProgressProductList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('details')
          .where('status', isEqualTo: 'In Progress')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Нет продукции в работе"));
        }

        final details = snapshot.data!.docs;

        return ListView.builder(
          itemCount: details.length,
          itemBuilder: (context, index) {
            final detail = details[index];
            final detailName = detail['detail_name'] ?? 'Без названия';
            final detailId = detail['detail_id'] ?? 'Нет ID';

            return ListTile(
              title: Text(detailName),
              subtitle: Text("ID: $detailId"),
              trailing: const Icon(Icons.hourglass_empty, color: Colors.orange),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QrResultPage(detailId: detailId),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
