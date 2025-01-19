import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:job_clone_app/Jobs/jobs_screen.dart';
import 'package:job_clone_app/Widgets/job_widget.dart';
import 'package:flutter/animation.dart';

class SearchScreen extends StatefulWidget {
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchQueryController = TextEditingController();
  String searchQuery = 'Search query';

  late AnimationController _animationController;
  late Animation<Offset> _backgroundAnimation;
  late Animation<double> _backgroundOpacity;

  bool isDialogOpen = false;

  @override
  void initState() {
    super.initState();

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

  Widget _buildSearchField() {
    return TextField(
      controller: _searchQueryController,
      autocorrect: true,
      decoration: InputDecoration(
        hintText: 'Search for jobs......',
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.white),
      ),
      style: TextStyle(color: Colors.white, fontSize: 16.0),
      onChanged: (query) => updateSearchQuery(query),
    );
  }

  List<Widget> _buildActions() {
    return <Widget>[
      IconButton(
        onPressed: () {
          _clearSearchQuery();
        },
        icon: Icon(Icons.clear),
      )
    ];
  }

  void _clearSearchQuery() {
    setState(() {
      _searchQueryController.clear();
      updateSearchQuery('');
    });
  }

  void updateSearchQuery(String newQuery) {
    setState(() {
      searchQuery = newQuery;
      print(searchQuery);
    });
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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black, Colors.deepOrange],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [0.2, 0.9],
            ),
          ),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => JobScreen()));
          },
          icon: Icon(Icons.arrow_back,
          color: Colors.deepOrange,),
        ),
        title: _buildSearchField(),
        actions: _buildActions(),
      ),
      body: Stack(
        children: [
          // Gradient background behind the job cards
          Positioned.fill(
            top: 30, // Adjusted to align with AppBar and make space for the animation
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
                    'https://images.pexels.com/photos/207353/pexels-photo-207353.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2',
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

          // StreamBuilder for job listings
          Positioned.fill(
            top: 30, // Adjusted to avoid overlap with AppBar
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('jobs')
                  .where('jobTitle', isGreaterThanOrEqualTo: searchQuery)
                  .where('recruitment', isEqualTo: true)
                  .snapshots(),
              builder: (context, AsyncSnapshot snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (snapshot.connectionState == ConnectionState.active) {
                  if (snapshot.data?.docs.isNotEmpty == true) {
                    return ListView.builder(
                      itemCount: snapshot.data?.docs.length,
                      itemBuilder: (BuildContext context, int index) {
                        return JobWidget(
                          jobTitle: snapshot.data?.docs[index]['jobTitle'],
                          jobDescription: snapshot.data?.docs[index]['jobDescription'],
                          jobId: snapshot.data?.docs[index]['jobId'],
                          uploadedBy: snapshot.data?.docs[index]['uploadedBy'],
                          userImage: snapshot.data?.docs[index]['userImage'],
                          name: snapshot.data?.docs[index]['name'],
                          recruitment: snapshot.data?.docs[index]['recruitment'],
                          email: snapshot.data?.docs[index]['email'],
                          location: snapshot.data?.docs[index]['location'],
                        );
                      },
                    );
                  } else {
                    return Center(
                      child: Text('There are no jobs available'),
                    );
                  }
                }
                return Center(
                  child: Text(
                    'Something went wrong',
                    style: TextStyle(fontSize: 30.0, fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
