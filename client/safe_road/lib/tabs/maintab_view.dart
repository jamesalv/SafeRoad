import 'package:flutter/material.dart';
import 'package:safe_road/screens/map_screen.dart';
import 'package:safe_road/screens/report_screen.dart';
import 'package:safe_road/utils/theme.dart';

class MainTab extends StatefulWidget {
  const MainTab({super.key});

  @override
  State<MainTab> createState() => _MainTabState();
}

class _MainTabState extends State<MainTab> {
  int _selectedIndex = 0;
  late PageController pageController;

  @override
  void initState() {
    super.initState();
    pageController = PageController(initialPage: _selectedIndex);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300), // Slightly faster animation
      curve: Curves.easeInOut, // Smoother animation curve
    );
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: const [
          MapScreen(),
          ReportScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(25),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          backgroundColor: SafeRoadTheme.background,
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.map_outlined,
                  color: _selectedIndex == 0
                      ? SafeRoadTheme.primary
                      : const Color.fromARGB(255, 177, 177, 177)),
              selectedIcon: const Icon(Icons.map, color: SafeRoadTheme.primary),
              label: 'Map',
            ),
            NavigationDestination(
              icon: Icon(Icons.report_outlined,
                  color: _selectedIndex == 1
                      ? SafeRoadTheme.primary
                      : const Color.fromARGB(255, 177, 177, 177)),
              selectedIcon:
                  const Icon(Icons.report, color: SafeRoadTheme.primary),
              label: 'Report',
            ),
          ],
        ),
      ),
    );
  }
}
