import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:job_clone_app/Widgets/all_companies_widget.dart';
import 'package:job_clone_app/Widgets/bottom_nav_bar.dart';

class AllWorkersScreen extends StatefulWidget {
  @override
  State<AllWorkersScreen> createState() => _AllWorkersScreenState();
}

class _AllWorkersScreenState extends State<AllWorkersScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchQueryController = TextEditingController();
  String searchQuery = '';
  final FocusNode _focusNode = FocusNode(); // Declare and initialize _focusNode
  late AnimationController _animationController;
  late Animation<Offset> _backgroundAnimation;
  late Animation<double> _backgroundOpacity;

  Widget _buildSearchField() {
    return TextField(
      controller: _searchQueryController,
      focusNode: _focusNode, // Attach the focus node here
      autocorrect: true,
      decoration: InputDecoration(
        hintText: 'Search for companies...',
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
        icon: Icon(Icons.clear, color: Colors.white),
      ),
    ];
  }

  @override
  void initState() {
    super.initState();

    // Initialize Animation Controller
    _animationController = AnimationController(
      duration: Duration(seconds: 10), // Duration for the animation
      vsync: this,
    );

    // Create animation to translate the background continuously
    _backgroundAnimation = Tween<Offset>(begin: Offset(0, 0), end: Offset(0, -1)).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.linear),
    );

    // Animation for the opacity of the background image
    _backgroundOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Start the animation (loop it)
    _animationController.repeat();

    // Request focus when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  void dispose() {
    _animationController.dispose(); // Clean up the animation controller
    _focusNode.dispose(); // Dispose the focus node when the widget is disposed
    super.dispose();
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
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      bottomNavigationBar: BottomNavigationBarForApp(indexNum: 1),
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Gradient background behind the worker cards
          Positioned.fill(
            top: 100,
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
                    'https://images.pexels.com/photos/804954/pexels-photo-804954.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    color: _animationController.isAnimating
                        ? Colors.transparent
                        : Colors.black.withOpacity(0.4),
                    colorBlendMode: BlendMode.darken,
                    height: 60.0,
                    width: 60.0,
                  ),
                ),
              ),
            ),
          ),

          // AppBar with dynamic height
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
              title: _buildSearchField(),
              actions: _buildActions(),
            ),
          ),

          // Main Content with StreamBuilder for worker listings
          Positioned.fill(
            top: 60,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, AsyncSnapshot snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.connectionState == ConnectionState.active) {
                  var filteredDocs = snapshot.data!.docs.where((DocumentSnapshot doc) {
                    // Cast the document to a Map<String, dynamic> to access the fields correctly
                    var name = (doc.data() as Map<String, dynamic>)['name'].toString().toLowerCase();
                    return name.contains(searchQuery.toLowerCase());
                  }).toList();

                  if (filteredDocs.isNotEmpty) {
                    return ListView.builder(
                      itemCount: filteredDocs.length,
                      itemBuilder: (context, index) {
                        var doc = filteredDocs[index];
                        var data = doc.data() as Map<String, dynamic>; // Cast here too
                        return AllWorkersWidget(
                          userID: data['id'],
                          userName: data['name'],
                          userEmail: data['email'],
                          phoneNumber: data['phoneNumber'],
                          userImageUrl: data['userImage'],
                        );
                      },
                    );
                  } else {
                    return Center(child: Text('No workers found.'));
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
