# Function Transformation

<style>
    @import url('/static/blog/00050_wrapping/examples.css');
</style>

Modern Javascript is firmly on the side of magic. Why write a hundred-line set
of meticulous loops when you can write a ten-line filter chain? Why invoke a
factory object dozens of times when you can write a map function? And if you
want your application's behavior to change from moment to moment, why use
explicit states, or a Strategy pattern, or reference a global flag, when you can
just swap out the functions themselves?

And why swap functions yourself? Let the functions do that for you. Wind them
up. Let them run.

(From here on, I'll be using Javascript instead of Actionscript in my examples,
but the concepts are 100% identical. If you use
[underscore.as](http://www.github.com/amacdougall/underscore.as/), you can use
the same core code in Actionscript 3. [jQuery](http://jquery.com) needs no
introduction.)

## Laborious Authentication

You've seen code like this a million times -- and in my opinion, that's 999,999
times too many.

HTML:

    :::html
    <div class="blogExample" id="example_01">
        <h1>Imaginary Blog Post</h1>
        <p>Here is the content of the blog post.</p>
        <h1 class="addComment"><a href="#">Add Comment</a></h1>
        <div class="commentForm hidden">
            <p>(Normal comment submission form.)</p>
        </div>
        <div class="loginForm hidden">
            <p>(Login form: username, password.)</p>
            <p><button>Submit</button></p>
        </div>
    </div> 

Javascript:

    :::js
    // wrapped in an instantly-executing function to avoid variable spillover
    (function() {
        $(document).ready(function() {
            var authenticated = false;

            var $content = $("#example_01");
            var $commentForm = $content.find("div.commentForm");
            var $loginForm = $content.find("div.loginForm");

            function addComment() {
                if (authenticated) {
                    $commentForm.show();
                    $loginForm.hide();
                } else {
                    $loginForm.show();
                }
            }

            $content.find("h1.addComment a").click(function (event) {
                event.preventDefault();
                addComment();
            });

            $loginForm.find("button").click(function(event) {
                event.preventDefault();
                $(this).parent().html("logging in...");
                // adding a delay to simulate a success callback
                var successHandler = function() {
                    authenticated = true;
                    addComment();
                };

                _(successHandler).delay(1000);
            });
        });
    })();

You can load the live example inline below.

<div id="example_01" class="blogExample"><a href="/static/blog/00050_wrapping/example_01.html">Example 01 (click to load)</a></div>

This code is pretty straightforward. First we locate DOM elements using jQuery,
using the leading `$` to indicate that they should only hold jQuery-wrapped
elements. Hungarian notation? Guilty, but at least it's [the good
kind](http://www.joelonsoftware.com/articles/Wrong.html). Our DOM objects
located, we define `addComment` to show the comment form if possible, and the
login form if necessary; and finally, we arrange for the login form to call
`addComment` again on a successful login.

If you have only one action on your site which requires a login, this kind of
structure is perfectly reasonable. Once you have two, however, you find yourself
copying your login form everywhere, and giving it a different success handler
each time, so it can resume a different user action. You can generate the login
form by cloning a hidden DOM element, but a more insidious problem remains: your
`addComment` function has to understand the _concept_ of authentication. Any
other function that requires authentication _also_ has to understand the
concept. You will be writing `if (authenticated)` until the day you die or your
app becomes obsolete&#8212;whichever comes first.

(Remember, it's bad when people never use your app. It's terrible when they never
stop. Written any good IE6 workarounds lately?)

## Sorcerous Authentication

How do we take authentication out of our functions and put it all in one place?
Short answer: _sorcery_. If you've been paying attention to my constant campaign
for passing functions as values, you might immediately think of something like
this:

    :::js
    function addComment() {
        if (authenticated) {
            // show comment form
        } else {
            authenticate(addComment);
        }
    }

    // And then somewhere else...
    /** Execute the supplied callback after user is authenticated. */
    function authenticate(callback) {
        if (authenticated) {
            callback();
        } else {
            loginForm.show();
            loginForm.bind("success", callback);
        }
    }

And this is definitely much closer to something I'd want to use. All our login
handling code moves to a separate function, `authenticate`, which is not
connected to commenting at all. `authenticate` can do its work and then execute
the callback to resume the workflow. But your `addComment` function still
includes the knowledge that the user must be authenticated. Imagine that in some
contexts, you allow anonymous comments, but in others, you don't: now you have
to write two functions (bad), or include logic in the function to decide whether
a login is required (far worse).

Instead, let's put the authentication requirement where it's most relevant: in
the code which defines the behavior of the page itself. `addComment` can remain
pleasantly generic, while this specific button prompts anonymous users for their
credentials.

    :::js
    (function() {
        $(document).ready(function() {
            var authenticated = false;

            var $content = $("#example_02");
            var $commentForm = $content.find("div.commentForm");
            var $loginForm = $content.find("div.loginForm");

            function addComment() {
                $commentForm.show();
            }

            function requireLogin(callback) {
                return function(event) {
                    event.preventDefault();
                    if (authenticated) {
                        callback();
                    } else {
                        // on login success, execute and remove callback
                        $loginForm.one("success", function() {
                            $loginForm.hide();
                            callback();
                        });
                        $loginForm.show();
                    }
                }
            }

            // set up $loginForm events
            $loginForm.find("a").click(function(event) {
                event.preventDefault();

                // simulate successful login after talking to server
                $(this).parent().html("logging in");
                _(function() {
                    authenticated = true;
                    $loginForm.trigger("success");
                }).delay(1000);
            });

            $content.find("h1.addComment a").click(requireLogin(addComment));
        });
    })();

You can load the live example inline below.

<div id="example_02" class="blogExample"><a href="/static/blog/00050_wrapping/example_02.html">Example 02 (click to load)</a></div>

The magical line here is `foo.click(requireLogin(addComment));`. `requireLogin`
creates a function which displays the login form if necessary, and handles its
`success` event by executing `addComment`. If no login is necessary, the
function returned from `requireLogin` calls `addComment` immediately. In other
words, the anonymous function which handles the login is _wrapped around_ the
function which handles comments; so this type of function is called a "wrapper."
You could also say that the login functionality is a "decoration" which can be
applied to any function; so a function like `requireLogin` is called a
"[decorator](http://en.wikipedia.org/wiki/Decorator_pattern)."

In a more general sense, `addComment` goes in, and what comes back is something
that can be used exactly the same way... but which has extra powers.
`requireLogin` is the gamma-ray chamber. `addComment` is Bruce Banner. We just
took a function and _changed it_, while still using it in the same code. If you
know object-oriented programming, the concept [may sound
familiar](http://en.wikipedia.org/wiki/Polymorphism_(computer_science)).
Polymorphism: it's not just for subclasses anymore!

## Tinker Toys

That example showed how to prevent the default functionality until a condition
is met, but we can also use decorators to augment a method&#8212;to make it do
more than it did before. Our weapon is `_.compose`, an underscore.js method
which transforms a list of functions into a single one which combines all the
functions into a single pipeline.

For a simple example of composition:

    :::js
    function foo(message) {
        return "foo" + (message || "");
    }

    function bar(message) {
        return "bar" + (message || "");
    }
    
    function baz(message) {
        return "baz" + (message || "");
    }

    var composed = _.compose(foo, bar, baz);
    composed(); // returns "foobarbaz"

In this example, `composed` is a function which runs `baz`, then `bar`, then
`foo`, passing the output of each function as input to the next. The output of
`baz` is "baz"; `bar` places "bar" in front of it to make "barbaz"; and so on.
`(message || "")` returns the empty string if `message` is null or false. We're
accustomed to reading from left to right, so this may feel strange, but once
you're accustomed to it, `_.compose` is a powerful tool. Here's a more practical
example: the "insert" and "delete" buttons add blocks of random text, while
"bold" and "italic" act as modifiers. Try this live example first; the code
follows.

<div id="example_03" class="blogExample"><a href="/static/blog/00050_wrapping/example_03.html">Example 03 (click to load)</a></div>

HTML:

    :::html
    <div class="controls">
        <div class="controlBlock">
            <button class="insert">Insert</button>
            <button class="delete">Delete</button>
        </div>
        <div class="controlBlock">
            <button decorator="makeBold">Bold</button>
            <button decorator="makeItalic">Italic</button>
        </div>
    </div>
    <p>Click <i>insert</i> and <i>delete</i> to add and remove elements.</p>
    <div class="itemList"></div>

And the much more interesting Javascript:

    :::js
    (function() {
        $(document).ready(function() {
            // find and jQuerify all needed DOM elements
            var $content = $("#example_03");
            var $itemList = $content.find("div.itemList");
            var $insertButton = $content.find("div.controls button.insert");
            var $deleteButton = $content.find("div.controls button.delete");

            var dummyText = [
                "Ant",
                "Bumblebee",
                "Butterfly",
                "Cricket",
                "Dragonfly",
                "Grasshopper",
                "Ladybug"
            ];

            /** The function to be used to add example elements. */
            var buildElement = buildRandomText;
            /** Decorator functions used to add styles. */
            var currentDecorators = [];

            function buildRandomText() {
                var randomText = dummyText[Math.floor(dummyText.length * Math.random())];
                return $("<p>" + randomText + "</p>");
            }

            var decorators = {
                makeItalic: function($element) {
                    return $element.addClass("italic");
                },

                makeBold: function($element) {
                    return $element.addClass("bold");
                }
            };

            $insertButton.click(function(event) {
                $itemList.append(buildElement());
            });

            $deleteButton.click(function(event) {
                $itemList.children().last().remove();
            });

            $content.find("button[decorator]").click(function() {
                $(this).toggleClass("selected");
                toggleDecorator(decorators[$(this).attr("decorator")]);
            });

            /**
             * Toggles presence of the supplied function in the decorators array, then
             * regenerates the buildElement function.
             */
            function toggleDecorator(f) {
                currentDecorators = _(currentDecorators).include(f) ?
                    _(currentDecorators).without(f) :
                    currentDecorators.concat(f);

                buildElement = _.compose.apply(null, currentDecorators.concat(buildRandomText));
            }
        });
    })();

The easiest way to understand this example is to focus on the `buildElement`
function; or rather, the function which is assigned to the `buildElement`
variable. At first, we assign it `buildRandomText`; but clicking the "bold" or
"italic" buttons alters that assignment. Click "bold", and the `makeBold`
function is added to the `currentDecorators` array. Click again, and the
function is removed. The underscore.js method `_.without` makes it easy to
remove a known value from an array; and the mapping between HTML attributes and
method names in a namespace may be brittle, but it's also extremely convenient.
Pick your poison. And once `currentDecorators` has some content, `_.compose`
comes into play.

If "bold" is selected and "italic" is not, `currentDecorators` only contains `makeBold`.
Let us revisit the definition of that function:

    :::js
    // it's defined a bit differently in the example,
    // but the effect is identical
    function makeBold($element) {
        return $element.addClass("bold");
    }

The function accepts a jQuery element, and returns it after adding the "bold"
class. Simple as that; but more complicated decorators are easy to imagine. In
this case, the decorator is earning its name: it literally applies decorations
to a UI element. An element goes in; an element which _should_ have the same use
case comes out. Remember, decorated functions are meant to be drop-in
replacements for their originals.


`_.compose(makeBold, buildRandomText)` creates and returns a function which
could otherwise be expressed as `makeBold(buildRandomText())`... and now perhaps
you see why the arguments to `_.compose` are written left to right. Add italic,
and you'll get a function which has the same effect as
`makeItalic(makeBold(buildRandomText()))`. The rightmost function just has to
return a value; each other function has to accept the value returned from the
next one.

### A side note: Function.apply

Sadly, `_.compose` takes variable arguments, not an array of methods, so we have
to use `Function.apply` before it will operate on our `currentDecorators` array.
Functions are objects; they can have methods. `Function.apply` executes the
function within a given context (`null` is sufficient here), and passes it each
array element as an argument. To put it another way, any function you can call
like this:

    :::js
    myFunction(alpha, beta, gamma);

...can also be called like this:

    :::js
    myFunction.apply(null, [alpha, beta, gamma]);

Have you ever written a loop to find the largest number in an array? From now
on, use `Math.max.apply(null, values)`. Who's the coolest kid on the block?
Read [Mozilla Developer Network's excellent
documentation](https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Function/apply)
for a bit more detail.

## Real-World Closures

I know you're champing at the bit to go write code with like a zillion closures,
but you know deep in your heart that it's all just showboating. You don't have
to use this stuff to get real work done, right? And if you do, it won't save you
much time over just writing some loops and storing some variables in a plain and
simple data structure. You may be right! But that didn't stop us at [Paperless
Post](http://www.paperlesspost.com) from using closures as part of our upcoming
undo/redo system. Stay tuned to our developer blog for a writeup. Lots of
interesting nuts and bolts.
