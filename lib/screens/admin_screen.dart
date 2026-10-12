import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../models/team_model.dart';
import '../models/ad_model.dart';
import 'home_screen.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Yönetim Paneli'),
          backgroundColor: Colors.black87,
          actions: [
            IconButton(
              icon: const Icon(Icons.phone_android, color: Colors.yellow),
              tooltip: 'Taraftar Görünümüne Geç',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Çıkış Yap',
              onPressed: () {
                Provider.of<AuthService>(context, listen: false).signOut();
              },
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Colors.yellow,
            labelColor: Colors.yellow,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.campaign), text: 'Reklam Yönetimi'),
              Tab(icon: Icon(Icons.analytics), text: 'Genel İstatistik'),
              Tab(icon: Icon(Icons.sports_soccer), text: 'Takımlar & Üyeler'),
              Tab(icon: Icon(Icons.event), text: 'Etkinlikler & Katılım'),
              Tab(icon: Icon(Icons.people), text: 'Kullanıcılar'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            AdsAdminTab(),
            OverviewAdminTab(),
            TeamsAdminTab(),
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

// REKLAMLAR, MEDYA YÖNETİMİ, SIRALAMA & İZLENME SEKMESİ
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
          leading: const Icon(Icons.add_circle, color: Colors.yellow, size: 28),
          title: const Text('Yeni Reklam Tanımla (Resim / Video)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: const Text('Görsel/video URL, yayın günü, sıklık, hedef takım ve sıra belirleyin', style: TextStyle(color: Colors.white54, fontSize: 12)),
          onTap: () => _showAddOrEditAdDialog(context, db),
        ),
        const Divider(height: 1, color: Colors.white24),
        Expanded(
          child: ads.isEmpty
              ? const Center(child: Text('Henüz eklenmiş reklam bulunmuyor.', style: TextStyle(color: Colors.white54)))
              : ListView.builder(
                  itemCount: ads.length,
                  itemBuilder: (context, index) {
                    final ad = ads[index];
                    final targetTeam = ad.targetTeamId == 'all'
                        ? null
                        : db.getTeamById(ad.targetTeamId);

                    return Card(
                      color: Colors.grey[850],
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: ad.isExpired
                              ? Colors.red.withOpacity(0.4)
                              : (ad.isActive ? Colors.yellow.withOpacity(0.3) : Colors.white12),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Üst Satır: Sıra, Başlık, İzlenme ve İşlemler
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.yellow,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '#${ad.displayOrder}',
                                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    ad.title,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.black45,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '👁️ ${ad.viewCount} İzlenme',
                                    style: const TextStyle(color: Colors.yellow, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Rozetler: Medya Türü, Süre / Gün, Hedef Takım, Sıklık
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                // Medya Türü
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: ad.mediaType == 'video' ? Colors.red[900] : Colors.blue[900],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(ad.mediaType == 'video' ? Icons.videocam : Icons.image, color: Colors.white, size: 12),
                                      const SizedBox(width: 4),
                                      Text(
                                        ad.mediaType == 'video' ? 'Video' : 'Görsel',
                                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                // Süre Durumu
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: ad.isExpired ? Colors.red[900] : Colors.green[900],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    ad.isExpired
                                        ? '❌ Süresi Doldu (Yayından Kalktı)'
                                        : '⏳ ${ad.remainingDays} Gün Kaldı (${ad.durationDays} Günlük)',
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                // Hedef Takım
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.purple[900],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    ad.targetTeamId == 'all'
                                        ? '⚽ Tüm Takımlar'
                                        : '⚽ ${targetTeam?.name ?? ad.targetTeamId}',
                                    style: const TextStyle(color: Colors.white, fontSize: 11),
                                  ),
                                ),
                                // Gösterim Sıklığı
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.amber[900],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    ad.frequency == 'always'
                                        ? '🔄 Her Şovda'
                                        : (ad.frequency == 'every_2' ? '🔄 2 Şovda 1' : '🔄 3 Şovda 1'),
                                    style: const TextStyle(color: Colors.white, fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Medya & Hedef Link
                            Text(
                              'Medya: ${ad.mediaUrl.isEmpty ? "(Örnek Varsayılan)" : ad.mediaUrl}',
                              style: const TextStyle(color: Colors.white54, fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Hedef: ${ad.targetUrl}',
                              style: const TextStyle(color: Colors.white38, fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),

                            // Alt Kontroller: Sıralama Butonları (Yukarı/Aşağı), Düzenle, Switch, Sil
                            Row(
                              children: [
                                // Sıralama Butonları
                                IconButton(
                                  icon: const Icon(Icons.arrow_upward, color: Colors.yellow, size: 20),
                                  tooltip: 'Yukarı Taşı (Önceliği Artır)',
                                  onPressed: index > 0 ? () => db.moveAdUp(ad.id) : null,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.arrow_downward, color: Colors.yellow, size: 20),
                                  tooltip: 'Aşağı Taşı (Önceliği Düşür)',
                                  onPressed: index < ads.length - 1 ? () => db.moveAdDown(ad.id) : null,
                                ),
                                const Spacer(),
                                // Düzenle Butonu
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.yellow),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  ),
                                  icon: const Icon(Icons.edit, color: Colors.yellow, size: 16),
                                  label: const Text('Düzenle', style: TextStyle(color: Colors.yellow, fontSize: 12)),
                                  onPressed: () => _showAddOrEditAdDialog(context, db, existingAd: ad),
                                ),
                                const SizedBox(width: 8),
                                // Aktif / Pasif Switch
                                Switch(
                                  value: ad.isActive,
                                  activeColor: Colors.yellow,
                                  onChanged: (val) {
                                    db.updateAd(ad.copyWith(isActive: val));
                                  },
                                ),
                                // Sil Butonu
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                  tooltip: 'Reklamı Sil',
                                  onPressed: () => _confirmDeleteAd(context, db, ad.id),
                                ),
                              ],
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

  void _confirmDeleteAd(BuildContext context, DatabaseService db, String adId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text('Reklamı Sil', style: TextStyle(color: Colors.redAccent)),
        content: const Text('Bu reklamı sistemden tamamen silmek istediğinize emin misiniz?', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              db.deleteAd(adId);
              Navigator.pop(ctx);
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  void _showAddOrEditAdDialog(BuildContext context, DatabaseService db, {AdModel? existingAd}) {
    final isEditing = existingAd != null;
    final titleCtrl = TextEditingController(text: existingAd?.title ?? '');
    final mediaUrlCtrl = TextEditingController(text: existingAd?.mediaUrl ?? '');
    final targetUrlCtrl = TextEditingController(text: existingAd?.targetUrl ?? 'https://');
    final orderCtrl = TextEditingController(text: '${existingAd?.displayOrder ?? (db.ads.length + 1)}');

    String mediaType = existingAd?.mediaType ?? 'image';
    String adType = existingAd?.type ?? 'sponsor';
    String targetTeamId = existingAd?.targetTeamId ?? 'all';
    int durationDays = existingAd?.durationDays ?? 7;
    String frequency = existingAd?.frequency ?? 'always';
    int rewardSec = existingAd?.rewardSeconds ?? 15;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            isEditing ? 'Reklamı Düzenle' : 'Yeni Reklam Tanımla',
            style: const TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Reklam Başlığı
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Reklam / Marka Başlığı *',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 14),

                // 2. Medya Türü (Görsel mi, Video mu?)
                const Text('Medya Türü (Gelen Reklam Formatı)', style: TextStyle(color: Colors.yellow, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('📷 Resim / Görsel')),
                        selected: mediaType == 'image',
                        selectedColor: Colors.yellow,
                        labelStyle: TextStyle(
                          color: mediaType == 'image' ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (val) {
                          if (val) setState(() => mediaType = 'image');
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('🎬 Video')),
                        selected: mediaType == 'video',
                        selectedColor: Colors.yellow,
                        labelStyle: TextStyle(
                          color: mediaType == 'video' ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (val) {
                          if (val) setState(() => mediaType = 'video');
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 3. Medya Bağlantısı / URL (Admin'e gelen resim/video)
                TextField(
                  controller: mediaUrlCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: mediaType == 'image' ? 'Resim URL / Görsel Bağlantısı' : 'Video URL / Video Bağlantısı',
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintText: mediaType == 'image' ? 'https://.../reklam.jpg' : 'https://.../reklam.mp4',
                    hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 14),

                // 4. Hedef Web / Sosyal Medya Linki
                TextField(
                  controller: targetUrlCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Tıklanınca Açılacak Web / Sosyal Medya Linki',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 16),

                // 5. Hedef Takım (Tüm Takımlar mı yoksa Tek Bir Takım mı?)
                const Text('Hedef Takım Filtresi', style: TextStyle(color: Colors.yellow, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  value: targetTeamId,
                  dropdownColor: Colors.grey[850],
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: [
                    const DropdownMenuItem(value: 'all', child: Text('🌍 Bütün Takımlarda Göster')),
                    ...db.allTeams.map((t) => DropdownMenuItem(value: t.id, child: Text('⚽ Sadece ${t.name}'))),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => targetTeamId = val);
                  },
                ),
                const SizedBox(height: 16),

                // 6. Kaç Gün Yayınlanacak? (Süresi dolunca otomatik kalkar)
                const Text('Yayınlanma Süresi (Süre Dolunca Otomatik Kalkar)', style: TextStyle(color: Colors.yellow, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                DropdownButtonFormField<int>(
                  value: durationDays,
                  dropdownColor: Colors.grey[850],
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 3, child: Text('⏳ 3 Gün Boyunca')),
                    DropdownMenuItem(value: 7, child: Text('⏳ 7 Gün (1 Hafta)')),
                    DropdownMenuItem(value: 15, child: Text('⏳ 15 Gün')),
                    DropdownMenuItem(value: 30, child: Text('⏳ 30 Gün (1 Ay)')),
                    DropdownMenuItem(value: 60, child: Text('⏳ 60 Gün (2 Ay)')),
                    DropdownMenuItem(value: 365, child: Text('⏳ 1 Yıl (Sürekli)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => durationDays = val);
                  },
                ),
                const SizedBox(height: 16),

                // 7. Ne Sıklıkla Oynatılacak?
                const Text('Gösterim Sıklığı', style: TextStyle(color: Colors.yellow, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  value: frequency,
                  dropdownColor: Colors.grey[850],
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'always', child: Text('🔄 Her Şovda / Her Açılışta')),
                    DropdownMenuItem(value: 'every_2', child: Text('🔄 2 Şovda Bir Göster')),
                    DropdownMenuItem(value: 'every_3', child: Text('🔄 3 Şovda Bir Göster')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => frequency = val);
                  },
                ),
                const SizedBox(height: 16),

                // 8. Gösterim Sırası & Minimum Süre
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: orderCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Sıra Numarası (Öncelik)',
                          labelStyle: TextStyle(color: Colors.white70),
                          hintText: '1, 2, 3...',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: rewardSec,
                        dropdownColor: Colors.grey[850],
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'İzlenme Süresi',
                          labelStyle: TextStyle(color: Colors.white70),
                        ),
                        items: const [
                          DropdownMenuItem(value: 10, child: Text('10 sn')),
                          DropdownMenuItem(value: 15, child: Text('15 sn')),
                          DropdownMenuItem(value: 30, child: Text('30 sn')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => rewardSec = val);
                        },
                      ),
                    ),
                  ],
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
                if (titleCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lütfen reklam başlığı girin.')),
                  );
                  return;
                }

                final orderVal = int.tryParse(orderCtrl.text.trim()) ?? (db.ads.length + 1);

                if (isEditing) {
                  final updated = existingAd.copyWith(
                    title: titleCtrl.text.trim(),
                    mediaUrl: mediaUrlCtrl.text.trim(),
                    mediaType: mediaType,
                    targetUrl: targetUrlCtrl.text.trim(),
                    targetTeamId: targetTeamId,
                    durationDays: durationDays,
                    frequency: frequency,
                    displayOrder: orderVal,
                    rewardSeconds: rewardSec,
                    endDate: existingAd.startDate.add(Duration(days: durationDays)),
                  );
                  db.updateAd(updated);
                } else {
                  final now = DateTime.now();
                  final newAd = AdModel(
                    id: 'ad_${now.millisecondsSinceEpoch}',
                    title: titleCtrl.text.trim(),
                    mediaUrl: mediaUrlCtrl.text.trim(),
                    mediaType: mediaType,
                    targetUrl: targetUrlCtrl.text.trim(),
                    type: adType,
                    isActive: true,
                    rewardSeconds: rewardSec,
                    viewCount: 0,
                    targetTeamId: targetTeamId,
                    durationDays: durationDays,
                    startDate: now,
                    endDate: now.add(Duration(days: durationDays)),
                    frequency: frequency,
                    displayOrder: orderVal,
                  );
                  db.addAd(newAd);
                }
                Navigator.pop(ctx);
              },
              child: Text(isEditing ? 'Güncelle' : 'Kaydet ve Yayınla'),
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
