# Overview

Switching between a mouse and a trackpad on a MacBook can be frustrating
since there's no quick way to toggle the *Natural Scrolling* setting.
Unfortunately, Apple Script turns out to be clunky and unreliable.

That’s where this handy little app comes in. With just a double-click,
you can switch the *Natural Scrolling* setting instantly. Even better,
pair it with a hotkey (e.g., with
[HotKey App](https://apps.apple.com/us/app/hotkey-app/id975890633))
for an even smoother experience!

# How it works

Like Apple Script, this app uses UI automation to get the job done --
but in a much more reliable way.

Instead of relying on fixed delays, it uses a retry mechanism to keep
things both fast and dependable. And rather than depending on a specific
parent-child relationship between UI elements, it scans all elements on
the page to find the one we need.

Specifically, it performs these steps:

1. Open *Trackpad* setting using this url: \
   `x-apple.systempreferences:com.apple.Trackpad-Settings.extension`.

2. Find the element with `Scroll & Zoom` label, and click it. \
   If you're using a different language on macOS, be sure to update the
   `"Scroll & Zoom"` string in `Main.m` accordingly.

3. Find the element with `NaturalScrollingToggle` identifier, and click
   it.

4. Close the *System Settings* window after 1 second.

# Compile

Xcode Command Line Tools is required (full version of Xcode also works).
If you don’t have either installed, run the following command to install
Xcode Command Line Tools:

```
xcode-select --install
```

Then build the app by running `build.sh`:

```
./build.sh
```

You'll get an executable, `ToggleNatualScrolling`, which is useful for
debugging in Terminal, and an app bundle, `ToggleNatualScrolling.app`,
which is ideal for everyday use.

It requires the Accessibility permission, please add the app to the list:
System Settings -> Privacy & Security -> Accessibility. If the app is
modified (recompiled), you need to remove the app from the list first,
and then add it back.

# Supported macOS versions

Tested on macOS 13 Sequoia. It should also work on earlier versions as
long as the *System Settings* UI is similar.
