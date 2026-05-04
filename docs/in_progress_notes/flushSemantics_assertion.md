# Known remaining issue: `flushSemantics` assertion (filtered from logs)

### Symptom on device

Every frame, on pages rendered by `HtmlView` that contain tables, stderr logs:

```
RenderBox was not laid out: RenderParagraph#... relayoutBoundary=up5 NEEDS-PAINT
'package:flutter/src/rendering/box.dart':
Failed assertion: line 2251 pos 12: 'hasSize'
```

Stack is 100% framework code: `PipelineOwner.flushSemantics` → `_RenderObjectSemantics.ensureGeometry` → 8 levels of `_updateChildGeometry` → `RenderBox.semanticBounds` → `.size` getter assertion.

### Impact

- **Non-fatal.** The app runs, tables render, users can read and scroll. The error is caught by the framework's error handler; the assertion fires during the semantics walk, not during layout.
- **Not user-visible.** Only appears in `adb logcat` / Xcode console / `flutter run` output.
- **Real devices only.** Not reproducible in `flutter_test` even with `tester.ensureSemantics()` + a phone-sized surface (`390×844`) + the real `Time_with_God.html` fixture. Confirmed during this session.

### Root cause (hypothesized)

The unlaid `RenderParagraph` (and friends — see the four variants below) lives inside a table cell produced by `flutter_html_table`'s `_layoutCells`: each cell is `CssBoxWidget → SizedBox.expand → Container → CssBoxWidget.withInlineSpanChildren → Text.rich → RenderParagraph`, all placed in a `LayoutGrid` inside a `LayoutBuilder` inside a `CssBoxWidget` that is a `WidgetSpan` child of the outer `RichText`. `LayoutBuilder` rebuilds children lazily when constraints change; on real devices the interaction between this rebuild and the paint / dry-layout / semantics passes produces races where one of those passes visits a render object whose current build-phase version has not yet had `performLayout` called. The page draws correctly because main layout stabilizes; only downstream passes stumble.

### What was tried and rejected

**`SelectionContainer.disabled` wrapper around the table** (mirroring `raw_tooltip.dart:813-815`, which Flutter itself uses to isolate tooltip overlays from `SelectionArea`). It **did not** fix the assertions and **broke text selection across the entire page** — a `SelectionContainer.disabled` inside a `WidgetSpan` appears to break the outer `SelectionArea`'s walk across sibling text, not just inside the disabled container. Reverted. There is a comment in `lib/widgets/html_view.dart` next to the `TagWrapExtension` documenting this dead end so nobody retries it.

### The four observed assertion variants

Diagnostic logging on the device (iOS simulator, iPhone 17, Flutter 3.41.2) captured **four** distinct signatures all originating from the same `TableHtmlExtension.build` code path:

