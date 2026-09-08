# Localization

English is the source language. French is the first reviewed localization.
Simplified Chinese, Japanese, Arabic, and Russian are complete drafts written to
exercise the layouts (CJK metrics, right-to-left mirroring, Cyrillic widths,
and the six Arabic and four Russian plural forms); they still need a native
speaker's review before they are advertised on the App Store.
The app, widget, and WatchNextCore each own a `Localizable.xcstrings` catalog.
System permission text lives separately in each target's `InfoPlist.xcstrings`.

Catalog keys use `feature.context.purpose`, for example
`settings.server.url.placeholder` or `feed.section.count.accessibilityLabel`.
Keep keys stable when wording changes. Prefer full words and semantic context
over view hierarchy. Translator comments explain where text appears and what
each argument means. Translate whole phrases and use catalog plural variations
for counts; do not assemble English singular/plural endings in code.

The app and widget enable Xcode's Generate String Catalog Symbols setting.
Xcode 26.6 turns `feed.hidden.count` into `feedHiddenCount(count:)`; dots in keys
do not create nested Swift namespaces. Generated sources remain build products.
App Intent metadata requires explicit `LocalizedStringResource` initializers:
the metadata exporter rejects generated properties there. Dynamic option titles
can use generated symbols normally.

WatchNextCore uses `String(localized:defaultValue:bundle:)` with `.module` so its
resources resolve from both app and widget. English defaults also allow command
line package tests to run when SwiftPM copies catalogs without compiling them.
Xcode compiles the catalogs into localized resources for the shipping app.

Persist identifiers and source data, never translated picker labels. Existing
widget density identifiers and case-insensitive media-kind values remain valid.
Collapsed-season descriptions resolve at display time, so cached media does
not require a refresh to adopt the selected language. Movies show no subtitle:
with only two kinds, the missing episode line already says "movie".
Server-supplied titles and technical log payloads retain their original text;
diagnostic controls and application-defined errors are localized.

When adding or changing strings:

1. Update the owning catalog's English value, comment, French translation, and
   plural forms where applicable.
2. Build the app and widget to regenerate symbols and validate App Intent metadata.
3. Check English and French layouts, including all widget sizes and VoiceOver
   labels, values, hints, and full descriptions for abbreviated widget content.
4. Run the package tests. Use Xcode's scheme language and region options for
   runtime localization checks; inspect system permission strings on a device.

App Store descriptions and screenshots are localized separately from the app.
