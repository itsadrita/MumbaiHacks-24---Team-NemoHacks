import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:web3dart/web3dart.dart';
import 'dart:typed_data';
import 'utils/constants.dart';
import 'utils/functions.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class UserInfoForm extends StatefulWidget {
  final String userId;

  UserInfoForm({required this.userId});
  @override
  _UserInfoFormState createState() => _UserInfoFormState();
}

class _UserInfoFormState extends State<UserInfoForm> {
  Client? httpClient;
  Web3Client? ethClient;
  final _formKey = GlobalKey<FormState>();
  TextEditingController _nameController = TextEditingController();
  TextEditingController _dobController = TextEditingController();
  TextEditingController _addressController = TextEditingController();
  TextEditingController _aadharController = TextEditingController();

  @override
  void initState() {
    httpClient = Client();
    ethClient = Web3Client(blockchain_url, httpClient!
        // socketConnector: () {
        //   return IOWebSocketChannel.connect(wsUrl).cast<String>();}
        );
    super.initState();
  }

  Uint8List? _imageBytes;

  String _encryptData(String data, String key) {
    final keyBytes =
        encrypt.Key.fromUtf8(key.padRight(32, '0')); // Ensure key is 32 bytes
    final iv = encrypt.IV.fromLength(16); // Random IV for security
    final encrypter = encrypt.Encrypter(encrypt.AES(keyBytes));

    final encrypted = encrypter.encrypt(data, iv: iv);
    return '${encrypted.base64}:${base64.encode(iv.bytes)}'; // Return both the encrypted data and IV
  }

  Future<String> _uploadToIPFS(String jsonData) async {
    final pinataApiKey = pinataAPIKey;
    final pinataSecretApiKey = pinataSecretAPIKey;

    final response = await http.post(
      Uri.parse('https://api.pinata.cloud/pinning/pinJSONToIPFS'),
      headers: {
        'Content-Type': 'application/json',
        'pinata_api_key': pinataApiKey,
        'pinata_secret_api_key': pinataSecretApiKey,
      },
      body: jsonEncode({"data": jsonData}),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      print('Uploaded to IPFS with CID: ${jsonResponse['IpfsHash']}');
      return jsonResponse['IpfsHash'];
    } else {
      print('Failed to upload to IPFS: ${response.body}');
      return "Error: Cannot return CID";
    }
  }

  Future<void> registerAndUploadToIPFS(String encryptedData) async {
    try {
      // Step 1: Upload encrypted data to IPFS and get CID
      String cid = await _uploadToIPFS(encryptedData);

      // Step 2: Call registerUser with the obtained CID
      String response = await registerUser(widget.userId, cid, ethClient!);
      print("User registered and CID added to the blockchain.");
    } catch (e) {
      print("An error occurred: $e");
    }
  }

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _uploadImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _imageBytes = result.files.first.bytes;
        });
      } else {
        print("No file selected.");
      }
    } catch (e) {
      print("Error selecting file: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Information Form'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your full name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _dobController,
                decoration: InputDecoration(
                  labelText: 'Date of Birth',
                ),
                readOnly: true,
                onTap: _pickDate,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select your date of birth';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Address',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your address';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _aadharController,
                decoration: InputDecoration(
                  labelText: 'Aadhar Card Number',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your Aadhar card number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextButton(
                onPressed: _uploadImage,
                child: Text('Upload Photograph'),
              ),
              _imageBytes != null
                  ? Image.memory(
                      _imageBytes!,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      height: 150,
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: Center(child: Text('No Image Selected')),
                    ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    // Create a Map of form data
                    final userData = {
                      'name': _nameController.text,
                      'date_of_birth': _dobController.text,
                      'address': _addressController.text,
                      'aadhar_card_number': _aadharController.text,
                      'photograph': _imageBytes != null
                          ? base64Encode(_imageBytes!)
                          : null, // Include the image
                    };

                    // Convert to JSON
                    final jsonData = jsonEncode(userData);

                    // Encrypt the JSON data
                    final key = encryptionKey; // Use a secure key
                    final encryptedData = _encryptData(jsonData, key);

                    // Upload to IPFS
                    await registerAndUploadToIPFS(encryptedData);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Form Submitted Successfully')),
                    );
                  }
                },
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}