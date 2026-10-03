import 'package:app4training/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which part of its work `StartupPage.init()` is currently in.
///
/// Only init() itself reports a stage, right before it starts the work of
/// that stage - so the caption under the startup spinner never claims
/// progress that hasn't been made. See docs/routing.md ("Why the loading
/// is staged") for what each stage does.
enum StartupStage {
  /// init() hasn't reported anything yet
  starting,

  /// Step 1: one stat() per language to find out which ones are on the device
  checkingLanguages,

  /// Step 2: fully loading the app language (the menu needs it)
  loadingAppLanguage,

  /// Still step 2: the app language is in, the language of the worksheet
  /// we resume isn't yet
  loadingRecentPage;

  static String getLocalized(BuildContext context, StartupStage stage) {
    switch (stage) {
      case StartupStage.starting:
        return context.l10n.loading;
      case StartupStage.checkingLanguages:
        return context.l10n.startupCheckingLanguages;
      case StartupStage.loadingAppLanguage:
        return context.l10n.startupLoadingAppLanguage;
      case StartupStage.loadingRecentPage:
        return context.l10n.startupLoadingRecentPage;
    }
  }
}

class StartupStageNotifier extends Notifier<StartupStage> {
  @override
  StartupStage build() => StartupStage.starting;

  /// Called by StartupPage.init() whenever it moves on to the next stage
  void report(StartupStage stage) {
    state = stage;
  }
}

/// The stage StartupPage.init() is in - drives the caption of its spinner
final startupStageProvider =
    NotifierProvider<StartupStageNotifier, StartupStage>(
      StartupStageNotifier.new,
    );
