import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttericon/font_awesome_icons.dart';
import 'package:job_clone_app/user_state.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../Widgets/bottom_nav_bar.dart';

class ProfileScreen extends StatefulWidget {

  final String userID;

  const ProfileScreen({super.key, required this.userID});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {

  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? name;
  String email = '';
  String phoneNumber = '';
  String imageUrl = '';
  String joinedAt = '';
  bool _isLoading = false;
  bool _isSameUser = false;

  late AnimationController _animationController;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _appBarAnimation;

  @override
  void initState() {
    super.initState();
    getUserData();
    // Initialize animation controller for background and app bar animation
    _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 20));
    _backgroundAnimation = CurvedAnimation(parent: _animationController, curve: Curves.linear)
      ..addListener(() {
        setState(() {});
      });

    // Animation for AppBar (size/height effect)
    _appBarAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut)
      ..addListener(() {
        setState(() {});
      });

    // Start the animation for background
    _animationController.repeat();
  }

  void getUserData() async {
    try {
      _isLoading = true;
      final DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userID)
          .get();
      if (userDoc.exists) {
        setState(() {
          name = userDoc.get('name');
          email = userDoc.get('email');
          phoneNumber = userDoc.get('phoneNumber');
          imageUrl = userDoc.get('userImage');
          Timestamp joinedAtTimeStamp = userDoc.get('createdAt');
          var joinedDate = joinedAtTimeStamp.toDate();
          joinedAt = '${joinedDate.year} - ${joinedDate.month} - ${joinedDate.day}';
        });
        User? user = _auth.currentUser;
        final _uid = user!.uid;
        setState(() {
          _isSameUser = _uid == widget.userID;
        });
      } else {
        print('User document does not exist');
      }
    } catch (error) {
      print('Error fetching user data: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget userInfo({required IconData icon, required String content})
  {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.white,
        ),
        Padding(
            padding: EdgeInsets.symmetric(horizontal: 7),
        child: Text(
          content,
          style: TextStyle(
            color: Colors.white54,
          ),
        ),),
      ],
    );
  }

  Widget _contactBy({
    required Color color, required Function fct, required IconData icon
})
{
  return CircleAvatar(
    backgroundColor: color,
    radius: 25,
    child: CircleAvatar(
      radius: 23,
      backgroundColor: Colors.white,
      child: IconButton(
        onPressed: () {
          fct();
        },
        icon: Icon(
            icon,
          color: color,
        ),
      ),
    ),
  );
}

void _openWhatsAppChat() async
{
    var url = 'https://wa.me/$phoneNumber?text=Hello WhatsUp!';
    launchUrlString(url);
}

void _mailTo() async {
    final Uri params = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Write subject here, Please&body=Hello, please write details here',
    );
    final url = params.toString();
    launchUrlString(url);
}

  void _callPhoneNumber() async
  {
    var url = 'tel://$phoneNumber';
    launchUrlString(url);
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return AnimatedBuilder(
        animation: _backgroundAnimation,
        builder: (context, child) {
      return Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(
              'https://images.unsplash.com/photo-1511527661048-7fe73d85e9a4?q=80&w=1965&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
            ),
            fit: BoxFit.cover,
            alignment: FractionalOffset(_backgroundAnimation.value, 0),
          ),
        ),
      child: Scaffold(
        bottomNavigationBar: BottomNavigationBarForApp(
            indexNum: 3),
        backgroundColor: Colors.transparent,
        body: Center(
          child: _isLoading
              ?
              Center(child: CircularProgressIndicator(),)
              :
              SingleChildScrollView(
                child: Padding(padding: EdgeInsets.only(top: 0),
                child: Stack(
                  children: [
                    Card(
                      color: Colors.white10,
                      margin: EdgeInsets.all(27),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Padding(
                          padding: EdgeInsets.all(5.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 100,),
                          Align(
                           alignment: Alignment.center,
                            child: Text(
                              name == null
                                  ?
                                  'Name here'
                                  :
                                  name!,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 21.0,
                              ),
                            ),
                          ),
                          SizedBox(height: 12,),
                          Divider(
                            thickness: 1,
                            color: Colors.white,
                          ),
                          SizedBox(height: 27,),
                          Padding(
                              padding: EdgeInsets.all(7.0),
                          child: Text(
                            'Account Information :',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 19.0,
                            ),
                          ),
                          ),
                          SizedBox(
                            height: 12,
                          ),
                          Padding(
                              padding: EdgeInsets.only(left: 7),
                          child: userInfo(
                              icon: Icons.email,
                              content: email),
                          ),
                          Padding(
                            padding: EdgeInsets.only(left: 7),
                            child: userInfo(
                                icon: Icons.phone,
                                content: phoneNumber),
                          ),
                          SizedBox(
                            height: 15,
                          ),
                          Divider(
                            thickness: 1,
                            color: Colors.white,
                          ),
                          SizedBox(
                            height: 35,
                          ),
                          _isSameUser
                          ?
                              Container()
                          :
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _contactBy(
                                      color: Colors.green,
                                      fct: (){
                                        _openWhatsAppChat();
                                      },
                                      icon: FontAwesome.whatsapp,),
                                  _contactBy(
                                    color: Colors.red,
                                    fct: (){
                                      _mailTo();
                                    },
                                    icon: Icons.mail_outline,),
                                  _contactBy(
                                    color: Colors.purple,
                                    fct: (){
                                      _callPhoneNumber();
                                    },
                                    icon: Icons.call,),
                                ],
                              ),
                          !_isSameUser
                          ?
                              Container()
                              :
                              Center(
                                child: Padding(
                                    padding: EdgeInsets.only(bottom: 30),
                                child: MaterialButton(
                                    onPressed: (){
                                      _auth.signOut();
                                      Navigator.push(context, MaterialPageRoute(builder: (context)=>UserState()));
                                    },
                                  color: Colors.black,
                                  elevation: 8,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                  child: Padding(
                                      padding: EdgeInsets.symmetric(vertical: 14),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Logout',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Signatra',
                                            fontSize: 28,
                                          ),
                                        ),
                                        SizedBox(width: 8,),
                                        Icon(
                                            Icons.logout,
                                          color: Colors.white,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                ),
                              ),
                        ],
                      ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: size.width * 0.26,
                          height: size.width * 0.26,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(
                              width: 8,
                              color: Theme.of(context).scaffoldBackgroundColor,
                            ),
                            image: DecorationImage(
                                image: NetworkImage(
                                  imageUrl == null
                                      ?
                                      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSm6khwcQVea71OSRDqWljeBz8gyhQDba55DQ&s'
                                      :
                                      imageUrl,
                                ),
                              fit: BoxFit.fill,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                ),
              ),
        ),
      ),
    );
  });
}}
