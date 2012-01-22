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
