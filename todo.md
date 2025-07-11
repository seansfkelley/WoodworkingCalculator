- put in popover content for approxation equality
- add setting for maximum precision: 1/16, 1/32, 1/64... thou?
    - should `evaluate` take a precision or always operate at maximum fidelity?
- show visual feedback when tapping a button
- prevent input if it doesn't make sense in that place (a la the regular Calculator app)
    - consider reformatting input with pretty fractions as-you-type so you can see how it's being parsed
- color palette and then test dark mode
- how does it behave on other device form factors?
- what to do about negative values?
- a la calculator app, holding backspace it should delete everything
- bug
    1. set display for feet and inches
    2. do a calculation that yields feet
    3. set display for inches only
    4. hit "+"
    5. the calculated result switches to inches, then appends "+"
- pretty frations: parser has to be able to read them, or keep a non-pretty version of it under the hood
    - probably easiest to support parsing them properly so that copy-paste works
- figure out how to not have to punch AppStorage through 3 different places
- add more unit tests
- add UI tests
- support parentheses? where to put buttons?
