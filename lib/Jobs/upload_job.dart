import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:job_clone_app/Services/global_methods.dart';
import 'package:uuid/uuid.dart';

import '../Persistent/persistent.dart';
import '../Services/global_variables.dart';
import '../Widgets/bottom_nav_bar.dart';

class UploadJobNow extends StatefulWidget {
  const UploadJobNow({super.key});


  @override
  State<UploadJobNow> createState() => _UploadJobNowState();
}

class _UploadJobNowState extends State<UploadJobNow> with SingleTickerProviderStateMixin {

  final TextEditingController _jobCategoryController = TextEditingController(
      text: 'Select Job Category');
  final TextEditingController _jobTitleController = TextEditingController();
  final TextEditingController _jobDescriptionController = TextEditingController();
  final TextEditingController _deadlineDateController = TextEditingController(text: 'Job Deadline Date');

  final _formKey = GlobalKey<FormState>();
  Timestamp? deadlineDateTimeStamp;
  DateTime? picked;
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _appBarAnimation;

  @override
  void initState() {
    super.initState();
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

  @override
  void dispose(){
    _animationController.dispose();
    _jobCategoryController.dispose();
    _jobTitleController.dispose();
    _jobDescriptionController.dispose();
    _deadlineDateController.dispose();
    super.dispose();
  }

  Widget _textTitles({required String label}) {
    return Padding(
      padding: EdgeInsets.all(3.0),
      child: Text(label, style: TextStyle(
        color: Colors.black,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),),
    );
  }

  Widget _textFormFields({
    required String valueKey,
    required TextEditingController controller,
    required bool enabled,
    required Function fct,
    required int maxLength,
  }) {
    return Padding(
      padding: EdgeInsets.all(3.0),
      child: InkWell(
        onTap: () {
          fct();
        },
        child: TextFormField(
          validator: (value) {
            if (value!.isEmpty) {
              return 'Value is missing';
            }
            return null;
          },
          controller: controller,
          enabled: enabled,
          key: ValueKey(valueKey),
          style: TextStyle(
            color: Colors.white,
          ),
          maxLines: valueKey == 'JobDescription' ? 3 : 1,
          maxLength: maxLength,
          keyboardType: TextInputType.text,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.black54,
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: Colors.black,
              ),
            ),
            errorBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: Colors.red,
              ),
            ),
          ),
        ),
      ),);
  }

  _showTaskCategoriesDialog({required Size size})
  {
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
                        _jobCategoryController.text =
                        Persistent.JobCategoryList[index];
                      });
                      Navigator.pop(context);
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
                setState(() {
                  // Reset the job category selection to the default text
                  _jobCategoryController.text =
                  'Select Job Category'; // Restore the placeholder
                });
                Navigator.pop(context); // Close the dialog
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _pickDateDialog() async {
    picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now().subtract(
          Duration(days: 0)
        ),
        lastDate: DateTime(2100));
    if(picked != null){
      setState(() {
        _deadlineDateController.text = '${picked!.year} - ${picked!.month} - ${picked!.day}';
        deadlineDateTimeStamp = Timestamp.fromMicrosecondsSinceEpoch(picked!.microsecondsSinceEpoch);
      });
    }
  }

  void _uploadTask() async {
    final jobId = Uuid().v4();
    User? user = FirebaseAuth.instance.currentUser;
    final _uid = user!.uid;
    final isValid = _formKey.currentState!.validate();

    if(isValid) {
      if(_deadlineDateController.text == 'Choose job Deadline date' || _jobCategoryController.text == 'Choose job category'){
        GlobalMethod.showErrorDialog(
            error: 'Please pick everything',
            ctx: context);
        return;
      }
      setState(() {
        _isLoading = true;
      });
      try
      {
        await FirebaseFirestore.instance.collection('jobs').doc(jobId).set({
          'jobId' : jobId,
          'uploadedBy' : _uid,
          'email' : user.email,
          'jobTitle' : _jobTitleController.text,
          'jobDescription' : _jobDescriptionController.text,
          'deadlineDate' : _deadlineDateController.text,
          'deadlineDateTimeStamp' : deadlineDateTimeStamp,
          'jobCategory' : _jobCategoryController.text,
          'jobComments' : [],
          'recruitment' : true,
          'createdAt' : Timestamp.now(),
          'name' : name,
          'userImage' : userImage,
          'location' : location,
          'applicants' : 0,
        });
        await Fluttertoast.showToast(
            msg: 'The task has been uploaded',
          toastLength: Toast.LENGTH_LONG,
          backgroundColor: Colors.grey,
          fontSize: 18.0,
        );
        _jobTitleController.clear();
        _jobDescriptionController.clear();
        setState(() {
          _jobCategoryController.text = 'Choose job category';
          _deadlineDateController.text = 'Choose job Deadline date';
        });
      }
      catch(error){
        {
          setState(() {
            _isLoading = false;
          });
          GlobalMethod.showErrorDialog(
              error: error.toString(),
              ctx: context
          );
        }
      }
      finally{
        setState(() {
          _isLoading = false;
        });
      }
    }
    else{
      print('Its not valid');
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery
        .of(context)
        .size;

    return AnimatedBuilder(
        animation: _backgroundAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1555883006-0f5a0915a80f?q=80&w=1961&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
                ),
                fit: BoxFit.cover,
                alignment: FractionalOffset(_backgroundAnimation.value, 0),
              ),
            ),
            child: Scaffold(
              bottomNavigationBar: BottomNavigationBarForApp(indexNum: 2),
              backgroundColor: Colors.transparent,
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.only(
                      top: 40.0, left: 5.0, right: 5.0),
                  // Add top padding here
                  child: Card(
                    color: Colors.white10,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 5),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: EdgeInsets.all(5.0),
                              child: Text(
                                'Please fill all fields',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Signatra',
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 5),
                          Divider(
                            thickness: 1,
                            color: Colors.black26,
                          ),
                          Padding(
                            padding: EdgeInsets.all(5.0),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _textTitles(label: 'Job Category :'),
                                  _textFormFields(
                                      valueKey: 'JobCategory',
                                      controller: _jobCategoryController,
                                      enabled: false,
                                      fct: () {
                                        _showTaskCategoriesDialog(size: size);
                                      },
                                      maxLength: 100),
                                  _textTitles(label: 'Job Title :'),
                                  _textFormFields(
                                      valueKey: 'JobTitle',
                                      controller: _jobTitleController,
                                      enabled: true,
                                      fct: () {},
                                      maxLength: 100),
                                  _textTitles(label: 'Job Description :'),
                                  _textFormFields(
                                      valueKey: 'JobDescription',
                                      controller: _jobDescriptionController,
                                      enabled: true,
                                      fct: () {},
                                      maxLength: 100),
                                  _textTitles(label: 'Job Deadline Date :'),
                                  _textFormFields(
                                      valueKey: 'Deadline',
                                      controller: _deadlineDateController,
                                      enabled: false,
                                      fct: () {
                                        _pickDateDialog();
                                      },
                                      maxLength: 100),
                                ],
                              ),
                            ),
                          ),
                          Center(
                            child: Padding(
                              padding: EdgeInsets.only(bottom: 30),
                              child: _isLoading
                                  ? CircularProgressIndicator()
                                  : MaterialButton(
                                onPressed: () {
                                  _uploadTask();
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
                                        'Post Now',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 28,
                                            fontFamily: 'Signatra'),
                                      ),
                                      SizedBox(width: 9),
                                      Icon(
                                        Icons.upload_file,
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
                ),
              ),
            ),
          );
        });
  }
}