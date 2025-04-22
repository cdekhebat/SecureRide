import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:secureride/controllers/auth_controller.dart';
import 'package:secureride/views/login_view.dart';
import 'package:secureride/views/preview_view.dart';
import 'package:secureride/views/camera_view.dart';
import 'package:secureride/views/friends_view.dart' as friends;
import 'package:secureride/views/profile_view.dart' as profile;
import 'package:secureride/views/add_friend_view.dart';
import 'package:secureride/views/home_dashboard.dart'; // Not home_view.dart

class MainMenuView extends StatefulWidget {
  const MainMenuView({super.key});

  @override
  State<MainMenuView> createState() => _MainMenuViewState();
}

class _MainMenuViewState extends State<MainMenuView> {
  final AuthController _authController = AuthController();
  int _currentIndex = 0;
  String _currentTheme = 'Classic';

  final Map<String, ThemeData> _themes = {
    'Classic': ThemeData(
      primaryColor: const Color(0xFF6DAEDB),
      colorScheme: ColorScheme.light(
        primary: const Color(0xFF6DAEDB),
        secondary: const Color(0xFFF4A896),
      ),
      appBarTheme: const AppBarTheme(
        color: Color(0xFF6DAEDB),
      ),
    ),
    'Dark': ThemeData.dark(),
    'Light': ThemeData.light(),
  };

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: _themes[_currentTheme],
      home: Scaffold(
        appBar: AppBar(
          title: const Text('SecureRide'),
          centerTitle: true,
          actions: [
            if (_currentIndex == 3)
              IconButton(
                icon: const Icon(Icons.person_add),
                tooltip: 'Add Friend',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddFriendView()),
                  );
                },
              ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.settings),
              onSelected: (value) {
                if (value == 'logout') {
                  _authController.signOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginView()),
                  );
                } else if (value == 'theme') {
                  _showThemeDialog(context);
                }
              },
              itemBuilder: (BuildContext context) {
                return [
                  const PopupMenuItem(
                    value: 'theme',
                    child: Row(
                      children: [
                        Icon(Icons.color_lens),
                        SizedBox(width: 8),
                        Text('Change Theme'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Logout'),
                      ],
                    ),
                  ),
                ];
              },
            ),
          ],
        ),
        body: _buildCurrentScreen(),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.video_library),
              label: 'Preview',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.camera_alt),
              label: 'Camera',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'Friends',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
          onTap: (index) => setState(() => _currentIndex = index),
        ),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return const HomeDashboard();
      case 1:
        return const PreviewView();
      case 2:
        return CameraView();
      case 3:
        return friends.FriendView();
      case 4:
        return profile.ProfileView();
      default:
        return const HomeDashboard(); // Default case to handle all other values
    }
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Theme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _themes.keys.map((themeName) {
              return ListTile(
                title: Text(themeName),
                onTap: () {
                  setState(() => _currentTheme = themeName);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}