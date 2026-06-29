
import 'package:flutter/material.dart';
import 'package:glint/app/app.dart';
import 'package:glint/config/injector.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:glint/core/network/fcm_client.dart';


Future<void> main()async{
  
  WidgetsFlutterBinding.ensureInitialized();

  // for sending notifications using FCM
  await Firebase.initializeApp();
  await FcmService().init();
  // Dependency injections
  setupLocator(); 

  runApp( const Glint());
}



