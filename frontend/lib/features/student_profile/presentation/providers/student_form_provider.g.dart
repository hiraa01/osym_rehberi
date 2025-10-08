// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_form_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(StudentForm)
const studentFormProvider = StudentFormProvider._();

final class StudentFormProvider
    extends $NotifierProvider<StudentForm, StudentFormState> {
  const StudentFormProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'studentFormProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$studentFormHash();

  @$internal
  @override
  StudentForm create() => StudentForm();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StudentFormState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StudentFormState>(value),
    );
  }
}

String _$studentFormHash() => r'a87c702ae40fb5346d2d6122fd9f34b087fc6431';

abstract class _$StudentForm extends $Notifier<StudentFormState> {
  StudentFormState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<StudentFormState, StudentFormState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<StudentFormState, StudentFormState>,
        StudentFormState,
        Object?,
        Object?>;
    element.handleValue(ref, created);
  }
}
