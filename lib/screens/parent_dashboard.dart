import 'package:flutter/material.dart';
import 'placeholder_screen.dart'; // Make sure this file exists
import 'role_selection_screen.dart'; // Import for Logout redirection

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  int _selectedIndex = 0;

  // Premium Royal Blue Palette (Trustworthy & Clean)
  final Color kPrimaryColor = const Color(0xFF1E40AF); // Deep Royal Blue
  final Color kSecondaryColor = const Color(0xFF3B82F6); // Bright Blue
  final Color kBackgroundColor = const Color(0xFFF8FAFC); // Slate 50 (Very Light Grey)
  final Color kCardColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      extendBody: true, // Navbar floats over content
      
      // --- 1. PREMIUM APP BAR ---
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 75,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color: kBackgroundColor,
            border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.05))),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle, 
                border: Border.all(color: kPrimaryColor, width: 2),
              ),
              child: const CircleAvatar(
                radius: 20, 
                backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=8')
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Parent Portal", style: TextStyle(color: Colors.grey[600], fontSize: 11, fontWeight: FontWeight.w600)),
                const Text("Mr. Sharma", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w800, fontSize: 18)),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 15),
            decoration: BoxDecoration(
              color: Colors.white, 
              shape: BoxShape.circle, 
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
            ),
            child: IconButton(
              icon: Icon(Icons.notifications_outlined, color: Colors.grey[800], size: 24),
              onPressed: () => _openPlaceholder(context, "Notifications", Icons.notifications),
            ),
          ),
        ],
      ),
      
      // --- 2. SMOOTH BODY TRANSITION ---
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: KeyedSubtree(
          key: ValueKey<int>(_selectedIndex),
          child: _getSelectedTab(),
        ),
      ),
      
      // --- 3. FLOATING GLASS NAVBAR ---
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(color: Colors.blue.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 10)),
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5, offset: const Offset(0, 2)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: kPrimaryColor,
            unselectedItemColor: Colors.grey[400],
            backgroundColor: Colors.white,
            elevation: 0,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 10),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 10),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: "Dashboard"),
              BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_rounded), label: "Fees"),
              BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_rounded), label: "Connect"),
              BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: "Profile"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getSelectedTab() {
    switch (_selectedIndex) {
      case 0: return _buildHomeTab();
      case 1: return _buildFeesTab();
      case 2: return _buildChatTab();
      case 3: return _buildProfileTab();
      default: return _buildHomeTab();
    }
  }

  // ==================== TAB 1: HOME ====================
  Widget _buildHomeTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Child Selector Pill (Modern)
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.grey.withOpacity(0.1)),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(radius: 8, backgroundColor: Colors.green, child: const Icon(Icons.check, size: 10, color: Colors.white)),
                  const SizedBox(width: 8),
                  Text("Aryan Sharma (10-A)", style: TextStyle(fontWeight: FontWeight.w700, color: Colors.grey[800], fontSize: 13)),
                  const SizedBox(width: 8),
                  Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey[400], size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 25),

          // 2. Premium Live Tracking Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [kPrimaryColor, const Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight
              ),
              boxShadow: [BoxShadow(color: kPrimaryColor.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                      child: const Row(children: [
                        Icon(Icons.fiber_manual_record, color: Colors.greenAccent, size: 10), 
                        SizedBox(width: 6), 
                        Text("LIVE STATUS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10))
                      ]),
                    ),
                    Icon(Icons.school_rounded, color: Colors.white.withOpacity(0.5)),
                  ],
                ),
                const SizedBox(height: 20),
                const Text("Mathematics Class", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                Text("Chapter 4: Quadratic Equations", style: TextStyle(color: Colors.blue[100], fontSize: 14)),
                const SizedBox(height: 25),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(value: 0.75, minHeight: 6, backgroundColor: Colors.black26, valueColor: const AlwaysStoppedAnimation(Colors.white)),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("10:00 AM", style: TextStyle(color: Colors.blue[200], fontSize: 11)),
                    Text("45 mins elapsed", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    Text("11:00 AM", style: TextStyle(color: Colors.blue[200], fontSize: 11)),
                  ],
                )
              ],
            ),
          ),
          
          const SizedBox(height: 30),

          // 3. Key Statistics Cards
          Row(
            children: [
              Expanded(child: _buildInfoCard("Attendance", "92%", "Present", Icons.calendar_today_rounded, Colors.green)),
              const SizedBox(width: 15),
              Expanded(child: _buildInfoCard("Fee Due", "₹4,500", "Pay Now", Icons.account_balance_wallet_rounded, Colors.orange)),
            ],
          ),

          const SizedBox(height: 30),

          // 4. Feature Grid (Updated to match Teacher/Student Dashboard Style)
          Text("Student Activity", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.grey[800])),
          const SizedBox(height: 15),
          
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3, // 3 Columns look more premium like Teacher dashboard
            childAspectRatio: 1.0,
            mainAxisSpacing: 15,
            crossAxisSpacing: 15,
            children: [
              _buildFeatureIcon("Homework", Icons.menu_book_rounded, Colors.blue, () => _openPlaceholder(context, "Homework", Icons.menu_book)),
              _buildFeatureIcon("Results", Icons.bar_chart_rounded, Colors.purple, () => _openPlaceholder(context, "Results", Icons.bar_chart)),
              _buildFeatureIcon("Behaviour", Icons.psychology_rounded, Colors.redAccent, () => _openPlaceholder(context, "Behaviour", Icons.psychology)),
              _buildFeatureIcon("Notices", Icons.campaign_rounded, Colors.amber[800]!, () => _openPlaceholder(context, "Notices", Icons.campaign)),
              _buildFeatureIcon("Calendar", Icons.event_note_rounded, Colors.teal, () => _openPlaceholder(context, "Calendar", Icons.event_note)),
              _buildFeatureIcon("Transport", Icons.directions_bus_rounded, Colors.indigo, () => _openPlaceholder(context, "Transport", Icons.directions_bus)),
              _buildFeatureIcon("Leave", Icons.edit_calendar_rounded, Colors.pink, () => _openPlaceholder(context, "Leave", Icons.edit_calendar)),
              _buildFeatureIcon("Gallery", Icons.photo_library_rounded, Colors.deepOrange, () => _openPlaceholder(context, "Gallery", Icons.photo_library)),
              _buildFeatureIcon("Syllabus", Icons.topic_rounded, Colors.cyan, () => _openPlaceholder(context, "Syllabus", Icons.topic)),
            ],
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ==================== TAB 2: FEES ====================
  Widget _buildFeesTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 5))],
          ),
          child: Column(
            children: [
              Text("Total Payable Amount", style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(height: 10),
              const Text("₹ 12,500", style: TextStyle(color: Colors.black87, fontSize: 36, fontWeight: FontWeight.w900)),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () => _openPlaceholder(context, "Payment", Icons.payment),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("PAY FEES NOW", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1)),
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: 30),
        Text("Payment Options", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.grey[800])),
        const SizedBox(height: 15),
        _buildListOption("Transaction History", Icons.history_rounded, Colors.blue),
        _buildListOption("Fee Structure", Icons.description_outlined, Colors.orange),
        _buildListOption("Download Receipts", Icons.download_rounded, Colors.teal),
        _buildListOption("Upcoming Dues", Icons.alarm_rounded, Colors.redAccent),
      ],
    );
  }

  // ==================== TAB 3: CHAT ====================
  Widget _buildChatTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text("Messages", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.grey[900])),
        const SizedBox(height: 20),
        _buildChatCard("Class Teacher", "Mrs. Radhika", "Regarding Aryan's project...", Icons.person_rounded, Colors.green),
        const SizedBox(height: 15),
        _buildChatCard("Admin Office", "Helpdesk", "Bus route changed for tomorrow.", Icons.admin_panel_settings_rounded, Colors.blueGrey),
        const SizedBox(height: 15),
        _buildChatCard("AI Assistant", "24/7 Support", "How can I help you today?", Icons.smart_toy_rounded, Colors.indigo),
      ],
    );
  }

  // ==================== TAB 4: PROFILE ====================
  Widget _buildProfileTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 5))]),
          child: Row(
            children: [
              CircleAvatar(radius: 35, backgroundColor: kPrimaryColor.withOpacity(0.1), child: Icon(Icons.person, size: 35, color: kPrimaryColor)),
              const SizedBox(width: 20),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Mr. Sharma", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), Text("Parent / Guardian", style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500))]),
            ],
          ),
        ),
        const SizedBox(height: 30),
        _buildProfileItem("Personal Details", Icons.badge_outlined),
        _buildProfileItem("Manage Students", Icons.supervisor_account_outlined),
        _buildProfileItem("Help & Support", Icons.support_agent_rounded),
        const SizedBox(height: 20),
        _buildProfileItem("Logout", Icons.logout_rounded, isDestructive: true, onTap: () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text("Logout"),
              content: const Text("Are you sure?"),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () { Navigator.pop(ctx); Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const RoleSelectionScreen())); },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                  child: const Text("Logout"),
                )
              ],
            ),
          );
        }),
      ],
    );
  }

  // ==================== HELPER WIDGETS ====================

  void _openPlaceholder(BuildContext context, String title, IconData icon) {
    Navigator.push(context, MaterialPageRoute(builder: (c) => PlaceholderScreen(title: title, icon: icon)));
  }

  Widget _buildInfoCard(String title, String val, String sub, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, color: color, size: 18), const SizedBox(width: 8), Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 11, fontWeight: FontWeight.bold))]),
          const SizedBox(height: 12),
          Text(val, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(sub, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // UPDATED: Now matches Teacher Dashboard (Icon inside colored Circle inside white Card)
  Widget _buildFeatureIcon(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08), 
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 10),
            Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[800])),
          ],
        ),
      ),
    );
  }

  Widget _buildListOption(String title, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 5)]),
      child: ListTile(
        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        trailing: Icon(Icons.chevron_right, size: 18, color: Colors.grey[300]),
        onTap: () => _openPlaceholder(context, title, icon),
      ),
    );
  }

  Widget _buildChatCard(String title, String subtitle, String msg, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey[200]!)),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 24)
        ),
        const SizedBox(width: 15),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          Text(msg, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[500], fontSize: 12))
        ])),
      ]),
    );
  }

  Widget _buildProfileItem(String title, IconData icon, {bool isDestructive = false, VoidCallback? onTap}) {
    return ListTile(
      onTap: onTap ?? () => _openPlaceholder(context, title, icon),
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: isDestructive ? Colors.red[50] : Colors.grey[100], borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: isDestructive ? Colors.red : Colors.grey[700], size: 20)),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: isDestructive ? Colors.red : Colors.black87)),
      trailing: Icon(Icons.chevron_right, size: 18, color: Colors.grey[300]),
    );
  }
}