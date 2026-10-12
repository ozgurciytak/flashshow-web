import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../models/event_model.dart';
import 'show_screen.dart';

class EventDetailScreen extends StatelessWidget {
  final String eventId;

  const EventDetailScreen({Key? key, required this.eventId}) : super(key: key);

  void _shareViaWhatsApp(BuildContext context, EventModel event) {
    final dateStr =
        '${event.eventDateTime.day.toString().padLeft(2, '0')}.${event.eventDateTime.month.toString().padLeft(2, '0')}.${event.eventDateTime.year} ${event.eventDateTime.hour.toString().padLeft(2, '0')}:${event.eventDateTime.minute.toString().padLeft(2, '0')}';
    final shareText = '''⚡ *Flash Show Etkinlik Daveti!* ⚡
🎉 *${event.title}*
📍 Konum: ${event.locationCity} ${event.venueName != null ? '(${event.venueName})' : ''}
⏰ Saat: $dateStr
📝 Açıklama: ${event.description}

Flash Show uygulamasında bana katıl, flaşlarımızı aynı anda senkronize yakalım!
Katılmak için uygulamayı açıp onay isteği gönderin.''';

    Clipboard.setData(ClipboardData(text: shareText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green[800],
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'WhatsApp davet metni kopyalandı! WhatsApp\'a yapıştırıp gönderebilirsiniz.',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _startFlashShow(BuildContext context, EventModel event, DatabaseService db) {
    final team = event.teamId != null ? db.getTeamById(event.teamId!) : null;
    final primary = team != null ? Color(int.parse('0xFF${team.primaryColorHex}')) : Colors.amber;
    final secondary = team != null ? Color(int.parse('0xFF${team.secondaryColorHex}')) : Colors.white;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShowScreen(
          teamName: event.title,
          league: team?.league,
          primaryColor: primary,
          secondaryColor: secondary,
          useFlash: true,
          useScreen: true,
          withCountdown: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);
    final auth = Provider.of<AuthService>(context);
    final user = auth.currentUserModel;

    final event = db.events.firstWhere(
      (e) => e.id == eventId,
      orElse: () => EventModel(
        id: '',
        title: 'Bulunamadı',
        description: '',
        eventType: '',
        locationCity: '',
        eventDateTime: DateTime.now(),
        creatorUserId: '',
        creatorEmail: '',
      ),
    );

    if (event.id.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Etkinlik Detayı'), backgroundColor: Colors.black87),
        body: const Center(child: Text('Etkinlik bulunamadı.', style: TextStyle(color: Colors.white))),
      );
    }

    final isCreator = user != null && user.id == event.creatorUserId;
    final isParticipant = user != null && event.participantUserIds.contains(user.id);
    final isPending = user != null && event.pendingUserIds.contains(user.id);

    final team = event.teamId != null ? db.getTeamById(event.teamId!) : null;
    final opponentTeam = event.opponentTeamId != null ? db.getTeamById(event.opponentTeamId!) : null;

    final dateStr =
        '${event.eventDateTime.day.toString().padLeft(2, '0')}.${event.eventDateTime.month.toString().padLeft(2, '0')}.${event.eventDateTime.year}';
    final timeStr =
        '${event.eventDateTime.hour.toString().padLeft(2, '0')}:${event.eventDateTime.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Etkinlik Detayı'),
        backgroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.greenAccent),
            tooltip: 'WhatsApp ile Davet Et',
            onPressed: () => _shareViaWhatsApp(context, event),
          ),
          if (isCreator)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              tooltip: 'Etkinliği Sil',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: Colors.grey[850],
                    title: const Text('Etkinliği Sil', style: TextStyle(color: Colors.redAccent)),
                    content: const Text('Bu etkinliği silmek istediğinize emin misiniz?', style: TextStyle(color: Colors.white)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Sil'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await db.deleteEvent(event.id);
                  if (context.mounted) Navigator.pop(context);
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst Rozet & Tür
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: event.eventType == 'match' ? Colors.blue[900] : Colors.purple[900],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    event.eventType == 'match' ? '⚽ Maç Etkinliği' : '🎉 Parti / Eğlence',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 10),
                if (isCreator)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.yellow[800],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('👑 Etkinlik Sahibi', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Başlık
            Text(
              event.title,
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Takım Bilgisi (Varsa)
            if (team != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(shape: BoxShape.circle),
                      child: ClipOval(
                        child: Row(
                          children: [
                            Expanded(child: Container(color: Color(int.parse('0xFF${team.primaryColorHex}')))),
                            Expanded(child: Container(color: Color(int.parse('0xFF${team.secondaryColorHex}')))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(team.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          if (opponentTeam != null)
                            Text('Rakip: ${opponentTeam.name}', style: const TextStyle(color: Colors.white60, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Zaman & Konum Kartı
            Card(
              color: Colors.grey[850],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time_filled, color: Colors.yellow),
                        const SizedBox(width: 12),
                        Text('$dateStr  -  Saat: $timeStr', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const Divider(color: Colors.white12, height: 20),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.yellow),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${event.locationCity}${event.venueName != null ? " • ${event.venueName}" : ""}',
                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white12, height: 20),
                    Row(
                      children: [
                        const Icon(Icons.people, color: Colors.yellow),
                        const SizedBox(width: 12),
                        Text(
                          '${event.participantUserIds.length} Katılımcı Onaylandı',
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Açıklama
            if (event.description.isNotEmpty) ...[
              const Text('Açıklama', style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  event.description,
                  style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // WhatsApp Davet Butonu (Kullanıcı davet edebilsin kuralı)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.chat, color: Colors.greenAccent),
                label: const Text('WhatsApp Üzerinden Davet Et', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.greenAccent, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _shareViaWhatsApp(context, event),
              ),
            ),
            const SizedBox(height: 12),

            // Canlı Flash Şov Butonu (Katılımcı veya kurucu ise doğrudan şov başlatabilsin)
            if (isParticipant || isCreator)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.flash_on, color: Colors.black, size: 24),
                  label: const Text('BU ETKİNLİK İÇİN ŞOVU BAŞLAT', style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _startFlashShow(context, event, db),
                ),
              )
            else if (isPending)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orangeAccent),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.hourglass_top, color: Colors.orangeAccent),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Katılım onay isteğiniz gönderildi. Etkinlik sahibi onayladığında etkinliğe dahil olacaksınız.',
                        style: TextStyle(color: Colors.orangeAccent, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.how_to_reg, color: Colors.black),
                  label: const Text('ETKİNLİĞE KATILMA İSTEĞİ GÖNDER', style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Lütfen önce giriş yapın.')),
                      );
                      return;
                    }
                    await db.requestToJoinEvent(event.id, user.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Colors.green,
                        content: Text('Katılma isteğiniz etkinlik sahibine iletildi!'),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 24),

            // ETKİNLİK SAHİBİ İSE: Bekleyen Onay İsteklerini Yönetme Alanı
            if (isCreator) ...[
              const Divider(color: Colors.white24, height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Onay Bekleyen İstekler', style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold, fontSize: 16)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: event.pendingUserIds.isNotEmpty ? Colors.orange : Colors.grey[700],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${event.pendingUserIds.length}',
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (event.pendingUserIds.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('Şu an bekleyen katılım isteği bulunmuyor.', style: TextStyle(color: Colors.white54, fontSize: 13)),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: event.pendingUserIds.length,
                  itemBuilder: (ctx, index) {
                    final requesterId = event.pendingUserIds[index];
                    return Card(
                      color: Colors.grey[850],
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.yellow,
                          child: Icon(Icons.person, color: Colors.black),
                        ),
                        title: Text('Kullanıcı: $requesterId', style: const TextStyle(color: Colors.white, fontSize: 14)),
                        subtitle: const Text('Katılma isteği gönderdi', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check_circle, color: Colors.greenAccent),
                              tooltip: 'Onayla',
                              onPressed: () async {
                                await db.approveJoinRequest(event.id, requesterId);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Katılımcı onaylandı!')),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.redAccent),
                              tooltip: 'Reddet',
                              onPressed: () async {
                                await db.rejectJoinRequest(event.id, requesterId);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('İstek reddedildi.')),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }
}
