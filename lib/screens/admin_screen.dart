import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../models/team_model.dart';
import '../models/ad_model.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Yönetim & İstatistik Paneli'),
          backgroundColor: Colors.black87,
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Colors.yellow,
            labelColor: Colors.yellow,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.analytics), text: 'Genel İstatistik'),
              Tab(icon: Icon(Icons.sports_soccer), text: 'Takımlar & Üyeler'),
              Tab(icon: Icon(Icons.campaign), text: 'Reklamlar & İzlenme'),
              Tab(icon: Icon(Icons.event), text: 'Etkinlikler & Katılım'),
              Tab(icon: Icon(Icons.people), text: 'Kullanıcılar'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            OverviewAdminTab(),
            TeamsAdminTab(),
            AdsAdminTab(),
            EventsAdminTab(),
            UsersAdminTab(),
          ],
        ),
      ),
    );
  }
}

// 1. GENEL İSTATİSTİK ÖZET SEKMESİ
class OverviewAdminTab extends StatelessWidget {
  const OverviewAdminTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);
    final totalUsers = db.users.length;
    final totalEvents = db.events.length;
    final totalParticipants = db.totalEventParticipants;
    final totalAdViews = db.totalAdViews;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('⚡ Uygulama Genel Metrikleri', style: TextStyle(color: Colors.yellow, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _buildMetricCard('Kayıtlı Üye', '$totalUsers', Icons.people, Colors.blue)),
              const SizedBox(width: 12),
              Expanded(child: _buildMetricCard('Toplam Reklam İzlenme', '$totalAdViews', Icons.play_circle_fill, Colors.amber)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildMetricCard('Açılan Etkinlik', '$totalEvents', Icons.event_available, Colors.purple)),
              const SizedBox(width: 12),
              Expanded(child: _buildMetricCard('Toplam Katılımcı', '$totalParticipants', Icons.groups, Colors.green)),
            ],
          ),
          const SizedBox(height: 24),

          // En Çok Destek Alan & En Çok Üyesi Olan Takımlar
          const Text('🏆 Takım Liderlik Tablosu', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...db.allTeams.map((team) {
            final memberCount = db.getTeamMemberCount(team.id);
            final supportCount = db.getSupportCount(team.id);
            if (memberCount == 0 && supportCount == 0) return const SizedBox.shrink();

            final pColor = Color(int.parse('0xFF${team.primaryColorHex}'));
            return Card(
              color: Colors.grey[850],
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: pColor, shape: BoxShape.circle),
                  child: Center(child: Text(team.name[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                ),
                title: Text(team.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text('Tutan Üye: $memberCount Kişi', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(8)),
                  child: Text('📺 $supportCount İzlenme Desteği', style: const TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        ],
      ),
    );
  }
}

// 2. TAKIMLAR & ÜYE SAYILARI SEKMESİ
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
              final supportCount = db.getSupportCount(team.id);
              final memberCount = db.getTeamMemberCount(team.id);

              return Card(
                color: Colors.grey[850],
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: ListTile(
                  leading: Container(
                    width: 38,
                    height: 38,
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
                  title: Text(team.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '${team.league}\n👤 Üye Sayısı: $memberCount taraftar | 📺 Destek: $supportCount izlenme',
                    style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                    onPressed: () => db.deleteTeam(team.id),
                  ),
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

// 3. REKLAMLAR & İZLENME SAYILARI SEKMESİ
class AdsAdminTab extends StatelessWidget {
  const AdsAdminTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);
    final ads = db.ads;

    return Column(
      children: [
        ListTile(
          tileColor: Colors.grey[850],
          leading: const Icon(Icons.add_circle, color: Colors.yellow),
          title: const Text('Yeni Reklam Ekle (Google / Sponsor)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: const Text('Admin panelinden değişken reklam tanımlayın', style: TextStyle(color: Colors.white54, fontSize: 12)),
          onTap: () => _showAddAdDialog(context, db),
        ),
        const Divider(height: 1, color: Colors.white24),
        Expanded(
          child: ads.isEmpty
              ? const Center(child: Text('Henüz eklenmiş reklam yok.', style: TextStyle(color: Colors.white54)))
              : ListView.builder(
                  itemCount: ads.length,
                  itemBuilder: (context, index) {
                    final ad = ads[index];
                    return Card(
                      color: Colors.grey[850],
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: Icon(
                          ad.type == 'google' ? Icons.ads_click : Icons.campaign,
                          color: Colors.yellow,
                          size: 32,
                        ),
                        title: Row(
                          children: [
                            Expanded(child: Text(ad.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: Colors.yellow, borderRadius: BorderRadius.circular(10)),
                              child: Text('👁️ ${ad.viewCount} İzlenme', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          'Tür: ${ad.type == "google" ? "Google AdMob" : "Özel Sponsor"} | Süre: ${ad.rewardSeconds}sn\nURL: ${ad.targetUrl}',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: ad.isActive,
                              activeColor: Colors.yellow,
                              onChanged: (val) {
                                db.updateAd(ad.copyWith(isActive: val));
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                              onPressed: () => db.deleteAd(ad.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showAddAdDialog(BuildContext context, DatabaseService db) {
    final titleCtrl = TextEditingController();
    final urlCtrl = TextEditingController(text: 'https://');
    String adType = 'sponsor';
    int rewardSec = 15;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Yeni Reklam Ekle', style: TextStyle(color: Colors.yellow)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Reklam Başlığı / Şirket Adı', labelStyle: TextStyle(color: Colors.white70)),
                ),
                TextField(
                  controller: urlCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Hedef Web Adresi / Bağlantı', labelStyle: TextStyle(color: Colors.white70)),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: adType,
                  dropdownColor: Colors.grey[850],
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Reklam Türü', labelStyle: TextStyle(color: Colors.white70)),
                  items: const [
                    DropdownMenuItem(value: 'sponsor', child: Text('Özel Sponsor Reklamı')),
                    DropdownMenuItem(value: 'google', child: Text('Google AdMob Reklamı')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => adType = val);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: rewardSec,
                  dropdownColor: Colors.grey[850],
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Minimum İzlenme Süresi', labelStyle: TextStyle(color: Colors.white70)),
                  items: const [
                    DropdownMenuItem(value: 10, child: Text('10 Saniye')),
                    DropdownMenuItem(value: 15, child: Text('15 Saniye (Standart)')),
                    DropdownMenuItem(value: 30, child: Text('30 Saniye (Uzun)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => rewardSec = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow, foregroundColor: Colors.black),
              onPressed: () {
                if (titleCtrl.text.trim().isNotEmpty) {
                  db.addAd(AdModel(
                    id: 'ad_${DateTime.now().millisecondsSinceEpoch}',
                    title: titleCtrl.text.trim(),
                    imageUrl: '',
                    targetUrl: urlCtrl.text.trim(),
                    type: adType,
                    isActive: true,
                    rewardSeconds: rewardSec,
                    viewCount: 0,
                  ));
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Ekle'),
            ),
          ],
        ),
      ),
    );
  }
}

// 4. ETKİNLİKLER & KATILIM SAYILARI SEKMESİ
class EventsAdminTab extends StatelessWidget {
  const EventsAdminTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);
    final events = db.events;

    if (events.isEmpty) {
      return const Center(child: Text('Kayıtlı etkinlik bulunmuyor.', style: TextStyle(color: Colors.white54)));
    }

    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        final ev = events[index];
        final participantCount = ev.participantUserIds.length;
        final pendingCount = ev.pendingUserIds.length;

        return Card(
          color: Colors.grey[850],
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: Icon(ev.eventType == 'match' ? Icons.sports_soccer : Icons.celebration, color: Colors.yellow),
            title: Text(ev.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text(
              '📍 ${ev.locationCity}${ev.venueName != null ? ' • ${ev.venueName}' : ''}\n👥 Onaylı Katılımcı: $participantCount kişi | ⏳ Bekleyen İstek: $pendingCount',
              style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
            ),
            isThreeLine: true,
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
              onPressed: () => db.deleteEvent(ev.id),
            ),
          ),
        );
      },
    );
  }
}

// 5. KULLANICILAR & ADMİN YÖNETİMİ SEKMESİ
class UsersAdminTab extends StatelessWidget {
  const UsersAdminTab({Key? key}) : super(key: key);

  void _showAddAdminDialog(BuildContext context, DatabaseService db) {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings, color: Colors.yellow),
            SizedBox(width: 8),
            Text('Yeni Admin Hesabı Ekle', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ekleyeceğiniz kişi tam yetkili Admin rolüne sahip olacaktır.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Admin E-posta Adresi',
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.yellow)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passCtrl,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Admin Şifresi',
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.yellow)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow, foregroundColor: Colors.black),
            onPressed: () async {
              final email = emailCtrl.text.trim();
              final pass = passCtrl.text.trim();
              if (email.isNotEmpty && pass.length >= 6) {
                await db.createAdminUser(email: email, password: pass);
                if (ctx.mounted) Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(backgroundColor: Colors.green, content: Text('$email başarıyla Admin olarak eklendi!')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lütfen geçerli e-posta ve en az 6 haneli şifre girin.')),
                );
              }
            },
            child: const Text('Admin Olarak Ekle'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);
    final users = db.users;

    return Column(
      children: [
        ListTile(
          tileColor: Colors.grey[850],
          leading: const Icon(Icons.person_add_alt_1, color: Colors.yellow),
          title: const Text('Yeni Admin Hesabı Oluştur', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: const Text('Başka kişilere admin yetkisi verin', style: TextStyle(color: Colors.white54, fontSize: 12)),
          onTap: () => _showAddAdminDialog(context, db),
        ),
        const Divider(height: 1, color: Colors.white24),
        Expanded(
          child: users.isEmpty
              ? const Center(
                  child: Text(
                    'Kayıtlı yerel kullanıcı bulunmuyor.',
                    style: TextStyle(color: Colors.white54),
                  ),
                )
              : ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final team = user.teamId != null ? db.getTeamById(user.teamId!) : null;
                    final isAdmin = user.role == 'admin';

                    return Card(
                      color: Colors.grey[850],
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: user.isSuspended
                              ? Colors.red
                              : (isAdmin ? Colors.yellow : Colors.blueGrey),
                          child: Icon(
                            user.isSuspended ? Icons.block : (isAdmin ? Icons.security : Icons.person),
                            color: Colors.black,
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(child: Text(user.email, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                            if (isAdmin)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                margin: const EdgeInsets.only(right: 4),
                                decoration: BoxDecoration(color: Colors.amber[800], borderRadius: BorderRadius.circular(4)),
                                child: const Text('ADMİN', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            if (user.isSuspended)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.red[900], borderRadius: BorderRadius.circular(4)),
                                child: const Text('ASKIDA', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                        subtitle: Text(
                          'Rol: ${user.role} | Takımı: ${team?.name ?? "Seçilmedi"}\nDurum: ${user.isSuspended ? "Hesap Askıya Alındı" : "Aktif"}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                isAdmin ? Icons.verified_user : Icons.add_moderator,
                                color: isAdmin ? Colors.yellow : Colors.white38,
                              ),
                              tooltip: isAdmin ? 'Admin Yetkisini Al (Kullanıcı Yap)' : 'Admin Yap',
                              onPressed: () => db.toggleUserRole(user.id),
                            ),
                            IconButton(
                              icon: Icon(
                                user.isSuspended ? Icons.play_arrow : Icons.pause,
                                color: user.isSuspended ? Colors.greenAccent : Colors.orangeAccent,
                              ),
                              tooltip: user.isSuspended ? 'Askıyı Kaldır' : 'Askıya Al',
                              onPressed: () => db.toggleUserSuspension(user.id),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                              tooltip: 'Kullanıcıyı Sil',
                              onPressed: () => db.deleteUser(user.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
