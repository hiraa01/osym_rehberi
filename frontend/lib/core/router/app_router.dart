import 'package:auto_route/auto_route.dart';
import 'package:injectable/injectable.dart';

import '../../features/home/presentation/pages/home_page.dart';
import '../../features/student_profile/presentation/pages/student_profile_page.dart';
import '../../features/student_profile/presentation/pages/create_student_page.dart';
import '../../features/recommendations/presentation/pages/recommendations_page.dart';
import '../../features/universities/presentation/pages/universities_page.dart';
import '../../features/universities/presentation/pages/departments_page.dart';

part 'app_router.gr.dart';

@AutoRouterConfig()
@injectable
class AppRouter extends _$AppRouter {
  @override
  List<AutoRoute> get routes => [
    // Home
    AutoRoute(
      page: HomeRoute.page,
      path: '/',
      initial: true,
    ),
    
    // Student Profile
    AutoRoute(
      page: StudentProfileRoute.page,
      path: '/profile',
    ),
    AutoRoute(
      page: CreateStudentRoute.page,
      path: '/profile/create',
    ),
    
    // Recommendations
    AutoRoute(
      page: RecommendationsRoute.page,
      path: '/recommendations/:studentId',
    ),
    
    // Universities
    AutoRoute(
      page: UniversitiesRoute.page,
      path: '/universities',
    ),
    AutoRoute(
      page: DepartmentsRoute.page,
      path: '/departments',
    ),
  ];
}
