import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:job_clone_app/Jobs/jobs_screen.dart';
import 'package:job_clone_app/Services/global_methods.dart';
import 'package:job_clone_app/Services/global_variables.dart';
import 'package:job_clone_app/Widgets/comments_widget.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:uuid/uuid.dart';

import '../ResumeBuilderScreen.dart';

class JobDetailsScreen extends StatefulWidget {

  final String uploadedBy;
  final String jobID;

  JobDetailsScreen({
    required this.uploadedBy,
    required this.jobID,
  });

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> with SingleTickerProviderStateMixin {

  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isCommenting = false;
  final TextEditingController _commentController = TextEditingController();
  String? authorName;
  String? userImageUrl;
  String? jobCategory;
  String? jobDescription;
  String? jobTitle;
  bool? recruitment;
  Timestamp? postedDateTimeStamp;
  Timestamp? deadlineDateTimeStamp;
  String? postedDate;
  String? deadlineDate;
  String? locationCompany = '';
  String? emailCompany = '';
  int applicants = 0;
  bool isDeadlineAvailable = false;
  bool showComment = false;

  late AnimationController _animationController;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _appBarAnimation;

  @override
  void initState() {
    super.initState();
    getJobData();

    // Initialize animation controller for background and app bar animation
    _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 20));
    _backgroundAnimation = CurvedAnimation(parent: _animationController, curve: Curves.linear)
      ..addListener(() {
        // Check if the widget is still mounted before calling setState
        if (mounted) {
          setState(() {});
        }
      });

