import 'package:battleship_lahacks/models/user.dart';
import 'package:battleship_lahacks/utils/alert_service.dart';
import 'package:battleship_lahacks/utils/config.dart';
import 'package:battleship_lahacks/utils/theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:fluro/fluro.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  String email = "";
  String password = "";

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  Future<void> loginEmail() async {
    if (email == "" || password == "") {
      AlertService.showErrorSnackbar(context, "Please make sure to fill out all the fields!");
      return;
    }
    try {
      fb.UserCredential result = await fb.FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      if (result.user != null) {
        router.navigateTo(context, "/check-auth", transition: TransitionType.fadeIn, replace: true, clearStack: true);
      }
    } catch(err) {
      AlertService.showErrorSnackbar(context, err.toString());
    }
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
            const Text("Login to your account below!", style: TextStyle(fontSize: 16),),
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
                      email = input;
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
                  loginEmail();
                },
                child: const Text("Login", style: TextStyle(color: Colors.black)),
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
              child: const Text("Don't have an account?"),
              onPressed: () {
                router.navigateTo(context, "/register", transition: TransitionType.fadeIn, replace: true, clearStack: true);
              },
            )
          ],
        ),
      ),
    );
  }
}
