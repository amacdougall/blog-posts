# Anonymous Functions in AS3

In Actionscript, functions are objects which can be stored in variables and
passed as arguments, just like any other value. Since functions are treated just
like any other object&#8212;like "first-class citizens," if you will&#8212;AS3
is said to have "first-class functions." This lets us do stuff that would be
cumbersome in other languages, but it also throws a whole new set of potholes in
our path. This post shows how to use first-class functions for state-based event
handling, user input interpretation, and array filtering, but I'll begin with
something you've seen a million times before: the lowly event listener.

## Anonymous Functions

This syntax appears constantly in Actionscript:

    :::as3
    /* figure 01 */
    function handleChange(event:Event):void {
        doStuff();
    }

    thing.addEventListener(Event.CHANGE, handleChange);

    // which is equivalent to this:
    thing.addEventListener(Event.CHANGE, function(event:Event):void {
        doStuff();
    });

Both syntaxes have the same effect: they create a function and register it to be
executed whenever the `thing` object fires a `CHANGE` event. In the first
example, the function gets a name; in the second, it has no name: it is
"anonymous." Here is an anonymous function:

    :::as3
    /* figure 02 */
    var alpha:Function = function():void {trace("alpha");};
    alpha(); // traces "alpha"
    var beta:Function = alpha;
    beta(); // traces "alpha", since it's the exact same function

The value assigned to `alpha` is a "function literal". Just like a string
literal is converted to a String object at runtime, and a regex literal is
converted to a `RegExp`, a function literal is converted to a `Function`. It's
an instance of the `Function` class. You must understand that the `function`
keyword in AS3 is almost identical to just assigning a anonymous function to a
variable.

    :::as3
    /* figure 03 */
    // has the same effect as the code in figure 02
    function alpha():void {
        trace("alpha")
    }
    alpha();
    var beta:Function = alpha;
    beta();

There are two subtle differences between functions defined using the `function`
keyword and functions which are stored in variables, arrays, or objects. One
concerns the behavior of the `this` keyword, and will be explained later. The
other is that variables defined using `function` are "hoisted" to the top of the
script, and interpreted first, so that they are available to all code in the
same scope. Anonymous functions follow the same rules as any other object: you
have to define them before you can use them.

From this point on, any function which is _not_ defined using the `function`
keyword, whether it is assigned to a variable or not, will be referred to as an
"anonymous function."

## Normal Event Listeners

Armed with this knowledge, you can guess how `EventDispatcher.addEventListener`
works. Given an event type and a function, it adds the function to an array of
functions to be called whenever an event of that type occurs. In fact, here's a
naive implementation:

    :::as3
    /* figure 03 */
    public class EventDispatcher {
        private var listeners:Object = {};

        /**
         * Registers the handler to be executed when an event of the supplied
         * type occurs.
         */
        public function addEventListener(type:String, handler:Function):void {
            listeners[type] ||= [];
            listeners[type].push(handler);
        }
        
        /**
         * Signals that an event of the supplied type has occurred. Calls
         * all handlers, passing each one the event as an argument.
         */
        public function dispatchEvent(event:Event):void {
            for each (var handler:Function in listeners[type]) {
                // though we passed it around as a value, it's still
                // a function... and we can call it as one with "()".
                handler(event);
            }
        }
    }

In the for-each loop, we have a variable named `handler`, which is assigned an
anonymous function as its value. As long as the value of a variable is an
instance of `Function`, we can invoke it with "()", just like any other
function.

This simple example doesn't prevent duplicate handlers, and has no way of
removing handlers, but it's a general outline of what Flash Player is doing
under the hood; and it would be impossible without anonymous functions. 

## State-based Event Listeners

You might already have implemented input states by using switch statements, sort
of like this:

    :::as3
    /* figure 04 */
    private function handleClick(event:MouseEvent):void {
        switch (state) {
            case INPUT:
                // behavior of click event while in input state
                break;
            case LOADING:
                // behavior of click event while in loading state
                break;
            case VIEW:
                // behavior of click event while in view state
                break;
        }
    }

    private function handleClick(event:MouseEvent):void {
        switch (state) {
            case INPUT:
                // behavior of move event while in input state
                break;
            case LOADING:
                // behavior of move event while in loading state
                break;
            case VIEW:
                // behavior of move event while in view state
                break;
        }
    }

