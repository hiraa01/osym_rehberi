// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_api_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(studentList)
const studentListProvider = StudentListFamily._();

final class StudentListProvider extends $FunctionalProvider<
        AsyncValue<StudentListResponse>,
        StudentListResponse,
        FutureOr<StudentListResponse>>
    with
        $FutureModifier<StudentListResponse>,
        $FutureProvider<StudentListResponse> {
  const StudentListProvider._(
      {required StudentListFamily super.from,
      required StudentListParams super.argument})
      : super(
          retry: null,
          name: r'studentListProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$studentListHash();

  @override
  String toString() {
    return r'studentListProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<StudentListResponse> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<StudentListResponse> create(Ref ref) {
    final argument = this.argument as StudentListParams;
    return studentList(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is StudentListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$studentListHash() => r'd44967181c9bb60fff36c0d2e26edc4237363dc4';

final class StudentListFamily extends $Family
    with
        $FunctionalFamilyOverride<FutureOr<StudentListResponse>,
            StudentListParams> {
  const StudentListFamily._()
      : super(
          retry: null,
          name: r'studentListProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  StudentListProvider call(
    StudentListParams params,
  ) =>
      StudentListProvider._(argument: params, from: this);

  @override
  String toString() => r'studentListProvider';
}

@ProviderFor(studentDetail)
const studentDetailProvider = StudentDetailFamily._();

final class StudentDetailProvider extends $FunctionalProvider<
        AsyncValue<StudentModel>, StudentModel, FutureOr<StudentModel>>
    with $FutureModifier<StudentModel>, $FutureProvider<StudentModel> {
  const StudentDetailProvider._(
      {required StudentDetailFamily super.from, required int super.argument})
      : super(
          retry: null,
          name: r'studentDetailProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$studentDetailHash();

  @override
  String toString() {
    return r'studentDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<StudentModel> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<StudentModel> create(Ref ref) {
    final argument = this.argument as int;
    return studentDetail(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is StudentDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$studentDetailHash() => r'e44f12754030bbc99961f93afe9717cfa91587da';

final class StudentDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<StudentModel>, int> {
  const StudentDetailFamily._()
      : super(
          retry: null,
          name: r'studentDetailProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  StudentDetailProvider call(
    int studentId,
  ) =>
      StudentDetailProvider._(argument: studentId, from: this);

  @override
  String toString() => r'studentDetailProvider';
}

@ProviderFor(StudentCreation)
const studentCreationProvider = StudentCreationProvider._();

final class StudentCreationProvider
    extends $NotifierProvider<StudentCreation, AsyncValue<StudentModel?>> {
  const StudentCreationProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'studentCreationProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$studentCreationHash();

  @$internal
  @override
  StudentCreation create() => StudentCreation();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<StudentModel?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<StudentModel?>>(value),
    );
  }
}

String _$studentCreationHash() => r'9646522aa039dba28a2f8aaf6dbdd89d9b12b4f6';

abstract class _$StudentCreation extends $Notifier<AsyncValue<StudentModel?>> {
  AsyncValue<StudentModel?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<AsyncValue<StudentModel?>, AsyncValue<StudentModel?>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<StudentModel?>, AsyncValue<StudentModel?>>,
        AsyncValue<StudentModel?>,
        Object?,
        Object?>;
    element.handleValue(ref, created);
  }
}

@ProviderFor(StudentUpdate)
const studentUpdateProvider = StudentUpdateProvider._();

final class StudentUpdateProvider
    extends $NotifierProvider<StudentUpdate, AsyncValue<StudentModel?>> {
  const StudentUpdateProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'studentUpdateProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$studentUpdateHash();

  @$internal
  @override
  StudentUpdate create() => StudentUpdate();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<StudentModel?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<StudentModel?>>(value),
    );
  }
}

String _$studentUpdateHash() => r'8c12138df3c9e028240dcdfadf1448bebfcac3c6';

abstract class _$StudentUpdate extends $Notifier<AsyncValue<StudentModel?>> {
  AsyncValue<StudentModel?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<AsyncValue<StudentModel?>, AsyncValue<StudentModel?>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<StudentModel?>, AsyncValue<StudentModel?>>,
        AsyncValue<StudentModel?>,
        Object?,
        Object?>;
    element.handleValue(ref, created);
  }
}

@ProviderFor(StudentDeletion)
const studentDeletionProvider = StudentDeletionProvider._();

final class StudentDeletionProvider
    extends $NotifierProvider<StudentDeletion, AsyncValue<bool>> {
  const StudentDeletionProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'studentDeletionProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$studentDeletionHash();

  @$internal
  @override
  StudentDeletion create() => StudentDeletion();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<bool> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<bool>>(value),
    );
  }
}

String _$studentDeletionHash() => r'f48205243be271cfb204c8ea8e26db6c2fffdc53';

abstract class _$StudentDeletion extends $Notifier<AsyncValue<bool>> {
  AsyncValue<bool> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<bool>, AsyncValue<bool>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<bool>, AsyncValue<bool>>,
        AsyncValue<bool>,
        Object?,
        Object?>;
    element.handleValue(ref, created);
  }
}

@ProviderFor(ScoreCalculation)
const scoreCalculationProvider = ScoreCalculationProvider._();

final class ScoreCalculationProvider extends $NotifierProvider<ScoreCalculation,
    AsyncValue<Map<String, dynamic>?>> {
  const ScoreCalculationProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'scoreCalculationProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$scoreCalculationHash();

  @$internal
  @override
  ScoreCalculation create() => ScoreCalculation();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<Map<String, dynamic>?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<AsyncValue<Map<String, dynamic>?>>(value),
    );
  }
}

String _$scoreCalculationHash() => r'80cfad76a2fc71da05fa45c5f55a75bed82ce2bd';

abstract class _$ScoreCalculation
    extends $Notifier<AsyncValue<Map<String, dynamic>?>> {
  AsyncValue<Map<String, dynamic>?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<Map<String, dynamic>?>,
        AsyncValue<Map<String, dynamic>?>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<Map<String, dynamic>?>,
            AsyncValue<Map<String, dynamic>?>>,
        AsyncValue<Map<String, dynamic>?>,
        Object?,
        Object?>;
    element.handleValue(ref, created);
  }
}
