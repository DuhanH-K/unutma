# Golden baselines

Golden images are intentionally platform-specific because Flutter's host test
renderer can rasterize the same font outlines differently on Windows and
macOS. Tests remain strict, pixel-for-pixel comparisons within each platform;
there is no global tolerance.

- `windows/` contains references reviewed on Windows with Flutter 3.47.0.
- `macos/` must contain references reviewed from a Codemagic macOS run with
  Flutter 3.47.0 before the iOS workflow can pass.

When a platform baseline is missing, `visual_qa_test.dart` writes an explicit
`<name>_<platform>_candidate.png` into `test/failures/` and fails. Review those
candidates and the rendered UI before promoting them to a baseline. Do not run
`--update-goldens` blindly.
