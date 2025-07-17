# WoodworkingCalculator

A four-function calculator tailored for the US customary system as it's used in woodworking.

Specifically, it:

- Understands fractions.
  - Type fractions in. Get fractions as output.
  - Configurable fractional precision.
  - Shortcuts for commonly-used fractions.
  - Accepts decimal, but will round the result to the nearest fraction. 
- Understands feet-and-inches notation.
  - Use the ' and " keys if necessary.
  - Configurably output feet-and-inches or just inches, to taste. 

## Building

There is a separate Xcode build target for [Citron](https://github.com/roop/citron/) and the grammar file it compiles. This is hardcoded to use `SDKROOT=macosx` so it works when the run target is iPhones. 

## Installing

Not distributed on the App Store. Build and install it through the regular Xcode techniques, or AltStore.