    // Animation for AppBar (size/height effect)
    _appBarAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut)
      ..addListener(() {
        // Check if the widget is still mounted before calling setState
        if (mounted) {
          setState(() {});
        }
      });

    // Start the animation for background
    if (mounted) {
      _animationController.repeat();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void getJobData() async {
    final DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uploadedBy)
        .get();

    if(userDoc == null){
      return;
    }
    else{
      setState(() {
        authorName = userDoc.get('name');
        userImageUrl = userDoc.get('userImage');
      });
    }
    final DocumentSnapshot jobDatabase = await FirebaseFirestore.instance
        .collection('jobs')
        .doc(widget.jobID)
        .get();

    if(jobDatabase == null){
      return;
    }
    else{
      setState(() {
        jobTitle = jobDatabase.get('jobTitle');
        jobDescription = jobDatabase.get('jobDescription');
        recruitment = jobDatabase.get('recruitment');
        emailCompany = jobDatabase.get('email');
        locationCompany = jobDatabase.get('location');
        applicants = jobDatabase.get('applicants');
        postedDateTimeStamp = jobDatabase.get('createdAt');
        deadlineDateTimeStamp = jobDatabase.get('deadlineDateTimeStamp');
        deadlineDate = jobDatabase.get('deadlineDate');
        var postDate = postedDateTimeStamp!.toDate();
        postedDate = '${postDate.year}-${postDate.month} - ${postDate.day}';
      });
      var date = deadlineDateTimeStamp!.toDate();
      isDeadlineAvailable = date.isAfter(DateTime.now());
    }
  }

  Widget dividerWidget(){
    return Column(
      children: [
        SizedBox(height: 7,),
        Divider(
          thickness: 1,
          color: Colors.grey,
        ),
        SizedBox(height: 7,),
      ],
    );
  }

  applyForJob() async {
    final subject = Uri.encodeQueryComponent('Applying for $jobTitle').replaceAll('+', ' ');
    final body = Uri.encodeQueryComponent('Hello, please attach Resume CV file').replaceAll('+', ' ');

    final Uri params = Uri(
      scheme: 'mailto',
      path: emailCompany,
      query: 'subject=$subject&body=$body',
    );

    final url = params.toString();

    try {
      await launchUrlString(url);  // Assuming this is async
      addNewApplicant();
    } catch (e) {
      print('Error launching URL: $e');
      // Handle error (maybe show an alert or toast)
    }
  }

  void addNewApplicant() async {
    try {
      var docRef = FirebaseFirestore.instance.collection('jobs').doc(widget.jobID);
      await docRef.update({
        'applicants': FieldValue.increment(1),  // Increment applicants count
      });
      Navigator.pop(context);
    } catch (e) {
      print('Error updating Firestore: $e');
      // Handle error (maybe show an alert or toast)
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: _backgroundAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                  'https://images.pexels.com/photos/29702291/pexels-photo-29702291/free-photo-of-luxury-mediterranean-villa-with-pool-and-sea-view.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2',
                ),
                fit: BoxFit.cover,
                alignment: FractionalOffset(_backgroundAnimation.value, 0),
              ),
            ),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                flexibleSpace: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade300, Colors.blueAccent],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      stops: [0.2, 0.9],
                    ),
                  ),
                ),
                leading: IconButton(
                    onPressed: () {
                      Navigator.pushReplacement(context,
                          MaterialPageRoute(builder: (context) => JobScreen()));
                    },
                    icon: Icon(Icons.close, size: 36, color: Colors.white,)),
              ),
              body: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Card(
                        color: Colors.black54,
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Text(
                                  jobTitle == null ? '' : jobTitle!,
                                  maxLines: 3,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 25,
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Container(
                                    height: 60,
                                    width: 60,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        width: 3,
                                        color: Colors.grey,
                                      ),
                                      shape: BoxShape.rectangle,
                                      image: DecorationImage(
                                          image: NetworkImage(
                                            userImageUrl == null
                                                ? 'https://secure.gravatar.com/avatar/27abadd59ce5c3174909dc0a306e1e17/?s=48&d=https://images.binaryfortress.com/General/UnknownUser1024.png'
                                                : userImageUrl!,
                                          ),
                                          fit: BoxFit.fill),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(left: 7.0),
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          authorName == null ? '' : authorName!,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                        SizedBox(
                                          height: 3,
                                        ),
                                        Text(
                                          locationCompany!,
                                          style: TextStyle(
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              dividerWidget(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    applicants.toString(),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 4,
                                  ),
                                  Text(
                                    'Applicants',
                                    style: TextStyle(
                                      color: Colors.grey,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 7,
                                  ),
                                  Icon(
                                    Icons.how_to_reg_sharp,
                                    color: Colors.grey,
                                  )
                                ],
                              ),
                              FirebaseAuth.instance.currentUser!.uid !=
                                  widget.uploadedBy
                                  ? Container()
                                  : Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  dividerWidget(),
                                  Text(
                                    'Recruitment',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(
                                    height: 3,
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.center,
                                    children: [
                                      TextButton(
                                          onPressed: () {
                                            User? user =
                                                _auth.currentUser;
                                            final _uid = user!.uid;
                                            if (_uid ==
                                                widget.uploadedBy) {
                                              try {
                                                FirebaseFirestore.instance
                                                    .collection('jobs')
                                                    .doc(widget.jobID)
                                                    .update({
                                                  'recruitment': true
                                                });
                                              } catch (error) {
                                                GlobalMethod
                                                    .showErrorDialog(
                                                  error:
                                                  'Action cannot be performed',
                                                  ctx: context,
                                                );
                                              }
                                            } else {
                                              GlobalMethod.showErrorDialog(
                                                  error:
                                                  'You cannot perform this action',
                                                  ctx: context);
                                            }
                                            getJobData();
                                          },
                                          child: Text(
                                            'ON',
                                            style: TextStyle(
                                              fontStyle: FontStyle.italic,
                                              color: Colors.black,
                                              fontSize: 15,
                                              fontWeight:
                                              FontWeight.normal,
                                            ),
                                          )),
                                      Opacity(
                                        opacity:
                                        recruitment == true ? 1 : 0,
                                        child: Icon(
                                          Icons.check_box,
                                          color: Colors.green,
                                        ),
                                      ),
                                      SizedBox(
                                        width: 40,
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          User? user = _auth.currentUser;
                                          final _uid = user!.uid;
                                          if (_uid == widget.uploadedBy) {
                                            try {
                                              FirebaseFirestore.instance
                                                  .collection('jobs')
                                                  .doc(widget.jobID)
                                                  .update({
                                                'recruitment': false
                                              });
                                            } catch (error) {
                                              GlobalMethod
                                                  .showErrorDialog(
                                                error:
                                                'Action cannot be performed',
                                                ctx: context,
                                              );
                                            }
                                          } else {
                                            GlobalMethod.showErrorDialog(
                                                error:
                                                'You cannot perform this action',
                                                ctx: context);
                                          }
                                          getJobData();
                                        },
                                        child: Text(
                                          'OFF',
                                          style: TextStyle(
                                            fontStyle: FontStyle.italic,
                                            color: Colors.black,
                                            fontSize: 15,
                                            fontWeight: FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                      Opacity(
                                        opacity:
                                        recruitment == false ? 1 : 0,
                                        child: Icon(
                                          Icons.check_box,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                              dividerWidget(),
                              Text(
                                'Job Description',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(
                                height: 7,
                              ),
                              Text(
                                jobDescription == null ? '' : jobDescription!,
                                textAlign: TextAlign.justify,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                              dividerWidget(),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(3.0),
                      child: Card(
                        color: Colors.black54,
                        child: Padding(
                          padding: EdgeInsets.all(7.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: 7,
                              ),
                              Center(
                                child: MaterialButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => ResumeBuilderScreen()),
                                    );
                                  },
                                  color: Colors.redAccent,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: Text(
                                      'Build your Resume',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Center(
                                child: Text(
                                  isDeadlineAvailable
                                      ? 'Actively Recruiting, Send CV/Resume:'
                                      : 'Deadline Passed away.',
                                  style: TextStyle(
                                    color: isDeadlineAvailable
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.normal,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 4,
                              ),
                              Center(
                                child: MaterialButton(
                                  onPressed: () {
                                    applyForJob();
                                  },
                                  color: Colors.blueAccent,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: Text(
                                      'Easy Apply Now',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              dividerWidget(),
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Uploaded on:',
                                    style: TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    postedDate == null ? '' : postedDate!,
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Deadline date:',
                                    style: TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    deadlineDate == null ? '' : deadlineDate!,
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              dividerWidget(),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(3.0),
                      child: Card(
                        color: Colors.black54,
                        child: Padding(
                          padding: EdgeInsets.all(6.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AnimatedSwitcher(
                                duration: Duration(
                                  milliseconds: 500,
                                ),
                                child: _isCommenting
                                    ? Row(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Flexible(
                                        flex: 3,
                                        child: TextField(
                                          controller: _commentController,
                                          style: TextStyle(
                                            color: Colors.white,
                                          ),
                                          maxLength: 200,
                                          keyboardType:
                                          TextInputType.text,
                                          maxLines: 6,
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor: Theme
                                                .of(context)
                                                .scaffoldBackgroundColor,
                                            enabledBorder:
                                            UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Colors.white),
                                            ),
                                            focusedBorder:
                                            OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Colors.pink),
                                            ),
                                          ),
                                        )),
                                    Flexible(
                                        child: Column(
                                          children: [
                                            Padding(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 5),
                                              child: MaterialButton(
                                                onPressed: () async {
                                                  if (_commentController
                                                      .text.length <
                                                      7) {
                                                    GlobalMethod
                                                        .showErrorDialog(
                                                        error:
                                                        'Comment cannot be less than 7',
                                                        ctx: context);
                                                  } else {
                                                    final _generatedId =
                                                    Uuid().v4();
                                                    await FirebaseFirestore
                                                        .instance
                                                        .collection('jobs')
                                                        .doc(widget.jobID)
                                                        .update({
                                                      'jobComments':
                                                      FieldValue
                                                          .arrayUnion([
                                                        {
                                                          'userId':
                                                          FirebaseAuth
                                                              .instance
                                                              .currentUser!
                                                              .uid,
                                                          'commentId':
                                                          _generatedId,
                                                          'name': name,
                                                          'userImageUrl':
                                                          userImage,
                                                          'commentBody':
                                                          _commentController
                                                              .text,
                                                          'time':
                                                          Timestamp.now(),
                                                        }
                                                      ]),
                                                    });
                                                    await Fluttertoast
                                                        .showToast(
                                                      msg:
                                                      'Your comment has been added',
                                                      toastLength:
                                                      Toast.LENGTH_LONG,
                                                      backgroundColor:
                                                      Colors.grey,
                                                      fontSize: 15.0,
                                                    );
                                                    _commentController
                                                        .clear();
                                                  }
                                                  setState(() {
                                                    showComment = true;
                                                  });
                                                },
                                                color: Colors.blueAccent,
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                      5),
                                                ),
                                                child: Text(
                                                  'Post',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight:
                                                    FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            TextButton(
                                                onPressed: () {
                                                  setState(() {
                                                    _isCommenting =
                                                    !_isCommenting;
                                                    showComment = false;
                                                  });
                                                },
                                                child: Text('Cancel'))
                                          ],
                                        ))
                                  ],
                                )
                                    : Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _isCommenting = !_isCommenting;
                                        });
                                      },
                                      icon: Icon(
                                        Icons.add_comment,
                                        color: Colors.blueAccent,
                                        size: 37,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 8,
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          showComment = true;
                                        });
                                      },
                                      icon: Icon(
                                        Icons.arrow_drop_down_circle,
                                        color: Colors.blueAccent,
                                        size: 37,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              showComment == false
                                  ? Container()
                                  : Padding(
                                padding: EdgeInsets.all(13.0),
                                child: FutureBuilder<DocumentSnapshot>(
                                  future: FirebaseFirestore.instance
                                      .collection('jobs')
                                      .doc(widget.jobID)
                                      .get(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return Center(
                                        child:
                                        CircularProgressIndicator(),
                                      );
                                    } else {
                                      if (snapshot.data == null) {
                                        Center(
                                          child: Text(
                                              'No comment for this job'),
                                        );
                                      }
                                    }
                                    return ListView.separated(
                                      shrinkWrap: true,
                                      physics:
                                      NeverScrollableScrollPhysics(),
                                      itemBuilder: (context, index) {
                                        return CommentWidget(
                                            commentId:
                                            snapshot.data!['jobComments']
                                            [index]['commentId'],
                                            commenterId:
                                            snapshot.data!['jobComments']
                                            [index]['userId'],
                                            commenterName:
                                            snapshot.data!['jobComments']
                                            [index]['name'],
                                            commentBody: snapshot
                                                .data!['jobComments']
                                            [index]['commentBody'],
                                            commenterImageUrl: snapshot
                                                .data!['jobComments']
                                            [index]['userImageUrl']);
                                      },
                                      separatorBuilder: (context, index) {
                                        return Divider(
                                          thickness: 1,
                                          color: Colors.grey,
                                        );
                                      },
                                      itemCount: snapshot
                                          .data!['jobComments'].length,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });}
  }