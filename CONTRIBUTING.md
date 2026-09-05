# Contributing

Thanks for helping.

- Open `WatchNext.xcworkspace`, not the project. Set your own team under Signing & Capabilities; the repository ships without one.
- Run the package tests before opening a pull request:

  ```sh
  cd Packages/WatchNextLogging && swift test
  cd Packages/WatchNextCore && swift test
  ```

- Try changes against `AppStore/DemoServer/demo_server.py` if you don't have servers at hand; it fakes all three with a fictional catalog.
- Keep commits small and use the existing style: `feat(scope): …`, `fix(scope): …`, `docs: …`.
- Never commit real titles, artwork, server addresses, keys or tokens. Screenshots and fixtures use invented media only.
- Widget configuration parameters stay Strings on purpose; see the README's known limitations before changing them to enums.
