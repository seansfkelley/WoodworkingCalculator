appearance
- 1 7/16 looks a lot like 17/16 -- more whitespace (two spaces)? dash character?
- consider highlighting whitespace with light grey underscores somehow
- improve visuals of wavy equals, right now it looks kind of like a mistake
- color palette and then test dark mode
- how does it behave on other device form factors?

calculation features
- support negative values?
    - seems like a might-as-well only in that it might be more surprising than helpful if it's absent
- support parentheses? where to put buttons?
    - could put them on the bottom row with a +/- (assuming negative values are supported), but would probably need a fourth button
- support pasting -- should evaluate immediately or just put the stuff in?

fractions and division
- pretty fractions: parser has to be able to read them, or keep a non-pretty version of it under the hood
    - probably easiest to support parsing them properly so that copy-paste works
- consider reformatting input with pretty fractions as-you-type so you can see how it's being parsed
- reconcile / versus ÷: the fractional helpers type / but it would be nice if the ÷ button typed a literal ÷

best practices
- add UI tests
