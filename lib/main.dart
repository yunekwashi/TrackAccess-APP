import 'package:flutter/material.dart';

void main() {
  runApp(TrackAccessApp());
}

/* ===========================
   DATA MODELS
=========================== */
class Student {
  final String uid;
  final String id;
  final String name;
  int points;
  int visits;

  Student({
    required this.uid,
    required this.id,
    required this.name,
    required this.points,
    required this.visits,
  });
}

class AttendanceLog {
  final String studentName;
  final DateTime time;

  AttendanceLog(this.studentName, this.time);
}

/* ===========================
   GLOBAL STATE
=========================== */
class AppState extends ChangeNotifier {
  static final AppState instance = AppState._internal();
  AppState._internal();

  final List<Student> students = [
    Student(uid: "A1", id: "2023-001", name: "Alice", points: 20, visits: 3),
    Student(uid: "B2", id: "2023-002", name: "Bob", points: 35, visits: 6),
    Student(uid: "C3", id: "2023-003", name: "Charlie", points: 15, visits: 2),
    Student(uid: "D4", id: "2023-004", name: "Diana", points: 40, visits: 7),
  ];

  final List<AttendanceLog> visitLogs = [];
  final Set<String> scannedToday = {};

  int _scanIndex = 0;

  String simulateRFIDScan() {
    final uid = students[_scanIndex].uid;
    _scanIndex = (_scanIndex + 1) % students.length;
    return uid;
  }

  Student? authenticateUID(String uid) {
    try {
      return students.firstWhere((s) => s.uid == uid);
    } catch (_) {
      return null;
    }
  }

  bool logVisit(Student student) {
    if (scannedToday.contains(student.uid)) return false;
    scannedToday.add(student.uid);
    visitLogs.add(AttendanceLog(student.name, DateTime.now()));
    student.points += 5;
    student.visits++;
    notifyListeners();
    return true;
  }

  void resetDailyAttendance() {
    scannedToday.clear();
    notifyListeners();
  }

  void resetStudentPoints(Student student) {
    student.points = 0;
    notifyListeners();
  }

  void addPoints(Student student, int value) {
    student.points += value;
    notifyListeners();
  }

  int todayVisits() {
    final now = DateTime.now();
    return visitLogs
        .where((l) =>
            l.time.year == now.year &&
            l.time.month == now.month &&
            l.time.day == now.day)
        .length;
  }

  int thisMonthVisits() {
    final now = DateTime.now();
    return visitLogs
        .where((l) => l.time.year == now.year && l.time.month == now.month)
        .length;
  }

  int totalVisits() => visitLogs.length;

  Student topStudent() {
    final sorted = [...students]..sort((a, b) => b.points.compareTo(a.points));
    return sorted.first;
  }
}

/* ===========================
   MAIN APP
=========================== */
class TrackAccessApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TrackAccess Library System',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFFF4F1FA),
        cardTheme: CardThemeData(
          elevation: 4,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
      ),
      home: MainLayout(),
    );
  }
}

/* ===========================
   MAIN LAYOUT
=========================== */
class MainLayout extends StatefulWidget {
  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  Widget currentPage = StudentModule();
  String pageTitle = "Student Module";

  void switchPage(String title, Widget page) {
    setState(() {
      pageTitle = title;
      currentPage = page;
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(pageTitle)),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.deepPurple),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.local_library, color: Colors.white, size: 40),
                  SizedBox(height: 12),
                  Text("TrackAccess",
                      style: TextStyle(color: Colors.white, fontSize: 22)),
                  Text("Library Attendance System",
                      style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.school),
              title: const Text("Student Module"),
              onTap: () => switchPage("Student Module", StudentModule()),
            ),
            ExpansionTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text("Admin Module"),
              children: [
                _adminItem("Dashboard", AdminDashboard()),
                _adminItem("Student Management", StudentManagement()),
                _adminItem("Attendance Analytics", AttendanceAnalytics()),
                _adminItem("Leaderboard Control", LeaderboardControl()),
                _adminItem("System Settings", SystemSettings()),
              ],
            ),
          ],
        ),
      ),
      body: currentPage,
    );
  }

  ListTile _adminItem(String title, Widget page) {
    return ListTile(
      leading: const Icon(Icons.arrow_right, color: Colors.deepPurple),
      title: Text(title),
      onTap: () => switchPage(title, page),
    );
  }
}

/* ===========================
   STUDENT MODULE
=========================== */
class StudentModule extends StatefulWidget {
  @override
  State<StudentModule> createState() => _StudentModuleState();
}

class _StudentModuleState extends State<StudentModule>
    with SingleTickerProviderStateMixin {
  String message = "Please tap your RFID card";
  final AppState state = AppState.instance;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
  }

  void scanCard() {
    final uid = state.simulateRFIDScan();
    final student = state.authenticateUID(uid);

    setState(() {
      if (student == null) {
        message = "Invalid Card.\nPlease contact the librarian.";
      } else {
        final success = state.logVisit(student);
        message = success
            ? "Welcome ${student.name}\nPoints: ${student.points}"
            : "Already logged today";
      }
      _controller.forward(from: 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SectionHeader(title: "📡 Student Check-in"),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(Icons.nfc, size: 60, color: Colors.deepPurple),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: scanCard,
                  icon: const Icon(Icons.touch_app),
                  label: const Text("Scan RFID Card"),
                ),
                const SizedBox(height: 16),
                FadeTransition(
                  opacity: _controller.drive(
                      Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeIn))),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        SectionHeader(title: "🏆 Live Leaderboard"),
        const SizedBox(height: 400, child: LiveLeaderboard()),
      ],
    );
  }
}

