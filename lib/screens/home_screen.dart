import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/auth_service.dart';
import '../models/team_model.dart';
import 'show_screen.dart';
import 'admin_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? selectedLeague;

  static final List<TeamModel> defaultTeams = [
    // Süper Lig
    TeamModel(id: 'gs', name: 'Galatasaray', league: 'Süper Lig', primaryColorHex: 'A32638', secondaryColorHex: 'FDB912'),
    TeamModel(id: 'fb', name: 'Fenerbahçe', league: 'Süper Lig', primaryColorHex: '000080', secondaryColorHex: 'FFFF00'),
    TeamModel(id: 'bjk', name: 'Beşiktaş', league: 'Süper Lig', primaryColorHex: '000000', secondaryColorHex: 'FFFFFF'),
    TeamModel(id: 'ts', name: 'Trabzonspor', league: 'Süper Lig', primaryColorHex: '800000', secondaryColorHex: '0000FF'),
    TeamModel(id: 'samsun', name: 'Samsunspor', league: 'Süper Lig', primaryColorHex: 'E30613', secondaryColorHex: 'FFFFFF'),
    TeamModel(id: 'goztepe', name: 'Göztepe', league: 'Süper Lig', primaryColorHex: 'FFE000', secondaryColorHex: 'DA291C'),
    TeamModel(id: 'ibfk', name: 'Başakşehir', league: 'Süper Lig', primaryColorHex: 'F58220', secondaryColorHex: '0B2240'),
    TeamModel(id: 'antalya', name: 'Antalyaspor', league: 'Süper Lig', primaryColorHex: 'E30613', secondaryColorHex: 'FFFFFF'),
    TeamModel(id: 'sivas', name: 'Sivasspor', league: 'Süper Lig', primaryColorHex: 'E30613', secondaryColorHex: 'FFFFFF'),
    TeamModel(id: 'konya', name: 'Konyaspor', league: 'Süper Lig', primaryColorHex: '008542', secondaryColorHex: 'FFFFFF'),
    TeamModel(id: 'eyup', name: 'Eyüpspor', league: 'Süper Lig', primaryColorHex: '4B1E87', secondaryColorHex: 'F9D616'),
    // Diğer
    TeamModel(id: 'rm', name: 'Real Madrid', league: 'Dünya', primaryColorHex: 'FFFFFF', secondaryColorHex: 'EEB211'),
    TeamModel(id: 'barca', name: 'Barcelona', league: 'Dünya', primaryColorHex: '004D98', secondaryColorHex: 'A50044'),
    TeamModel(id: 'mci', name: 'Manchester City', league: 'Dünya', primaryColorHex: '6CABDD', secondaryColorHex: '1C2C5B'),
    TeamModel(id: 'liv', name: 'Liverpool', league: 'Dünya', primaryColorHex: 'C8102E', secondaryColorHex: '00B2A9'),
  ];

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
    // If Firebase is not configured or unavailable, show default teams directly (prevent grey screen)
    if (!authService.isFirebaseAvailable) {
      return _buildTeamList(context, authService, defaultTeams);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('teams').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildTeamList(context, authService, defaultTeams);
        }

        List<TeamModel> allTeams = [];
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          try {
            allTeams = snapshot.data!.docs.map((d) => TeamModel.fromMap(d.data() as Map<String, dynamic>, d.id)).toList();
          } catch (_) {
            allTeams = defaultTeams;
          }
        } else {
          allTeams = defaultTeams;
        }

        return _buildTeamList(context, authService, allTeams);
      },
    );
  }

  Widget _buildTeamList(BuildContext context, AuthService authService, List<TeamModel> allTeams) {
    Set<String> leagues = allTeams.map((t) => t.league).toSet();
    if (!leagues.contains(selectedLeague)) {
      selectedLeague = leagues.isNotEmpty ? leagues.first : 'Süper Lig';
    }

    List<TeamModel> filteredTeams = allTeams.where((t) => t.league == selectedLeague).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: DropdownButtonFormField<String>(
            value: selectedLeague,
            dropdownColor: Colors.grey[800],
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'select_league'.tr(),
              labelStyle: const TextStyle(color: Colors.yellow),
              enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.yellow)),
            ),
            items: leagues.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
            onChanged: (val) => setState(() => selectedLeague = val),
          ),
        ),
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
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: primaryColor,
                          child: Icon(Icons.flash_on, color: secondaryColor, size: 20),
                        ),
                        title: Text(team.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text(team.league, style: const TextStyle(color: Colors.white54, fontSize: 12)),
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
    TeamModel? fallbackTeam = defaultTeams.where((t) => t.id == teamId).isNotEmpty
        ? defaultTeams.firstWhere((t) => t.id == teamId)
        : null;

    if (fallbackTeam != null || !authService.isFirebaseAvailable) {
      fallbackTeam ??= defaultTeams.first;
      Color primary = Color(int.parse('0xFF${fallbackTeam.primaryColorHex}'));
      Color secondary = Color(int.parse('0xFF${fallbackTeam.secondaryColorHex}'));
      return _buildDashboardContent(context, authService, fallbackTeam.name, primary, secondary);
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('teams').doc(teamId).get(),
      builder: (context, snapshot) {
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null || snapshot.data!.data() == null) {
          var defaultTeam = defaultTeams.first;
          Color primary = Color(int.parse('0xFF${defaultTeam.primaryColorHex}'));
          Color secondary = Color(int.parse('0xFF${defaultTeam.secondaryColorHex}'));
          return _buildDashboardContent(context, authService, defaultTeam.name, primary, secondary);
        }
        
        var teamData = snapshot.data!.data() as Map<String, dynamic>;
        Color primary = Color(int.parse('0xFF${teamData['primaryColorHex']}'));
        Color secondary = Color(int.parse('0xFF${teamData['secondaryColorHex']}'));
        return _buildDashboardContent(context, authService, teamData['name'], primary, secondary);
      },
    );
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
