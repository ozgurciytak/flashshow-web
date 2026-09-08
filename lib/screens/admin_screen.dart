import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    if (!authService.isFirebaseAvailable) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Yönetim Paneli'),
          backgroundColor: Colors.black87,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.cloud_off, size: 64, color: Colors.yellow),
                SizedBox(height: 16),
                Text(
                  'Firebase Bağlantısı Yok',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 8),
                Text(
                  'Yönetim paneli bulut veritabanı (Firestore) gerektirir. Şu anda yerel/demo moddasınız.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Yönetim Paneli'),
          backgroundColor: Colors.black87,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Takımlar'),
              Tab(text: 'Reklamlar'),
              Tab(text: 'Kullanıcılar'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            TeamsAdminTab(),
            AdsAdminTab(),
            UsersAdminTab(),
          ],
        ),
      ),
    );
  }
}

class TeamsAdminTab extends StatelessWidget {
  const TeamsAdminTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: const Text('Yeni Takım Ekle'),
          trailing: const Icon(Icons.add),
          onTap: () {
            // Takım ekleme modülü (Basit dialog ile gösterilebilir)
            _showAddTeamDialog(context);
          },
        ),
        const Divider(),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('teams').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              return ListView(
                children: snapshot.data!.docs.map((doc) {
                  return ListTile(
                    title: Text(doc['name']),
                    subtitle: Text('Renkler: #${doc['primaryColorHex']} / #${doc['secondaryColorHex']}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => FirebaseFirestore.instance.collection('teams').doc(doc.id).delete(),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAddTeamDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final pColorCtrl = TextEditingController(text: 'FF0000');
    final sColorCtrl = TextEditingController(text: 'FFFFFF');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Takım Ekle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Takım Adı')),
            TextField(controller: pColorCtrl, decoration: const InputDecoration(labelText: 'Birincil Renk (Hex)')),
            TextField(controller: sColorCtrl, decoration: const InputDecoration(labelText: 'İkincil Renk (Hex)')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('teams').add({
                'name': nameCtrl.text,
                'primaryColorHex': pColorCtrl.text,
                'secondaryColorHex': sColorCtrl.text,
              });
              Navigator.pop(context);
            },
            child: const Text('Kaydet'),
          )
        ],
      ),
    );
  }
}

// Reklam ve Kullanıcı sekmeleri de benzer şekilde StreamBuilder kullanılarak yapılabilir.
class AdsAdminTab extends StatelessWidget {
  const AdsAdminTab({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Reklam Yönetim Modülü (Yapım Aşamasında)'));
  }
}

class UsersAdminTab extends StatelessWidget {
  const UsersAdminTab({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        return ListView(
          children: snapshot.data!.docs.map((doc) {
            return ListTile(
              title: Text(doc['email']),
              subtitle: Text('Rol: ${doc['role']} | Takım ID: ${doc['teamId']}'),
            );
          }).toList(),
        );
      },
    );
  }
}