/* ===========================
   LIVE LEADERBOARD
=========================== */
class LiveLeaderboard extends StatelessWidget {
  const LiveLeaderboard();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState.instance,
      builder: (context, _) {
        final sorted = [...AppState.instance.students]
          ..sort((a, b) => b.points.compareTo(a.points));
        final maxPoints =
            sorted.isNotEmpty ? sorted.first.points.toDouble() : 1.0;

        return ListView.builder(
          itemCount: sorted.length,
          itemBuilder: (context, index) {
            final rank = index + 1;
            final student = sorted[index];
            final isTop3 = rank <= 3;

            Color rankColor;
            switch (rank) {
              case 1:
                rankColor = Colors.amber;
                break;
              case 2:
                rankColor = Colors.grey;
                break;
              case 3:
                rankColor = Colors.brown;
                break;
              default:
                rankColor = Colors.deepPurple;
            }

            return Card(
              color: isTop3 ? Colors.deepPurple.shade50 : null,
              child: ListTile(
                leading: CircleAvatar(
                  radius: 22,
                  backgroundColor: rankColor,
                  child: Text(
                    "#$rank",
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  student.name,
                  style: TextStyle(
                      fontWeight: isTop3 ? FontWeight.bold : FontWeight.normal),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${student.visits} visits"),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: student.points / (maxPoints == 0 ? 1 : maxPoints),
                      color: Colors.deepPurple,
                      backgroundColor: Colors.deepPurple.shade100,
                    ),
                  ],
                ),
                trailing: Text(
                  "${student.points} pts",
                  style:
                      const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/* ===========================
   ADMIN MODULES
=========================== */
class AdminDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    final top = state.topStudent();

    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SectionHeader(title: "📊 Admin Overview"),
            _statGrid(state),
            const SizedBox(height: 20),
            Card(
              child: ListTile(
                leading: const Icon(Icons.emoji_events,
                    color: Colors.deepPurple, size: 36),
                title: const Text("Top Performing Student"),
                subtitle: Text("${top.name} — ${top.points} points"),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _statGrid(AppState state) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _statCard("Today's Visits", state.todayVisits(), Icons.today),
        _statCard("This Month", state.thisMonthVisits(), Icons.calendar_month),
        _statCard("Total Visits", state.totalVisits(), Icons.history),
        _statCard("Total Students", state.students.length, Icons.people),
      ],
    );
  }

  Widget _statCard(String title, int value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Colors.deepPurple),
            const SizedBox(height: 12),
            Text(value.toString(),
                style:
                    const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(title),
          ],
        ),
      ),
    );
  }
}

class StudentManagement extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SectionHeader(title: "👥 Student Management"),
            ...state.students.map((student) {
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.person, color: Colors.deepPurple),
                  title: Text(student.name),
                  subtitle:
                      Text("ID: ${student.id} | Visits: ${student.visits}"),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == "add") {
                        state.addPoints(student, 5);
                      } else if (value == "reset") {
                        state.resetStudentPoints(student);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                          value: "add", child: Text("➕ Add 5 Points")),
                      const PopupMenuItem(
                          value: "reset", child: Text("♻ Reset Points")),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }
}

class AttendanceAnalytics extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    final logs = state.visitLogs.reversed.toList();

    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SectionHeader(title: "📈 Attendance Analytics"),
            Card(
              child: ListTile(
                leading: const Icon(Icons.today, color: Colors.deepPurple),
                title: const Text("Today's Visits"),
                trailing: Text(state.todayVisits().toString(),
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_month, color: Colors.deepPurple),
                title: const Text("This Month's Visits"),
                trailing: Text(state.thisMonthVisits().toString(),
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            SectionHeader(title: "🗂 Recent Check-ins"),
            ...logs.take(10).map((log) {
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.menu_book, color: Colors.deepPurple),
                  title: Text(log.studentName),
                  subtitle: Text(
                      "${log.time.year}-${log.time.month}-${log.time.day} "
                      "${log.time.hour}:${log.time.minute.toString().padLeft(2, '0')}"),
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }
}

class LeaderboardControl extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SectionHeader(title: "🏆 Leaderboard Control"),
            ...state.students.map((student) {
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.emoji_events, color: Colors.deepPurple),
                  title: Text(student.name),
                  subtitle: Text("${student.points} points"),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == "bonus") {
                        state.addPoints(student, 10);
                      } else if (value == "reset") {
                        state.resetStudentPoints(student);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                          value: "bonus", child: Text("🏅 Give 10 Bonus Points")),
                      const PopupMenuItem(
                          value: "reset", child: Text("♻ Reset Points")),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }
}

class SystemSettings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SectionHeader(title: "⚙ System Settings"),
        Card(
          child: ListTile(
            leading: const Icon(Icons.restart_alt, color: Colors.deepPurple),
            title: const Text("Reset Daily Attendance"),
            subtitle: const Text("Allows students to scan again today"),
            trailing: ElevatedButton(
              onPressed: () {
                state.resetDailyAttendance();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Daily attendance reset")),
                );
              },
              child: const Text("Reset"),
            ),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.deepPurple),
            title: const Text("Clear All Points"),
            subtitle: const Text("Leaderboard will restart from zero"),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                for (final s in state.students) {
                  s.points = 0;
                }
                state.notifyListeners();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("All points cleared")),
                );
              },
              child: const Text("Clear"),
            ),
          ),
        ),
      ],
    );
  }
}

/* ===========================
   REUSABLE HEADER
=========================== */
class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.deepPurple,
        ),
      ),
    );
  }
}



