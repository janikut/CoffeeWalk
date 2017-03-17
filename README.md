# CoffeeWalk
App for finding coffee within walking distance. Consumes Foursquare's explore API.

The venues are displayed as pins on a map, with the name and address of each venue appearing in a callout on tap. The venues come from the "Recommended" section of Foursquare's explore API call.

Supported systems:
- iPhone devices running iOS 10.2
- all tests have been done on the simulator only

Next steps:
- allow more granular selection of walking time, perhaps through a scrubber
- implement custom callouts for pins that would contain more detail, including website
- localize strings: it's good practice to localize strings, even if currently the app only supports one language
- implement Unit Tests
