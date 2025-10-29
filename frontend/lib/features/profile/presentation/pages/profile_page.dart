import 'package:flutter/material.dart';

import '../../../../core/services/api_service.dart';
import '../../../auth/data/providers/auth_service.dart';
import '../../../auth/presentation/pages/auth_check_page.dart';
import '../../../settings/presentation/pages/theme_settings_page.dart';
import '../widgets/edit_profile_dialog.dart';
import '../widgets/update_goal_dialog.dart';
import '../../../initial_setup/presentation/widgets/preferences_selection_step.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = getAuthService(ApiService());
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilim'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Profil kartı
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Theme.of(context).primaryColor,
                        child: Text(
                          (user?.name?.substring(0, 1).toUpperCase() ?? 'Ö'),
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user?.name ?? 'Kullanıcı',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? user?.phone ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Ayarlar ve seçenekler
              _buildSettingsSection(
                context,
                user,
              ),
            ],
          ),
      ),
    );
  }

  Widget _buildSettingsSection(
    BuildContext context,
    dynamic user,
  ) {
    final authService = getAuthService(ApiService());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            'Hesap Ayarları',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildListTile(
                context,
                'Profil Bilgilerini Düzenle',
                Icons.edit_outlined,
                () {
                  showDialog(
                    context: context,
                    builder: (_) => EditProfileDialog(
                      currentName: user?.name,
                      currentEmail: user?.email,
                      currentPhone: user?.phone,
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              _buildListTile(
                context,
                'Tercihlerimi Güncelle',
                Icons.settings_outlined,
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        appBar: AppBar(title: const Text('Tercihlerimi Güncelle')),
                        body: PreferencesSelectionStep(
                          departmentType: 'SAY', // Varsayılan, güncelleme modunda kullanıcı değiştirebilir
                          examScores: const [], // Güncelleme modunda netler gerekmiyor
                          onPreferencesCompleted: (prefs) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Tercihler güncellendi!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                          onBack: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              _buildListTile(
                context,
                'Hedef Bölümümü Değiştir',
                Icons.flag_outlined,
                () {
                  showDialog(
                    context: context,
                    builder: (_) => const UpdateGoalDialog(),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            'Uygulama',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildListTile(
                context,
                'Tema Ayarları',
                Icons.palette_outlined,
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ThemeSettingsPage(),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              _buildListTile(
                context,
                'Hakkında',
                Icons.info_outline,
                () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'ÖSYM Rehberi',
                    applicationVersion: '1.0.0',
                    applicationIcon: const Icon(Icons.school_rounded, size: 48),
                    children: [
                      const Text(
                        'Yapay zeka destekli üniversite tercih öneri sistemi',
                      ),
                    ],
                  );
                },
              ),
              const Divider(height: 1),
              _buildListTile(
                context,
                'Çıkış Yap',
                Icons.logout,
                () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Çıkış Yap'),
                      content: const Text(
                        'Çıkış yapmak istediğinize emin misiniz?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('İptal'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Çıkış Yap'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true && context.mounted) {
                    await authService.logout();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const AuthCheckPage()),
                        (route) => false,
                      );
                    }
                  }
                },
                color: Colors.red,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListTile(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap, {
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(color: color),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey[400],
      ),
      onTap: onTap,
    );
  }
}

