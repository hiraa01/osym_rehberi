// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

/// generated route for
/// [DepartmentDetailPage]
class DepartmentDetailRoute extends PageRouteInfo<DepartmentDetailRouteArgs> {
  DepartmentDetailRoute({
    Key? key,
    required int departmentId,
    List<PageRouteInfo>? children,
  }) : super(
          DepartmentDetailRoute.name,
          args: DepartmentDetailRouteArgs(
            key: key,
            departmentId: departmentId,
          ),
          initialChildren: children,
        );

  static const String name = 'DepartmentDetailRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<DepartmentDetailRouteArgs>();
      return DepartmentDetailPage(
        key: args.key,
        departmentId: args.departmentId,
      );
    },
  );
}

class DepartmentDetailRouteArgs {
  const DepartmentDetailRouteArgs({
    this.key,
    required this.departmentId,
  });

  final Key? key;

  final int departmentId;

  @override
  String toString() {
    return 'DepartmentDetailRouteArgs{key: $key, departmentId: $departmentId}';
  }
}

/// generated route for
/// [DepartmentListPage]
class DepartmentListRoute extends PageRouteInfo<void> {
  const DepartmentListRoute({List<PageRouteInfo>? children})
      : super(
          DepartmentListRoute.name,
          initialChildren: children,
        );

  static const String name = 'DepartmentListRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const DepartmentListPage();
    },
  );
}

/// generated route for
/// [HomePage]
class HomeRoute extends PageRouteInfo<void> {
  const HomeRoute({List<PageRouteInfo>? children})
      : super(
          HomeRoute.name,
          initialChildren: children,
        );

  static const String name = 'HomeRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const HomePage();
    },
  );
}

/// generated route for
/// [RecommendationDetailPage]
class RecommendationDetailRoute
    extends PageRouteInfo<RecommendationDetailRouteArgs> {
  RecommendationDetailRoute({
    Key? key,
    required int studentId,
    required int recommendationId,
    List<PageRouteInfo>? children,
  }) : super(
          RecommendationDetailRoute.name,
          args: RecommendationDetailRouteArgs(
            key: key,
            studentId: studentId,
            recommendationId: recommendationId,
          ),
          initialChildren: children,
        );

  static const String name = 'RecommendationDetailRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<RecommendationDetailRouteArgs>();
      return RecommendationDetailPage(
        key: args.key,
        studentId: args.studentId,
        recommendationId: args.recommendationId,
      );
    },
  );
}

class RecommendationDetailRouteArgs {
  const RecommendationDetailRouteArgs({
    this.key,
    required this.studentId,
    required this.recommendationId,
  });

  final Key? key;

  final int studentId;

  final int recommendationId;

  @override
  String toString() {
    return 'RecommendationDetailRouteArgs{key: $key, studentId: $studentId, recommendationId: $recommendationId}';
  }
}

/// generated route for
/// [RecommendationListPage]
class RecommendationListRoute
    extends PageRouteInfo<RecommendationListRouteArgs> {
  RecommendationListRoute({
    Key? key,
    required int studentId,
    List<PageRouteInfo>? children,
  }) : super(
          RecommendationListRoute.name,
          args: RecommendationListRouteArgs(
            key: key,
            studentId: studentId,
          ),
          initialChildren: children,
        );

  static const String name = 'RecommendationListRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<RecommendationListRouteArgs>();
      return RecommendationListPage(
        key: args.key,
        studentId: args.studentId,
      );
    },
  );
}

class RecommendationListRouteArgs {
  const RecommendationListRouteArgs({
    this.key,
    required this.studentId,
  });

  final Key? key;

  final int studentId;

  @override
  String toString() {
    return 'RecommendationListRouteArgs{key: $key, studentId: $studentId}';
  }
}

/// generated route for
/// [StudentCreatePage]
class StudentCreateRoute extends PageRouteInfo<void> {
  const StudentCreateRoute({List<PageRouteInfo>? children})
      : super(
          StudentCreateRoute.name,
          initialChildren: children,
        );

  static const String name = 'StudentCreateRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const StudentCreatePage();
    },
  );
}

/// generated route for
/// [StudentDetailPage]
class StudentDetailRoute extends PageRouteInfo<StudentDetailRouteArgs> {
  StudentDetailRoute({
    Key? key,
    required int studentId,
    List<PageRouteInfo>? children,
  }) : super(
          StudentDetailRoute.name,
          args: StudentDetailRouteArgs(
            key: key,
            studentId: studentId,
          ),
          initialChildren: children,
        );

  static const String name = 'StudentDetailRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<StudentDetailRouteArgs>();
      return StudentDetailPage(
        key: args.key,
        studentId: args.studentId,
      );
    },
  );
}

class StudentDetailRouteArgs {
  const StudentDetailRouteArgs({
    this.key,
    required this.studentId,
  });

  final Key? key;

  final int studentId;

  @override
  String toString() {
    return 'StudentDetailRouteArgs{key: $key, studentId: $studentId}';
  }
}

/// generated route for
/// [StudentListPage]
class StudentListRoute extends PageRouteInfo<void> {
  const StudentListRoute({List<PageRouteInfo>? children})
      : super(
          StudentListRoute.name,
          initialChildren: children,
        );

  static const String name = 'StudentListRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const StudentListPage();
    },
  );
}

/// generated route for
/// [UniversityListPage]
class UniversityListRoute extends PageRouteInfo<void> {
  const UniversityListRoute({List<PageRouteInfo>? children})
      : super(
          UniversityListRoute.name,
          initialChildren: children,
        );

  static const String name = 'UniversityListRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const UniversityListPage();
    },
  );
}

abstract class _$AppRouter extends RootStackRouter {
  _$AppRouter({super.navigatorKey});

  @override
  List<AutoRoute> get routes;
}
