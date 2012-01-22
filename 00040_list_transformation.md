# Closures in List Transformation

A closure stores information. It can have access to a single parameter given to
it at runtime; or to an internal data structure it can use to make decisions; or
even to large chunks of your program's state, letting you pass _behavior_
without needing to pass _information_. In this post, I'll show you how to use
closures to work with arrays: in a few lines of code, you can grind a nested
data structure down to just a handful of targeted values. With a few more, you
can transform them into anything you need. And with a pinch of closure fairy
dust, you can make those filters and transforms _magical_, building powerful and
intelligent functionality up from a few lines of initializer code. The results
will fascinate and horrify. But mostly fascinate.

## Basic List Filtering

Let's start slow: filtering a list. Let's start with this class, which
represents an enemy in a video game.

    :::as3
    /* figure 01 */
    public class Alien extends Sprite {
        public var level:int;     // experience level
        public var health:int;    // remaining health
        public var weapon:Weapon; // equipped weapon
    }

Now create a bunch of aliens at random xy positions between 100 and -100. To
figure out which ones are onscreen at the moment, we'll filter out all the
aliens whose x and y are less than 0; or to put it another way, _select_ all the
aliens whose x and y are greater.

    :::as3
    /* figure 02 */
    /**
     * Returns a random number between abs and -abs.
     */
    function randomPosition(abs:Number):Number {
        return (abs * 2 * Math.random()) - abs;
    }

    // create 12 new aliens at random positions
    var aliens:Array = [];
    while (aliens.length < 12) {
        var alien:Alien = new Alien();
        alien.x = randomPosition(100);
        alien.y = randomPosition(100);
        aliens.push(alien);
    }

    // get only the aliens with x and y > 0
    var onscreenAliens:Array = [];
    for each (var alien:Alien in aliens) {
        if (alien.x > 0 && alien.y > 0) {
            onscreenAliens.push(alien);
        }
    }

    // now rewrite it with Array.filter
    var onscreenAliens:Array = aliens.filter(
        function(s:Sprite, i:int, a:Array):Boolean {
            return sprite.x > 0 && sprite.y > 0;
        });

If we know we're going to do a lot of these filtering operations, it makes sense
to define the filter function somewhere else. And since `Array.filter` returns a
new `Array` containing only the selected elements, we can chain the calls
together.

    :::as3
    /* figure 03 */
    /** Filter: returns only onscreen aliens. */
    function onScreen(alien:Alien, i:int, a:Array):Boolean {
        return alien.x > 0 && alien.y > 0;
    }

    /** Filter: returns only aliens wielding gauss rifles. */
    function hasGaussRifle(alien:Alien, i:int, a:Array):Boolean {
        return alien.weapon.type == "gaussRifle";
    }

    var rifleAliens:Array = aliens.filter(onScreen).filter(hasGaussRifle);

With this method, we're getting closer to something useful and flexible; but we
still need a separate function for every filtering condition, even if some of
them are very simple. We need a way to parameterize our filters, and that's
where closures come in. 

## Smart Filters

From here on, we'll use the underscore.as version of `filter`, which doesn't
require that obnoxious three-argument function. It does, however, require each
chain to begin with `.chain()` and end with either `.value()` or `.each()`, for
reasons we'll discuss soon. It's a tradeoff: underscore.as grants more power
than `Array` has on its own, but requires the coder to invoke it. If you're only
applying one filter, you don't need `.chain()` or `.value()`.

