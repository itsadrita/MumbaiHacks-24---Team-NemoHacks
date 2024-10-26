import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

// User Model
class User {
  final String id;
  final String name;
  final String gender;
  final int age;
  final String? destination;
  final List<String>? preferredGender;
  final int? preferredAgeRange;

  User({
    required this.id,
    required this.name,
    required this.gender,
    required this.age,
    this.destination,
    this.preferredGender,
    this.preferredAgeRange,
  });

  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return User(
      id: doc.id,
      name: data['name'] ?? '',
      gender: data['gender'] ?? '',
      age: data['age'] ?? 0,
    );
  }
}

class MatchScreen extends StatefulWidget {
  @override
  _MatchScreenState createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  List<User> users = [];
  List<User> selectedUsers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchHardcodedUsers();
    fetchUsersFromFirestore();
  }

  void fetchHardcodedUsers() {
    final adrita = User(
      id: '3',
      name: 'Adrita',
      gender: 'Female',
      age: 20,
      destination: 'Dadar',
      preferredGender: ['Female'],
      preferredAgeRange: 23,
    );

    users = [
      adrita,
      User(id: '', name: '', gender: '', age: 0),
      User(id: '1', name: 'Alice', gender: 'female', age: 21),
      User(id: '2', name: 'Sophia', gender: 'female', age: 22),
    ];

    selectedUsers = [adrita];
  }

  Future<void> fetchUsersFromFirestore() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('travelProfiles')
          .where('gender', isEqualTo: 'female')
          .where('destination', isEqualTo: 'Dadar')
          .where('age', isGreaterThanOrEqualTo: 20)
          .where('age', isLessThanOrEqualTo: 23)
          .get();

      final firestoreUsers = querySnapshot.docs.map((doc) => User.fromFirestore(doc)).toList();

      setState(() {
        users.addAll(firestoreUsers);
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching users from Firestore: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Travel Profiles",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFF507DBC),
        elevation: 5,
        actions: [
          IconButton(
            icon: Icon(Icons.check, color: Colors.white),
            onPressed: () {
              if (selectedUsers.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StatusPage(
                      currentUser: users.firstWhere((u) => u.id == '3'),
                      allUsers: selectedUsers,
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF56C2A6)))
          : ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                if (user.name.isEmpty) return SizedBox(height: 20);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (selectedUsers.contains(user)) {
                        selectedUsers.remove(user);
                      } else {
                        selectedUsers.add(user);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      gradient: selectedUsers.contains(user)
                          ? LinearGradient(
                              colors: [Color(0xFF507DBC), Color(0xFFFF6B6B)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : LinearGradient(
                              colors: [Color(0xFF2A2D34), Color(0xFF1C1E22)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    padding: EdgeInsets.all(16.0),
                    child: ListTile(
                      title: Text(
                        user.name,
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "Gender: ${user.gender}, Age: ${user.age}${user.destination != null ? ", Destination: ${user.destination}" : ""}",
                        style: TextStyle(color: Colors.white70),
                      ),
                      trailing: Icon(
                        selectedUsers.contains(user) ? Icons.check_circle : Icons.circle_outlined,
                        color: selectedUsers.contains(user) ? Color(0xFFFF6B6B) : Colors.white70,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}


class StatusPage extends StatefulWidget {
  final User currentUser;
  final List<User> allUsers;

  StatusPage({required this.currentUser, required this.allUsers});

  @override
  _StatusPageState createState() => _StatusPageState();
}

class _StatusPageState extends State<StatusPage> {
  bool adritaStatusReached = false;
  bool adritaStatusMeeting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.currentUser.name}'s Status", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF507DBC),
        elevation: 5,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: widget.allUsers.map((user) {
                bool isAdrita = user.id == widget.currentUser.id;

                return Card(
                  color: Color(0xFF2A2D34),
                  margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  shadowColor: Colors.black.withOpacity(0.3),
                  elevation: 6,
                  child: ListTile(
                    title: Text(
                      user.name,
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Reached Destination: ${isAdrita ? adritaStatusReached : false}",
                          style: TextStyle(color: Colors.white70),
                        ),
                        Text(
                          "Meeting Others: ${isAdrita ? adritaStatusMeeting : false}",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                    trailing: isAdrita
                        ? Column(
                            children: [
                              Checkbox(
                                activeColor: Color(0xFF56C2A6),
                                value: adritaStatusReached,
                                onChanged: (value) {
                                  setState(() {
                                    adritaStatusReached = value ?? false;
                                  });
                                },
                              ),
                              Checkbox(
                                activeColor: Color(0xFF56C2A6),
                                value: adritaStatusMeeting,
                                onChanged: (value) {
                                  setState(() {
                                    adritaStatusMeeting = value ?? false;
                                  });
                                },
                              ),
                            ],
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

