import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl_phone_field/intl_phone_field.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final savedToken = prefs.getString('token');
  runApp(MyApp(savedToken: savedToken));
}

// 🔗 Change this (Android Emulator: 10.0.2.2)
const String baseUrl = "http://localhost:5000";

class MyApp extends StatelessWidget {
  final String? savedToken;
  const MyApp({super.key, this.savedToken});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Contact Keeper',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: savedToken == null ? const HomePage() : ContactsPage(token: savedToken!),
    );
  }
}

//
// ---------------- HOME PAGE ----------------
//
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Contact Keeper")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.contacts, size: 80, color: Colors.indigo),
            const SizedBox(height: 20),
            const Text("Welcome to Contact Keeper",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              ),
              child: const Text("Login"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const RegisterPage()),
              ),
              child: const Text("Register"),
            ),
          ],
        ),
      ),
    );
  }
}

//
// ---------------- LOGIN PAGE ----------------
//
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String email = '', password = '';
  bool loading = false;

  Future<void> login() async {
    setState(() => loading = true);
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = res.body.isNotEmpty ? jsonDecode(res.body) : {};
      setState(() => loading = false);

      if (res.statusCode == 200 && data['token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ContactsPage(token: data['token'])),
        );
      } else {
        showMsg(data['message'] ?? "Login failed");
      }
    } catch (e) {
      setState(() => loading = false);
      showMsg("Server not reachable");
    }
  }

  void showMsg(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(labelText: "Email"),
              onChanged: (v) => email = v,
            ),
            TextField(
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
              onChanged: (v) => password = v,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : login,
              child: Text(loading ? "Logging in..." : "Login"),
            ),
            TextButton(
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const RegisterPage()),
              ),
              child: const Text("No account? Register"),
            ),
          ],
        ),
      ),
    );
  }
}

//
// ---------------- REGISTER PAGE ----------------
//
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  String name = '', email = '', password = '', confirm = '';
  bool loading = false;

  Future<void> register() async {
    setState(() => loading = true);
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'confirmPassword': confirm
        }),
      );
      final data = res.body.isNotEmpty ? jsonDecode(res.body) : {};
      setState(() => loading = false);
      showMsg(data['message'] ?? "Registration failed");
      if (res.statusCode == 200 &&
          (data['message'] == "Registered successfully" ||
              data['success'] == true)) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    } catch (e) {
      setState(() => loading = false);
      showMsg("Server not reachable");
    }
  }

  void showMsg(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              decoration: const InputDecoration(labelText: "Name"),
              onChanged: (v) => name = v,
            ),
            TextField(
              decoration: const InputDecoration(labelText: "Email"),
              onChanged: (v) => email = v,
            ),
            TextField(
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
              onChanged: (v) => password = v,
            ),
            TextField(
              decoration:
                  const InputDecoration(labelText: "Confirm Password"),
              obscureText: true,
              onChanged: (v) => confirm = v,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : register,
              child: Text(loading ? "Please wait..." : "Register"),
            ),
          ],
        ),
      ),
    );
  }
}

//
// ---------------- CONTACTS PAGE (with EDIT + UNDO) ----------------
//
class ContactsPage extends StatefulWidget {
  final String token;
  const ContactsPage({super.key, required this.token});
  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  List contacts = [];
  List filteredContacts = [];
  bool loading = true;
  String searchQuery = '';
  Map<String, dynamic>? lastDeletedContact;

