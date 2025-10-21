import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/theme/app_theme.dart';

class ThemeSettingsPage extends StatelessWidget {
  const ThemeSettingsPage({super.key});

  Widget _buildThemeOption(
    BuildContext context,
    ThemeProvider themeProvider,
    ThemeMode mode,
    IconData icon,
    String label,
  ) {
    final isSelected = themeProvider.themeMode == mode;
    
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: Theme.of(context).primaryColor,
            )
          : const Icon(
              Icons.circle_outlined,
              color: Colors.grey,
            ),
      onTap: () => themeProvider.setThemeMode(mode),
      selected: isSelected,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tema Ayarları'),
      ),
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Tema Modu Seçimi
              const Text(
                'Tema Modu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    _buildThemeOption(
                      context,
                      themeProvider,
                      ThemeMode.light,
                      Icons.brightness_5,
                      'Aydınlık',
                    ),
                    const Divider(height: 1),
                    _buildThemeOption(
                      context,
                      themeProvider,
                      ThemeMode.dark,
                      Icons.brightness_2,
                      'Karanlık',
                    ),
                    const Divider(height: 1),
                    _buildThemeOption(
                      context,
                      themeProvider,
                      ThemeMode.system,
                      Icons.brightness_auto,
                      'Sistem',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Renk Paleti
              const Text(
                'Renk Seçimi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: AppTheme.colorPalette.length,
                itemBuilder: (context, index) {
                  final entry = AppTheme.colorPalette.entries.elementAt(index);
                  final colorKey = entry.key;
                  final color = entry.value;
                  final isSelected = themeProvider.primaryColor == color;

                  return InkWell(
                    onTap: () {
                      themeProvider.setPrimaryColor(colorKey);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(16),
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withOpacity(0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                )
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 32,
                            )
                          : null,
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Renk İsimleri
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: AppTheme.colorPalette.entries.map((entry) {
                      final isSelected =
                          themeProvider.primaryColor == entry.value;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: entry.value,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              entry.key.toUpperCase(),
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            if (isSelected) ...[
                              const Spacer(),
                              Icon(
                                Icons.check_circle,
                                color: entry.value,
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

