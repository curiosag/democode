	var tabLinks = new Array();
	var contentDivs = new Array();

	function init() {

		// Grab the tab links and content divs from the page
		var tabListItems = document.getElementById('tabs').childNodes;
		for (var i = 0; i < tabListItems.length; i++) {
			if (tabListItems[i].nodeName == "LI") {
				var tabLink = getFirstChildWithTagName(tabListItems[i], 'A');
				var id = getHash(tabLink.getAttribute('href'));
				tabLinks[id] = tabLink;
				contentDivs[id] = document.getElementById(id);
			}
		}

		var i = 0;
		for ( var id in tabLinks) {
			tabLinks[id].onclick = showTab;
			tabLinks[id].onfocus = function() {
				this.blur()
			};
			if (i == 0)
				tabLinks[id].className = 'selected';
			i++;
		}

		// Hide all content divs except the first
		var i = 0;
		for ( var id in contentDivs) {
			if (i != 0)
				contentDivs[id].className = 'tabContent hide';
			i++;
		}
	}

	function showTab() {
		var selectedId = getHash(this.getAttribute('href'));

		for ( var id in contentDivs) {
			if (id == selectedId) {
				tabLinks[id].className = 'selected';
				contentDivs[id].className = 'tabContent';
			} else {
				tabLinks[id].className = '';
				contentDivs[id].className = 'tabContent hide';
			}
		}

		// Stop the browser following the link
		return false;
	}

	function getFirstChildWithTagName(element, tagName) {
		for (var i = 0; i < element.childNodes.length; i++) {
			if (element.childNodes[i].nodeName == tagName)
				return element.childNodes[i];
		}
	}

	function getHash(url) {
		return url.substring(url.lastIndexOf('#') + 1);
	}