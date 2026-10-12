import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'watch_ad_dialog.dart';
import 'event_detail_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({Key? key}) : super(key: key);

  void _copyAdvertisingEmail(BuildContext context) {
    Clipboard.setData(const ClipboardData(text: 'bilgi@taraftarflashshow.com'));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.blue[900],
        content: const Row(
          children: [
            Icon(Icons.mail_outline, color: Colors.white),
            SizedBox(width: 8),
            Text('bilgi@taraftarflashshow.com panoya kopyalandı!'),
          ],
        ),
      ),
    );
  }

  void _showAdvertiseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[850],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.campaign, color: Colors.yellow),
            SizedBox(width: 8),
            Text('Reklam Vermek İstiyorum', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Uygulama içinde reklam vermek ve markanızı binlerce taraftara ulaştırmak için bizimle iletişime geçebilirsiniz:',
              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.yellow.withOpacity(0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.email, color: Colors.yellow, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: SelectableText(
                      'bilgi@taraftarflashshow.com',
                      style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'İstediğiniz zaman yukarıdaki e-posta adresine mail atabilirsiniz. Ekibimiz reklam teklifleri için en kısa sürede dönüş sağlayacaktır.',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Kapat', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow, foregroundColor: Colors.black),
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Mail Adresini Kopyala'),
            onPressed: () {
              Navigator.pop(ctx);
              _copyAdvertisingEmail(context);
            },
          ),
        ],
      ),
    );
  }

  void _supportTeamWithAd(BuildContext context, String teamId, String teamName) {
    final db = Provider.of<DatabaseService>(context, listen: false);
    final activeAds = db.getAdsForTeam(teamId);

    if (activeAds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$teamName için şu an aktif bir reklam bulunamadı.')),
      );
      return;
    }

    final adToWatch = activeAds.first;

    WatchAdDialog.show(
      context,
      teamId: teamId,
      teamName: teamName,
      ad: adToWatch,
    ).then((watched) {
      if (watched == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green[800],
            content: Text('🎉 Harika! $teamName için 1 destek puanı başarıyla gönderildi!'),
          ),
        );
      }
    });
  }

  // HESABI ASKIYA ALMA DİYALOĞU
  void _confirmSuspendAccount(BuildContext context, AuthService auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[850],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.pause_circle_outline, color: Colors.orangeAccent),
            SizedBox(width: 8),
            Text('Hesabı Askıya Al', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: const Text(
          'Hesabınızı geçici olarak dondurmak (askıya almak) istediğinize emin misiniz? Oturumunuz sonlandırılacak ve profiliniz pasif hale getirilecektir.',
          style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.3),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgeç', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, foregroundColor: Colors.black),
            onPressed: () async {
              Navigator.pop(ctx);
              await auth.suspendCurrentUser();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Colors.orange,
                  content: Text('Hesabınız başarıyla askıya alındı ve oturum kapatıldı.'),
                ),
              );
            },
            child: const Text('Evet, Askıya Al'),
          ),
        ],
      ),
    );
  }

  // HESABI KALICI SİLME DİYALOĞU
  void _confirmDeleteAccount(BuildContext context, AuthService auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[850],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Hesabı Kalıcı Olarak Sil', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: const Text(
          'DİKKAT: Bu işlem geri alınamaz! Tüm üyelik bilgileriniz, takıma verdiğiniz destekler ve kayıtlarınız cihazdan kalıcı olarak silinecektir.',
          style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.3),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgeç', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await auth.deleteCurrentUserAccount();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Colors.red,
                  content: Text('Hesabınız kalıcı olarak silindi.'),
                ),
              );
            },
            child: const Text('Kalıcı Olarak Sil'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final db = Provider.of<DatabaseService>(context);
    final user = auth.currentUserModel;

    final team = (user?.teamId != null) ? db.getTeamById(user!.teamId!) : null;
    final supportCount = team != null ? db.getSupportCount(team.id) : 0;
    final userHistory = user != null ? db.getUserEventHistory(user.id) : [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hesabım'),
        backgroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kullanıcı Bilgisi Kartı
            Card(
              color: Colors.grey[850],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.yellow,
                      child: Icon(
                        user?.role == 'admin' ? Icons.admin_panel_settings : Icons.person,
                        size: 34,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.email ?? 'misafir@flashshow.com',
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            team != null ? 'Tuttuğu Takım: ${team.name}' : 'Takım seçilmedi',
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // TAKIMINA DESTEK OL BÖLÜMÜ (Reklam İzleme)
            Card(
              color: Colors.grey[850],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.yellow.withOpacity(0.5), width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.volunteer_activism, color: Colors.yellow, size: 24),
                        SizedBox(width: 8),
                        Text('Takımına Destek Ol', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      team != null
                          ? '${team.name} için reklam izleyerek kulübüne destek gönder! Tamamen izlenen her reklam takımına +1 destek kazandırır.'
                          : 'Destek göndermek için lütfen önce ana ekrandan takımınızı seçin.',
                      style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.3),
                    ),
                    if (team != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${team.name} Toplam Destek:', style: const TextStyle(color: Colors.white, fontSize: 13)),
                            Text('🏆 $supportCount Destek', style: const TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.play_circle_fill, color: Colors.black),
                          label: Text(
                            'Reklam İzle ve ${team.name}\'a Destek Ol',
                            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.yellow,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => _supportTeamWithAd(context, team.id, team.name),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ETKİNLİK GEÇMİŞİ
            const Row(
              children: [
                Icon(Icons.history, color: Colors.yellow, size: 22),
                SizedBox(width: 8),
                Text('Etkinlik Geçmişim', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            if (userHistory.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Henüz katıldığınız veya oluşturduğunuz bir etkinlik bulunmuyor.',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: userHistory.length,
                itemBuilder: (ctx, index) {
                  final event = userHistory[index];
                  final isOwner = user != null && user.id == event.creatorUserId;
                  return Card(
                    color: Colors.grey[850],
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(event.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        '${event.locationCity} • ${event.eventDateTime.day}.${event.eventDateTime.month}.${event.eventDateTime.year} ${event.eventDateTime.hour.toString().padLeft(2, '0')}:${event.eventDateTime.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isOwner ? Colors.amber[900] : Colors.blue[900],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isOwner ? 'Oluşturduğun' : 'Katıldığın',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EventDetailScreen(eventId: event.id),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            const SizedBox(height: 24),

            // REKLAM VERMEK İSTİYORUM BÖLÜMÜ
            Card(
              color: Colors.grey[850],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: ListTile(
                leading: const Icon(Icons.campaign, color: Colors.yellow, size: 28),
                title: const Text('Reklam Vermek İstiyorum', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text('Markanızı milyonlara duyurun • İletişim', style: TextStyle(color: Colors.white54, fontSize: 12)),
                trailing: const Icon(Icons.chevron_right, color: Colors.yellow),
                onTap: () => _showAdvertiseDialog(context),
              ),
            ),
            const SizedBox(height: 20),

            // HESAP YÖNETİMİ & GÜVENLİK (Askıya Alma ve Hesap Silme)
            if (user != null) ...[
              const Text('Hesap Güvenliği & Ayarlar', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Card(
                color: Colors.grey[850],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.pause_circle_outline, color: Colors.orangeAccent),
                      title: const Text('Hesabımı Askıya Al (Dondur)', style: TextStyle(color: Colors.white, fontSize: 14)),
                      subtitle: const Text('Hesabınızı geçici olarak pasif hale getirin', style: TextStyle(color: Colors.white54, fontSize: 11)),
                      trailing: const Icon(Icons.chevron_right, color: Colors.white38),
                      onTap: () => _confirmSuspendAccount(context, auth),
                    ),
                    const Divider(color: Colors.white12, height: 1),
                    ListTile(
                      leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
                      title: const Text('Hesabımı Kalıcı Olarak Sil', style: TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Tüm verilerinizi geri dönüşsüz olarak temizleyin', style: TextStyle(color: Colors.white54, fontSize: 11)),
                      trailing: const Icon(Icons.chevron_right, color: Colors.redAccent),
                      onTap: () => _confirmDeleteAccount(context, auth),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Alt Bilgilendirme
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Reklam ve sponsorluk talepleri için:\nbilgi@taraftarflashshow.com',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
