# TimePlane — 2026 Modernization Roadmap

> Prepared: 2026-04-27. Audience: maintainer(s) and any contributors picking this project back up.

---

## 1. Executive Summary

- **The toolchain is ~12 years stale.** RubyMotion, Teacup, BubbleWrap, and rake 10 are all end-of-life or effectively abandoned. The app targets iOS 6.0; current App Store minimum is iOS 16.
- **There is no CI.** Zero automation means breakage is discovered only when someone tries to build locally. Adding GitHub Actions is the single highest-leverage change that costs almost nothing.
- **The test suite is a stub.** One spec that checks `UIApplication.sharedApplication.windows.size` gives false confidence. Real behaviour (timezone rendering, gesture math, sunrise calculations) is untested.
- **Security posture is zero.** No Dependabot, no secret scanning, no SBOM. Hardcoded developer provisioning profile paths and certificate names are committed in `Rakefile`.
- **The strategic fork is "maintain or rewrite".** RubyMotion's commercial future is uncertain. A realistic modernization plan must acknowledge that the lowest-risk long-term path is a **Swift/SwiftUI rewrite**, with RubyMotion triage as the short-term stabilization step.

---

## 2. Current State

| Dimension | Current |
|---|---|
| **Language** | Ruby (RubyMotion — Ruby compiled to native iOS binary) |
| **RubyMotion version** | Unknown; Rakefile loads from `/Library/RubyMotion/lib` |
| **iOS deployment target** | iOS 6.0 (App Store min is iOS 16 as of 2025) |
| **Key gem deps** | teacup 2.1.10, motion-support 0.2.5, bubble-wrap 1.3.0, rake 10.1.0 |
| **Lockfile** | `Gemfile.lock` present but pinned to very old versions |
| **Build system** | `rake` via RubyMotion Rakefile |
| **CI** | None |
| **Test framework** | RubyMotion built-in spec runner (MacBacon-derived) |
| **Test coverage** | 1 integration smoke test (effectively 0% unit coverage) |
| **Linter/formatter** | None |
| **Container/Docker** | None |
| **Observability** | None |
| **Secret management** | Provisioning profile paths and signing cert names hardcoded in `Rakefile` |
| **CLAUDE.md** | Present (untracked in git at time of audit) |

---

## 3. Recommendations

### 3.1 Language / Runtime / Framework

#### Short-term: stabilize on RubyMotion (if the app must ship quickly)

RubyMotion is still available but is effectively a single-vendor, niche commercial tool with a shrinking community. Before any feature work, the build must be validated against a current toolchain:

1. Install RubyMotion 9.x (latest stable as of 2026) and Xcode 16.
2. Bump `app.deployment_target` in `Rakefile` from `'6.0'` to `'16.0'`. iOS 6 devices are not supported by any current Xcode simulator.
3. Update `bubble-wrap` to `2.0+` (drops many iOS 6-era shims) and `motion-support` to `1.0+`. Both publish RubyMotion 9-compatible releases.
4. Pin the RubyMotion version in a `.rubymotion-version` file:
   ```
   9.4
   ```
5. Replace `UIBarButtonItemStyleBordered` (deprecated iOS 8, removed iOS 13) with `UIBarButtonItemStylePlain`.
6. Replace `presentModalViewController` (deprecated iOS 6) with `presentViewController(_:animated:completion:)`.

#### Long-term: migrate to Swift + SwiftUI

RubyMotion's commercial trajectory is a risk. A SwiftUI rewrite is approximately 500–800 lines of Swift for the current feature set:

- `ContentView` replaces `TimePlaneController` (UITableViewController)
- `TimeRowView` replaces `TimePlaneCell` + `TimeView`
- `TimeZonePickerView` replaces `TimeZonesController`
- Sunrise calculation (`app/sunrise.rb`) ports cleanly to Swift; consider using Apple's `SolarEvents` API (iOS 16+) instead.
- Persist timezone list with `@AppStorage` instead of direct `NSUserDefaults`.

