import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:secureride/controllers/auth_controller.dart';
import 'package:secureride/views/login_view.dart';

class MainMenuView extends StatefulWidget {
  @override
  _MainMenuViewState createState() => _MainMenuViewState();
}

class _MainMenuViewState extends State<MainMenuView> {
  final AuthController _authController = AuthController();
  int _currentIndex = 0;
  bool _isConnected = false;
  bool _isRecording = false;
  String _currentTheme = 'Classic';

  final Map<String, ThemeData> _themes = {
    'Classic': ThemeData(
      primaryColor: Color(0xFF6DAEDB), // Soft blue
      colorScheme: ColorScheme.light(
        primary: Color(0xFF6DAEDB), // Soft blue
        secondary: Color(0xFFF4A896), // Soft coral
      ),
      appBarTheme: AppBarTheme(
        color: Color(0xFF6DAEDB), // Soft blue
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Color(0xFFF4A896), // Soft coral
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
          actions: [
            PopupMenuButton<String>(
              icon: Icon(Icons.settings),
              onSelected: (value) {
                if (value == 'logout') {
                  _authController.signOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginView()),
                  );
                } else if (value == 'theme') {
                  _showThemeDialog(context);
                }
              },
              itemBuilder: (BuildContext context) {
                return [
                  PopupMenuItem(
                    value: 'theme',
                    child: Row(
                      children: [
                        Icon(Icons.color_lens),
                        SizedBox(width: 8),
                        Text('Change Theme'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
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
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0: return _buildHomeScreen();
      case 1: return _buildPreviewScreen();
      case 2: return _buildCameraScreen();
      case 3: return _buildFriendScreen();
      case 4: return _buildProfileScreen();
      default: return _buildHomeScreen();
    }
  }

  Widget _buildHomeScreen() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isConnected ? 'Connected' : 'Disconnected',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Text(
            'Auto-Recording',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SwitchListTile(
            title: Text('Enable Auto-Recording'),
            value: _isRecording,
            onChanged: _isConnected ? (value) => setState(() => _isRecording = value) : null,
          ),
          if (!_isConnected)
            Text(
              'Connect to ESP32 to enable recording',
              style: TextStyle(color: Colors.red),
            ),
        ],
      ),
    );
  }

  Widget _buildPreviewScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.video_library, size: 50),
          SizedBox(height: 20),
          Text('Video Preview Screen'),
        ],
      ),
    );
  }

  Widget _buildCameraScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.camera_alt, size: 50),
          SizedBox(height: 20),
          Text('Camera Screen'),
        ],
      ),
    );
  }

  Widget _buildFriendScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people, size: 50),
          SizedBox(height: 20),
          Text('Friend List Screen'),
        ],
      ),
    );
  }

  Widget _buildProfileScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person, size: 50),
          SizedBox(height: 20),
          Text('Profile Screen'),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      type: BottomNavigationBarType.fixed,
      items: [
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
    );
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Select Theme'),
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