But in this approach, you have three possible behaviors defined for each event
handler, resulting in code clutter: if you're only interested in the view state,
you have to skip past the other states to find it. A different approach is to
change your event handlers only once when the state changes; and although you
could define functions with names like `readyStateClickHandler`, it's
more flexible to map event handlers to state constants. Here's an example:

    :::as3
    /* figure 05 */
    public class InputHandler {
        /* state constants */
        public static const INPUT:String = "input";
        public static const LOADING:String = "loading";
        public static const VIEW:String = "view";

        /* stores current value of "this" */
        private var self:InputHandler = this;

        /* input handlers */
        private var handlers:Object = {
            input: {
                click: function(event:MouseEvent):void {
                    // click handler for input state
                },
                move: function(event:MouseEvent):void {
                    // mouse move handler for input state
                }
            },
            loading: {
                click: function(event:MouseEvent):void {
                    // click handler for loading state
                },
                move: function(event:MouseEvent):void {
                    // mouse move handler for loading state
                }
            },
            view: {
                click: function(event:MouseEvent):void {
                    // click handler for view state
                },
                move: function(event:MouseEvent):void {
                    // mouse move handler for view state
                }
            }
        };

        private var _state:String = "input";

        public function get state():String {return _state;}
        public function set state(value:String):void {
            if (_state != value) {
                // replace click handler
                removeEventListener(MouseEvent.CLICK, handlers[state].click);
                addEventListener(MouseEvent.CLICK, handlers[value].click);
                _state = value;
            }
        }
    }

