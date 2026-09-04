# iOS Mac launcher

From the repository root on a Mac, run:

```bash
bash Scripts/open-ios.sh
```

The script needs a full Xcode installation, but does not require Homebrew or administrator access. It generates `NukeUnitTracker.xcodeproj` using a private per-user XcodeGen cache, then opens the project in Xcode.

After Xcode opens, choose an iPhone simulator in the toolbar and press the triangular Run button.
