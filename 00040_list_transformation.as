    /* figure 01 */
    public class Alien extends Sprite {
        public var level:int = 1;
        public var type:String = "soldier";
        public var health:int = 100;
        public var weapon:Weapon = new Weapon(Weapon.SHOCK_RIFLE);
    }

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

    // now rewrite it with a Array.filter
    var onscreenAliens:Array = aliens.filter(
        function(alien:Alien, i:int, a:Array):Boolean {
            return alien.x > 0 && alien.y > 0;
        });

    // the underscore.as version is just a tad simpler
    var onscreenAliens:Array = _(aliens).select(
        function(alien:Alien):Boolean {
            return alien.x > 0 && alien.y > 0;
        });

    /* figure 03 */
    /** Filter: returns only onscreen aliens. */
    function onScreen(alien:Alien, i:int, a:Array):Boolean {
        return alien.x > 0 && alien.y > 0;
    }

    /** Filter: returns only aliens wielding gauss rifles. */
    function hasGaussRifle(alien:Alien, i:int, a:Array):Boolean {
        return alien.weapon.type == Weapon.GAUSS_RIFLE;
    }

    var rifleAliens:Array = aliens.filter(onScreen).filter(hasGaussRifle);

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

    /* figure 05 */
    var cities:Array = [
        {name: "New York", state: "NY"},
        {name: "Houston", state: "TX"},
        {name: "Seattle", state: "OR"}
    ];

    // results in ["NY", "TX", "OR"]
    var states:Array = _(cities).pluck("state");


    /* figure 06 */
    // filter functions for underscore.as can be simpler. One example:
    /** Filter builder: selects Aliens by weapon type. */
    function hasWeapon(weaponType:String):Function {
        return function(alien:Alien):Boolean {
            return alien.weapon.type == weaponType;
        };
    }

    /** Filter builder: selects Weapons by percentage of ammo remaining. */
    function maxAmmoPercentage(percentage:Number):Function {
        return function(weapon:Weapon):Boolean {
            return weapon.ammoCount / weapon.ammoMax < percentage;
        };
    }

    // here's a sequence that uses _.pluck to go down a level midstream.
    var grenadeLaunchers:Array = _(aliens).chain()
        .select(withinBounds(gameArea.getBounds(stage)))
        .select(hasWeapon(Weapon.PLASMA_LAUNCHER))
        .pluck("weapon")
        .select(maxAmmoPercentage(0.2))
        .each(function(w:Weapon):void {
            w.reload();
        });

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
        .select(minLevel(3))
        .select(minHealthPercentage(0.8))
        .select(combinedLevel(20))
        .value();

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

    var weapons:Array = _(aliens).map(bestWeapon());

    _(aliens).chain().zip(weapons).each(function(pair:Array):void {
        // each pair is an [alien, weapon] array
        pair[0].weapon = pair[1];
    });

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
