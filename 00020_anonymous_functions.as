    /* figure 01 */
    function handleChange(event:Event):void {
        doStuff();
    }

    thing.addEventListener(Event.CHANGE, handleChange);

    // which is equivalent to this:
    thing.addEventListener(Event.CHANGE, function(event:Event):void {
        doStuff();
    });

    /* figure 02 */
    // an anonymous function, assigned to a variable
    var alpha:Function = function():void {trace("alpha");};
    alpha(); // traces "alpha"
    var beta:Function = alpha;
    beta(); // traces "alpha", since it's the exact same function

    /* figure 03 */
    // has the same effect as the code in figure 02
    function alpha():void {
        trace("alpha")
    }
    alpha();
    var beta:Function = alpha;
    beta();

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
                handler(event);
            }
        }
    }

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

    private function handleMove(event:MouseEvent):void {
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
                    mapping.handler();
                    return;
                }
            }
            // if no pattern matched, display an error message
        }
    }

    /* figure 08 */
    /** Filter function: returns true if n is a positive integer. */
    // AS3 requires filter functions to have all three arguments
    function isNaturalNumber(n:Number, i:int, a:Array):Boolean {
        return n >= 1 && n % 1 == 0;
    }

    var list:Array = [-2, -1, 0, 1, 2.5, 3];
    var naturalNumbers:Array = list.filter(isNaturalNumber);
    // naturalNumbers is now [1, 3]

    /* figure 09 */
    var naturalNumbers:Array = list.filter(
        function(n:Number, i:int, a:Array):Boolean {
            return n >= 1 && n % 1 == 0;
        });

    /* figure 10 */
    public class ProductList extends Sprite {
        private var products:Array;

        // filter buttons
        public var justAddedButton:SimpleButton;
        public var freeShippingButton:SimpleButton;
        public var closeoutButton:SimpleButton;

        public function ProductList() {
            products = loadProductsFromDatabase();
            linkToFilter(justAddedButton, justAdded);
            linkToFilter(freeShippingButton, freeShipping);
            linkToFilter(closeoutButton, closeout);
        }

        /** Display the supplied product list on screen. */
        public function display(productList:Array):void {
            // draw only these products to the screen
        }

        /** Convenience method for hooking up filters to buttons. */
        private function linkToFilter(button:SimpleButton, filter:Function):void {
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