In underscore.as, `select` is a synonym for `filter`. I prefer it, since I think
it better reflects what the method really does: it selects only certain elements
from the original list.

    :::as3
    /* figure 04 */
    /** Filter builder: selects within rectangle. */
    function withinBounds(bounds:Rectangle):Function {
        return function(alien:Alien):Boolean {
            return bounds.containsPoint(new Point(alien.x, alien.y));
        };
    }

    /** Filter builder: selects on weapon type. */
    function hasWeapon(weaponType:String):Function {
        return function(alien:Alien):Boolean {
            return alien.weapon.type == weaponType;
        };
    }

    /** Filter builder: selects aliens of a minimum level. */
    function minLevel(level:int):Function {
        return function(alien:Alien):Boolean {
            return alien.level >= level;
        };
    }

    var grenadiers:Array = _(aliens).chain()
        .select(withinBounds(new Rectangle(0, 0, 800, 600))
        .select(hasWeapon(Weapon.PLASMA_LAUNCHER))
        .value();

    var eliteRaiders:Array = _(aliens).chain()
        .select(withinBounds(gameArea.getBounds(stage)))
        .select(hasWeapon(Weapon.SHOCK_RIFLE))
        .select(minLevel(5))
        .value();

`withinBounds`, `hasWeapon`, and `minLevel` are not filter functions; they
create filter functions on demand, each suited for a specific purpose. Combined
with the inherent chaining capability of `Array.filter`, parameterized filters
make it easy to mix and match filtering operations. 

Although underscore.as requires an explicit `chain` call at the start of a
method chain, it also permits more operations than just `Array.filter`,
`Array.map`, and `Array.forEach`. For example, `_.pluck` returns the value of
the named property for each element in the target array. Here is a trivial
example.

    :::as3
    /* figure 05 */
    var cities:Array = [
        {name: "New York", state: "NY"},
        {name: "Houston", state: "TX"},
        {name: "Seattle", state: "OR"}
    ];

    var states:Array = _(cities).pluck("state");
    // results in ["NY", "TX", "OR"]

And here's an application to our alien situation.

    :::as3
    /* figure 06 */
    // filter functions for underscore.as can be simpler. One example:
    /** Filter builder: selects Aliens by weapon type. */
    function hasWeapon(weaponType:String):Function {
        return function(alien:Alien):Boolean {
            return alien.weapon.type == weaponType;
        };
    }

    /** Filter builder: selects Weapons by percentage of ammo remaining. */
    function maxAmmo(percentage:Number):Function {
        return function(weapon:Weapon):Boolean {
            return weapon.ammoCount / weapon.ammoMax < percentage;
        };
    }

    // here's a sequence that uses _.pluck to go down a level midstream.
    var grenadeLaunchers:Array = _(aliens).chain()
        .select(withinBounds(gameArea.getBounds(stage)))
        .select(hasWeapon(Weapon.PLASMA_LAUNCHER))
        .pluck("weapon")
        .select(maxAmmo(0.2))
        .each(function(w:Weapon):void {
            w.reload();
        });

As you can see, `_.select` and `_.pluck` make it easy to extract specific values
from a multi-layered data structure and then do something to them. This style of
element selection may already be familiar to you from libraries like
[jQuery](http://www.jquery.com).

## Smarter Filters

It's handy to create a special-purpose filter function on the spot, but once
created, that function always has the same effect. Closures can do more than
that. Here's a filter function which filters out duplicate values, by storing an
array of known elements.

    :::as3
    /* figure 07 */
    import flash.utils.Dictionary;

    function unique():Function {
        var known:Dictionary = new Dictionary();

        return function(element:*):Boolean {
            if (known[element]) {
                return false;
            } else {
                known[element] = true; // any value will do
                return true;
            }
        };
    }

    var list:Array = [1, 2, 1, 2, 1, 2, 3];
    var uniques:Array = _(list).unique(); // [1, 2, 3]

The `unique` function defines a `Dictionary` whose keys will be the objects
which have been passed into it so far. The values don't matter: the point of the
`Dictionary` class is that it can have any object as a key, not just a string.
As a pleasant side effect, we can use dictionaries to simulate the `Set` class
in Java: a bag of unique values, nothing more or less. If we had stored known
values in an `Array`, even detecting if an element is _in_ the array at all
would require us to compare the target element with every element in the array,
at worst&#8212;and the worst would happen every time the uniqueness filter
encountered a brand new element. With `Dictionary`, we do exactly one check for
each incoming element.

If it's not clear how the function is storing and using the `known` variable,
here's a simpler use of the same concept:

    ::as3
    /* figure 08 */
    function buildAccumulator(startingValue:Number):Function {
        var total:Number = startingValue;

        return function(n:Number):Number {
            total += n;
            return total;
        };
    }

    var runningTotal:Function = buildAccumulator(0);
    var expenditures:Array = [
        runningTotal(20),
        runningTotal(24),
        runningTotal(29),
        runningTotal(22)
    ];

    // expenditures is now [20, 44, 73, 95]
    
Each time `runningTotal` is called, it adds the argument to its internal `total`
variable and then returns the new value of `total`. The function will retain a
reference to that variable for as long as it exists.

To apply this concept to our game, let's grab aliens with a combined experience
level not to exceed 20, with individual level 3 or higher, and at least
80% health remaining.

    :::as3
    /* figure 09 */
    /**
     * Filter builder: selects Aliens until their combined level equals or
     * exceeds levelCap.
     */
    function combinedLevel(levelCap:int):Function {
        var total:int = 0;

        return function(alien:Alien):Boolean {
            total += alien.level;
            return total <= levelCap;
        };
    }

    // the minLevel and minHealthPercentage filters should be obvious

    var squad:Array = _(aliens).chain()
        .filter(minLevel(3))
        .filter(minHealthPercentage(0.8))
        .filter(combinedLevel(20))
        .value();

## Filter Creator Creators

At the risk of sounding like the infamous Java `FactoryFactory`, we'll go one
layer deeper. We've been making some filter builders which are quite similar --
they just operate on different attributes. So why repeat ourselves?

    :::as3
    /* figure 10 */
    /** Filter builder builder: for a minimum numeric property. */
    function minFilter(property:String):Function {
        return function(minValue:Number):Function {
            return function(object:*):Boolean {
                return object[property] <= minValue;
            };
        };
    }

    var filters:Object = {
        minLevel: minFilter("level"),
        minHealth: minFilter("health")
    };

For a certain type of person, a mere filter creator creator is peanuts. Why just
filter our lists? Why not change them into something completely different? But
personally, that's where I draw the line; I recoil from the brink; I carefully
and quietly put the laptop down, close it with a gentle click, and go out and
enjoy the nice weather. _Ha ha ha!_ Just kidding!

## List Transformation

Meet `Array.map`.

    :::as3
    /* figure 11 */
    function louder(s:String, i:int, a:Array):String {
        return s.toUpperCase();
    }

    var words:Array = ["correct", "horse", "battery", "staple"];
    trace(words.map(louder).join()); // CORRECT HORSE BATTERY STAPLE

    // like Array.filter, Array.map functions require three arguments
    function multiplyBy(n:Number, i:int, a:Array):Function {
        return function(m:Number):Number {
            return n * m;
        };
    }

    var numbers:Array = [1, 2, 3, 4];
    var doubled:Array = numbers.map(multiplyBy(2)); // 2, 4, 6, 8

While `filter` returns a `Boolean` to narrow down an existing list, `map`
creates a new list, by executing a function on every element of the first list.
An example from our game:

    :::as3
    /* figure 12 */
    function bestWeapon():Function {
        return function(alien:Alien):Weapon {
            switch (alien.type) {
                // we don't need break statements since each case returns
                case "soldier": return new Weapon(Weapon.SHOCK_RIFLE);
                case "sniper": return new Weapon(Weapon.GAUSS_RIFLE);
                // ...other cases
            }
        };
    }

    var weapons:Array = _(aliens).map(bestWeapon);

    _(aliens).chain().zip(weapons).each(function(pair:Array) {
        // each pair is an [alien, weapon] array
        pair[0].weapon = pair[1];
    });

In underscore.as, `_.zip` combines two arrays A and B into an array of pairs:
`_([1, 2, 3]).zip("a", "b", "c")` results in `[[1, "a"], [2, "b"], [3, "c"]]`.
Think of the values as teeth of a zipper. When you have two arrays whose
elements belong together, in the same order&#8212;like our array of aliens and our
array of weapons for them&#8212;`_.zip` is the tool to use.

We call a function to get our best-weapon mapping function, because we _always_
want to create a new function. It's a matter of style: would you rather remember
that some maps and filters are used with `filter(myFilter)` and others are
`filter(myFilter())`? Or would you rather just call them the same way all the
time? Some filters, like the unique-element filter used above, _have_ to be
created anew each time they're used. So for consistency, we'll do this with all
of them.

## Smart Maps and Smarter Maps

Just like filters, we can build mapping functions to perform particular actions.
Check out how `withAmmoType` creates a new array, sure, but all the elements are
the same&#8212;just with one property changed.

    :::as3
    /* figure 13 */
    function withAmmoType(ammoType:String):Function {
        return function(weapon:Weapon):Weapon {
            weapon.ammoType = ammoType;
            return weapon;
        };
    }

    var weapons:Array = _(aliens).chain()
        .map(bestWeapon())
        .map(withAmmoType(Ammo.ARMOR_PIERCING))
        .value();

    _(aliens).each(function(alien:Alien, index:int):Alien {
        alien.weapon = weapons[index];
    });
    
This way of assigning weapons to aliens may be easier to understand than the
`_.zip` version, and it demonstrates that you can use the index argument to your
filter and map functions in underscore.as&#8212;you just aren't required to. On the
other hand, by calling `weapons[index]`, this code throws you right back into
the mindset of `for (var i:int = 0; i < foo.length; i++)`... exactly the sort of
loop drudgery we want to escape. Why should we waste our time telling the
computer _how_ to loop over a set of items? Why should we have to tell the
computer what _numbers_ to plug into an array to get values out? With `_.zip`,
we just say "transform the data in a way that's easy to think about."

Naturally, we won't stop there. With our `unique` function, and our squad
builders, we saw that we can build a closure which holds a running set of data.
With mapping functions, we can do considerably more. 

    :::as3
    /* figure 14 */
    /**
     * Map builder: matches enemy difficulty to the player characters,
     * and makes sure enemy party has at least one of each type.
     */
    function balance(party:Party):Function {
        var targetCombinedLevel:int = party.combinedLevel + 5;
        var targetAverageLevel:int = 0;

        var types:Array = ["grenadier", "soldier", "sniper", "scout"];

        // this time we're using all the arguments
        return function(alien:Alien, i:int, a:Array):Alien {
            // set target average level once we know the array length
            targetAverageLevel ||= Math.round(targetCombinedLevel / a.length);

            alien.level = targetAverageLevel;

            // change the alien type until all required types are used
            if (types.length > 0) {
                alien.type = types.pop();
            }

            return alien;
        };
    }

Here we have a function which transforms an entire list of enemies to match an
in-game requirement. The possibilities don't stop there: we could use an inner
mapping function to convert player classes to enemy types, ensuring that each
player character is confronted with an appropriate counterattack. Or we could
add a mapping which places the aliens in a formation based on the input type, by
altering their `x` and `y` values: `.map(toFormation("phalanx"))` or something.

## Next Up: Function Mutation

In the next post, I'll switch gears and talk about how to modify or even replace
the behavior of functions at runtime. This opens up the ability to add
application functionality on the fly, or just to simplify your code by doing a
whole lot with just a few lines.
