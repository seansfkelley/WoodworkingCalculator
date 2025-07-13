appearance
- color palette and then test dark mode
- how does it behave on other device form factors?
- 1 7/16 looks a lot like 17/16 -- more whitespace (two spaces)? dash character?
- consider highlighting whitespace with light grey underscores somehow
- improve visuals of wavy equals, right now it looks kind of like a mistake

calculation features
- what to do about negative values?
- support parentheses? where to put buttons?
- support pasting -- should evaluate immediately or just put the stuff in?

fractions and division
- pretty fractions: parser has to be able to read them, or keep a non-pretty version of it under the hood
    - probably easiest to support parsing them properly so that copy-paste works
- consider reformatting input with pretty fractions as-you-type so you can see how it's being parsed
- reconcile / versus ÷: the fractional helpers type / but it would be nice if the ÷ button typed a literal ÷

best practices
- figure out how to not have to punch AppStorage through 3 different places
- add UI tests
- rethink Input object
    - since `description` can change when `displayInchesOnly` changes, it should be @Published or something similar so that when downstream things render based on it they get the latest (i.e. the input)
    - same as above for precision, so you can change it after you've already calculated a result
        - this means that it should hold the CalculationResult, not the rounded result
