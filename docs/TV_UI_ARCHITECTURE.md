# Medito TV UI Architecture

## Product direction

Android TV / Google TV is not treated as a stretched phone interface. The TV presentation layer is remote-first while continuing to reuse Medito's repositories, providers, models, playback engine, authentication, and content APIs.

## Permanent Zen Mode

On Leanback devices, `zenModeProvider` resolves to `true` and ignores attempts to disable it. The TV UI intentionally does not surface streak percentages, consistency rings, reminder-oriented progress, or the Zen Mode setting itself.

Stats can still be recorded internally so account history remains consistent across devices.

## Primary navigation

`TvNavigationShell` is the TV root UI. It uses a fixed left rail with five destinations:

1. Home
2. Explore
3. Search
4. Library
5. Settings

Settings is anchored at the bottom of the rail. The rail uses explicit focus styling and D-pad activation. Right from the rail transfers directional focus into the page content; Back from any non-Home root destination returns to Home.

The phone/tablet floating navigation remains unchanged.

## Home

`TvHomeView` replaces the mobile home composition on TV. It follows a streaming-app layout:

- one large, single-focus "Continue your path" hero
- horizontal Featured shelf
- horizontal Quick access shelf
- large 10-foot focus treatment with scale, border, and glow

The mobile streak/progress header, Your Path explainer interaction, donation/shop surfaces, and phone-only shortcuts are not part of the TV home.

## Explore

`TvExploreView` uses a fixed card grid designed for directional navigation rather than the phone masonry presentation.

## Search

`TvSearchView` is a dedicated root destination. The search field is a large focus target and invokes the platform keyboard when selected. Search results continue to reuse Medito's shared search implementation.

## Library

`TvLibraryView` provides TV entry points for Favorites and Downloads. It intentionally groups saved/offline content into one TV concept rather than exposing scattered mobile actions.

## Settings

`TvSettingsView` is intentionally smaller than mobile Settings. It currently exposes:

- Account
- Theme
- Advanced preferences
- Analytics & Privacy

Phone-only settings and Zen Mode controls are not shown.

## Shared focus primitive

`TvFocusCard` is the shared 10-foot focus surface. When focused it:

- increases scale slightly
- draws a primary-color border
- adds a subtle glow/background
- calls `Scrollable.ensureVisible` so D-pad movement keeps the focused card on screen

## Files

TV-specific presentation lives under `lib/views/tv/` so mobile UI can continue evolving without forcing phone interaction patterns onto television devices.
