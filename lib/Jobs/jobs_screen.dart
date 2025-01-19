import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:job_clone_app/Search/search_job.dart';
import 'package:job_clone_app/Widgets/bottom_nav_bar.dart';
import 'package:job_clone_app/Widgets/job_widget.dart';
import 'package:job_clone_app/user_state.dart';
import '../Persistent/persistent.dart';
import 'dart:async';

class JobScreen extends StatefulWidget {
  @override
  State<JobScreen> createState() => _JobScreenState();
}

class _JobScreenState extends State<JobScreen> with SingleTickerProviderStateMixin {
  String? jobCategoryFilter;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late AnimationController _animationController;
  late Animation<Offset> _backgroundAnimation;
  late Animation<double> _backgroundOpacity;

  bool isDialogOpen = false; // Flag to track if the dialog is open

  @override
  void initState() {
    super.initState();
    Persistent persistentObject = Persistent();
    persistentObject.getMyData();

    // Initialize Animation Controller
    _animationController = AnimationController(
      duration: Duration(seconds: 10), // Duration for the animation
      vsync: this,
    );

    // Create animation to translate the background continuously
    _backgroundAnimation = Tween<Offset>(
      begin: Offset(0, 0),
      end: Offset(0, -1),
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.linear),
    );

    // Animation for the opacity of the background image
    _backgroundOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Start the animation (loop it)
    _animationController.repeat();
  }

  // Show the job categories dialog
  _showTaskCategoriesDialog({required Size size}) {
    if (isDialogOpen) return; // Prevent opening if the dialog is already open

    setState(() {
      isDialogOpen = true; // Mark the dialog as open
    });

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.black54,
          title: Text(
            'Job Category',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          content: Container(
            width: size.width * 0.8, // Reduce width slightly
            height: size.height * 0.35,
            child: Scrollbar( // Add a scrollbar for easier navigation
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: Persistent.JobCategoryList.length,
                itemBuilder: (ctx, index) {
                  return InkWell(
                    onTap: () {
                      setState(() {
                        jobCategoryFilter = Persistent.JobCategoryList[index];
                      });
                      Navigator.canPop(context) ? Navigator.pop(context) : null;
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 5.0, horizontal: 10.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.arrow_right_alt_outlined,
                            color: Colors.grey,
                          ),
                          SizedBox(width: 8), // Add some spacing
                          Expanded( // Constrain the width of the text
                            child: Text(
                              Persistent.JobCategoryList[index],
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow
                                  .ellipsis, // Prevent overflow
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.canPop(context) ? Navigator.pop(context) : null;
                setState(() {
                  isDialogOpen = false; // Mark the dialog as closed when it's dismissed
                });
              },
              child: Text(
                'Close',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
            TextButton(
                onPressed: () {
                  setState(() {
                    jobCategoryFilter = null;
                  });
                  Navigator.canPop(context) ? Navigator.pop(context) : null;
                  setState(() {
                    isDialogOpen = false; // Mark the dialog as closed when it's dismissed
                  });
                },
                child: Text(
                  'Cancel Filter', style: TextStyle(color: Colors.white),)),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose(); // Clean up the animation controller when done
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      bottomNavigationBar: BottomNavigationBarForApp(indexNum: 0),
      backgroundColor: Colors.white, // Set the background to white
      body: Stack(
        children: [
          // Gradient background behind the job cards
          Positioned.fill(
            top: 100, // Adjusted to align with AppBar and make space for the animation
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.deepOrange.shade400.withOpacity(0.4),
                    Colors.blueAccent.withOpacity(0.3),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          // Animated background image moving upwards with opacity effect
          Positioned.fill(
            child: IgnorePointer(
              ignoring: _animationController.isAnimating,
              child: SlideTransition(
                position: _backgroundAnimation,
                child: FadeTransition(
                  opacity: _backgroundOpacity,
                  child: Image.network(
                    'https://images.pexels.com/photos/29702291/pexels-photo-29702291/free-photo-of-luxury-mediterranean-villa-with-pool-and-sea-view.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    color: _animationController.isAnimating
                        ? Colors.transparent
                        : Colors.black.withOpacity(0.4),
                    colorBlendMode: BlendMode.darken,
                  ),
                ),
              ),
            ),
          ),

          // AppBar with gradient color
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.shade400.withOpacity(0.3), // Lower opacity
                      Colors.blueAccent.withOpacity(0.3), // Lower opacity
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
              automaticallyImplyLeading: false,
              leading: IconButton(
                onPressed: () {
                  _showTaskCategoriesDialog(size: size);
                },
                icon: Icon(Icons.filter_list_rounded, color: Colors.black),
              ),
              actions: [
                IconButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => SearchScreen()),
                    );
                  },
                  icon: Icon(Icons.search_outlined, color: Colors.black),
                ),
              ],
            ),
          ),

          // Main Content with StreamBuilder for job listings
          Positioned.fill(
            top: 60, // Adjusted to avoid overlap with AppBar
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>( // Get job listings
              stream: FirebaseFirestore.instance
                  .collection('jobs')
                  .where('recruitment', isEqualTo: true)
                  .where('jobCategory',
                  isEqualTo: jobCategoryFilter?.isNotEmpty ?? false
                      ? jobCategoryFilter
                      : null)
                  .orderBy('createdAt', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.connectionState == ConnectionState.active) {
                  if (snapshot.data?.docs.isNotEmpty == true) {
                    return ListView.builder(
                      itemCount: snapshot.data?.docs.length,
                      itemBuilder: (context, index) {
                        var jobData = snapshot.data?.docs[index].data();
                        return JobWidget(
                          jobTitle: jobData?['jobTitle'],
                          jobDescription: jobData?['jobDescription'],
                          jobId: jobData?['jobId'],
                          uploadedBy: jobData?['uploadedBy'],
                          userImage: jobData?['userImage'],
                          name: jobData?['name'],
                          recruitment: jobData?['recruitment'],
                          email: jobData?['email'],
                          location: jobData?['location'],
                        );
                      },
                    );
                  } else {
                    return Center(child: Text('There are no jobs available'));
                  }
                }
                return Center(child: Text('Something went wrong.'));
              },
            ),
          ),
        ],
      ),
    );
  }
}
