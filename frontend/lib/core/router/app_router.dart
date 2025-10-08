import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:osym_rehberi/features/home/presentation/pages/home_page.dart';
import 'package:osym_rehberi/features/student_profile/presentation/pages/student_list_page.dart';
import 'package:osym_rehberi/features/student_profile/presentation/pages/student_create_page.dart';
import 'package:osym_rehberi/features/student_profile/presentation/pages/student_detail_page.dart';
import 'package:osym_rehberi/features/universities/presentation/pages/university_list_page.dart';
import 'package:osym_rehberi/features/universities/presentation/pages/department_list_page.dart';
import 'package:osym_rehberi/features/universities/presentation/pages/department_detail_page.dart';
import 'package:osym_rehberi/features/recommendations/presentation/pages/recommendation_list_page.dart';
import 'package:osym_rehberi/features/recommendations/presentation/pages/recommendation_detail_page.dart';

part 'app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends _$AppRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(page: HomeRoute.page, initial: true),
        AutoRoute(page: StudentListRoute.page),
        AutoRoute(page: StudentCreateRoute.page),
        AutoRoute(page: StudentDetailRoute.page),
        AutoRoute(page: UniversityListRoute.page),
        AutoRoute(page: DepartmentListRoute.page),
        AutoRoute(page: DepartmentDetailRoute.page),
        AutoRoute(page: RecommendationListRoute.page),
        AutoRoute(page: RecommendationDetailRoute.page),
      ];
}
