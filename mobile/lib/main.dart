import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'database_helper.dart';
import 'history_screen.dart';

void main() {
  runApp(const SocialShieldAI());
}

// ============================================================
// API CONFIGURATION
// ============================================================

// IMPORTANT:
// For Android Emulator use:
// const String apiBaseUrl = '192.168.1.105:8000';
//
// For your physical phone, replace this with your LAPTOP'S
// local IPv4 address, for example:
// const String apiBaseUrl = '192.168.1.105:8000';

const String apiBaseUrl = '192.168.1.105:8000';


// ============================================================
// APP
// ============================================================

class SocialShieldAI extends StatelessWidget {
  const SocialShieldAI({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SocialShieldAI',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// ============================================================
// HELPER MESSAGE
// ============================================================

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

// ============================================================
// PROFILE MODEL
// ============================================================

class ProfileData {
  final String username;
  final int followers;
  final int following;
  final String biography;
  final int mediaCount;
  final int hasProfilePicture;
  final int isPrivate;

  ProfileData({
    required this.username,
    required this.followers,
    required this.following,
    required this.biography,
    required this.mediaCount,
    required this.hasProfilePicture,
    required this.isPrivate,
  });

  int get usernameLength => username.length;

  int get usernameDigitCount {
    return username
        .split('')
        .where((character) => RegExp(r'[0-9]').hasMatch(character))
        .length;
  }

  int get biographyLength => biography.length;

  Map<String, dynamic> toJson() {
    return {
      'userFollowerCount': followers,
      'userFollowingCount': following,
      'userBiographyLength': biographyLength,
      'userMediaCount': mediaCount,
      'userHasProfilPic': hasProfilePicture,
      'userIsPrivate': isPrivate,
      'usernameDigitCount': usernameDigitCount,
      'usernameLength': usernameLength,
    };
  }
}

// ============================================================
// API SERVICE
// ============================================================

class ApiService {
  Future<Map<String, dynamic>> analyzeProfile(
    ProfileData profile,
  ) async {
    final response = await http
        .post(
          Uri.parse('$apiBaseUrl/predict'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode(profile.toJson()),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception(
        'Server error: ${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body);

    if (data['error'] != null) {
      throw Exception(data['error'].toString());
    }

    return Map<String, dynamic>.from(data);
  }
}

// ============================================================
// 1. SPLASH SCREEN
// ============================================================

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.shield,
                    size: 75,
                    color: Colors.indigo,
                  ),
                ),

                const SizedBox(height: 30),

                const Text(
                  'SocialShieldAI',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'Secure Social Media with AI',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 50),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'NEXT',
                      style: TextStyle(fontSize: 17),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// 2. LOGIN SCREEN
// ============================================================

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  final DatabaseHelper dbHelper = DatabaseHelper();

  bool hidePassword = true;
  bool loading = false;

  Future<void> login() async {
    final usernameOrEmail =
        usernameController.text.trim();

    final password = passwordController.text;

    if (usernameOrEmail.isEmpty || password.isEmpty) {
      showMessage(
        context,
        'Please enter login details.',
      );
      return;
    }

    setState(() {
      loading = true;
    });

    final user = await dbHelper.loginUser(
      usernameOrEmail,
      password,
    );

    if (!mounted) return;

    setState(() {
      loading = false;
    });

    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            userId: user['id'] as int,
            name: user['name'] as String,
          ),
        ),
      );
    } else {
      showMessage(
        context,
        'Invalid username/email or password.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            const SizedBox(height: 25),

            const Icon(
              Icons.lock_outline,
              size: 75,
              color: Colors.indigo,
            ),

            const SizedBox(height: 20),

            const Text(
              'Welcome Back!',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 35),

            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: 'Email / Username',
                prefixIcon: Icon(Icons.person),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: passwordController,
              obscureText: hidePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    hidePassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      hidePassword = !hidePassword;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 10),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const ForgotPasswordScreen(),
                    ),
                  );
                },
                child: const Text('Forgot Password?'),
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: loading ? null : login,
                child: loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'LOGIN',
                        style: TextStyle(fontSize: 17),
                      ),
              ),
            ),

            const SizedBox(height: 15),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                const Text("Don't have an account?"),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const RegistrationScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Create an Account',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 3. REGISTRATION
// ============================================================

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() =>
      _RegistrationScreenState();
}

