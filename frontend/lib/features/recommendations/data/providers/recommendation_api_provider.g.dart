// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recommendation_api_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(recommendationList)
const recommendationListProvider = RecommendationListFamily._();

final class RecommendationListProvider extends $FunctionalProvider<
        AsyncValue<List<RecommendationModel>>,
        List<RecommendationModel>,
        FutureOr<List<RecommendationModel>>>
    with
        $FutureModifier<List<RecommendationModel>>,
        $FutureProvider<List<RecommendationModel>> {
  const RecommendationListProvider._(
      {required RecommendationListFamily super.from,
      required int super.argument})
      : super(
          retry: null,
          name: r'recommendationListProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$recommendationListHash();

  @override
  String toString() {
    return r'recommendationListProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<RecommendationModel>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<RecommendationModel>> create(Ref ref) {
    final argument = this.argument as int;
    return recommendationList(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RecommendationListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$recommendationListHash() =>
    r'18972700ca777022508c9ec14ee67218937fb9ee';

final class RecommendationListFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<RecommendationModel>>, int> {
  const RecommendationListFamily._()
      : super(
          retry: null,
          name: r'recommendationListProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  RecommendationListProvider call(
    int studentId,
  ) =>
      RecommendationListProvider._(argument: studentId, from: this);

  @override
  String toString() => r'recommendationListProvider';
}

@ProviderFor(recommendationStats)
const recommendationStatsProvider = RecommendationStatsFamily._();

final class RecommendationStatsProvider extends $FunctionalProvider<
        AsyncValue<RecommendationStats>,
        RecommendationStats,
        FutureOr<RecommendationStats>>
    with
        $FutureModifier<RecommendationStats>,
        $FutureProvider<RecommendationStats> {
  const RecommendationStatsProvider._(
      {required RecommendationStatsFamily super.from,
      required int super.argument})
      : super(
          retry: null,
          name: r'recommendationStatsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$recommendationStatsHash();

  @override
  String toString() {
    return r'recommendationStatsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<RecommendationStats> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<RecommendationStats> create(Ref ref) {
    final argument = this.argument as int;
    return recommendationStats(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RecommendationStatsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$recommendationStatsHash() =>
    r'999c30a8db7632a9c7657f8e331c199548c14249';

final class RecommendationStatsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<RecommendationStats>, int> {
  const RecommendationStatsFamily._()
      : super(
          retry: null,
          name: r'recommendationStatsProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  RecommendationStatsProvider call(
    int studentId,
  ) =>
      RecommendationStatsProvider._(argument: studentId, from: this);

  @override
  String toString() => r'recommendationStatsProvider';
}

@ProviderFor(RecommendationGeneration)
const recommendationGenerationProvider = RecommendationGenerationProvider._();

final class RecommendationGenerationProvider extends $NotifierProvider<
    RecommendationGeneration, AsyncValue<List<RecommendationModel>?>> {
  const RecommendationGenerationProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'recommendationGenerationProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$recommendationGenerationHash();

  @$internal
  @override
  RecommendationGeneration create() => RecommendationGeneration();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<RecommendationModel>?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<AsyncValue<List<RecommendationModel>?>>(value),
    );
  }
}

String _$recommendationGenerationHash() =>
    r'ce9db32b501312d9d570bb00711e5c098a6cba2b';

abstract class _$RecommendationGeneration
    extends $Notifier<AsyncValue<List<RecommendationModel>?>> {
  AsyncValue<List<RecommendationModel>?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<List<RecommendationModel>?>,
        AsyncValue<List<RecommendationModel>?>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<List<RecommendationModel>?>,
            AsyncValue<List<RecommendationModel>?>>,
        AsyncValue<List<RecommendationModel>?>,
        Object?,
        Object?>;
    element.handleValue(ref, created);
  }
}
