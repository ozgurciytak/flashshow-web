import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../models/team_model.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Yönetim Paneli (Sabit Veritabanı)'),
          backgroundColor: Colors.black87,
          bottom: const TabBar(
            indicatorColor: Colors.yellow,
            labelColor: Colors.yellow,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.sports_soccer), text: 'Takımlar'),
              Tab(icon: Icon(Icons.campaign), text: 'Reklamlar'),
              Tab(icon: Icon(Icons.people), text: 'Kullanıcılar'),
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
    final db = Provider.of<DatabaseService>(context);
    final teams = db.allTeams;

    return Column(
      children: [
        ListTile(
          tileColor: Colors.grey[850],
          leading: const Icon(Icons.add_circle, color: Colors.yellow),
          title: const Text('Yeni Takım Ekle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: Text('Mevcut: ${teams.length} Takım', style: const TextStyle(color: Colors.white54, fontSize: 12)),
          onTap: () => _showAddTeamDialog(context, db),
        ),
        const Divider(height: 1, color: Colors.white24),
        Expanded(
          child: ListView.builder(
            itemCount: teams.length,
            itemBuilder: (context, index) {
              final team = teams[index];
              final pColor = Color(int.parse('0xFF${team.primaryColorHex}'));
              final sColor = Color(int.parse('0xFF${team.secondaryColorHex}'));
              return ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: ClipOval(
                    child: Row(
                      children: [
                        Expanded(child: Container(color: pColor)),
                        Expanded(child: Container(color: sColor)),
                      ],
                    ),
                  ),
                ),
                title: Text(team.name, style: const TextStyle(color: Colors.white)),
                subtitle: Text('${team.league} | #${team.primaryColorHex} / #${team.secondaryColorHex}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                  onPressed: () => db.deleteTeam(team.id),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAddTeamDialog(BuildContext context, DatabaseService db) {
    final nameCtrl = TextEditingController();
    final leagueCtrl = TextEditingController(text: 'Süper Lig');
    final pColorCtrl = TextEditingController(text: 'FF0000');
    final sColorCtrl = TextEditingController(text: 'FFFFFF');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Yeni Takım Ekle', style: TextStyle(color: Colors.yellow)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Takım Adı', labelStyle: TextStyle(color: Colors.white70))),
              TextField(controller: leagueCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Lig (Örn: Süper Lig / Diğer Ligler)', labelStyle: TextStyle(color: Colors.white70))),
              TextField(controller: pColorCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Birincil Renk (Hex)', labelStyle: TextStyle(color: Colors.white70))),
              TextField(controller: sColorCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'İkincil Renk (Hex)', labelStyle: TextStyle(color: Colors.white70))),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow, foregroundColor: Colors.black),
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                final newId = 'team_${DateTime.now().millisecondsSinceEpoch}';
                db.addTeam(TeamModel(
                  id: newId,
                  name: nameCtrl.text.trim(),
                  league: leagueCtrl.text.trim().isEmpty ? 'Süper Lig' : leagueCtrl.text.trim(),
                  primaryColorHex: pColorCtrl.text.trim().replaceAll('#', ''),
                  secondaryColorHex: sColorCtrl.text.trim().replaceAll('#', ''),
                ));
                Navigator.pop(context);
              }
            },
            child: const Text('Kaydet'),
          )
        ],
      ),
    );
  }
}

class AdsAdminTab extends StatelessWidget {
  const AdsAdminTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);
    final ads = db.ads;

    return ListView.builder(
      itemCount: ads.length,
      itemBuilder: (context, index) {
        final ad = ads[index];
        return ListTile(
          leading: const Icon(Icons.campaign, color: Colors.yellow),
          title: Text(ad.targetUrl, style: const TextStyle(color: Colors.white)),
          subtitle: Text('Durum: ${ad.isActive ? "Aktif" : "Pasif"}', style: const TextStyle(color: Colors.white54)),
        );
      },
    );
  }
}

class UsersAdminTab extends StatelessWidget {
  const UsersAdminTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);
    final users = db.users;

    if (users.isEmpty) {
      return const Center(
        child: Text(
          'Kayıtlı yerel kullanıcı bulunmuyor.',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return ListTile(
          leading: const Icon(Icons.person, color: Colors.yellow),
          title: Text(user.email, style: const TextStyle(color: Colors.white)),
          subtitle: Text('Rol: ${user.role} | Takım: ${user.teamId ?? "Seçilmedi"}', style: const TextStyle(color: Colors.white54)),
        );
      },
    );
  }
}
