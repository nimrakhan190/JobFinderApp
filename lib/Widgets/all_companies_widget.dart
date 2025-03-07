import 'package:flutter/material.dart';
import 'package:job_clone_app/Search/profile_company.dart';
import 'package:url_launcher/url_launcher_string.dart';

class AllWorkersWidget extends StatefulWidget {

  final String userID;
  final String userName;
  final String userEmail;
  final String phoneNumber;
  final String userImageUrl;

  AllWorkersWidget({
    required this.userID,
    required this.userName,
    required this.userEmail,
    required this.phoneNumber,
    required this.userImageUrl,
});

  @override
  State<AllWorkersWidget> createState() => _AllWorkersWidgetState();
}

class _AllWorkersWidgetState extends State<AllWorkersWidget> {

  void _mailTo() async {
    var mailUrl = 'mailto:${widget.userEmail}';
    print('widget.userEmail ${widget.userEmail}');
    
    if(await canLaunchUrlString(mailUrl)){
      await launchUrlString(mailUrl);
    }
    else {
      print('Error');
      throw 'Error Occurred';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      color: Colors.white10,
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: ListTile(
        onTap: (){
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>ProfileScreen(userID: widget.userID)));
        },
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Container(
          padding: EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(
                width: 1,
              ),
            ),
          ),
          child: SizedBox(
            width: 40,
            height: 40,
            child: ClipOval(
              child: Image.network(
                widget.userImageUrl.isEmpty
                    ? 'https://cdn.icon-icons.com/icons2/2643/PNG/512/female_woman_person_people_avatar_icon_159367.png'
                    : widget.userImageUrl,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        title: Text(
          widget.userName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              'Visit Profile',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
        trailing: IconButton(
            onPressed: (){
              _mailTo();
            },
            icon: Icon(
              Icons.mail_outline,
              size: 30,
              color: Colors.grey,
            )
        ),
      ),
    );
  }
}