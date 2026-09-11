import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/team_model.dart';
import 'show_screen.dart';
import 'admin_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? selectedLeague = 'Süper Lig';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUserModel;

    return Scaffold(
      appBar: AppBar(
        title: Text('app_name'.tr()),
        backgroundColor: Colors.black87,
        actions: [
          if (user?.teamId != null && user!.teamId!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.swap_horiz, color: Colors.yellow),
              tooltip: 'change_team'.tr(),
              onPressed: () => authService.clearTeam(),
            ),
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () {
              if (context.locale.languageCode == 'tr') {
                context.setLocale(const Locale('en'));
              } else {
                context.setLocale(const Locale('tr'));
              }
            },
            tooltip: 'language'.tr(),
          ),
          if (authService.isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings, color: Colors.yellow),
              tooltip: 'admin_panel'.tr(),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminScreen()),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'logout'.tr(),
            onPressed: () => authService.signOut(),
          ),
        ],
      ),
      body: SafeArea(
        child: (user?.teamId == null || user!.teamId!.isEmpty)
            ? _buildTeamSelection(context, authService) 
            : _buildMainDashboard(context, authService, user.teamId!),
      ),
    );
  }

  Widget _buildTeamSelection(BuildContext context, AuthService authService) {
    final db = Provider.of<DatabaseService>(context);
    return _buildTeamList(context, authService, db.allTeams);
  }

  Widget _buildTeamAvatar(Color primary, Color secondary) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24, width: 2),
      ),
      child: ClipOval(
        child: Row(
          children: [
            Expanded(child: Container(color: primary)),
            Expanded(child: Container(color: secondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamList(BuildContext context, AuthService authService, List<TeamModel> allTeams) {
    Set<String> leagues = allTeams.map((t) => t.league).toSet();
    if (!leagues.contains(selectedLeague)) {
      selectedLeague = leagues.isNotEmpty ? leagues.first : 'Süper Lig';
    }

    List<TeamModel> filteredTeams;
    if (_searchQuery.isNotEmpty) {
      filteredTeams = allTeams.where((t) => t.name.toLowerCase().contains(_searchQuery)).toList();
    } else {
      filteredTeams = allTeams.where((t) => t.league == selectedLeague).toList();
    }

    return Column(
      children: [
        // Lig Seçim Açılır Menüsü
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: DropdownButtonFormField<String>(
            value: selectedLeague,
            dropdownColor: Colors.grey[800],
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              labelText: 'select_league'.tr(),
              labelStyle: const TextStyle(color: Colors.yellow),
              enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.yellow)),
              focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.yellow, width: 2)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: leagues.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
            onChanged: (val) {
              setState(() {
                selectedLeague = val;
                _searchQuery = '';
                _searchController.clear();
              });
            },
          ),
        ),
        // Arama Çubuğu
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'search_team'.tr(),
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: const Icon(Icons.search, color: Colors.yellow),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.grey[850],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val.trim().toLowerCase();
              });
            },
          ),
        ),
        // Takım Listesi
        Expanded(
          child: filteredTeams.isEmpty
              ? Center(child: Text('no_team_found'.tr(), style: const TextStyle(color: Colors.white70)))
              : ListView.builder(
                  itemCount: filteredTeams.length,
                  itemBuilder: (context, index) {
                    var team = filteredTeams[index];
                    Color primaryColor = Color(int.parse('0xFF${team.primaryColorHex}'));
                    Color secondaryColor = Color(int.parse('0xFF${team.secondaryColorHex}'));
                    return Card(
                      color: Colors.grey[850],
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: _buildTeamAvatar(primaryColor, secondaryColor),
                        title: Text(
                          team.name, 
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Text(
                          team.league, 
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.yellow, size: 16),
                        onTap: () => authService.updateUserTeam(team.id),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMainDashboard(BuildContext context, AuthService authService, String teamId) {
    final db = Provider.of<DatabaseService>(context);
    final team = db.getTeamById(teamId) ?? db.allTeams.first;
    Color primary = Color(int.parse('0xFF${team.primaryColorHex}'));
    Color secondary = Color(int.parse('0xFF${team.secondaryColorHex}'));
    return _buildDashboardContent(context, authService, team.name, team.league, primary, secondary);
  }

  void _launchShow(
    BuildContext context,
    String teamName,
    String league,
    Color primary,
    Color secondary, {
    bool useFlash = true,
    bool useScreen = true,
    bool withCountdown = false,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShowScreen(
          teamName: teamName,
          league: league,
          primaryColor: primary,
          secondaryColor: secondary,
          useFlash: useFlash,
          useScreen: useScreen,
          withCountdown: withCountdown,
        ),
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context, AuthService authService, String teamName, String league, Color primary, Color secondary) {
    return Column(
      children: [
        _buildAdBanner(),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 8),
                Text(
                  teamName,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primary),
                ),
                const SizedBox(height: 8),
                // Canlı Senkronizasyon Rozeti
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.greenAccent.withOpacity(0.6), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'sync_badge'.tr(),
                        style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Büyük Flaş Butonu (Dokununca Şovu Başlatır)
                GestureDetector(
                  onTap: () => _launchShow(context, teamName, league, primary, secondary),
                  child: Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primary,
                      border: Border.all(color: secondary, width: 8),
                      boxShadow: [
                        BoxShadow(color: primary.withOpacity(0.5), blurRadius: 20, spreadRadius: 5),
                      ],
                    ),
                    child: Center(
                      child: Icon(Icons.flash_on, size: 75, color: secondary),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Doğrudan Ekrandaki Büyük "ŞOVU BAŞLAT" Butonu
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.flash_on, color: Colors.black, size: 26),
                    label: Text(
                      'start_show'.tr(),
                      style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow,
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => _launchShow(context, teamName, league, primary, secondary),
                  ),
                ),
                const SizedBox(height: 12),
                // Şov Seçenekleri & Takım Değiştir Butonları
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.tune, color: Colors.white70, size: 18),
                      label: Text('show_options'.tr(), style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      onPressed: () => _showOptionsDialog(context, teamName, league, primary, secondary),
                    ),
                    const SizedBox(width: 16),
                    TextButton.icon(
                      icon: const Icon(Icons.swap_horiz, color: Colors.yellow, size: 18),
                      label: Text('change_team'.tr(), style: const TextStyle(color: Colors.yellow, fontSize: 14)),
                      onPressed: () => authService.clearTeam(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showOptionsDialog(BuildContext context, String teamName, String league, Color primary, Color secondary) {
    bool useFlash = true;
    bool useScreen = true;
    bool withCountdown = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final bottomPadding = MediaQuery.of(ctx).padding.bottom;
            final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
            return SafeArea(
              top: false,
              bottom: true,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24, 16, 24, bottomPadding + bottomInset + 36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Text('show_options'.tr(), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      'sync_subtext'.tr(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.greenAccent, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: Text('enable_flash'.tr(), style: const TextStyle(color: Colors.white)),
                      subtitle: const Text('Arka kamera flaşı ritmik çakar', style: TextStyle(color: Colors.white54, fontSize: 11)),
                      activeColor: Colors.yellow,
                      value: useFlash,
                      onChanged: (val) => setModalState(() => useFlash = val),
                    ),
                    SwitchListTile(
                      title: Text('screen_visuals'.tr(), style: const TextStyle(color: Colors.white)),
                      subtitle: const Text('Takım arması ve renkler ekranda parlar', style: TextStyle(color: Colors.white54, fontSize: 11)),
                      activeColor: Colors.yellow,
                      value: useScreen,
                      onChanged: (val) => setModalState(() => useScreen = val),
                    ),
                    SwitchListTile(
                      title: Text('enable_countdown'.tr(), style: const TextStyle(color: Colors.white)),
                      subtitle: const Text('3 saniye geri sayımdan sonra başlar', style: TextStyle(color: Colors.white54, fontSize: 11)),
                      activeColor: Colors.yellow,
                      value: withCountdown,
                      onChanged: (val) => setModalState(() => withCountdown = val),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.flash_on, color: Colors.black),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellow,
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 4,
                        ),
                        label: Text('start_show'.tr(), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _launchShow(
                            context,
                            teamName,
                            league,
                            primary,
                            secondary,
                            useFlash: useFlash,
                            useScreen: useScreen,
                            withCountdown: withCountdown,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
        );
      }
    );
  }

  Widget _buildAdBanner() {
    return Container(
      height: 80,
      color: Colors.black,
      alignment: Alignment.center,
      child: const Text('AD BANNER', style: TextStyle(color: Colors.grey)),
    );
  }
}
