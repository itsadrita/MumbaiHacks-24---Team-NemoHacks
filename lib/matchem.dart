import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:women_safety/matchy.dart';

// User Model
class User {
  final String id;
  final String name;
  final String gender;
  final int age;
  final String destination;
  final DateTime travelTime;
  final List<String> preferredGender;
  final int minPreferredAge;
  final int maxPreferredAge;
  bool metGroup;
  bool reachedDestination;

  User({
    required this.id,
    required this.name,
    required this.gender,
    required this.age,
    required this.destination,
    required this.travelTime,
    required this.preferredGender,
    required this.minPreferredAge,
    required this.maxPreferredAge,
    this.reachedDestination = false,
    this.metGroup = false,
  });

  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return User(
      id: doc.id,
      name: data['name'] ?? '',
      gender: data['gender'] ?? '',
      age: data['age'] ?? 0,
      destination: data['destination'] ?? '',
      travelTime: (data['travelTime'] as Timestamp).toDate(),
      preferredGender: List<String>.from(data['preferredGender'] ?? []),
      minPreferredAge: data['minPreferredAge'] ?? 0,
      maxPreferredAge: data['maxPreferredAge'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'gender': gender,
      'age': age,
      'destination': destination,
      'travelTime': Timestamp.fromDate(travelTime),
      'preferredGender': preferredGender,
      'minPreferredAge': minPreferredAge,
      'maxPreferredAge': maxPreferredAge,
    };
  }
}

// Registration Screen
class RegistrationScreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _nameController = TextEditingController();
  final _genderController = TextEditingController();
  final _ageController = TextEditingController();
  final _destinationController = TextEditingController();
  final _preferredGenderController = TextEditingController();
  final _minPreferredAgeController = TextEditingController();
  final _maxPreferredAgeController = TextEditingController();

  TimeOfDay? _selectedTravelTime;

  Future<void> _selectTravelTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTravelTime) {
      setState(() {
        _selectedTravelTime = picked;
      });
    }
  }

  void _registerUser() async {
    if (_selectedTravelTime == null) {
      print("Please select a travel time.");
      return;
    }

    try {
      final now = DateTime.now();
      final travelDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        _selectedTravelTime!.hour,
        _selectedTravelTime!.minute,
      );

      final minPreferredAge = int.tryParse(_minPreferredAgeController.text);
      final maxPreferredAge = int.tryParse(_maxPreferredAgeController.text);

      if (minPreferredAge == null || maxPreferredAge == null) {
        print("Please enter valid age range values.");
        return;
      }

      final newUser = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        gender: _genderController.text,
        age: int.parse(_ageController.text),
        destination: _destinationController.text,
        travelTime: travelDateTime,
        preferredGender: _preferredGenderController.text.split(','),
        minPreferredAge: minPreferredAge,
        maxPreferredAge: maxPreferredAge,
      );

      await FirebaseFirestore.instance
          .collection('travelProfiles')
          .doc(newUser.id)
          .set(newUser.toFirestore());

      _clearForm();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MatchScreen(),
        ),
      );
    } catch (e) {
      print("Error during registration: $e");
    }
  }

  void _clearForm() {
    _nameController.clear();
    _genderController.clear();
    _ageController.clear();
    _destinationController.clear();
    _preferredGenderController.clear();
    _minPreferredAgeController.clear();
    _maxPreferredAgeController.clear();
    setState(() {
      _selectedTravelTime = null;
    });
  }

  Widget _buildTextField(TextEditingController controller, String labelText,
      {bool isNumeric = false}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: Colors.white),
        filled: true,
        fillColor: Colors.grey[800],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      style: TextStyle(color: Colors.white),
    );
  }

 @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text("Register"),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2A2D34), Color(0xFF507DBC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    ),
    body: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFA3D5FF), Color(0xFF56C2A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTextField(_nameController, "Name"),
            SizedBox(height: 20),
            _buildTextField(_genderController, "Gender"),
            SizedBox(height: 20),
            _buildTextField(_ageController, "Age", isNumeric: true),
            SizedBox(height: 20),
            _buildTextField(_destinationController, "Destination"),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedTravelTime == null
                        ? 'Select Travel Time'
                        : 'Travel Time: ${_selectedTravelTime!.format(context)}',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _selectTravelTime(context),
                  child: Text("Choose Time"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFF6B6B), // Coral button
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            _buildTextField(
                _preferredGenderController, "Preferred Gender (comma-separated)"),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                      _minPreferredAgeController, "Min Preferred Age",
                      isNumeric: true),
                ),
                SizedBox(width: 15),
                Expanded(
                  child: _buildTextField(
                      _maxPreferredAgeController, "Max Preferred Age",
                      isNumeric: true),
                ),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _registerUser,
              child: Text("Register"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFF6B6B), // Coral button
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}