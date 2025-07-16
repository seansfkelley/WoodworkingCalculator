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

I don't know how to Xcode properly. Before building the app in Xcode, you need to `cd WoodworkingCalculator/Parser && make`, which will compile and spit out the parser in Swift, which is necessary to build the app.

## Installing

Not distributed on the App Store. Build and install it through the regular Xcode techniques, or AltStore.