Target: Swift 6, minimum iOS 16, Xcode 16. Use Swift strict concurrency (`-strict-concurrency=complete`) from day one to avoid retrofitting later.

---

### 3.2 Dependencies

**Current state:** `Gemfile.lock` was last resolved circa 2013–2014. No audit has ever been run.

Steps:
1. **Audit immediately:**
   ```bash
   bundle audit check --update
   ```
   Install `bundler-audit` (`gem install bundler-audit`). All four gems are old enough that known CVEs may exist.

2. **Regenerate the lockfile** after bumping deps:
   ```bash
   bundle update --conservative
   ```

3. **Enable Dependabot** for the `bundler` ecosystem (see §3.7). Weekly cadence is sufficient for a maintenance-mode app.

4. For the Swift rewrite path, use Swift Package Manager exclusively. Avoid CocoaPods and Carthage for new code. Pin exact versions in `Package.resolved`.

---

### 3.3 Testing

**Current state:** 1 smoke spec; all gesture logic, zoom clamping, timezone math, and sunrise calculation are untested.

#### RubyMotion path
- Add unit specs for `clip_zoom` (boundary conditions: below 0.75, above 5, in range).
- Add unit specs for `sunrise.rb` with known lat/lon/date fixtures.
- Target: ≥40% line coverage measured via `motion-coverage` gem.
- Use `motion-stump` for stubbing `NSUserDefaults` in controller specs.

Example spec to add immediately:
```ruby
describe "TimePlaneController#clip_zoom" do
  before { @ctrl = TimePlaneController.alloc.init }
  it "clamps below minimum" do
    @ctrl.send(:clip_zoom, 0.1).should == 0.75
  end
  it "clamps above maximum" do
    @ctrl.send(:clip_zoom, 10).should == 5
  end
  it "passes through in-range values" do
    @ctrl.send(:clip_zoom, 2.0).should == 2.0
  end
end
```

