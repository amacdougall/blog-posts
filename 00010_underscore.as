// Accompanying code examples.

/* figure 01 */
var list:Array = [
    {name: "Alice", age: 35},
    {name: "Bob", age: 24},
    {name: "Carol", age: 31}
];

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

/* figure 03 */
// idiomatic AS3
var result:Array = [];
for each (var person:Object in list) {
    result.push(person.name);
}

// underscore.as
var result:Array = _(list).pluck("name");

/* figure 04 */
// idiomatic AS3
var result:Array = [];
for each (var person:Object in list) {
    result.push(buildIcon(person));
}

// underscore.as
var result:Array = _(list).map(buildIcon);

/* figure 05 */
// idiomatic AS3
for each (var person:Object in list) {
    trace(person.name + ": " + person.age);
}

// underscore.as
_(list).each(function(person:*):void {
    trace(person.name + ": " + person.age);
}

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

/* figure 08 */
// underscore.as
var result:Array = _(list).chain()
    .select(greaterThan(30))
    .map(buildIcon)
    .map(setAlphaTo(0.5))
    .value();

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
        scrollDelayTimer.start();
    } else {
        scrollDelayTimer.start();
    }
};

scrollBar.addEventListener(Event.CHANGE, handleScroll);


// underscore.as
function handleScroll(event:Event):void {
    update();
}

scrollBar.addEventListener(Event.CHANGE, _(handleScroll).debounce(250));

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
