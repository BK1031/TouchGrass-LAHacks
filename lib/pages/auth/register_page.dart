import 'package:battleship_lahacks/models/user.dart';
import 'package:battleship_lahacks/utils/alert_service.dart';
import 'package:battleship_lahacks/utils/config.dart';
import 'package:battleship_lahacks/utils/theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:fluro/fluro.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {

  User registerUser = User();
  String password = "";
  bool validUsername = true;

  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  Future<void> registerEmail() async {
    if (registerUser.firstName == "" || registerUser.lastName == "" || registerUser.email == "" || registerUser.username == "" || password == "") {
      AlertService.showErrorSnackbar(context, "Please make sure to fill out all the fields!");
      return;
    }
    if (!await checkUsername(registerUser.username)) {
      AlertService.showErrorSnackbar(context, "That username is already taken!");
      return;
    }
    try {
      fb.UserCredential result = await fb.FirebaseAuth.instance.createUserWithEmailAndPassword(email: registerUser.email, password: password);
      if (result.user != null) {
        registerUser.id = result.user!.uid;
        FirebaseFirestore.instance.collection("users").doc(registerUser.id).set(registerUser.toJson());
        router.navigateTo(context, "/check-auth", transition: TransitionType.fadeIn, replace: true, clearStack: true);
      }
    } catch(err) {
      AlertService.showErrorSnackbar(context, err.toString());
    }
  }

  Future<bool> checkUsername(String username) async {
    QuerySnapshot result = await FirebaseFirestore.instance.collection("users").where("id", isEqualTo: username).get();
    return result.size == 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Battleship"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text("Create your account below!", style: TextStyle(fontSize: 16),),
            Row(
              children: [
                const Text("First Name", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),),
                const Padding(padding: EdgeInsets.all(2)),
                Expanded(
                  child: TextField(
                    controller: firstNameController,
                    textAlign: TextAlign.end,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "Alex",
                    ),
                    textCapitalization: TextCapitalization.words,
                    keyboardType: TextInputType.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
                    onChanged: (input) {
                      if (mounted) {
                        setState(() {
                          registerUser.firstName = input;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            Row(
              children: [
                const Text("Last Name", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),),
                const Padding(padding: EdgeInsets.all(2)),
                Expanded(
                  child: TextField(
                    controller: lastNameController,
                    textAlign: TextAlign.end,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "Lopes",
                    ),
                    textCapitalization: TextCapitalization.words,
                    keyboardType: TextInputType.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
                    onChanged: (input) {
                      if (mounted) {
                        setState(() {
                          registerUser.lastName = input;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            Row(
              children: [
                const Text("Username", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),),
                const Padding(padding: EdgeInsets.all(2)),
                Expanded(
                  child: TextField(
                    controller: usernameController,
                    textAlign: TextAlign.end,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "alopes",
                    ),
                    textCapitalization: TextCapitalization.none,
                    keyboardType: TextInputType.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
                    onChanged: (input) {
                      if (mounted) {
                        String formatted = input.toLowerCase().replaceAll(" ", "-");
                        setState(() {
                          registerUser.username = formatted;
                          usernameController.text = formatted;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            Row(
              children: [
                const Text("Email", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),),
                const Padding(padding: EdgeInsets.all(2)),
                Expanded(
                  child: TextField(
                    controller: emailController,
                    textAlign: TextAlign.end,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "alopes@gmail.com",
                    ),
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
                    onChanged: (input) {
                      registerUser.email = input;
                    },
                  ),
                ),
              ],
            ),
            Row(
              children: [
                const Text("Password", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),),
                const Padding(padding: EdgeInsets.all(2)),
                Expanded(
                  child: TextField(
                    controller: passwordController,
                    textAlign: TextAlign.end,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "*******"
                    ),
                    textCapitalization: TextCapitalization.none,
                    obscureText: true,
                    keyboardType: TextInputType.text,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
                    onChanged: (input) {
                      password = input;
                    },
                  ),
                ),
              ],
            ),
            const Padding(padding: EdgeInsets.all(16.0)),
            SizedBox(
              height: 50.0,
              width: double.infinity,
              child: CupertinoButton(
                color: ACCENT_COLOR,
                borderRadius: BorderRadius.circular(16),
                onPressed: () {
                  registerEmail();
                },
                child: const Text("Create Account", style: TextStyle(color: Colors.black)),
              ),
            ),
            const Padding(padding: EdgeInsets.all(8.0)),
            const Text("——  OR  ——"),
            const Padding(padding: EdgeInsets.all(8.0)),
            OutlinedButton(
              style: ButtonStyle(
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                          side: const BorderSide(color: Colors.red)
                      )
                  )
              ),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset("images/icons/google-icon.png", height: 25, width: 25,),
                    ),
                    const Padding(padding: EdgeInsets.all(4),),
                    const Text("Sign in with Google", style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
              onPressed: () {
                AlertService.showErrorDialog(context, "Google Sign-in disabled", "Please create an account with email/password for now.", () {});
              },
            ),
            const Padding(padding: EdgeInsets.all(16)),
            CupertinoButton(
              child: const Text("Already have an account?"),
              onPressed: () {
                router.navigateTo(context, "/login", transition: TransitionType.fadeIn, replace: true, clearStack: true);
              },
            )
          ],
        ),
      ),
    );
  }
}