#### Swift rewrite path
- Use **XCTest** for unit tests, **Swift Testing** (introduced Xcode 16) for new test files.
- Use **XCUITest** for UI automation (add/remove timezone, pan gesture simulation).
- Integrate **Codecov** in CI; require ≥70% coverage on PRs.
- Add **mutation testing** with [Muter](https://github.com/muter-mutation-testing/muter) after baseline coverage is established.

---

### 3.4 CI/CD

**Current state:** No CI whatsoever.

Add `.github/workflows/ci.yml`. The RubyMotion variant requires macOS runners (iOS simulators only run on macOS):

```yaml
name: CI

on:
  push:
    branches: [master]
  pull_request:

jobs:
  test:
    runs-on: macos-15
    timeout-minutes: 30
    steps:
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683  # v4.2.2

      - name: Set up Ruby
        uses: ruby/setup-ruby@32110d4e311bd8996b2a82bf2a43b714bec91345  # v1.201.0
        with:
          ruby-version: '3.3'
          bundler-cache: true

      - name: Install RubyMotion
        run: |
          # RubyMotion requires a license key; use secret RM_LICENSE_KEY
          echo "RubyMotion install steps here (vendor or cache /Library/RubyMotion)"
        env:
          RM_LICENSE_KEY: ${{ secrets.RM_LICENSE_KEY }}

      - name: Run specs
        run: bundle exec rake spec
```

Key CI modernization requirements:
- **Pin all `uses:` to full SHA** (not `@v4` tags) to prevent supply-chain attacks.
- **Cache gems** via `bundler-cache: true` on `ruby/setup-ruby`.
- **Cache the iOS simulator** runtime using `actions/cache` keyed on Xcode version.
- **Use OIDC** for any cloud deployments (App Store Connect via `apple-actions/upload-testflight-build`) instead of long-lived API keys stored as secrets.
- Add a separate `lint` job running RuboCop (RubyMotion profile) on every PR.

For the Swift rewrite, replace the RubyMotion steps with `xcodebuild test -scheme TimePlane -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest'`.

---

### 3.5 Code Quality

**Current state:** No linter, no formatter, no pre-commit hooks.

#### RubyMotion path
1. Add **RuboCop** with `rubocop-rubymotion` extension:
   ```
   gem 'rubocop', '~> 1.65'
   gem 'rubocop-rubymotion'
   ```
   Add `.rubocop.yml`:
   ```yaml
   require: rubocop-rubymotion
   AllCops:
     NewCops: enable
     TargetRubyVersion: 3.3
   ```
2. Add **pre-commit** hooks via the `overcommit` gem:
   ```yaml
   # .overcommit.yml
   PreCommit:
     RuboCop:
       enabled: true
   ```

#### Swift rewrite path
- Use **SwiftLint** 0.57+ with strict mode.
- Use **SwiftFormat** for deterministic formatting.
- Add both to the CI `lint` job and as pre-commit hooks via [pre-commit](https://pre-commit.com):
  ```yaml
  # .pre-commit-config.yaml
  repos:
    - repo: https://github.com/nicklockwood/SwiftFormat
      rev: 0.54.3
      hooks:
        - id: swiftformat
    - repo: https://github.com/realm/SwiftLint
      rev: 0.57.0
      hooks:
        - id: swiftlint
  ```
- Enable **strict Swift concurrency checking** (`SWIFT_STRICT_CONCURRENCY = complete` in Xcode build settings).

---

### 3.6 Observability

**Current state:** None. For an offline iOS app this is low priority, but crash reporting and basic analytics are table stakes for an App Store app.

1. **Crash reporting:** Integrate **Firebase Crashlytics** (free tier). For the Swift rewrite, use the Swift Package Manager distribution.
2. **Analytics:** Use **TelemetryDeck** (privacy-respecting, no PII, €0 for small apps) rather than Firebase Analytics. Add events for: app launch, timezone added/removed, "Now" button tapped.
3. **Structured logging:** For debug builds only, use `os_log` (available since iOS 10, Swift-native via `OSLog`):
   ```swift
   import OSLog
   private let logger = Logger(subsystem: "de.furrylabs.TimePlane", category: "TimePlane")
   logger.info("Timezone added: \(tz.identifier, privacy: .public)")
   ```
4. **OpenTelemetry:** Not applicable for this offline iOS app at this time. Revisit if a backend component is ever added.

---

### 3.7 Security & Supply Chain

**Current state:** No scanning, no SBOM, secrets in source.

Actions (in priority order):

1. **Remove secrets from `Rakefile` immediately.** The hardcoded provisioning profile paths and certificate names are not secrets per se (they're developer-local config), but they make the build non-reproducible and will break on any other machine. Move to environment variables or a `.env.local` file that is `.gitignore`d:
   ```ruby
   app.development do
     app.provisioning_profile = ENV['DEV_PROVISIONING_PROFILE']
     app.codesign_certificate = ENV['DEV_CODESIGN_CERT']
   end
   ```

2. **Enable GitHub secret scanning** on the repository (Settings → Security → Secret scanning). Enable push protection.

3. **Enable Dependabot** (`.github/dependabot.yml`):
   ```yaml
   version: 2
   updates:
     - package-ecosystem: bundler
       directory: "/"
       schedule:
         interval: weekly
       open-pull-requests-limit: 5
   ```

4. **Enable CodeQL** for static analysis:
   ```yaml
   # .github/workflows/codeql.yml
   name: CodeQL
   on:
     push:
       branches: [master]
     schedule:
       - cron: '0 6 * * 1'
   jobs:
     analyze:
       runs-on: macos-15
       permissions:
         security-events: write
       steps:
         - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683
         - uses: github/codeql-action/init@v3
           with:
             languages: ruby
         - uses: github/codeql-action/analyze@v3
   ```
   For the Swift rewrite, add `languages: swift` instead.

5. **Generate an SBOM** at release time using [syft](https://github.com/anchore/syft):
   ```bash
   syft dir:. -o spdx-json > sbom.spdx.json
   ```
   Attach to GitHub Releases as an artifact.

6. **Vulnerability scanning:** Run [grype](https://github.com/anchore/grype) against the SBOM in CI:
   ```bash
   grype sbom:sbom.spdx.json --fail-on high
   ```

---

### 3.8 Container / Deployment

**Current state:** No containerization. iOS apps cannot run in Linux containers, so Docker is not relevant for the runtime artifact.

What IS relevant:

1. **CI environment reproducibility.** Specify exact `macos-15` runner (not `macos-latest`, which is a floating alias). Pin Xcode version explicitly:
   ```yaml
   - name: Select Xcode
     run: sudo xcode-select -s /Applications/Xcode_16.3.app
   ```

2. **App Store deployment via Fastlane.** Replace the manual `rake archive` + Xcode Organizer workflow with [Fastlane](https://fastlane.tools):
   ```ruby
   # Fastfile
   lane :beta do
     build_app(scheme: "TimePlane")
     upload_to_testflight
   end
   ```
   Use OIDC-based App Store Connect API keys (not long-lived p8 files) stored in GitHub Actions secrets.

3. **No Docker needed** for this app. If a future backend companion service is added, use a multi-stage `Dockerfile` with `gcr.io/distroless/base-debian12` as the final stage and sign images with `cosign`.

---

### 3.9 Developer Experience

**Current state:** Setup requires a licensed RubyMotion installation, which is Mac-only and non-trivial.

1. **Add a `CONTRIBUTING.md`** documenting exact setup steps:
   - Install Xcode 16 from the App Store
   - Install RubyMotion 9.x: `brew install rubymotion` (if the tap is maintained) or from rubymotion.com
   - Activate license: `motion activate <key>`
   - `bundle install && rake`

2. **Add a dev-environment script** (`bin/setup`):
   ```bash
   #!/usr/bin/env bash
   set -euo pipefail
   gem install bundler --no-document
   bundle install
   echo "Run 'rake' to build in the simulator."
   ```

3. **Dev Container / Codespaces:** Not feasible for RubyMotion (Mac-only toolchain). For the Swift rewrite path, a devcontainer is still not useful (Xcode requires macOS). Instead, document that contributors need macOS 14+ with Xcode 16.

4. **Commit the `CLAUDE.md`** — it exists in the working tree but was untracked at audit time. It is high quality and should be version-controlled:
   ```bash
   git add CLAUDE.md
   ```

5. **Add `bin/` scripts** for common tasks (`bin/test`, `bin/lint`) so contributors don't need to memorize rake task names.

---

### 3.10 AI / Agent Readiness

**Current state:** `CLAUDE.md` is present and substantive but untracked in git.

1. **Commit `CLAUDE.md`** immediately (see §3.9 point 4). Agents and contributors need it version-controlled.

2. **Expand `CLAUDE.md`** with:
   - A description of each source file's role (e.g., what `time_view.rb` vs `time_plane_cell.rb` each own)
   - The known broken state (iOS deployment target gap, deprecated APIs)
   - Which files are safe to edit vs. high-risk (e.g., `sunrise.rb` has external attribution — flag it)
   - A "current known failures" section so agents don't waste cycles chasing pre-existing issues

3. **Add agent-friendly test fixtures** in `spec/fixtures/` with known timezone/sunrise inputs and expected outputs. Agents can run `rake spec` to verify their changes without a working simulator.

4. **Add a `CODEOWNERS` file** to require human review on `Rakefile` and signing-related changes:
   ```
   # .github/CODEOWNERS
   Rakefile @tkadauke
   docs/     @tkadauke
   ```

5. **Structured commit conventions.** Adopt [Conventional Commits](https://www.conventionalcommits.org/) to enable automated changelogs and make agent commit history parseable:
   ```
   feat: add UTC timezone as default
   fix: clamp zoom below 0.75 correctly
   docs: update CLAUDE.md with file roles
   ```

---

## 4. Prioritized Roadmap

| Priority | Item | Effort | Impact |
|---|---|---|---|
| **P0** | Remove hardcoded cert/profile paths from `Rakefile` | 30 min | High — prevents accidental secret exposure and makes builds portable |
| **P0** | Commit `CLAUDE.md` to git | 5 min | High — immediately improves agent and contributor onboarding |
| **P0** | Bump `app.deployment_target` to `'16.0'` and validate build | 2–4 h | High — app is currently unsubmittable to App Store |
| **P0** | Add basic GitHub Actions CI (`rake spec` on `macos-15`) | 2 h | High — catches regressions immediately |
| **P1** | Update all gem dependencies and regenerate lockfile | 2 h | High — eliminates known-vulnerable versions |
| **P1** | Enable Dependabot for bundler ecosystem | 30 min | Medium — automates future dep hygiene |
| **P1** | Enable GitHub secret scanning with push protection | 15 min | High — prevents future accidental commits |
| **P1** | Add RuboCop + rubocop-rubymotion and fix existing offenses | 4 h | Medium — establishes a style baseline |
| **P1** | Expand test suite: `clip_zoom`, `sunrise.rb` unit specs | 4 h | Medium — reduces regression risk on the only non-trivial logic |
| **P1** | Replace deprecated UIKit API calls (3 known usages) | 2 h | High — required for iOS 16+ compatibility |
| **P2** | Add CodeQL workflow | 1 h | Medium — free SAST, low maintenance |
| **P2** | Integrate Fastlane for App Store / TestFlight delivery | 1 day | Medium — eliminates manual release process |
| **P2** | Add `bin/setup` and `CONTRIBUTING.md` | 2 h | Low — quality-of-life for contributors |
| **P2** | Add Firebase Crashlytics | 4 h | Medium — production visibility currently zero |
| **P2** | Strategic decision: continue RubyMotion or begin SwiftUI rewrite | 1–2 weeks (rewrite) | High — resolves the fundamental toolchain risk |
| **P2** | Generate SBOM with syft at release time | 1 h | Low-Medium — supply chain compliance |

---

## 5. Risks & Non-Goals

### Risks

**RubyMotion commercial risk.** RubyMotion is developed by a single company (HipByte). If they discontinue the product (or have already — verify current license availability before investing), the entire RubyMotion path collapses. Validate that a current RubyMotion license is obtainable before committing to the stabilization path.

**iOS SDK churn.** Apple deprecated and removed many UIKit APIs between iOS 6 and iOS 16. A `deployment_target` bump will surface compilation errors in RubyMotion that may not have obvious RubyMotion-idiomatic fixes.

**Simulator-only CI.** Running `rake spec` in GitHub Actions requires a macOS runner with a licensed RubyMotion installation. This is non-trivial to automate and adds cost ($0.08/min for macOS runners vs. $0.008/min for Linux). Consider whether the test value justifies the CI cost until the suite has meaningful coverage.

### Non-Goals

- **Adding new features before the build is validated.** The CLAUDE.md is explicit: stabilize first.
- **Supporting iOS < 16.** iOS 6 through 15 represent <2% of active devices and are not accepted by the App Store.
- **Dockerizing the iOS app.** iOS binaries run on Apple hardware/simulators only; containerization is not applicable to the app artifact itself.
- **Full OpenTelemetry instrumentation.** The app has no network calls and no backend; distributed tracing adds zero value at this scale.
- **Migrating away from `NSUserDefaults`.** It works, it is simple, and the data model is trivial. `SwiftData` or Core Data would be overengineering for a list of timezone strings.
- **Maintaining CocoaPods or Carthage support.** If the Swift rewrite uses SPM, do not add CocoaPods compatibility layers.
