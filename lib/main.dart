import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const PresenceApp());
}

class PresenceApp extends StatelessWidget {
  const PresenceApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Présence QR Gafsa',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0875D1)),
        fontFamily: 'Roboto',
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool obscurePassword = true;
  bool isStudent = true;
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async{
    if (emailController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar
          (content: Text('veuillez remplir tous les champs '),
          ),
      );
      return;

    }
    setState(() {
      isLoading = true;

    });
    try{
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword
      (email: emailController.text.trim(),
       password: passwordController.text,
       );
       final user = credential.user;
       if(user == null){
        throw Exception('utilisateur introuvable');
       }
       //récupérer le profil dans firestore
       final userDoc = await FirebaseFirestore.instance.collection('users')
       .doc(user.uid)
       .get();
       //vérifier si le profil existe
       if (!userDoc.exists){
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
         ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Profil utilisateur introuvable'),
    ),
  );
  return;



       }
       final userData = userDoc.data()!;
       final roleFirestore = userData['role'];
       final actif = userData['actif'] == true;
       final roleChoisi = isStudent ? 'etudiant' : 'enseignant';

       // vérifier si le compte est actif
       if(!actif){
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
         ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('votre compte est désactivé'),
    ),
  );
  return;
       }
       //vérifier le role sélectionner
       if (roleFirestore != roleChoisi){
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
         ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Le role selectionné ne correspond pas au compte'),
    ),
  );
  return;

       }
       if (!mounted) return;
         ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Connexion réussie : $roleFirestore'),
    ),
  );
      
    
    } 
    on FirebaseAuthException catch (e){
      String message = 'Erreur de connexion';
      if (e.code == 'user-not-found'){
        message= 'Aucun compte trouvé avec cet e-mail';
      }
      else if (e.code == 'wrong-password' ||
    e.code == 'invalid-credential') {
  message = 'E-mail ou mot de passe incorrect';
} else if (e.code == 'network-request-failed') {
  message = 'Vérifiez votre connexion Internet';
}
      if(!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  } catch(e) {
    debugPrint('ERREUR CONNEXION : $e');
    if(!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(
        content: Text('Erreur : $e'),
        duration: const Duration(seconds: 8),
        ),
    );
  } finally {
    if (mounted){
      setState(() {
        isLoading=false;
      });
    }
  }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEAF7FF), Colors.white, Color(0xFFD5ECFF)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
            child: Column(
              children: [
                const SizedBox(height: 15),
                //LOGO ISAEG
                Image.asset(
                  'assets/isaeg_logo.jpg',
                  height: 135,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 18),
                const Text(
                  'Gestion des présence ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF103A78),
                  ),
                ),
                const Text(
                  'par Qr code',
                  style: TextStyle(fontSize: 24, color: Color(0xFF0875D1)),
                ),
                const SizedBox(height: 15),
                const Icon(
                  Icons.qr_code_scanner,
                  size: 65,
                  color: Color(0xFF079DE5),
                ),
                const SizedBox(height: 25),
                //formulaire
                Container(
                  padding: const EdgeInsets.all(0),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withValues(alpha: 0.12),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Adresse e-mail',
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Mot de Passe',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Récupération du mot de passe à connecter',
                                ),
                              ),
                            );
                          },
                          child: const Text('Mot de passe oublié ?'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      //connexion
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: ElevatedButton.icon(
                          onPressed: login,
                          icon: const Icon(Icons.login),
                          label: const Text(
                            'se connecter',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF103A78),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 15),
                            child: Text('ou'),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 18),
                      //creer compte
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Page de création de compte a realisé',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.person_add_alt_1),
                          label: const Text(
                            'créer un compte',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF103A78),
                            side: const BorderSide(
                              color: Color(0xFF103A78),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      const Text(
                        'connectez-vous en tant que:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF103A78),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: roleCard('Étudiant', Icons.school, true),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: roleCard(
                              'Enseignant',
                              Icons.co_present,
                              false,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                const Text(
                  'Présence QR Gafsa © 2026',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF103A78),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget roleCard(String title, IconData iconData, bool student) {
    final selected = isStudent == student;
    return GestureDetector(
      onTap: () {
        setState(() {
          isStudent = student;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 125,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFD9F0FF) : const Color(0xFFF7FAFF),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? const Color(0xFF0875D1) : const Color(0xFFE0E7F0),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(iconData, size: 42, color: const Color(0xFF103A78)),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF103A78),
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF0875D1),
                size: 19,
              ),
          ],
        ),
      ),
    );
  }
}
