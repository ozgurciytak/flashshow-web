import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../models/event_model.dart';

class CreateEventScreen extends StatefulWidget {
  final String? initialTeamId;

  const CreateEventScreen({Key? key, this.initialTeamId}) : super(key: key);

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _cityController = TextEditingController(text: 'İstanbul');
  final _venueController = TextEditingController();

  String _eventType = 'match'; // 'match' or 'entertainment'
  String? _selectedTeamId;
  String? _selectedOpponentTeamId;
  DateTime _selectedDate = DateTime.now().add(const Duration(hours: 2));
  TimeOfDay _selectedTime = TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 2)));

  @override
  void initState() {
    super.initState();
    _selectedTeamId = widget.initialTeamId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _cityController.dispose();
    _venueController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: Colors.yellow, onPrimary: Colors.black),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: Colors.yellow, onPrimary: Colors.black),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final db = Provider.of<DatabaseService>(context, listen: false);
    final auth = Provider.of<AuthService>(context, listen: false);
    final user = auth.currentUserModel;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Etkinlik oluşturmak için giriş yapmalısınız.')),
      );
      return;
    }

    final eventDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final newEvent = EventModel(
      id: 'event_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      eventType: _eventType,
      teamId: _eventType == 'match' ? _selectedTeamId : null,
      opponentTeamId: _eventType == 'match' ? _selectedOpponentTeamId : null,
      locationCity: _cityController.text.trim(),
      venueName: _venueController.text.trim().isNotEmpty ? _venueController.text.trim() : null,
      eventDateTime: eventDateTime,
      creatorUserId: user.id,
      creatorEmail: user.email,
    );

    // Kural Kontrolü (Aynı etkinlikten iki tane olmasın: Eğlence/parti vb.)
    final error = db.canCreateEvent(newEvent);
    if (error != null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.grey[850],
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
              SizedBox(width: 8),
              Text('Etkinlik Çakışması', style: TextStyle(color: Colors.white, fontSize: 18)),
            ],
          ),
          content: Text(error, style: const TextStyle(color: Colors.white70)),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow, foregroundColor: Colors.black),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Anladım'),
            ),
          ],
        ),
      );
      return;
    }

    final success = await db.createEvent(newEvent);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Flash Show Etkinliğiniz başarıyla oluşturuldu!'),
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);
    final teams = db.allTeams;

    if (_selectedTeamId == null && teams.isNotEmpty) {
      _selectedTeamId = teams.first.id;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Etkinlik Oluştur'),
        backgroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Etkinlik Türü Seçimi
              const Text('Etkinlik Türü', style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('⚽ Maç Etkinliği')),
                      selected: _eventType == 'match',
                      selectedColor: Colors.yellow,
                      labelStyle: TextStyle(
                        color: _eventType == 'match' ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _eventType = 'match');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('🎉 Parti / Eğlence')),
                      selected: _eventType == 'entertainment',
                      selectedColor: Colors.yellow,
                      labelStyle: TextStyle(
                        color: _eventType == 'entertainment' ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _eventType = 'entertainment');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Maç Etkinliği ise Takım Seçimi
              if (_eventType == 'match') ...[
                const Text('Senin Takımın', style: TextStyle(color: Colors.white, fontSize: 14)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedTeamId,
                  dropdownColor: Colors.grey[850],
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: teams.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
                  onChanged: (val) => setState(() => _selectedTeamId = val),
                ),
                const SizedBox(height: 14),
                const Text('Rakip Takım (İsteğe bağlı)', style: TextStyle(color: Colors.white, fontSize: 14)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedOpponentTeamId,
                  dropdownColor: Colors.grey[850],
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    hintText: 'Rakip Takım Seç (Varsa)',
                    hintStyle: const TextStyle(color: Colors.white38),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Seçilmedi (Yalnızca Takım Şovu)')),
                    ...teams.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))),
                  ],
                  onChanged: (val) => setState(() => _selectedOpponentTeamId = val),
                ),
                const SizedBox(height: 16),
              ],

              // Etkinlik Başlığı
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Etkinlik Başlığı *',
                  labelStyle: const TextStyle(color: Colors.yellow),
                  hintText: _eventType == 'match' ? 'Örn: Kadıköy Meydan Maç Koreografisi' : 'Örn: Mezuniyet & Yaz Partisi Flash Şovu',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Lütfen başlık girin' : null,
              ),
              const SizedBox(height: 16),

              // Şehir / Konum
              TextFormField(
                controller: _cityController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Şehir / Bölge *',
                  labelStyle: const TextStyle(color: Colors.yellow),
                  hintText: 'Örn: İstanbul, Kadıköy, İzmir, Ankara...',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                  prefixIcon: const Icon(Icons.location_on, color: Colors.yellow),
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Lütfen şehir veya bölge girin' : null,
              ),
              const SizedBox(height: 16),

              // Mekan / Stat
              TextFormField(
                controller: _venueController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Mekan / Stadyum / Toplanma Alanı',
                  labelStyle: const TextStyle(color: Colors.white70),
                  hintText: 'Örn: Rams Park Kuzey Tribünü, Alsancak Kordon...',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                  prefixIcon: const Icon(Icons.place, color: Colors.white54),
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),

              // Tarih ve Saat Seçimi
              const Text('Etkinlik Zamanı', style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today, color: Colors.yellow, size: 18),
                      label: Text(
                        '${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white38),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _pickDate,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.access_time, color: Colors.yellow, size: 18),
                      label: Text(
                        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white38),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _pickTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Açıklama
              TextFormField(
                controller: _descController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Açıklama & Detaylar',
                  labelStyle: const TextStyle(color: Colors.white70),
                  hintText: 'Katılımcılara yönelik toplanma ve şov detayları...',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 24),

              // Bilgilendirme Kutusu
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.yellow.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: Colors.yellow, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _eventType == 'match'
                            ? 'Maç etkinliği oluşturulduğunda diğer taraftarlar katılım onayı isteyebilir, siz de WhatsApp üzerinden arkadaşlarınızı doğrudan davet edebilirsiniz. Rakip takım da kendi etkinliğini aynı kurallarla açabilir.'
                            : 'Eğlence ve parti etkinliklerinde aynı bölgede mükerrer (çakışan) etkinliğe izin verilmez. Etkinlik sahibi katılımcı onaylarını bizzat yönetir.',
                        style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Oluştur Butonu
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.flash_on, color: Colors.black),
                  label: const Text('ETKİNLİĞİ OLUŞTUR', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
