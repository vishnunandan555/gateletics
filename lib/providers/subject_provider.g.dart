// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subject_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(OverallProgressColor)
final overallProgressColorProvider = OverallProgressColorProvider._();

final class OverallProgressColorProvider
    extends $NotifierProvider<OverallProgressColor, Color> {
  OverallProgressColorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'overallProgressColorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$overallProgressColorHash();

  @$internal
  @override
  OverallProgressColor create() => OverallProgressColor();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Color value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Color>(value),
    );
  }
}

String _$overallProgressColorHash() =>
    r'326c9bbcef3a56e3eea9807738d89a0a957fa79a';

abstract class _$OverallProgressColor extends $Notifier<Color> {
  Color build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Color, Color>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Color, Color>,
              Color,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(isarService)
final isarServiceProvider = IsarServiceProvider._();

final class IsarServiceProvider
    extends $FunctionalProvider<IsarService, IsarService, IsarService>
    with $Provider<IsarService> {
  IsarServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isarServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isarServiceHash();

  @$internal
  @override
  $ProviderElement<IsarService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  IsarService create(Ref ref) {
    return isarService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IsarService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IsarService>(value),
    );
  }
}

String _$isarServiceHash() => r'8c3ba51b267777511e5bd77c35aa1504b4eb4384';

@ProviderFor(subjects)
final subjectsProvider = SubjectsProvider._();

final class SubjectsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Subject>>,
          List<Subject>,
          Stream<List<Subject>>
        >
    with $FutureModifier<List<Subject>>, $StreamProvider<List<Subject>> {
  SubjectsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'subjectsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$subjectsHash();

  @$internal
  @override
  $StreamProviderElement<List<Subject>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Subject>> create(Ref ref) {
    return subjects(ref);
  }
}

String _$subjectsHash() => r'39bea189ef1c8d4a1a977f4749ac59693dc9671b';

@ProviderFor(SubjectController)
final subjectControllerProvider = SubjectControllerProvider._();

final class SubjectControllerProvider
    extends $NotifierProvider<SubjectController, AsyncValue<void>> {
  SubjectControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'subjectControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$subjectControllerHash();

  @$internal
  @override
  SubjectController create() => SubjectController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$subjectControllerHash() => r'4b4c11771153d6f00292d06718d7a0ac0255a747';

abstract class _$SubjectController extends $Notifier<AsyncValue<void>> {
  AsyncValue<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, AsyncValue<void>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, AsyncValue<void>>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