  Future<void> fetchContacts() async {
    setState(() => loading = true);
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/contacts'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (res.statusCode == 200) {
        contacts = jsonDecode(res.body);
        filteredContacts = contacts;
      }
    } catch (_) {
      contacts = [];
      filteredContacts = [];
    }
    setState(() => loading = false);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
      (route) => false,
    );
  }

  void filterContacts(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredContacts = contacts;
      } else {
        filteredContacts = contacts.where((c) {
          final name = (c['name'] ?? '').toString().toLowerCase();
          return name.startsWith(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> deleteContact(String id) async {
    final contactToDelete =
        contacts.firstWhere((c) => c['_id'] == id, orElse: () => {});
    lastDeletedContact = contactToDelete;

    setState(() {
      contacts.removeWhere((c) => c['_id'] == id);
      filteredContacts.removeWhere((c) => c['_id'] == id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Contact deleted"),
        action: SnackBarAction(
          label: "UNDO",
          onPressed: () {
            if (lastDeletedContact != null) {
              setState(() {
                contacts.add(lastDeletedContact!);
                filteredContacts = contacts;
              });
              saveRestoredContact(lastDeletedContact!);
              lastDeletedContact = null;
            }
          },
        ),
      ),
    );

    await http.delete(
      Uri.parse('$baseUrl/contacts/$id'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
  }

  Future<void> saveRestoredContact(Map contact) async {
    await http.post(
      Uri.parse('$baseUrl/contacts'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}'
      },
      body: jsonEncode(contact),
    );
    fetchContacts();
  }

  @override
  void initState() {
    super.initState();
    fetchContacts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Contacts"),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: logout),
        ],
      ),
      body: Column(
        children: [
          // 🔍 Search Field
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search by alphabet (e.g. A)',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: filterContacts,
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : filteredContacts.isEmpty
                    ? const Center(child: Text("No contacts found"))
                    : ListView.builder(
                        itemCount: filteredContacts.length,
                        itemBuilder: (context, i) {
                          final c = filteredContacts[i];
                          return ListTile(
                            title: Text(c['name'] ?? ''),
                            subtitle: Text(c['phone'] ?? ''),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AddEditContact(
                                          token: widget.token,
                                          contact: c,
                                        ),
                                      ),
                                    );
                                    fetchContacts();
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => deleteContact(c['_id']),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddEditContact(token: widget.token),
            ),
          );
          fetchContacts();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

//
// ---------------- ADD / EDIT CONTACT ----------------
//
class AddEditContact extends StatefulWidget {
  final String token;
  final Map? contact;
  const AddEditContact({super.key, required this.token, this.contact});

  @override
  State<AddEditContact> createState() => _AddEditContactState();
}

class _AddEditContactState extends State<AddEditContact> {
  late TextEditingController nameCtrl;
  late TextEditingController emailCtrl;
  late TextEditingController addressCtrl;
  String phone = '';
  bool loading = false;

  Future<void> saveContact() async {
    setState(() => loading = true);
    final body = jsonEncode({
      'name': nameCtrl.text,
      'phone': phone,
      'email': emailCtrl.text,
      'address': addressCtrl.text
    });

    try {
      if (widget.contact == null) {
        await http.post(
          Uri.parse('$baseUrl/contacts'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${widget.token}'
          },
          body: body,
        );
      } else {
        await http.put(
          Uri.parse('$baseUrl/contacts/${widget.contact!['_id']}'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${widget.token}'
          },
          body: body,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (_) {}
    setState(() => loading = false);
  }

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.contact?['name'] ?? '');
    emailCtrl = TextEditingController(text: widget.contact?['email'] ?? '');
    addressCtrl = TextEditingController(text: widget.contact?['address'] ?? '');
    phone = widget.contact?['phone'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: Text(widget.contact == null ? "Add Contact" : "Edit Contact")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              decoration: const InputDecoration(labelText: "Name"),
              controller: nameCtrl,
            ),
            IntlPhoneField(
              decoration: const InputDecoration(labelText: "Phone Number"),
              initialCountryCode: "IN",
              initialValue: phone,
              onChanged: (p) => phone = p.completeNumber,
            ),
            TextField(
              decoration: const InputDecoration(labelText: "Email"),
              controller: emailCtrl,
            ),
            TextField(
              decoration: const InputDecoration(labelText: "Address"),
              controller: addressCtrl,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : saveContact,
              child: Text(loading ? "Saving..." : "Save"),
            ),
          ],
        ),
      ),
    );
  }
}
