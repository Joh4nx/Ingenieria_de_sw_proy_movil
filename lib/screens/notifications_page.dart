import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);
  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    _markNotificationsAsRead();
  }

  Future<void> _markNotificationsAsRead() async {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    // Consulta las notificaciones no leídas
    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('notificaciones')
        .where('recipientId', isEqualTo: currentUserId)
        .where('read', isEqualTo: false)
        .get();

    // Marca cada notificación como leída
    for (var doc in snapshot.docs) {
      await doc.reference.update({'read': true});
    }
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notificaciones"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notificaciones')
            .where('recipientId', isEqualTo: currentUserId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final notifications = snapshot.data!.docs;
          if (notifications.isEmpty) {
            return const Center(child: Text("No tienes notificaciones."));
          }
          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final data = notifications[index].data() as Map<String, dynamic>;
              return ListTile(
                leading: const Icon(Icons.notification_important),
                title: Text(data['message'] ?? ''),
                subtitle: data['timestamp'] != null
                    ? Text(
                  (data['timestamp'] as Timestamp)
                      .toDate()
                      .toString(),
                  style: const TextStyle(fontSize: 12),
                )
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}
