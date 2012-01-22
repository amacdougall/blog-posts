    /* figure 00 */
    // TODO: try this!
    function foo():Function {
        var instance:SomeClass = new SomeClass();
        return instance.someFunction;
    }
    // see if returned function has instance variable access;
    // of course it does, but it's good to check.

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

    /* figure 03 */
    public class Driver {
        public var license:DriversLicense;

        public function canLegallyDrive():Boolean {
            return license.valid;
        }
    }

    var driver:Driver = Database.getRandomDriver();
    trace("License number " + driver.license.id);
    trace("Can drive? " + driver.canLegallyDrive());

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

    /* figure 05 */
    for each (var painting:Painting in paintings) {
        var paintingButton:Button = new PaintingButton(painting);
        paintingButton.addEventListener(MouseEvent.CLICK,
            (function(paintingButton:PaintingButton):Function {
                return function(event:Event):void {
                    showPainting(paintingButton.painting);
                }
            })(paintingButton));

    /* figure 06 */
    function createHandler(paintingButton:PaintingButton):Function {
        var handler:Function = function(event:Event):void {
            showPainting(paintingButton.painting);
        };
        return handler;
    }

    /* figure 07 */
    var monaLisaButton:PaintingButton = new PaintingButton(monaLisa);

    var handler:Function = (function(paintingButton:PaintingButton):Function {
        return function(event:Event):void {
            showPainting(paintingButton.painting);
        };
    })(monaLisaButton);

    monaLisaButton.addEventListener(MouseEvent.CLICK, handler);

    /* figure 08 */
    var one:int = function():int {return 1;}(); // execute immediately
    var two:int = (function():int {return 2;})(); // a bit clearer?

    /* figure 09 */
    for each (var painting:Painting in paintings) {
        var paintingButton:Button = new PaintingButton(painting);
        paintingButton.addEventListener(MouseEvent.CLICK,
            function(event:Event):void {
                showPainting(PaintingButton(event.currentTarget).painting);
            });
    }

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

    /* figure 11 */
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
    bar.sayName(); // traces "Bar"

    /* figure 12 */
    public class Foo {
        public var name:String = "Foo";
        public function sayName():String {
            trace(this.name);
        }
    }
