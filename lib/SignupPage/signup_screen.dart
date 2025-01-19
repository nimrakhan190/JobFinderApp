import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:job_clone_app/Services/global_methods.dart';
import 'package:job_clone_app/Services/global_variables.dart';

class SignUp extends StatefulWidget {

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> with TickerProviderStateMixin {

  late Animation<double> _animation;
  late AnimationController _animationController;

  final TextEditingController _fullNameController = TextEditingController(
      text: '');
  final TextEditingController _emailTextController = TextEditingController(
      text: '');
  final TextEditingController _passTextController = TextEditingController(
      text: '');
  final TextEditingController _phoneNumberController = TextEditingController(
      text: '');
  final TextEditingController _locationController = TextEditingController(
      text: '');

  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passFocusNode = FocusNode();
  final FocusNode _phoneNumberFocusNode = FocusNode();
  final FocusNode _positionCPFocusNode = FocusNode();

  final _signUpFormKey = GlobalKey<FormState>();
  bool _obscureText = true;
  bool _isLoading = false;
  String? imageUrl;
  File? imageFile;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _animationController.dispose();
    _fullNameController.dispose();
    _emailTextController.dispose();
    _passTextController.dispose();
    _phoneNumberController.dispose();
    _emailFocusNode.dispose();
    _passFocusNode.dispose();
    _positionCPFocusNode.dispose();
    _phoneNumberFocusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 20));
    _animation =
    CurvedAnimation(parent: _animationController, curve: Curves.linear)
      ..addListener(() {
        setState(() {});
      });
    _animationController.repeat();
  }

  void _showImageDialog() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Please choose an option',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () {
                    // create getFromCamera
                    _getFromCamera();
                  },
                  child: Row(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.camera,
                          color: Colors.purple,
                        ),),
                      Text('Camera',
                        style: TextStyle(
                          color: Colors.purple,
                        ),),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () {
                    // create getFromGallery
                    _getFromGallery();
                  },
                  child: Row(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.image,
                          color: Colors.purple,
                        ),),
                      Text('Gallery',
                        style: TextStyle(
                          color: Colors.purple,
                        ),),
                    ],
                  ),
                ),
              ],
            ),
          );
        });
  }

  void _getFromCamera() async {
    XFile? pickedFile = await ImagePicker().pickImage(
        source: ImageSource.camera);
    _cropImage(pickedFile!.path);
    Navigator.pop(context);
  }

  void _getFromGallery() async {
    XFile? pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery);
    _cropImage(pickedFile!.path);
    Navigator.pop(context);
  }

  void _cropImage(String filePath) async {
    CroppedFile? croppedImage = await ImageCropper().cropImage(
      sourcePath: filePath,
      maxHeight: 1200, // Set a high maximum height
      maxWidth: 1200,  // Set a high maximum width
      compressQuality: 100, // Ensure high quality
    );

    if (croppedImage != null) {
      setState(() {
        imageFile = File(croppedImage.path);
      });
    }
  }

  void _submitFormOnSignUp() async {
    final isValid = _signUpFormKey.currentState!.validate();
    if (!isValid) return; // If the form is not valid, exit early.

    if (imageFile == null) {
      GlobalMethod.showErrorDialog(
        error: 'Please pick an image',
        ctx: context,
      );
      return; // Exit if no image is selected.
    }

    setState(() {
      _isLoading = true; // Start loading.
    });

    try {
      // Create user with email and password.
      await _auth.createUserWithEmailAndPassword(
        email: _emailTextController.text.trim().toLowerCase(),
        password: _passTextController.text.trim(),
      );

      final User? user = _auth.currentUser;
      if (user != null) {
        final _uid = user.uid;
        final ref = FirebaseStorage.instance.ref().child('userImages').child('$_uid.jpg');

        // Upload image file.
        await ref.putFile(imageFile!);
        final imageUrl = await ref.getDownloadURL();

        // Save user data to Firestore.
        await FirebaseFirestore.instance.collection('users').doc(_uid).set({
          'id': _uid,
          'name': _fullNameController.text,
          'email': _emailTextController.text,
          'userImage': imageUrl,
          'phoneNumber': _phoneNumberController.text,
          'location': _locationController.text,
          'createdAt': Timestamp.now(),
        });

        // Navigate to another screen if needed.
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop(); // Close the sign-up screen.
        } else {
          Navigator.of(context).pushReplacementNamed('/home'); // Replace with the home screen.
        }
      }
    } catch (error) {
      GlobalMethod.showErrorDialog(
        error: error.toString(),
        ctx: context,
      );
    } finally {
      setState(() {
        _isLoading = false; // Ensure loading state is reset.
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [
          CachedNetworkImage(
            placeholder: (context,url) => Image.asset(
              'assets/images/wallpaper.jpg',
              fit: BoxFit.fill,
            ), imageUrl: signUpUrlImage,
            errorWidget: (context,url,error) => Icon(Icons.error),
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            alignment: FractionalOffset(_animation.value,0),
          ),
          Container(
            color: Colors.black26,
            child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16,vertical: 80),
            child: ListView(
              children: [
                Form(
                    key: _signUpFormKey,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: (){
                        //Create ShowImageDialog
                        _showImageDialog();
                      },
                      child: Padding(
                          padding: EdgeInsets.all(8.0),
                      child: Container(
                        width: size.width*0.24,
                        height: size.width*0.24,
                        decoration: BoxDecoration(
                          border: Border.all(width: 1,color: Colors.cyanAccent),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: imageFile == null
                          ? Icon(Icons.camera_enhance_sharp,color: Colors.cyan,size: 30,)
                          : Image.file(imageFile!,fit: BoxFit.fill,),
                        ),
                      ),),
                    ),
                    SizedBox(height: 15,),
                    TextFormField(
                      textInputAction: TextInputAction.next,
                      onEditingComplete: () => FocusScope.of(context).requestFocus(_emailFocusNode),
                      keyboardType: TextInputType.name,
                      controller: _fullNameController,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'This filed is missing';
                        } else {
                          return null;
                        }
                      },
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Full name / Company name',
                        hintStyle: TextStyle(color: Colors.white),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        errorBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                    SizedBox(height: 15,),
                    TextFormField(
                      textInputAction: TextInputAction.next,
                      onEditingComplete: () => FocusScope.of(context).requestFocus(_passFocusNode),
                      keyboardType: TextInputType.emailAddress,
                      controller: _emailTextController,
                      validator: (value) {
                        if (value!.isEmpty || !value.contains('@')) {
                          return 'Please enter a valid Email address';
                        } else {
                          return null;
                        }
                      },
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Email',
                        hintStyle: TextStyle(color: Colors.white),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        errorBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                    SizedBox(height: 15,),
                    TextFormField(
                      textInputAction: TextInputAction.next,
                      onEditingComplete: () => FocusScope.of(context).requestFocus(_phoneNumberFocusNode),
                      keyboardType: TextInputType.visiblePassword,
                      controller: _passTextController,
                      obscureText : !_obscureText,
                      validator: (value) {
                        if (value!.isEmpty || value.length < 7) {
                          return 'Please enter a valid password';
                        } else {
                          return null;
                        }
                      },
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        suffixIcon: GestureDetector(
                          onTap: () {
                            setState(() {
                              _obscureText = !_obscureText;
                            });
                          },
                          child: Icon(
                            _obscureText ? Icons.visibility : Icons.visibility_off,
                            color: Colors.white,
                          ),
                        ),
                        hintText: 'Password',
                        hintStyle: TextStyle(color: Colors.white),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        errorBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                    SizedBox(height: 15,),
                    TextFormField(
                      textInputAction: TextInputAction.next,
                      onEditingComplete: () => FocusScope.of(context).requestFocus(_positionCPFocusNode),
                      keyboardType: TextInputType.phone,
                      controller: _phoneNumberController,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'This field is missing';
                        } else {
                          return null;
                        }
                      },
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Phone Number',
                        hintStyle: TextStyle(color: Colors.white),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        errorBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                    SizedBox(height: 15,),
                    TextFormField(
                      textInputAction: TextInputAction.next,
                      onEditingComplete: () => FocusScope.of(context).requestFocus(_positionCPFocusNode),
                      keyboardType: TextInputType.text,
                      controller: _locationController,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'This field is missing';
                        } else {
                          return null;
                        }
                      },
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Company Address',
                        hintStyle: TextStyle(color: Colors.white),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        errorBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                    SizedBox(height: 20,),
                    _isLoading
                    ?
                        Center(
                          child: Container(
                            height: 70,
                            width: 70,
                            child: CircularProgressIndicator(

                            ),
                          ),
                        )
                        :
                        MaterialButton(
                            onPressed: (){
                            //   create submitFormOnSignUp
                              _submitFormOnSignUp();
                            },
                        color: Colors.cyan,
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 13),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'SignUp',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),),
                        ),
                    SizedBox(height: 35,),
                    Center(
                      child: RichText(
                          text: TextSpan(
                            children: [TextSpan(
                              text: 'Already have an Account?',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            TextSpan(
                              text: '   ',
                            ),
                            TextSpan(
                              recognizer: TapGestureRecognizer()
                                  ..onTap = () => Navigator.canPop(context)
                                  ? Navigator.pop(context)
                                      : null,
                              text: 'Login',
                              style: TextStyle(
                                color: Colors.cyan,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            )],
                          ),
                      ),
                    ),],
                ),
                ),],
            ),),
          ),],
      ),
    );
  }
}
