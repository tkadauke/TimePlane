# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TimePlane is a small RubyMotion iOS app for visualizing and converting times across multiple time zones. The main view stacks horizontal time lines for user-selected zones on top of each other, making cross-zone comparisons (e.g. "if it is 9am here, what time is it in Hong Kong?") readable at a glance. It also overlays sunrise and sunset bands per zone using the zone's geographic coordinates. The app shipped on the iOS App Store.

## Tech Stack

- Language: Ruby (RubyMotion, compiled to native iOS)
- Platform target: iOS 6.0+, iPhone and iPad
- Build tool: RubyMotion's Rake-based build system (`rake`)
- Dependencies (via Bundler / Gemfile):
  - `teacup` - stylesheet DSL for UIKit views
  - `motion-support` - ActiveSupport-style core extensions for RubyMotion
  - `bubble-wrap` - convenience wrappers around iOS APIs
- Test framework: RubyMotion's built-in Bacon-style spec runner

## Repository Structure

```
.
|-- Rakefile                # RubyMotion project config (app name, version, signing, deploy target)
|-- Gemfile / Gemfile.lock  # Ruby dependencies
|-- app/                    # Application source
|   |-- app_delegate.rb         # UIApplication entry point, sets up root nav controller
|   |-- time_plane_controller.rb  # Main UITableViewController; pan/pinch gestures, add/edit time zones
|   |-- time_zones_controller.rb  # Modal picker for adding a time zone (search + list)
|   |-- time_plane_cell.rb        # Custom UITableViewCell composing the timeline + labels
|   |-- time_view.rb              # Custom UIView that draws the hour ticks and sunrise/sunset bands
|   |-- time_zone_locations.rb    # Hardcoded lat/long lookup keyed by NSTimeZone name
|   |-- sunrise.rb                # Sunrise/sunset calculation module
|   |-- ui_view.rb                # UIView monkey-patch adding `each_subview`
|   |-- styles/                   # Teacup stylesheets
|   `-- assets/                   # Source icon used by the `icons` rake task
|-- resources/              # App icons, launch images, etc. shipped into the bundle
`-- spec/                   # RubyMotion specs (one example file)
```

## Common Commands

All commands assume RubyMotion is installed locally at `/Library/RubyMotion` (referenced from the `Rakefile`).

- Install Ruby dependencies: `bundle install`
- Build and run in the iOS Simulator: `rake`
- Run on a specific simulator device: `rake device_name="iPhone 5"`
- Run the spec suite: `rake spec`
- Show all RubyMotion config keys for the project: `rake config`
- Regenerate app icons from `app/assets/icon.png` into `resources/`: `rake icons` (requires ImageMagick's `convert` on PATH)
- Build a release archive: `rake archive` (requires the release provisioning profile and signing identity configured in `Rakefile`)

## Architecture & Conventions

- Standard RubyMotion layout: every `.rb` file under `app/` is autoloaded at build time. There is no manual `require` graph for app code.
- UI is built imperatively in `viewDidLoad` / `init` methods using UIKit classes directly. Layout for cells is declared via `teacup` stylesheets in `app/styles/`.
- `TimePlaneController` (root controller) owns the list of `NSTimeZone` instances. Persistence is via `NSUserDefaults` under the key `time_zones`, storing the zones' name strings.
- `TimePlaneCell` composes a `TimeView` (custom drawing) plus a name label and a current-time label. The cell starts an `NSTimer` to refresh the time label each minute.
- `TimeView#drawRect:` does all the timeline rendering with Core Graphics: hour tick marks, day-boundary numbers, the red "now" marker, and yellow sunrise/sunset bands. Pan offset and pinch zoom are mapped to a `@slot_width` (pixels per hour).
- Sunrise/sunset times come from `Sunrise.sunrise` / `Sunrise.sunset` in `app/sunrise.rb`, which implements the standard astronomical algorithm. Coordinates per zone come from the constant `TIME_ZONE_LOCATIONS` in `app/time_zone_locations.rb`. Zones not present in that map simply render without sun bands.
- `Sunrise` returns `:up_all_day` or `:down_all_day` symbols for polar edge cases; `TimeView` checks for these explicitly.
- `app/ui_view.rb` opens `UIView` to add `each_subview`, used by the controller to walk all `TimePlaneCell`s when applying offset/zoom updates.
- Naming: file names are `snake_case.rb` and contain a single PascalCase class matching the file name (RubyMotion convention).

## Testing

- Specs live in `spec/` and use RubyMotion's built-in Bacon-style DSL (`describe` / `it` / `.should ==`).
- Run all specs against the simulator: `rake spec`.
- The current spec coverage is minimal (one smoke test that the app has a window). The README explicitly notes that the author skipped writing tests for this side project, so adding new specs alongside changes is encouraged but there is little prior art to mirror.
- `AppDelegate#application:didFinishLaunchingWithOptions:` short-circuits when `RUBYMOTION_ENV == 'test'`, so specs do not bring up the full UI by default.

## Notes / Gotchas

- The `Rakefile` hardcodes absolute paths to provisioning profiles under `/Users/tkadauke/Library/MobileDevice/Provisioning Profiles/` and developer/distribution signing identities for "Thomas Kadauke". Any other contributor needs to swap these for their own profiles before `rake device` or `rake archive` will succeed; `rake` against the simulator works without them.
- `app.deployment_target = '6.0'` and the code uses several APIs that are deprecated or removed on modern iOS, e.g. `presentModalViewController:animated:`, `dismissModalViewControllerAnimated:`, `UISearchDisplayController`, `UITableViewCellStyleSubtitle`, `UITextAlignmentRight`, and `UIBarButtonItemStyleBordered`. Touching the UI on a current RubyMotion / iOS SDK will likely require modernizing these call sites.
- `TIME_ZONE_LOCATIONS` was machine-generated and contains a number of obviously wrong coordinates (e.g. `America/Cayman` mapped to a point in California, `America/Halifax` mapped to the UK, several `Antarctica/*` entries pointing to random places). Treat the table as approximate and verify before relying on it.
- `TimeView` and `TimePlaneCell` each schedule a 1-second `NSTimer` per instance and never invalidate them. With many cells this leaks timers; be aware when adding cell-lifecycle changes.
- There is no CI configuration in the repo (no `.github/workflows/`, no `.travis.yml`); all testing is local via `rake spec`.
