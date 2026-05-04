# Content Rendering

How worksheet HTML actually shows up on screen — the `flutter_html` configuration, the `sanitize()` workarounds, the global error filter, and the special-cases each addresses.

## Pipeline

```
ViewPage
  → pageContentProvider returns String content (with base64 images already inlined)
  → HtmlView(content, direction)
        Padding → SingleChildScrollView → Column → SelectionArea
          → Directionality(LTR | RTL based on Globals.rtlLanguages)
            → Html.fromDom(
                document: sanitize(content, isDarkMode),
                extensions: [TagWrapExtension({'table'}, …), TableHtmlExtension()],
                style: { body, td, th, h1, h2, h3, li, p, ul },
                onAnchorTap: (url, _, __) => Navigator.pushNamed(context, '/view$url'),
              )
```

## `sanitize()` (`lib/widgets/html_view.dart`)

The HTML emitted by the upstream `pywikitools` exporter has a few constructs that `flutter_html` can't render correctly. `sanitize()` runs a tree-rewrite step over the parsed DOM to fix them. Each rewrite is documented in-place, but here is the index:

| Pattern in source HTML | What `sanitize()` does | Why |
| --- | --- | --- |
| `<td><div class="mw-translate-fuzzy">…</div>` | Inlines the `<div>` content | flutter_html-3.0.0 with `<div>` inside `<td>` makes the page unusable (issue #170) |
| `<p><span class="mw-translate-fuzzy">…</span>` | Inlines the `<span>` content | Same root cause |
| `<td><p>X</p></td>` | → `<td>X</td>` | flutter_html_table issue #1188 |
| `<th><p>X</p></th>` | → `<th>X</th>` | Same |
| `<td><ul><li>x</li>…</ul></td>` | → `<td>• x<br/>…</td>` | Same — list items inside cells break layout |
| `<th style="…">` | strip `style` | confuses width computation |
| `<table style="width:100%" …>` | strip `style` and `width` attrs | flutter_html-3.0.0 reads `100%` as `100 px` (CssBoxWidget._computeSize doesn't resolve percent units) — the table would overflow by hundreds of pixels |
| `<p><span style="font-size:125%"><i><b>X</b></i></span></p>` | → `<h2><i><b>X</b></i></h2>` | so subtitles render at proper size |
| `<div class="floatleft"><img></div><div style="margin-left:25px"><p>…</p></div>` | → `<table><tr><td><img></td><td>…</td></tr></table>` | flutter_html doesn't support CSS `float`; this is the workaround used by "God's Story (five fingers)" |
| Dark mode + `<div style="...background-color:#f9f9f9; border:1px solid black">` | swap colors → `#090909` + `solid white` | so the box stays readable in dark mode |

> **Note**: There are several `// FIXME` comments for fixing these in the HTML generator
> (`pywikitools`) instead, since fixing `flutter_html` is out of scope.

## `Html.fromDom` configuration

- **Extensions** (order matters): `TagWrapExtension({'table'}, …)` must come **before** `TableHtmlExtension()`. The wrap extension matches `<table>` first, delegates the inner build to the table extension via `prepareFromExtension(extensionsToIgnore: {this})`, and wraps the result in `_HorizontalTableScroll`. If the order were reversed, the table extension would win and the wrap would never apply, leaving wide tables to overflow or trigger "RenderBox was not laid out" assertions.
- **`_HorizontalTableScroll`** is a small `StatefulWidget` that gives the inner `SingleChildScrollView(scrollDirection: Axis.horizontal)` an explicit `ScrollController` (because it lives inside a `WidgetSpan` where `PrimaryScrollController` doesn't apply) and forces `Scrollbar.thumbVisibility: true` so users see when a table is wider than the screen.
- **Style overrides** for `body`, `td`, `th`, `h1`, `h2`, `h3`, `li`, `p`, `ul` to tune spacing and alignment.
- **`onAnchorTap`**: any `<a href="/Foo/de">` link routes through `Navigator.pushNamed(context, '/view/Foo/de')`. This is what makes inline links between worksheets work.

## `_installHtmlTableSemanticsFilter()` (`lib/main.dart`)

A long, well-documented function that wraps `FlutterError.onError` and silently drops known-non-fatal assertions thrown by `flutter_html_table` 3.0.0. Read the docstring before changing anything here.

The filter matches **two conditions, both required**:

**(a) Exception message contains one of:**
- `RenderBox was not laid out`
- `computeDryBaseline`
- `renderBoxDoingDryBaseline`
- `'child!.hasSize'`

**(b) Stack contains one of:**
- `flutter_html/`
- `flutter_layout_grid/`
- `flushSemantics`

The four assertion variants are all inside `flutter_html_table` 3.0.0's `LayoutBuilder` / `LayoutGrid` / `WidgetSpan` composition. Variant 2 (semantics-pass) has a pure-framework stack (no package frames), so we additionally match on `flushSemantics`.

Anything that fails either condition is forwarded to the previous handler (typically `FlutterError.presentError`), so unrelated regressions are *not* masked.

A single breadcrumb is emitted via `debugPrint` on the first suppression per app run, so logs show the filter is active. Subsequent suppressions are silent to avoid log spam.

**Why this is in `main.dart` rather than the widget layer:**
1. The assertions don't reproduce in `flutter_test`, so a widget-level fix can't be regression-tested.
2. The root cause is third-party (`flutter_html_table`).
3. Wrapping tables in `SelectionContainer.disabled` was tried and broke text selection without fixing the assertion.

> **Note:** The proper fix is a newer upstream `flutter_html_table`.
> Until then this filter keeps the logs usable.

## Selection and direction

- The whole rendered area sits inside a single top-level `SelectionArea`, so users can copy worksheet text. (One earlier attempt to wrap tables in `SelectionContainer.disabled` was reverted because it broke selection across the page.)
- `Directionality` is set to `RTL` for languages in `Globals.rtlLanguages` (currently `['ar', 'fa']`). Adding a new RTL language requires updating that list.

## Image handling

Images are inlined as base64 by `pageContentProvider` *before* `HtmlView` ever sees the HTML. This avoids `flutter_html` having to load `file://`-prefixed URIs (which is fragile on Android/iOS). The downside is the rendered HTML can be large — for image-heavy worksheets like "God's Story (five fingers)" the inlined string can be hundreds of KB. So far this hasn't been a problem in practice.
