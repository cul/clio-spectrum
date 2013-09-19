
The voyager_api project has a number of unit tests verifying
the return of correct messages for a variety of holdings statuses.

The specs in this directory of the clio_spectrum project are based
on the voyager_api tests, by verifying that front-end queries
for given bibs pass-thru appropriate messages all the way to
the web front-end of the app.

The specs here are only a very partial coverage of the voyager_api tests.
Most of the voyager_api tests use mock records.  Specs here are only
written when there is a real Voyager record to test against.

Specs here and are updated manually, and will not necessarily be in 
sync with voyager_api.

ALL tests herein are fragile - they may break if the item cataloging
or holdings status are modified.

