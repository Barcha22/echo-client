import 'package:get_it/get_it.dart';
import '../core/network/api_client.dart';
import '../core/network/socket_client.dart';
import '../features/auth/repositories/auth_service.dart';
import '../features/chat/repositories/message_service.dart';
import '../features/friends/repositories/friend_service.dart';
import '../features/profile/repositories/profile_service.dart';


final locator = GetIt.instance;

void setupLocator(){
  // core services
  locator.registerLazySingleton(()=>ApiService());
  locator.registerLazySingleton(()=>SocketService());

  // feature services
  locator.registerLazySingleton(()=>AuthService());
  locator.registerLazySingleton(()=>MessageService());
  locator.registerLazySingleton(()=>FriendService());
  locator.registerLazySingleton(()=>ProfileService());

}
