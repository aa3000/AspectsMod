AspectsMod 1.0 
==============

Fix Aspects's issue [#2](https://github.com/steipete/Aspects/issues/2) and [#11](https://github.com/steipete/Aspects/issues/11).

**Those issues caused by __ASPECTS_ARE_BEGIN_CALLED__ doesn't know the real class**. 

**How this mod works**.

Hook the objc_msgSendSuper and relative functions.

Based on [InspectiveC](https://github.com/DavidGoldman/InspectiveC), [itrace by emeau](https://github.com/emeau/itrace), [AspectiveC by saurik](http://svn.saurik.com/repos/menes/trunk/aspectivec/AspectiveC.mm), and [Subjective-C by kennytm](http://networkpx.blogspot.com/2009/09/introducing-subjective-c.html).

Used [fishhook by facebook](https://github.com/facebook/fishhook).

Release Notes
-----------------

Version 1.0.0

- Initial release
