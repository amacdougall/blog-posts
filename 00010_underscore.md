# An Introduction to underscore.as

[underscore.as](http://www.github.com/amacdougall/underscore.as) is an
Actionscript 3.0 port of Jeremy Ashkenas's excellent
[underscore.js](http://documentcloud.github.com/underscore/) library. Like its
Javascript original, underscore.as provides a quick syntax for functional
programming concepts. Unlike the original, underscore.as is not idiomatic: it
doesn't look like the kind of Actionscript you probably write every day. You
may have to adjust your programming style to take full advantage of it. I hope
this quick introduction will explain why you should bother.

## Actionscript 3.0 is Java

If you're old, wrinkled, and toothless&#8212;about 35 in programmer
years&#8212;you remember the Flash 5 and Actionscript 1.0 versions of
Actionscript. They were the first ones to work like Javascript, and despite
their many flaws, they had some useful ideas at their core: prototype-based
inheritance, mixins, anonymous functions, dynamic classes. Presented with
these new features, programmers immediately used them for evil. Not only was
code scattered wildly among dozens of timeline frames and stage instances, but
properties were added to objects willy-nilly without rhyme, reason, or
documentation. Broken function scope and an undocumented event system made
anonymous functions difficult to use as event handlers. Even the base API
presented an inconsistent mishmash of interfaces.

Beginning with Actionscript 2.0, the language designers began painting over
the language with an explicit class system, static type annotations, even
interfaces. Programmers could now write Actionscript as if it were Java, and
they did; but old-timers were still free to assign function objects to
`MovieClip.onRelease` to their heart's content. But with Actionscript 3.0,
everything changed: old-timers cried bloody murder as static types, object
orientation, and addEventListener carried the day.

Polyglot programmers will immediately notice that most Actionscript 3.0 code
today looks a great deal like Java. This is not accidental. Actionscript 3.0 was
developed hand in hand with Flex in an attempt to woo [enterprise
developers](http://www.thedailywtf.com), with considerable success. "Enterprise
Flex" is definitely a thing now. But in the process, quick and easy Flash
development has gotten bogged down in boilerplate; and at the same time, things
that should have gotten easier with each language version have stayed pretty
much the same.

## Actionscript 3.0 is Javascript

But Adobe added one more feature with AS3: closures. I'll explain these
mysterious beasts in detail in a later post, but for now it's enough to say
that a closure is a special type of function which contains extra information,
beyond the arguments it is given. A closure can do things a normal function
cannot. With the addition of closures, Actionscript 3.0 gained most of the
flexibility and power of Javascript&#8212;and if you don't believe that
Javascript has flexibility and power, look at what libraries like jQuery are
doing under the hood. With a little help from static initializers, language
hackery, and the ":\*" type annotation, we can achieve in AS3 almost anything
we can achieve in Javascript.

Through judicious use of closures, it is possible to create simple constructs
of great power, escaping the verbose Java-like syntax of AS3; or, if you
prefer, building upon the spartan simplicity of core Javascript. Here are a
few examples of idiomatic AS3 code which can be simplified by use of
underscore.as.

## Modifying Collections

For all the examples below, assume the following list.

    :::as3
    /* figure 01 */
    var list:Array = [
        {name: "Alice", age: 35},
        {name: "Bob", age: 24},
        {name: "Carol", age: 31}
    ];

A common array filtering task: get only the array elements matching certain
criteria. Normally, this requires a loop and an results array, but with
underscore.as, the select() function prepares the results list on the fly. Using
the syntax `_(list).select(f)`, it returns a list of elements for which the
function `f` returned true.

    :::as3
    /* figure 02 */
    // idiomatic AS3
    var result:Array = [];
    for each (var person:Object in list) {
        if (person.age > 30) {
            result.push(person);
        }
    }

    // underscore.as
    var result:Array = _(list).select(function(person:Object):Boolean {
        return person.age > 30;
    });

Another common task: get a particular property of each element. Again,
underscore.as takes care of the plumbing.

    :::as3
    /* figure 03 */
    // idiomatic AS3
    var result:Array = [];
    for each (var person:Object in list) {
        result.push(person.name);
    }

    // underscore.as
    var result:Array = _(list).pluck("name");

It also makes it easy to get the results of a function for each element...

    :::as3
    /* figure 04 */
    // idiomatic AS3
    var result:Array = [];
    for each (var person:Object in list) {
        result.push(buildIcon(person));
    }

    // underscore.as
    var result:Array = _(list).map(buildIcon);

...or to just _do_ something to each element:

    :::as3
    /* figure 05 */
    // idiomatic AS3
    for each (var person:Object in list) {
        trace(person.name + ": " + person.age);
    }

    // underscore.as
    _(list).each(function(person:*):void {
        trace(person.name + ": " + person.age);
    }

Okay, maybe that last one wasn't so impressive... but what if we want to combine
these operations? Let's filter the elements on a criterion, then build an icon
for each one, setting each icon to 50% alpha.

    :::as3
    /* figure 06 */
    // idiomatic AS3
    var result:Array = [];
    for each (var person:Object in list) {
        if (person.age > 30) {
            var icon:Sprite = buildIcon(person);
            icon.alpha = 0.5;
            result.push(icon);
        }
    }

    // underscore.as
    var result:Array = _(list).chain().select(function(person:Object):Boolean {
        return person.age > 30;
    }).map(buildIcon).map(function(icon:Sprite):Sprite {
        icon.alpha = 0.5;
    }).value();

You may be thinking, at this point, that these two examples are about the same
length, and the first is more readable, because it looks more like normal AS3
code. You would be right. But let's revisit that example, assuming the
existence of these two functions:

    :::as3
    /* figure 07 */
    // function generators
    function greaterThan(threshold:int):Function {
        return function(age:int):Boolean {
            return age > threshold;
        };
    }

    function setAlphaTo(value:Number):Function {
        return function(target:Sprite):Sprite {
            target.alpha = value;
            return target;
        };
    }

These are functions which create special-purpose functions, functions that
come equipped with information they need to do their work. This process is
called "partial application," and it's one major use of the power of closures.
I'll explain what it means soon. For now, just look at this:

    :::as3
    /* figure 08 */
    // underscore.as
    var result:Array = _(list).chain()
        .select(greaterThan(30))
        .map(buildIcon)
        .map(setAlphaTo(0.5))
        .value();

Suddenly the code looks less like AS3 and more like a special language designed
to do exactly what you wanted. That's the power of functional programming.

## Modifying Functions

underscore.as also makes it easy to modify functions themselves, and this is
where it really makes hard things easy. For instance, executing a function
after a delay:

    :::as3
    /* figure 09 */
    // idiomatic AS3
    var timer:Timer = new Timer(1000, 1);
    timer.addEventListener(TimerEvent.TIMER_COMPLETE,
        function(event:Event):void {
            doStuff();
        });
    timer.start();

    // underscore.as
    _(doStuff).delay(1000);

When handling user input, sometimes you want to execute an event handler only
after a stream of input events has ceased. Responding to typed input by querying
a database, perhaps, or handling a scrollbar drag by loading more content. This
concept goes back to the earliest days of electrical engineering, where a lever
might literally bounce when flipped, causing a false double signal; thus,
ignoring extra inputs is called "debouncing." In traditional AS3, it's fairly
verbose, but underscore.as handles it in a single call:

    :::as3
    /* figure 10 */
    // relatively idiomatic AS3
    var scrollDelayTimer:Timer = new Timer(250, 1);
    scrollDelayTimer.addEventListener(TimerEvent.TIMER_COMPLETE,
        function(event:Event):void {
            update();
        });

    function handleScroll(event:Event):void {
        if (scrollDelayTimer.isRunning) {
            scrollDelayTimer.reset();
        }
        scrollDelayTimer.start();
    };

    scrollBar.addEventListener(Event.CHANGE, handleScroll);


    // underscore.as
    function handleScroll(event:Event):void {
        update();
    }

    scrollBar.addEventListener(Event.CHANGE, _(handleScroll).debounce(250));

You could do the idiomatic version in fewer lines... by making it less
idiomatic. The more you add closures and anonymous functions, the closer you
get to how underscore.as is implemented under the hood in the first place.

One last example: built-in result caching. If we have a function which takes
time to get a result, but it always gets the same result for the same input
value, it is wise to cache each result so we can get it instantly on subsequent
calls.

    :::as3
    /* figure 11 */
    // idiomatic AS3
    // original...
    function verySlowLookup(id:String):ComplexObject {
        return getFromLegacyDatabase(id);
    }

    // and with caching:
    var lookupResults:Dictionary = new Dictionary();

    function verySlowLookup(id:String):ComplexObject {
        return lookupResults[id] || getFromLegacyDatabase(id);
    }

    // underscore.as
    var verySlowLookup:Function = _(getFromLegacyDatabase).memoize();

Ready to start playing with it yourself? [Grab it from
github](http://github.com/amacdougall/underscore.as), and read the inline
documentation in com.alanmacdougall.underscore.\_ for instructions; the
[documentation for underscore.js](http://documentcloud.github.com/underscore/)
will help too.

Interested, but want to know more? Stay tuned: in coming posts, I'll explain
anonymous functions, closures, and how they apply to both standard AS3 and
underscore.as.
