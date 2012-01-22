# Understanding Closures and Context

In [Anonymous Functions in AS3](http://www.alanmacdougall.com/blog/post/3/), we
looked at how anonymous functions can simplify code structure, but we skirted
around their most powerful capability. An anonymous function can hold additional
data, beyond what it gets from its arguments, and it can use that data in its
work.

By holding extra data, an anonymous function can be custom-designed, on the fly,
to perform a specific duty; it can apply special logic it normally couldn't have
access to; it can access application state; it can even "transform" other
functions, changing their behavior, without needing access to their internals,
through a sneaky substitution known as "wrapping"; but before we can put
closures to work, we need to understand what makes them tick.

## Portable Scope

Let's start with a normal, everyday function, defined in a class.

    :::as3
    /* figure 01 */
    public class Student {
        public var name:String;
        public var grade:String;
        public var tests:Array;

        public function toString():String {
            return name + ", grade " + grade;
        }

        public function averageScore():Number {
            var connection:Connection = Database.getConnection();

            // in real life, we'd do this all in SQL, of course
            function retrieveGrade(test:Test):Number {
                return connection.getGrade(test);
            }

            var total:Number = 0;

            for each (var test:Test in tests) {
                total += retrieveGrade(test);
            }

            return total / tests.length;
        }
    }

It should not be surprising that `toString` has access to the `name` and `grade`
variables, because those variables are defined in the same _scope_ as the
`toString` function. And in `averageScore`, it should not be surprising that
`retrieveGrade` has access to `connection`, because that variable is defined in
the same scope as `retrieveGrade`. But how about this?

    :::as3
    /* figure 02 */
    function nameGenerator():Function {
        var names:Array = ["Squirtle", "Bulbasaur", "Charmander", "Pikachu"];

        var next:Function = function():String {
            var result:String = names.shift();
            names.push(result);
            return result;
        };

        return next;
    }

    var nextName:Function = nameGenerator();
    trace(nextName()); // Squirtle
    trace(nextName()); // Bulbasaur

In `nameGenerator`, the `names` array is defined; then the `next` function is
defined; then the `next` function is returned... and then the `names` array
_goes out of scope_. As far as outside code is concerned, everything that
happens within `nameGenerator` happens in a sealed environment. Variables
defined there cannot spill out of it. And this is true: but a function defined
within a function _takes that scope with it_. When the `next` function is
created, it gains access to the variables which were visible at that moment...
and keeps that access as long as it exists.

## A Little Context

Imagine a very simple class definition:

    :::as3
    /* figure 03 */
    public class Driver {
        public var id:String;
        public var license:DriversLicense;

        public function canLegallyDrive():Boolean {
            return license.valid;
        }
    }

    var driver:Driver = Database.getRandomDriver();
    trace("License number " + driver.license.id);
    trace("Can drive? " + driver.canLegallyDrive());

Outside the class definition, we need to specify `driver.license`, but within
the class definition, we can refer to the `license` variable directly. That's
because `license` is part of the _context_ in which `canLegallyDrive` executes:
that is, `license` is a property of `this`. Every single line of code which
executes in AS3 has a `this` value, even if it is never directly referenced.
Every identifier&#8212;every function name, every variable name&#8212;is a
property of `this`. As I discussed in the [last
post](http://www.alanmacdougall.com/blog/post/3/), the value of `this` will
change if the function is executed in a different scope... unless the function
is a closure. Closures take their context&#8212;their `this` value&#8212;with
them. A closure can have access to as many variables as the application
requires, and good taste permits.

Closures are wonderfully abusable. Just wait.

## Common Closure Pitfalls

When working with many UI objects at once, everyone makes this error at least once.

    :::as3
    /* figure 04 */
    var paintings:Array = Database.getGalleryData().paintings;

    for each (var painting:Painting in paintings) {
        // PaintingButton constructor draws all UI graphics
        var paintingButton:Button = new PaintingButton(painting);
        paintingButton.addEventListener(MouseEvent.CLICK,
            function(event:Event):void {
                showPainting(paintingButton.painting);
            });
    }

Looks straightforward, right? But when you run it, you'll find that it always
acts as though you clicked on the last button in the list. This code creates a
separate handler function for each button, but each function is created in the
same scope; it has the same context; its `this` value is the same; and so each
function has a reference to the same `paintingButton` variable. A _reference_ to
the variable, not a copy of its value. As the loop continues, the value of
`paintingButton` changes; and whenever any of the handler functions are called,
they access the _current_ value of `paintingButton`.

There are two ways to handle this situation. If you want to use anonymous
functions, you will need to create an intermediate variable for each one, like
this:

    :::as3
    /* figure 05 */
    for each (var painting:Painting in paintings) {
        var paintingButton:Button = new PaintingButton(painting);
        paintingButton.addEventListener(MouseEvent.CLICK,
            (function(paintingButton:PaintingButton):Function {
                return function(event:Event):void {
                    showPainting(paintingButton.painting);
                }
            )(paintingButton));

If this looks crazy to you, you're not alone. I would not put this in production
code, just because it's a really odd construction. But understanding it is
crucial to understanding closures. Let's break it down a step at a time:

    :::as3
    /* figure 06 */
    function createHandler(paintingButton:PaintingButton):Function {
        var handler:Function = function(event:Event):void {
            showPainting(paintingButton.painting);
        };
        return handler;
    }

This is a function which takes a `PaintingButton` argument, and returns an
anonymous function which holds a reference to the argument variable. Here's the
critical part: when we call `createHandler(monaLisaButton)`&#8212;that is, we
call `createHandler` with a specific `PaintingButton`&#8212;the argument is
assigned to the argument variable `paintingButton` for as long as
`createHandler` continues to execute. That argument variable is not the same
variable as `monaLisaButton`. When the inner function, `handler`, is created, it
holds a reference to `paintingButton`, whose value has been set to the argument.
It keeps that reference... even though `createHandler` completes and the
argument variable otherwise goes out of scope. Since each invocation of
`createHandler` creates a new short-lived argument variable, each function
returned from `createHandler` has a different context&#8212;a different
`this`&#8212;and thus a different `paintingButton` variable which can hold a
different value.

Armed with that knowledge, this code should make a little more sense:

    :::as3
    /* figure 07 */
    var monaLisaButton:PaintingButton = new PaintingButton(monaLisa);

    var handler:Function = (function(paintingButton:PaintingButton):Function {
        return function(event:Event):void {
            showPainting(paintingButton.painting);
        };
    })(monaLisaButton);

    monaLisaButton.addEventListener(MouseEvent.CLICK, handler);

The value of `handler` is derived by declaring a function literal and
immediately executing it. We don't store the function; we just invoke it
instantly, by tacking `(monaLisaButton)` on right after the function literal.
The parentheses around the function literal are not necessary; they're just a
reminder to consider the function literal as an expression to be evaluated.
These two constructions are equivalent:

    :::as3
    /* figure 08 */
    var one:int = function():int {return 1;}(); // execute immediately
    var two:int = (function():int {return 2;})(); // a bit clearer?

You should be able to understand exactly why figure 05 works now, but in
practice, it's a clear-cut case of "closure abuse". Here's a better approach:

    :::as3
    /* figure 09 */
    for each (var painting:Painting in paintings) {
        var paintingButton:Button = new PaintingButton(painting);
        paintingButton.addEventListener(MouseEvent.CLICK,
            function(event:Event):void {
                showPainting(PaintingButton(event.currentTarget).painting);
            });
    }

Much more pragmatic, much easier to think about. Like any programming tool,
closures should only be used where the benefits are worth the extra effort.

## Function Binding

As discussed in the [previous post](http://www.alanmacdougall.com/blog/post/3/),
anonymous functions normally execute in the context in which they are called,
not the context in which they are defined. True enough&#8212;unless you "bind"
the functions. Here's the original example:

    :::as3
    /* figure 10 */
    public class Foo {
        public var name:String = "Foo";
        public var sayName:Function = function():void {
            trace(this.name);
        }
    }

    public class Bar {
        public var name:String = "Bar";
        public var sayName:Function = null;
    }

    var foo:Foo = new Foo();
    var bar:Bar = new Bar();
    bar.sayName = foo.sayName;
    foo.sayName(); // traces "Foo"
    bar.sayName(); // traces "Bar"

And here's one in which the `sayName` function is bound to the instance of
`Foo`:

    :::as3
    public class Foo {
        public var name:String = "Foo";
        public var sayName:Function = bind(function():void {
            trace(this.name);
        });

        private function bind(f:Function):Function {
            var self:Foo = this;
            return function(...args):* {
                return f.apply(self, args);
            };
        }
    }

    public class Bar {
        public var name:String = "Bar";
        public var sayName:Function = null;
    }

    var foo:Foo = new Foo();
    var bar:Bar = new Bar();
    bar.sayName = foo.sayName;
    foo.sayName(); // traces "Foo"
    bar.sayName(); // also traces "Foo"

Every function is an instance of `Function`; and `Function` has two methods,
`call` and `apply`. They're both similar in that they let the user specify the
value of `this` for a specific invocation of the function. `Foo.bind` returns a
function&#8212;a closure&#8212;which _always_ calls the supplied method with the
value of `this` at the time `bind` was executed. By making `this` immutable, it
makes it safe to pass the function around without changing its behavior.

This is exactly what the `function` keyword does, quietly and modestly, whenever
you compile a SWF. To get the same behavior much more easily, simply do this:

    :::as3
    /* figure 12 */
    public class Foo {
        public var name:String = "Foo";
        public function sayName():String {
            trace(this.name);
        }
    }

Honestly, function binding _per se_ won't come up very much in AS3. Most
functions are defined within classes, or can take advantage of normal scope
rules and the closure mechanism to maintain access to the variables they need.
But the core idea of a function which _transforms_ other functions will come up
time and again, not only in AS3 but in Javascript, Ruby, Python, and other
languages.

## The Potential of Closures

In the next post, we'll put closures to work, from simple list manipulation to
rewriting application behavior on the fly; and with any luck, you will begin to
see just what potential lies buried within these concepts.
