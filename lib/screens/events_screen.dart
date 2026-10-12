import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../models/event_model.dart';
import 'event_detail_screen.dart';
import 'create_event_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({Key? key}) : super(key: key);

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final TextEditingController _locationController = TextEditingController();
  String _selectedFilter = 'all'; // 'all', 'match', 'entertainment'

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);
    List<EventModel> events = db.searchEventsByLocation(_locationController.text);

    if (_selectedFilter != 'all') {
      events = events.where((e) => e.eventType == _selectedFilter).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flash Show Etkinlikleri'),
        backgroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.yellow, size: 28),
            tooltip: 'Etkinlik Oluştur',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateEventScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Konum / Bölge Arama Çubuğu
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _locationController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Konuma göre etkinlik ara (Örn: Kadıköy, İzmir)...',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Colors.yellow),
                suffixIcon: _locationController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _locationController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[850],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          // Filtre Butonları (Tümü, Maç, Parti/Eğlence)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _buildFilterChip('all', 'Tümü'),
                const SizedBox(width: 8),
                _buildFilterChip('match', '⚽ Maç Etkinlikleri'),
                const SizedBox(width: 8),
                _buildFilterChip('entertainment', '🎉 Parti / Eğlence'),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Etkinlik Listesi
          Expanded(
            child: events.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.event_busy, size: 56, color: Colors.white24),
                          const SizedBox(height: 12),
                          const Text(
                            'Bu konuma ait etkinlik bulunamadı.',
                            style: TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'İlk etkinliği siz oluşturabilir ve arkadaşlarınızı çağırabilirsiniz!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white38, fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add, color: Colors.black),
                            label: const Text('Etkinlik Oluştur', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const CreateEventScreen()),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      final team = event.teamId != null ? db.getTeamById(event.teamId!) : null;
                      final dateStr =
                          '${event.eventDateTime.day.toString().padLeft(2, '0')}.${event.eventDateTime.month.toString().padLeft(2, '0')} - ${event.eventDateTime.hour.toString().padLeft(2, '0')}:${event.eventDateTime.minute.toString().padLeft(2, '0')}';

                      return Card(
                        color: Colors.grey[850],
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EventDetailScreen(eventId: event.id),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: event.eventType == 'match' ? Colors.blue[900] : Colors.purple[900],
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        event.eventType == 'match' ? '⚽ Maç' : '🎉 Parti / Eğlence',
                                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        const Icon(Icons.access_time, color: Colors.yellow, size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          dateStr,
                                          style: const TextStyle(color: Colors.yellow, fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  event.title,
                                  style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, color: Colors.white54, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      event.venueName != null
                                          ? '${event.locationCity} • ${event.venueName}'
                                          : event.locationCity,
                                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                                    ),
                                  ],
                                ),
                                if (team != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Takım: ${team.name}',
                                    style: const TextStyle(color: Colors.yellow, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '👥 ${event.participantUserIds.length} Katılımcı',
                                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                                    ),
                                    const Row(
                                      children: [
                                        Text('İncele & Katıl', style: TextStyle(color: Colors.yellow, fontSize: 13, fontWeight: FontWeight.bold)),
                                        Icon(Icons.chevron_right, color: Colors.yellow, size: 18),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.yellow,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('Etkinlik Oluştur', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateEventScreen()),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: Colors.yellow,
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : Colors.white70,
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (val) {
        if (val) setState(() => _selectedFilter = key);
      },
    );
  }
}