| # | Exception signature | Where it fires | Stack fingerprint |
|---|---|---|---|
| 1 | `RenderBox was not laid out: ...` | `PipelineOwner.flushPaint` → `RenderCSSBox.paint` → `RenderDecoratedBox.paint` → `RenderBox.size` | Contains `flutter_html/` and `flutter_layout_grid/` |
| 2 | `RenderBox was not laid out: ...` | `PipelineOwner.flushSemantics` → `_SemanticsGeometry.computeChildGeometry` → `RenderBox.semanticBounds` → `RenderBox.size` | **Pure framework** — no package frames (the semantics walk doesn't go through widget code) |
| 3 | `renderBoxDoingDryBaseline == null` / `RenderBox.size accessed in ...computeDryBaseline` | `RenderParagraph.performLayout` → `layoutInlineChildren` → child `performLayout` reading `.size` during a dry-baseline computation | Contains `flutter_html/src/css_box_widget.dart` |
| 4 | `'child!.hasSize' is not true` | `RenderAligningShiftedBox.alignChild` while laying out a `Container` constructed in `flutter_html_table.dart:261` | Contains `flutter_html/` and `flutter_layout_grid/` |

Variant 2 is the reason early attempts at a stack-path-based filter failed: the stack is **entirely** framework code — no `flutter_html` frames appear, because `_SemanticsGeometry.computeChildGeometry` traverses the `_RenderObjectSemantics` tree directly. A filter that only requires package paths in the stack will silently miss this variant.

### Current workaround: global `FlutterError.onError` filter

`lib/main.dart` installs a global error filter via `_installHtmlTableSemanticsFilter()` before `runApp`. It suppresses **only** errors matching all four known signatures and forwards everything else unchanged to the previously-installed handler (typically `FlutterError.presentError`).

Match condition (applied AND-wise):

1. **Exception text** contains one of:
   - `"RenderBox was not laid out"` — covers variants 1 and 2
   - `"computeDryBaseline"` — covers variant 3
   - `"renderBoxDoingDryBaseline"` — alternate spelling of variant 3
   - `"'child!.hasSize'"` — covers variant 4 (note the surrounding single quotes, which are part of Dart's formatted `AssertionError` output)
1. **Stack text** contains one of:
   - `"flutter_html/"` — covers variants 1, 3, 4
   - `"flutter_layout_grid/"` — covers variants 1, 4
   - `"flushSemantics"` — **critical** for variant 2, whose stack has no package frames

Any error that fails either half is forwarded unchanged, so unrelated regressions are not masked.

First suppression per app run emits a single breadcrumb via `debugPrint`:

> `Suppressing known flutter_html_table non-fatal framework assertions (see Task Progress.md §5 and main.dart _installHtmlTableSemanticsFilter for details). Subsequent suppressions are silent.`

Subsequent suppressions are silent.

### Verification

Before the filter was installed, opening `Essentials → Time With God` on the iOS simulator produced ~2,200 lines of stack dumps per page load (see `logs.txt` committed as an artifact during the session — ~200 KB of essentially the same four errors repeating across ~50 frames). After the filter with the broadened match condition, the same page load produces **zero** full stack dumps (see `logs_2.txt`, 72 lines, ending cleanly with one breadcrumb and no error bodies).

### Unrelated log noise that is NOT suppressed (on purpose)

The same page load also prints ~12 lines per view of:

> `Due to Flutter layout restrictions (see https://github.com/flutter/flutter/issues/65895), contents set to 'vertical-align: baseline' within an intrinsically-sized layout may not display as expected...`

These are `debugPrint` messages emitted by `flutter_html` itself (not `FlutterError` exceptions), so they do **not** go through `FlutterError.onError` and are **not** affected by this filter. They point at upstream issue `flutter/flutter#65895`. They're verbose but functional — nothing is actually cut off or misrendered in the app — so they're left alone. If they ever become intolerable, the fix would be a `debugPrint` override, not an extension of this filter. Logging that as part of §7 future work.

### Investigation trail

The match condition went through three iterations before converging on the four-variant form above. The key insights each step produced:

1. **v1: match on `flushSemantics` only** — worked for the first error we saw (and for variant 2 today), but missed everything the paint pass reports with `library: 'rendering library'`. Gave up because we didn't have device diagnostic output yet.
1. **v2: match on `flutter_html/` / `flutter_layout_grid/` in stack** — caught variants 1, 3, 4 but silently missed variant 2 because the semantics walk stack is pure framework.
1. **v3 (current): 4 exception signatures + package paths OR `flushSemantics`** — catches all four observed variants. Verified against a real-device log capture on iOS simulator.

The diagnostic logging that drove this convergence (`[FILTER DIAG #N] exception type / text / library / stack-contains-flushSemantics / exception-contains-"RenderBox was not laid out"`, throttled to first 5 invocations) has since been removed from `main.dart` now that the filter is validated. If a future Flutter / flutter_html upgrade produces a new unsuppressed variant, the first step of triage should be to temporarily re-add that diagnostic block and capture one device log run.
