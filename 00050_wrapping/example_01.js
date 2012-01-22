(function () {
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

		$content.find("h1.addComment a").click(function(event) {
			event.preventDefault();
			addComment();
		});

		$loginForm.find("a").click(function (event) {
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
