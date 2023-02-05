window.pdfheight=160;
window.dirheight=50;

function attachalt(containertop,elementheight) {
    return function(k,v) {
            $(v).removeClass("shaded");
	    var elementtop = Math.floor($(v).position().top) - containertop;
	    var row = Math.floor(elementtop / elementheight);
	    var isshaded = 1 - (row % 2); /* First, third, etc. */
	    if (isshaded) {
		$(v).addClass("shaded");
	    }
    }
}

function addalt() {
    var filecontainer = $("#filelist");
    var dircontainer =  $("#dirlist" );
    var filecontainertop = Math.floor(filecontainer.position().top);
    var dircontainertop  = Math.floor( dircontainer.position().top);
    var filecallback = attachalt(filecontainertop,pdfheight);
    var dircallback  = attachalt( dircontainertop,dirheight);
    $.each($(".pdffile"), function(k,v){filecallback(k,v);});
    $.each($(".dir"),     function(k,v){ dircallback(k,v);});
}

$(document).ready(addalt);
$(window).resize(addalt);
	