class _RegistrationScreenState
    extends State<RegistrationScreen> {
  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  final DatabaseHelper dbHelper = DatabaseHelper();

  bool hidePassword = true;
  bool hideConfirmPassword = true;
  bool loading = false;

  Future<void> register() async {
    final name = nameController.text.trim();
    final username = usernameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmController.text;

    if (name.isEmpty ||
        username.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      showMessage(
        context,
        'Please fill all the fields.',
      );
      return;
    }

    if (username.length < 3) {
      showMessage(
        context,
        'Username must be at least 3 characters.',
      );
      return;
    }

    final emailPattern =
        RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (!emailPattern.hasMatch(email)) {
      showMessage(
        context,
        'Please enter a valid email address.',
      );
      return;
    }

    if (password.length < 6) {
      showMessage(
        context,
        'Password must contain at least 6 characters.',
      );
      return;
    }

    if (password != confirmPassword) {
      showMessage(
        context,
        'Passwords do not match.',
      );
      return;
    }

    setState(() {
      loading = true;
    });

    final usernameExists =
        await dbHelper.userExists(username);

    final emailExists =
        await dbHelper.userExists(email);

    if (!mounted) return;

    if (usernameExists || emailExists) {
      setState(() {
        loading = false;
      });

      showMessage(
        context,
        'Username or email already exists.',
      );
      return;
    }

    final success = await dbHelper.registerUser(
      name,
      username,
      email,
      password,
    );

    if (!mounted) return;

    setState(() {
      loading = false;
    });

    if (success) {
      showMessage(
        context,
        'Registration successful! Please login.',
      );

      Navigator.pop(context);
    } else {
      showMessage(
        context,
        'Registration failed. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            const Icon(
              Icons.person_add,
              size: 70,
              color: Colors.indigo,
            ),

            const SizedBox(height: 20),

            const Text(
              'Create Your Account',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            TextField(
              controller: nameController,
              textCapitalization:
                  TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(Icons.alternate_email),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: emailController,
              keyboardType:
                  TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: passwordController,
              obscureText: hidePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    hidePassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      hidePassword = !hidePassword;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: confirmController,
              obscureText: hideConfirmPassword,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon:
                    const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    hideConfirmPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      hideConfirmPassword =
                          !hideConfirmPassword;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: loading ? null : register,
                child: loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'REGISTER',
                        style: TextStyle(fontSize: 17),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 4. FORGOT PASSWORD
// ============================================================

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends State<ForgotPasswordScreen> {
  final identifierController = TextEditingController();

  final DatabaseHelper dbHelper = DatabaseHelper();

  bool loading = false;

  Future<void> continueReset() async {
    final identifier =
        identifierController.text.trim();

    if (identifier.isEmpty) {
      showMessage(
        context,
        'Please enter your email or username.',
      );
      return;
    }

    setState(() {
      loading = true;
    });

    final exists =
        await dbHelper.userExists(identifier);

    if (!mounted) return;

    setState(() {
      loading = false;
    });

    if (!exists) {
      showMessage(
        context,
        'No account found with these details.',
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResetPasswordScreen(
          identifier: identifier,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            const SizedBox(height: 30),

            const Icon(
              Icons.lock_reset,
              size: 75,
              color: Colors.indigo,
            ),

            const SizedBox(height: 20),

            const Text(
              'Reset Your Password',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            const Text(
              'Enter your registered email or username.',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 30),

            TextField(
              controller: identifierController,
              decoration: const InputDecoration(
                labelText: 'Email / Username',
                prefixIcon: Icon(Icons.email),
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed:
                    loading ? null : continueReset,
                child: loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('CONTINUE'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 5. RESET PASSWORD
// ============================================================

class ResetPasswordScreen extends StatefulWidget {
  final String identifier;

  const ResetPasswordScreen({
    super.key,
    required this.identifier,
  });

  @override
  State<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState
    extends State<ResetPasswordScreen> {
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  final DatabaseHelper dbHelper = DatabaseHelper();

  bool loading = false;

  Future<void> resetPassword() async {
    final password = passwordController.text;
    final confirmPassword =
        confirmController.text;

    if (password.isEmpty ||
        confirmPassword.isEmpty) {
      showMessage(
        context,
        'Please enter both passwords.',
      );
      return;
    }

    if (password.length < 6) {
      showMessage(
        context,
        'Password must contain at least 6 characters.',
      );
      return;
    }

    if (password != confirmPassword) {
      showMessage(
        context,
        'Passwords do not match.',
      );
      return;
    }

    setState(() {
      loading = true;
    });

    final success = await dbHelper.resetPassword(
      widget.identifier,
      password,
    );

    if (!mounted) return;

    setState(() {
      loading = false;
    });

    if (success) {
      showMessage(
        context,
        'Password updated successfully!',
      );

      Navigator.popUntil(
        context,
        (route) => route.isFirst,
      );
    } else {
      showMessage(
        context,
        'Unable to update password.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set New Password'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            const SizedBox(height: 30),

            const Icon(
              Icons.password,
              size: 70,
              color: Colors.indigo,
            ),

            const SizedBox(height: 25),

            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                prefixIcon: Icon(Icons.lock),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: confirmController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed:
                    loading ? null : resetPassword,
                child: loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('SET PASSWORD'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 6. HOME SCREEN
// ============================================================

class HomeScreen extends StatelessWidget {
  final int userId;
  final String name;

  const HomeScreen({
    super.key,
    required this.userId,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SocialShieldAI'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.shield,
              size: 90,
              color: Colors.indigo,
            ),

            const SizedBox(height: 25),

            Text(
              'Hello, $name 👋',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            const Text(
              "Let's detect suspicious profiles.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 35),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.search),
                label: const Text(
                  "LET'S START",
                  style: TextStyle(fontSize: 17),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          TestingLabScreen(
                        userId: userId,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.history),
                label: const Text(
                  'SCAN HISTORY',
                  style: TextStyle(fontSize: 16),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HistoryScreen(
                        userId: userId,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 7. PROFILE TESTING LAB
// ============================================================

class TestingLabScreen extends StatelessWidget {
  final int userId;

  const TestingLabScreen({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Testing Lab'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            const Icon(
              Icons.biotech,
              size: 75,
              color: Colors.indigo,
            ),

            const SizedBox(height: 15),

            const Text(
              'AI Profile Testing Lab',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Test sample profiles or create your own '
              'profile to analyze it using AI.',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 35),

            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.people),
                label: const Text(
                  'TEST SAMPLE PROFILES',
                  style: TextStyle(fontSize: 16),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          SampleProfilesScreen(
                        userId: userId,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 60,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.person_add),
                label: const Text(
                  'CREATE YOUR OWN PROFILE',
                  style: TextStyle(fontSize: 16),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          CreateProfileScreen(
                        userId: userId,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SAMPLE DATA
// ============================================================

final List<ProfileData> sampleProfiles = [
  ProfileData(
    username: 'john_doe',
    followers: 258,
    following: 238,
    biography: '',
    mediaCount: 0,
    hasProfilePicture: 1,
    isPrivate: 0,
  ),

  ProfileData(
    username: 'user123456',
    followers: 25,
    following: 1937,
    biography: '',
    mediaCount: 0,
    hasProfilePicture: 1,
    isPrivate: 1,
  ),

  ProfileData(
    username: 'travellover',
    followers: 2207,
    following: 593,
    biography:
        'Travel enthusiast and photographer',
    mediaCount: 198,
    hasProfilePicture: 1,
    isPrivate: 0,
  ),

  ProfileData(
    username: 'fake98765',
    followers: 15,
    following: 399,
    biography: '',
    mediaCount: 0,
    hasProfilePicture: 0,
    isPrivate: 0,
  ),
];

// ============================================================
// 8. SAMPLE PROFILES
// ============================================================

class SampleProfilesScreen extends StatelessWidget {
  final int userId;

  const SampleProfilesScreen({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sample Profiles'),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(15),
        itemCount: sampleProfiles.length,
        itemBuilder: (context, index) {
          final profile = sampleProfiles[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 15),
            elevation: 3,
            child: ListTile(
              contentPadding:
                  const EdgeInsets.all(15),
              leading: CircleAvatar(
                backgroundColor:
                    Colors.indigo.shade50,
                child: const Icon(
                  Icons.person,
                  color: Colors.indigo,
                ),
              ),
              title: Text(
                '@${profile.username}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                '${profile.followers} followers • '
                '${profile.following} following',
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 18,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ProfileDetailsScreen(
                      userId: userId,
                      profile: profile,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// 9. CREATE YOUR OWN PROFILE
// ============================================================

class CreateProfileScreen extends StatefulWidget {
  final int userId;

  const CreateProfileScreen({
    super.key,
    required this.userId,
  });

  @override
  State<CreateProfileScreen> createState() =>
      _CreateProfileScreenState();
}

class _CreateProfileScreenState
    extends State<CreateProfileScreen> {
  final usernameController =
      TextEditingController();

  final followersController =
      TextEditingController();

  final followingController =
      TextEditingController();

  final biographyController =
      TextEditingController();

  final mediaController =
      TextEditingController();

  int hasProfilePicture = 1;
  int isPrivate = 0;

  int? positiveNumber(String text) {
    return int.tryParse(text.trim());
  }

  void continueToDetails() {
    final username =
        usernameController.text.trim();

    final followers =
        positiveNumber(followersController.text);

    final following =
        positiveNumber(followingController.text);

    final media =
        positiveNumber(mediaController.text);

    final biography =
        biographyController.text;

    if (username.isEmpty ||
        followers == null ||
        following == null ||
        media == null) {
      showMessage(
        context,
        'Please enter valid profile details.',
      );
      return;
    }

    if (followers < 0 ||
        following < 0 ||
        media < 0) {
      showMessage(
        context,
        'Values cannot be negative.',
      );
      return;
    }

    if (username.length > 50) {
      showMessage(
        context,
        'Username is too long.',
      );
      return;
    }

    final profile = ProfileData(
      username: username,
      followers: followers,
      following: following,
      biography: biography,
      mediaCount: media,
      hasProfilePicture: hasProfilePicture,
      isPrivate: isPrivate,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileDetailsScreen(
          userId: widget.userId,
          profile: profile,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Profile'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.person_search,
              size: 70,
              color: Colors.indigo,
            ),

            const SizedBox(height: 20),

            const Text(
              'Enter Profile Details',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 25),

            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                prefixIcon:
                    Icon(Icons.alternate_email),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: followersController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Followers',
                prefixIcon:
                    Icon(Icons.people),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: followingController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Following',
                prefixIcon:
                    Icon(Icons.person_add),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: biographyController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Biography',
                hintText:
                    'Enter profile biography',
                prefixIcon:
                    Icon(Icons.description),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: mediaController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Posts / Media Count',
                prefixIcon:
                    Icon(Icons.photo_library),
              ),
            ),

            const SizedBox(height: 20),

            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text(
                      'Profile Picture',
                    ),
                    subtitle: Text(
                      hasProfilePicture == 1
                          ? 'Available'
                          : 'Not available',
                    ),
                    value:
                        hasProfilePicture == 1,
                    onChanged: (value) {
                      setState(() {
                        hasProfilePicture =
                            value ? 1 : 0;
                      });
                    },
                  ),

                  SwitchListTile(
                    title: const Text(
                      'Private Account',
                    ),
                    subtitle: Text(
                      isPrivate == 1
                          ? 'Private'
                          : 'Public',
                    ),
                    value: isPrivate == 1,
                    onChanged: (value) {
                      setState(() {
                        isPrivate =
                            value ? 1 : 0;
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: continueToDetails,
                child: const Text(
                  'VIEW PROFILE DETAILS',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 10. PROFILE DETAILS
// ============================================================

class ProfileDetailsScreen extends StatelessWidget {
  final int userId;
  final ProfileData profile;

  const ProfileDetailsScreen({
    super.key,
    required this.userId,
    required this.profile,
  });

  Widget detailRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 8,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.indigo,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void analyze(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnalysisLoadingScreen(
          userId: userId,
          profile: profile,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Details'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 45,
              backgroundColor:
                  Colors.indigo.shade50,
              child: const Icon(
                Icons.person,
                size: 50,
                color: Colors.indigo,
              ),
            ),

            const SizedBox(height: 15),

            Text(
              '@${profile.username}',
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 25),

            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    detailRow(
                      Icons.people,
                      'Followers',
                      '${profile.followers}',
                    ),
                    detailRow(
                      Icons.person_add,
                      'Following',
                      '${profile.following}',
                    ),
                    detailRow(
                      Icons.description,
                      'Biography Length',
                      '${profile.biographyLength}',
                    ),
                    detailRow(
                      Icons.photo_library,
                      'Media Count',
                      '${profile.mediaCount}',
                    ),
                    detailRow(
                      Icons.account_circle,
                      'Profile Picture',
                      profile.hasProfilePicture == 1
                          ? 'Yes'
                          : 'No',
                    ),
                    detailRow(
                      Icons.lock,
                      'Account',
                      profile.isPrivate == 1
                          ? 'Private'
                          : 'Public',
                    ),
                    detailRow(
                      Icons.numbers,
                      'Username Digits',
                      '${profile.usernameDigitCount}',
                    ),
                    detailRow(
                      Icons.text_fields,
                      'Username Length',
                      '${profile.usernameLength}',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () => analyze(context),
                icon: const Icon(Icons.psychology),
                label: const Text(
                  'ANALYZE WITH AI',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 11. AI LOADING
// ============================================================

class AnalysisLoadingScreen extends StatefulWidget {
  final int userId;
  final ProfileData profile;

  const AnalysisLoadingScreen({
    super.key,
    required this.userId,
    required this.profile,
  });

  @override
  State<AnalysisLoadingScreen> createState() =>
      _AnalysisLoadingScreenState();
}

class _AnalysisLoadingScreenState
    extends State<AnalysisLoadingScreen> {
  final ApiService apiService = ApiService();

  String status = 'Preparing profile data...';

  @override
  void initState() {
    super.initState();
    analyzeProfile();
  }

  Future<void> analyzeProfile() async {
    await Future.delayed(
      const Duration(milliseconds: 500),
    );

    if (!mounted) return;

    setState(() {
      status = 'Sending data to AI model...';
    });

    try {
      final result =
          await apiService.analyzeProfile(
        widget.profile,
      );

      if (!mounted) return;

      setState(() {
        status = 'AI analysis completed!';
      });

      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AnalysisResultScreen(
            userId: widget.userId,
            profile: widget.profile,
            result: result,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      Navigator.pop(context);

      showMessage(
        context,
        'Could not connect to AI server.\n'
        'Make sure FastAPI is running.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Analysis'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.psychology,
                size: 90,
                color: Colors.indigo,
              ),

              const SizedBox(height: 30),

              const CircularProgressIndicator(),

              const SizedBox(height: 30),

              const Text(
                'AI is analyzing the profile...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              Text(
                status,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// 12. ANALYSIS RESULT
// ============================================================

class AnalysisResultScreen extends StatelessWidget {
  final int userId;
  final ProfileData profile;
  final Map<String, dynamic> result;

  const AnalysisResultScreen({
    super.key,
    required this.userId,
    required this.profile,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final prediction =
        result['prediction']?.toString() ?? 'UNKNOWN';

    final confidence =
        result['confidence'] is num
            ? (result['confidence'] as num).toDouble()
            : 0.0;

    final confidenceLevel =
        result['confidence_level']
                ?.toString() ??
            'Unknown';

    final factors =
        result['risk_factors'] is List
            ? List<String>.from(
                result['risk_factors'],
              )
            : <String>[];

    final isFake = prediction == 'FAKE';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis Result'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              isFake
                  ? Icons.warning_amber_rounded
                  : Icons.verified,
              size: 90,
              color: isFake
                  ? Colors.orange
                  : Colors.green,
            ),

            const SizedBox(height: 15),

            Text(
              prediction,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: isFake
                    ? Colors.orange
                    : Colors.green,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              '@${profile.username}',
              style: const TextStyle(
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 25),

            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      'AI Confidence',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      '${confidence.toStringAsFixed(2)}%',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      'Confidence Level: '
                      '$confidenceLevel',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Risk Indicators',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 10),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  children: factors.map(
                    (factor) {
                      return ListTile(
                        contentPadding:
                            EdgeInsets.zero,
                        leading: Icon(
                          Icons.info_outline,
                          color: isFake
                              ? Colors.orange
                              : Colors.indigo,
                        ),
                        title: Text(factor),
                      );
                    },
                  ).toList(),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Card(
              color: Colors.indigo.shade50,
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Text(
                  isFake
                      ? 'This profile shows indicators '
                        'associated with suspicious or '
                        'fake profiles. Consider '
                        'verifying the account before '
                        'trusting it.'
                      : 'The AI model did not detect '
                        'major fake-profile indicators '
                        'in this profile.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  final db =
                      DatabaseHelper();

                  await db.saveScanHistory(
                    userId: userId,
                    profileUsername:
                        profile.username,
                    prediction: prediction,
                    confidence: confidence,
                    confidenceLevel:
                        confidenceLevel,
                    riskFactors:
                        factors.join(' | '),
                  );

                  if (!context.mounted) return;

                  showMessage(
                    context,
                    'Analysis saved to history.',
                  );
                },
                child: const Text(
                  'SAVE TO HISTORY',
                ),
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.popUntil(
                    context,
                    (route) =>
                        route.settings.name == null ||
                        route.isFirst,
                  );
                },
                child: const Text(
                  'BACK TO TESTING LAB',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

