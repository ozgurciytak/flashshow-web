import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/auth_service.dart';
import '../models/team_model.dart';
import 'show_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? selectedLeague;
  
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUserModel;

    return Scaffold(
      appBar: AppBar(
        title: Text('app_name'.tr()),
        backgroundColor: Colors.black87,
        actions: [
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
              onPressed: () {}, // AdminScreen routing
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authService.signOut(),
          ),
        ],
      ),
      body: user?.teamId == null 
          ? _buildTeamSelection(context, authService) 
          : _buildMainDashboard(context, user!.teamId!),
    );
  }

  static final List<TeamModel> defaultTeams = [
    TeamModel(id: 'gs', name: 'Galatasaray', league: 'Süper Lig', primaryColorHex: 'A32638', secondaryColorHex: 'FDB912'),
    TeamModel(id: 'fb', name: 'Fenerbahçe', league: 'Süper Lig', primaryColorHex: '000080', secondaryColorHex: 'FFFF00'),
    TeamModel(id: 'bjk', name: 'Beşiktaş', league: 'Süper Lig', primaryColorHex: '000000', secondaryColorHex: 'FFFFFF'),
    TeamModel(id: 'ts', name: 'Trabzonspor', league: 'Süper Lig', primaryColorHex: '800000', secondaryColorHex: '0000FF'),
  ];

  Widget _buildTeamSelection(BuildContext context, AuthService authService) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('teams').snapshots(),
      builder: (context, snapshot) {
        List<TeamModel> allTeams = [];
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          allTeams = snapshot.data!.docs.map((d) => TeamModel.fromMap(d.data() as Map<String, dynamic>, d.id)).toList();
        } else {
          allTeams = defaultTeams;
        }
        
        Set<String> leagues = allTeams.map((t) => t.league).toSet();
        selectedLeague ??= leagues.isNotEmpty ? leagues.first : 'Süper Lig';
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
              child: ListView.builder(
                itemCount: filteredTeams.length,
                itemBuilder: (context, index) {
                  var team = filteredTeams[index];
                  Color primaryColor = Color(int.parse('0xFF${team.primaryColorHex}'));
                  return ListTile(
                    leading: CircleAvatar(backgroundColor: primaryColor),
                    title: Text(team.name, style: const TextStyle(color: Colors.white)),
                    onTap: () => authService.updateUserTeam(team.id),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMainDashboard(BuildContext context, String teamId) {
    TeamModel? fallbackTeam = defaultTeams.where((t) => t.id == teamId).isNotEmpty
        ? defaultTeams.firstWhere((t) => t.id == teamId)
        : null;

    if (fallbackTeam != null) {
      Color primary = Color(int.parse('0xFF${fallbackTeam.primaryColorHex}'));
      Color secondary = Color(int.parse('0xFF${fallbackTeam.secondaryColorHex}'));
      return _buildDashboardContent(context, fallbackTeam.name, primary, secondary);
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('teams').doc(teamId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null || snapshot.data!.data() == null) {
          var defaultTeam = defaultTeams.first;
          Color primary = Color(int.parse('0xFF${defaultTeam.primaryColorHex}'));
          Color secondary = Color(int.parse('0xFF${defaultTeam.secondaryColorHex}'));
          return _buildDashboardContent(context, defaultTeam.name, primary, secondary);
        }
        
        var teamData = snapshot.data!.data() as Map<String, dynamic>;
        Color primary = Color(int.parse('0xFF${teamData['primaryColorHex']}'));
        Color secondary = Color(int.parse('0xFF${teamData['secondaryColorHex']}'));
        return _buildDashboardContent(context, teamData['name'], primary, secondary);
      },
    );
  }

  Widget _buildDashboardContent(BuildContext context, String teamName, Color primary, Color secondary) {
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
                const SizedBox(height: 40),
                GestureDetector(
                  onTap: () => _showOptionsDialog(context, primary, secondary),
                  child: Container(
                    width: 200,
                    height: 200,
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
                const SizedBox(height: 24),
                Text('start_show'.tr(), style: const TextStyle(fontSize: 24, color: Colors.white)),
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
