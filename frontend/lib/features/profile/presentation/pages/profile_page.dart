import 'package:flutter/material.dart';

import '../../../../core/services/api_service.dart';
import '../../../auth/data/providers/auth_service.dart';
import '../../../auth/presentation/pages/auth_check_page.dart';
import '../../../settings/presentation/pages/theme_settings_page.dart';
import '../widgets/edit_profile_dialog.dart';
import '../../../goals/presentation/pages/update_goal_page.dart';
import '../../../preferences/presentation/pages/update_preferences_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = getAuthService(ApiService());
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Profil Sayfası',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
            // Profil kartı - Stitch Style
              Card(
              elevation: 0,
                shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                padding: const EdgeInsets.all(24.0),
                  child: Column(
                  children: [
                    Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Text(
                          (user?.name?.substring(0, 1).toUpperCase() ?? 'Ö'),
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user?.name ?? 'Kullanıcı',
                        style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
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
            'HESAP AYARLARI',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              color: Colors.grey,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
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
              Divider(height: 1, indent: 56, endIndent: 16),
              _buildListTile(
                context,
                'Tercihlerimi Güncelle',
                Icons.settings_outlined,
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const UpdatePreferencesPage(),
                    ),
                  );
                },
              ),
              Divider(height: 1, indent: 56, endIndent: 16),
              _buildListTile(
                context,
                'Hedef Bölümümü Değiştir',
                Icons.flag_outlined,
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const UpdateGoalPage(),
                    ),
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
            'UYGULAMA AYARLARI',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              color: Colors.grey,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.primary,
                    size: 22,
                  ),
                ),
                title: const Text(
                  'Tema',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: Switch(
                  value: false, // TODO: Tema durumunu kontrol et
                  onChanged: (value) {
                    // Tema değiştir
                  },
                ),
              ),
              Divider(height: 1, indent: 56, endIndent: 16),
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
              Divider(height: 1, indent: 56, endIndent: 16),
              _buildListTile(
                context,
                'Çıkış Yap',
                Icons.logout,
                () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
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
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
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
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (color ?? theme.colorScheme.primary).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: color ?? theme.colorScheme.primary,
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: color,
        ),
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

