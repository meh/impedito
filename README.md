impedito - the better MPD client
================================
This MPD client tries to merge the nice interface of [moc](http://moc.daper.net/) with
the configurability of [cmus](http://cmus.sourceforge.net/) and add a nice scripting layer
on top of it all.

*moc* is a very nice player, the interface is very straightforward and nice looking, although
it lacks decent key configurability and the implementation behind isn't the best possible.

*cmus* on the other hand has a very nice set of features, it's very configurable and can do
a lot of stuff that *moc* can't do, but its usability is quite poor compared to *moc*.

None of the two support a way to add extensions in the UI (for example a lyrics panel) so what
I try to achieve is the best backend in the usage of *MPD* and the best extensibility by using
Ruby.