In this system, we can define all our event handlers in the handlers object,
grouped by state; it's easier to work on the behavior for one state at a time.
Of course, for even more modularity, we could implement the classic [State
pattern](http://en.wikipedia.org/wiki/State_pattern).

## Anonymous functions and `this`

You probably noticed a quirk: the `self` variable defined right before the input
handlers. This is a workaround for one of the pitfalls of anonymous functions:
functions which are _not_ created with the `function` keyword do not have a
single permanent `this` value. Instead, `this` is always equal to the context in
which the function is called. An example:

    :::as3
    /* figure 06 */
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

    /* At this point, bar.sayName is the exact same Function object as
     * foo.sayName! But if we call it on each object in turn...
     */
    foo.sayName(); // traces "foo"
    bar.sayName(); // traces "bar"

Sometimes this is exactly the behavior you want! You might want to give an
object new methods, and give those methods the ability to access their new
"host" object&#8212;sort of like defining a class at runtime. In the example
above, when we assign `foo`'s `sayName` function to `bar`, `sayName` behaves as
if it had been defined in the `Bar` class all along.

But sometimes that behavior gets in your way. In fact, Adobe's documentation
says not to use anonymous functions as event listeners at all&#8212;but that's a
sad, dry, timid way to live. We can squeeze a lot of extra power out of
anonymous functions as long as we know three things. First, the value of `this`
can change; second, we can store the _current_ value of `this` and use it later.
Within all those event handlers, just use `self` where you would normally use
`this`. I'll explain the underlying theory in the next post.

The third thing? Who says you need to use `this` in event handlers in the first
place? Just refer to instance variables as you normally would, and everything
will work just fine.

## User input interpretation

Anonymous functions also come in handy when responding to user input. Imagine a
multiplayer game with a chat window. In addition to chatting with other players,
the user can type simple commands beginning with "/", as in IRC. We want to
provide abbreviations for advanced users, and allow permutations such as
variable arguments. Here's an easy way to do it with regular expressions and
anonymous functions:

    :::as3
    /* figure 07 */
    public class Interpreter {
        private var commands:Array = [
                // e.g. "/h", "/help"
            {   pattern: /^\/h(elp)?$/,
                command: function(input:String):void {
                    // display help text
                }
            },
                // e.g. "/w alan Hey, what's up?"
            {   pattern: /^\/w(hisper)? (\w+) (.+)$/,
                command: function(input:String):void {
                    // find the target user
                    // send a whisper to the target user
                }
            }
        ];

        public function interpret(input:String):void {
            for each (var mapping:Object in commands) {
                if (input.match(mapping.pattern)) {
                    mapping.handler(input);
                    return;
                }
            }
            // if no pattern matched, display an error message
        }
    }

This system makes it easy to define new input/handler pairs, and since the
handlers are defined right after the patterns that invoke them, the code is
simple to understand.

## Array filtering

AS3 provides built-in methods for array transformation using first-class
functions: `filter` and `map`. Here's the usage of
`filter`:

    :::as3
    /* figure 08 */
    /** Filter function: returns true if n is a positive integer. */
    // AS3 requires filter functions to have all three arguments
    function isNaturalNumber(n:Number, i:int, a:Array):Boolean {
        return n >= 1 && n % 1 == 0;
    }

    var list:Array = [-2, -1, 0, 1, 2.5, 3];
    var naturalNumbers:Array = list.filter(isNaturalNumber);
    // naturalNumbers is now [1, 3]

`Array.filter` takes one argument: a function. It applies that function to each
element of the array in turn. If the function returns false, that element is not
included in the result. `Array.filter` requires the filter function to have
three arguments, but if we want the flexibility of anonymous functions, this
gets cumbersome:

    :::as3
    /* figure 09 */
    var naturalNumbers:Array = list.filter(
        function(n:Number, i:int, a:Array):Boolean {
            return n >= 1 && n % 1 == 0;
        });

[underscore.as](http://www.github.com/amacdougall/underscore.as) accepts
functions as simple as `function(e:*):Boolean`. The underlying
concept, however, is identical.

This approach becomes more powerful when we start to pre-define filter functions
and call them on demand. For instance, imagine a product list with filter
buttons:

    :::as3
    /* figure 10 */
    public class ProductList extends Sprite {
        private var products:Array;

        // filter buttons
        public var justAddedButton:SimpleButton;
        public var freeShippingButton:SimpleButton;
        public var closeoutButton:SimpleButton;

        public function ProductList() {
            products = loadProductsFromDatabase();
            linkFilter(justAddedButton, justAdded);
            linkFilter(freeShippingButton, freeShipping);
            linkFilter(closeoutButton, closeout);
        }

        /** Display the supplied product list on screen. */
        public function display(productList:Array):void {
            // draw only these products to the screen
        }

        /** Convenience method for hooking up filters to buttons. */
        private function linkFilter(button:SimpleButton, filter:Function):void {
            button.addEventListener(MouseEvent.CLICK,
                function(event:MouseEvent):void {
                    display(products.filter(filter));
                });
        }

        /** Allows only Products whose justAdded property is true. */
        private function justAdded(p:Product, i:int, a:Array):Boolean {
            return p.justAdded;
        }

        /** Allows only Products whose freeShipping property is true. */
        private function freeShipping(p:Product, i:int, a:Array):Boolean {
            return p.freeShipping;
        }

        /** Allows only Products whose closeout property is true. */
        private function closeout(p:Product, i:int, a:Array):Boolean {
            return p.closeout;
        }
    }

In this case, although we're passing the filter functions around as values, the
functions themselves _were_ declared with the `function` keyword. This doesn't
mean we can't treat them as variables! It just means that for those functions,
the value of `this` is fixed for all time, and those functions are available
even before code execution reaches that point in the file.

## Functions with superpowers

In the next post, we'll discuss closures&#8212;anonymous functions which contain
extra data. You've already seen a simple closure when we used the `self`
variable to get a durable reference to `this`. But closures can do far more than
that; in fact, with closures, it is possible to create a sort of mini-language
within Actionscript 3, replacing loops and branches with terse, targeted
commands, or even changing the behavior of existing functions. This is common in
languages like Lisp or Ruby, where this type of programming is called a
Domain-Specific Language, or DSL. The popular Javascript library jQuery can be
considered a comprehensive DSL for front-end programming; aspects of Rails can
be considered a DSL for web programming (and much more). We can tap into similar
power in Actionscript 3 if we choose.
