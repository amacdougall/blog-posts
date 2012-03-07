# How We Added Time Travel to Paperless Post

The card creation system at Paperless post is meant to enable painstaking
customization, within the templates our design team generates. Over and over,
we've seen our users turn out fine-tuned cards that stretch the limits of the
design system. They experiment, they tweak, they twiddle, and they turn out
card, from the artistic to the bizarre, that we as programmers could never have
anticipated. We recognize this as a major strength of our site, and so editing
features have always been a priority. At length, after withstanding a huge
holiday rush, we had breathing room to tackle a major new editing feature: a
fully reversible undo history.

## Earlier Attempts

We have not spent the last three years ignoring this need, of course. Undo
history has been in the app, off and on, in various forms, for a long time. For
instance, until recently, text input could be undone with Ctrl-Z, although it
wasn't redoable. We switched from per-character undo to batched input undo over
the summer, with a little help from the `_.debounce` feature of
[underscore.as](http://www.github.com/amacdougall/underscore.as).

Meanwhile, on the Javascript side of the application, we had a state-based undo
system... and that split between undo systems is emblematic of one of the key
design decisions behind the card creation app. In early summer, we switched over
from our original pure-Flash card creation app to a new approach we call "the
hybrid": a Javascript UI wrapping a Flash viewport. Visually, Javascript handles
all the HTML controls outside the viewport, while the viewport renders the card
and handles UI interaction that happens within it, such as dragging a photo.
More importantly, our Javascript code can be said to drive the app: it has
modules which interact with the server to maintain a canonical card state, and
it relays that state to Flash as needed. In turn, it interprets events from
Flash and updates the server when necessary. Between the two sides, there is a
great deal of local communication, with Javascript taking the commanding role;
and data is only synced to the server when needed.

Our goal for this separation was to permit advanced Flash rendering techniques
such as fast photo filters and high-quality fonts, while doing most UI elements
in HTML. Javascript, HAML, and Sass make UI updates a snap. When implementing an
undo history, however, having two codebases on two runtimes makes life harder.

Although our whole-app-state-based history system was promising, and although
its outstanding bugs could have been resolved, we knew we wanted a much more
incremental and flexible approach. Instead of serializing the entire app state
on every user action, why not store only the relevant delta?

After some internal discussion, we settled on the classic undo implementation:
the Command pattern. I first used the Command pattern in Java land, and although
I respected its power, I dreaded the tedium of defining customized command
classes, potentially one for every possible user action, each containing copies
of the state necessary to reverse and repeat the action. As I thought about it,
however, I realized that Javascript and its more straitlaced cousin Actionscript
3 were well-suited to the pattern -- considerably more so than Java and C++,
where the pattern accumulated its original mindshare.

## Basics of the Command Pattern

There are two immediate motivations for the pattern in UI programming. One is to
attach a single procedure to multiple UI elements -- a menu item, a toolbar
button, and a keyboard shortcut, for example -- with more flexibility than event
handlers, such as runtime remapping. In a language with first-class functions,
such as Javascript, this handles itself; so do many other behavioral patterns,
such as Strategy... up to a point.

But the overriding reason to use the Command pattern is to implement undo and
redo. Without a way to visualize actions as storable objects, only two sensible
approaches remain: you can save coded representations of the actions to be
performed and revoked, such as strings to be interpreted later; or you can save
snapshots of the entire state of your app.

Both approaches can be effective. An array of simple action codes such as
"element 123abc color = #ff0000", or more computer-readable data objects such as
`{targetID: "123abc", action: "move", x: 120, y: 0}`, will work for a long time,
especially if you write a simple interpreter for such commands. But once you
need to undelete a complex object, your undelete command must suddenly contain
all the commands necessary to rebuild the object from scratch; or you begin to
cache deleted objects for potential resurrection, and must perforce remember to
purge them when discarding a history branch.

Keeping a snapshot of the whole state is simple enough, as long as your model is
amenable to serialization in the first place. But unless you're restoring a
whole VM state, or rebuilding a purely noninteractive document, it becomes a
real task to ensure functionality in all situations. You need a strong canonical
source of state data -- which we had, in the Javascript session state. The
snapshot approach had legs. But it lacked the one thing we really wanted:
isolation. A history event involving text should be replayable even if an
unrelated photo has been changed elsewhere; but with a snapshot approach, this
was impossible.

The classic approach, we decided, was best. A Command, in this pattern, is just
that: an object representing a command to be executed -- or reversed -- by the
application. Commands are not UI actions: a click is not a Command, but a click
can trigger a command. Commands are not controller or model methods:
`record.delete()` is not a Command, but a Command can invoke that method.
At its barest minimum, a Command is an object which has a single `execute`
method. For our purposes, it must also have `undo`. This is especially simple in
Javascript, where we don't even need to make a class:

    :::javascript
    var command = {
        execute: function() {
            releaseTheHounds();
        },

        undo: function() {
            deployDogCatcher();
        }
    };

## Storing Historical State

Of course, in this example, we assume that `releaseTheHounds` and
`deployDogCatcher` are global functions that take no parameters. In any real
application, we will have commands which alter the program state. Their `undo`
implementation must know what state to revert to. In Java, it was common to
write subclasses which hold that state in member variables, much like this:

    :::java
    public class ColorChangeCommand extends Command {

        private Potato potato;
        private int oldColor;
        private int newColor;

        public ColorChangeCommand(Potato potato, int newColor) {
            this.potato = potato;
            this.oldColor = potato.getColor();
            this.newColor = newColor;
        }

        public void execute() {
            potato.setColor(newColor);
        }

        public void undo() {
            potato.setColor(oldColor);
        }
    }

Then we would use it in an event handler like this:

    :::java
    // TODO: verify that this is reasonable Java
    public void handleColorClick(ClickEvent event) {
        Command command = new ColorChangeCommand(
            PP.getApplication().getCurrentPotato(),
            event.target.getColor());
        command.execute();
    }

This subclass is simple, but as you start doing more complicated things,
subclasses proliferate. Such a system can quickly get out of hand. There are
many tricks to manage that complexity, but once you start using extra patterns
or even full-fledged frameworks, well, ["now you have two
problems"](http://regex.info/blog/2006-09-15/247).

Javascript and Actionscript 3 sidestep the whole issue. Functions in those
languages are _closures_, which means that they retain references to everything
that was in scope when they were defined. All you need is a simple hash to hold
a couple of closures, and you're done. Here's the above example, as we might
write it for Paperless Post.

    :::javascript
    function handleColorClick(event) {
        var potato = PP.Current.potato;
        var newColor = $(this).attr("data-color");
        var oldColor = potato.color;

        var command = {
            execute: function() {
                potato.color = newColor;
            },
            undo: function() {
                potato.color = oldColor;
            }
        };

        command.execute();
    }

In this case, all the information we need is defined within the scope of
`handleColorClick`; and since that scope is available to the nested functions
`execute` and `undo`, it remains available to those functions whenever they
happen to run. Already you can see a gain in simplicity. As long as you have a
good grasp of function scope and closure mechanics, which should be natural for
any Javascript programmer these days, the simplicity stays even when you're
storing complex objects in those closures.

## Recording, Rewinding, and Replaying History

TODO: improve and condense this section

Javascript and Actionscript make it easy to create a command object along with
all its state. The history of the app state -- assumign it is entirely
user-driven, or that a user-driven component can easily be separated -- can be
exprssed simple as a linked chain of command. The obvious and correct approach
is to embody history as an array, which is used as a stack: push an executed
command, pop a command in order to undo it. Push undone commands onto a redo
stack; pop those commands one by one to replay history, pushing each redone
command onto the undo stack.

This is obvious and correct... until you start dealing with the two codebases,
two runtimes. That's when things get trickier. A lot of interactions involve JS
simply sending model updates to the Flash viewport, which duly renders them; but
when an action originates within Flash, such as a photo drag or text input, this
approach is ineffective. For simple updates, such as a photo's position, perhaps
it would be sufficient to send JS a model update; but more complex actions, such
as text input, must be stored as commands holding sophisticated state such as
text patches and formatting object fragments. The goal of applying only deltas,
right? And sending patch or fragmentary format data to JS would add complexity
we don't need.

My second thought was to give each runtime its own history, with special
commands used to hand over control of the undo and redo buttons -- literally
swapping event handlers, actually, depending on which runtime was "up" to undo
the next command. This quickly led to the approach I actually used. (Note: I
didn't write code for bad approaches, just notes. Never underestimate the
debugging power of a notepad!)

## Main and Subordinate Command Stores


