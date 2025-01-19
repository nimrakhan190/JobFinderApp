import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:job_clone_app/Jobs/job_details.dart';
import 'package:job_clone_app/Services/global_methods.dart';

class JobWidget extends StatefulWidget {
  final String jobTitle;
  final String jobDescription;
  final String jobId;
  final String uploadedBy;
  final String userImage;
  final String name;
  final bool recruitment;
  final String email;
  final String location;

  const JobWidget({
    super.key,
    required this.jobTitle,
    required this.jobDescription,
    required this.jobId,
    required this.uploadedBy,
    required this.userImage,
    required this.name,
    required this.recruitment,
    required this.email,
    required this.location,
  });

  @override
  State<JobWidget> createState() => _JobWidgetState();
}

class _JobWidgetState extends State<JobWidget> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  _deleteDialog() {
    User? user = _auth.currentUser;
    if (user == null) {
      Fluttertoast.showToast(
        msg: "No user logged in",
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: Colors.red,
        fontSize: 16.0,
      );
      return;
    }
    final _uid = user.uid;
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          actions: [
            TextButton(
              onPressed: () async {
                try {
                  if (widget.uploadedBy == _uid) {
                    await FirebaseFirestore.instance
                        .collection('jobs')
                        .doc(widget.jobId)
                        .delete();
                    await Fluttertoast.showToast(
                      msg: 'Job has been deleted',
                      toastLength: Toast.LENGTH_LONG,
                      backgroundColor: Colors.grey,
                      fontSize: 18.0,
                    );
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  } else {
                    GlobalMethod.showErrorDialog(
                      error: 'You cannot perform this action',
                      ctx: ctx,
                    );
                  }
                } catch (error) {
                  GlobalMethod.showErrorDialog(
                    error: 'This task cannot be deleted',
                    ctx: ctx,
                  );
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white24,
      elevation: 8,
      margin: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => JobDetailsScreen(
                uploadedBy: widget.uploadedBy,
                jobID: widget.jobId,
              ),
            ),
          );
        },
        onLongPress: () {
          _deleteDialog();
        },
        contentPadding: EdgeInsets.symmetric(horizontal: 13, vertical: 5),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: widget.userImage.isNotEmpty
              ? Image.network(
            widget.userImage,
            height: 60,
            width: 60,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Image.asset(
                'assets/images/default_user.png', // Replace with your placeholder image
                height: 60,
                width: 60,
                fit: BoxFit.cover,
              );
            },
          )
              : Icon(
            Icons.account_circle,
            size: 60,
            color: Colors.grey,
          ),
        ),
        title: Text(
          widget.jobTitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.amber,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 5),
            Text(
              widget.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 5),
            Text(
              widget.jobDescription,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.black87,
                fontSize: 14,
              ),
            ),
          ],
        ),
        trailing: Icon(
          Icons.keyboard_arrow_right,
          size: 25,
          color: Colors.black54,
        ),
      ),
    );
  }
}
