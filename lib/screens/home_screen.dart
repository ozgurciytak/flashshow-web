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
      body: (user?.teamId == null || user!.teamId!.isEmpty)
          ? _buildTeamSelection(context, authService) 
          : _buildMainDashboard(context, authService, user.teamId!),
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
    return _buildDashboardContent(context, authService, team.name, primary, secondary);
  }

  Widget _buildDashboardContent(BuildContext context, AuthService authService, String teamName, Color primary, Color secondary) {
    return Column(
      children: [
        _buildAdBanner(),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  teamName,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primary),
                ),
                const SizedBox(height: 32),
                GestureDetector(
                  onTap: () => _showOptionsDialog(context, primary, secondary),
                  child: Container(
                    width: 190,
                    height: 190,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primary,
                      border: Border.all(color: secondary, width: 8),
                      boxShadow: [
                        BoxShadow(color: primary.withOpacity(0.5), blurRadius: 20, spreadRadius: 5),
                      ],
                    ),
                    child: Center(
                      child: Icon(Icons.flash_on, size: 80, color: secondary),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('start_show'.tr(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 16),
                TextButton.icon(
                  icon: const Icon(Icons.swap_horiz, color: Colors.yellow, size: 20),
                  label: Text('change_team'.tr(), style: const TextStyle(color: Colors.yellow, fontSize: 16)),
                  onPressed: () => authService.clearTeam(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showOptionsDialog(BuildContext context, Color primary, Color secondary) {
    bool useFlash = true;
    bool useScreen = true;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('show_options'.tr(), style: const TextStyle(color: Colors.white, fontSize: 20)),
                  const SizedBox(height: 20),
                  SwitchListTile(
                    title: Text('enable_flash'.tr(), style: const TextStyle(color: Colors.white)),
                    activeColor: Colors.yellow,
                    value: useFlash,
                    onChanged: (val) => setModalState(() => useFlash = val),
                  ),
                  SwitchListTile(
                    title: Text('enable_screen'.tr(), style: const TextStyle(color: Colors.white)),
                    activeColor: Colors.yellow,
                    value: useScreen,
                    onChanged: (val) => setModalState(() => useScreen = val),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow, minimumSize: const Size(double.infinity, 50)),
                    child: Text('start_show'.tr(), style: const TextStyle(color: Colors.black)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ShowScreen(
                            primaryColor: primary, 
                            secondaryColor: secondary,
                            useFlash: useFlash,
                            useScreen: useScreen,
                          ),
                        ),
                      );
                    },
                  )
                ],
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
