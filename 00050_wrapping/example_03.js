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
