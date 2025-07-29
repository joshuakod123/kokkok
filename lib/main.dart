import 'package:flutter/material.dart';
import 'package:kokkok/screens/auth_screen.dart';
import 'package:kokkok/screens/main_screen.dart'; // 곧 만들 메인 화면
import 'package:kokkok/screens/splash_screen.dart'; // 로딩 중 화면
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    // TODO: 이 부분은 이미 당신의 키로 교체하셨을 겁니다.
    url: 'https://wlxtjzklegnswklekbar.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndseHRqemtsZWduc3drbGVrYmFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE5MzgyNzUsImV4cCI6MjA2NzUxNDI3NX0.IYxCb28McldWLYBzQokWLPuACbXJaKDOudQkFdToLWI',
  );

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '콕콕',
      theme: ThemeData(
          primarySwatch: Colors.deepPurple,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          scaffoldBackgroundColor: Colors.white, // 앱 전체 배경색을 흰색으로
          textTheme: const TextTheme( // 기본 텍스트 스타일
            bodyLarge: TextStyle(color: Color(0xFF333333)),
            bodyMedium: TextStyle(color: Color(0xFF555555)),
            titleLarge: TextStyle(fontWeight: FontWeight.bold),
          ),
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12.0)),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ))),
      // Supabase의 인증 상태 변경을 실시간으로 감지합니다.
      home: StreamBuilder<AuthState>(
        stream: supabase.auth.onAuthStateChange,
        builder: (context, snapshot) {
          // 로딩 중일 때는 스플래시 화면을 보여줍니다.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }
          // 로그인 되어 있다면 메인 화면으로 이동합니다.
          if (snapshot.hasData && snapshot.data!.session != null) {
            return const MainScreen();
          }
          // 로그인 되어 있지 않다면 인증 화면으로 이동합니다.
          return const AuthScreen();
        },
      ),
    );
  }
}

