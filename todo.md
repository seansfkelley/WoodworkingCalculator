deployment
- icon/splash screen

fractions and division
- consider reformatting input with pretty fractions as-you-type so you can see how it's being parsed
    - I think this requires synchronization points in the grammar to allow parsing things like "1 1/4+"
    - this would definitely have to use the parser and not just a regex; `1/2/3/4` would have to be displayed as (1/2) / 3 / 4 and definitely not (1/2) / (3/4) (which a simple greedy regex would do) 
- pretty fractions: parser has to be able to read them, or keep a non-pretty version of it under the hood
    - probably easiest to support parsing them properly so that copy-paste works
- reconcile / versus ÷: the fractional helpers type / but it would be nice if the ÷ button typed a literal ÷

appearance
- 1 7/16 looks a lot like 17/16 -- more whitespace (two spaces)? dash character?
- consider highlighting whitespace with light grey underscores somehow
- color palette and then test dark mode

calculation features
- support parentheses? where to put buttons?
    - each row is 4 buttons, could use a double-height equals for a third, so what's the fourth?
    - this might introduce too much complexity to the try-catch implementation of isValidPrefix
- support pasting -- should evaluate immediately or just put the stuff in?

best practices
- add UI tests

