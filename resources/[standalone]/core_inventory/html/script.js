var Inventories = {};
var InventoryParms = {};

var urls = {};

urls["CAPPELLO"] = 'https://i.imgur.com/oR0C4Bv.png';
urls["MASCHERA"] = 'https://i.imgur.com/lZsIFas.png';
urls["TORSO"] = 'https://i.imgur.com/f40rFto.png';
urls["TSHIRT"] = 'https://i.imgur.com/ML0tJ5g.png';
urls["COLLANA"] = 'https://i.imgur.com/r3g0DUy.png';
urls["SCARPE"] = 'https://i.imgur.com/fbv2tta.png';
urls["OROLOGIO"] = 'https://i.imgur.com/JDSynri.png';
urls["OCCHIALI"] = 'https://i.imgur.com/6mwc3uT.png';
urls["PANTALONI"] = 'https://i.imgur.com/ommIAaF.png';
urls["GIUBBOTTO"] = 'https://i.imgur.com/SahghTg.png';

var pesoattuale = 0
var pesomassimo = 0
var yourhexmother = ''
var bloccoInv = false

//SETTINGS
var Settings = {
    inventorycolor: '#ffffff',
    labelcolor: '#242424',
    slotcolor: '#1f1f1f',
    slotborder: '#3b3b3b',
    slothover: '#ffffff',
    durabilitycolor: '#e87613',
    autoplacing: true
};

//DRAGGABLE
var itemDragging;
var idx;
var idy;

var startSlot = 0;
var startInv = '';

var startX = 0;
var startY = 0;

var canPlace = false;

var lastSlot = 0;
var lastInv = '';

var flipped = false;

var dragDrop = false;
var dragUse = false;
var dragTimeout = null;

//STACK
var stackItems = false;
var stackItem = null;
var stackInventory = null;

//SPLIT
var splitAmount = null;
var splitItem = null;
var splitSlot = null;
var splitFinv = null;
var splitTinv = null;

//KEYS
var ctrlClicked = false;
var shiftClicked = false;
var recentInventory = null;
var attachmentsOpened = false;
var attachmentContentPos = null;

var keybindActive = null;

//MAIN
var config;
var cid;
var qbitems;

//SCREENPLACING
var minHeight;

// Audio
var audioPlayer;

//Mouse Dragging
var dragging = false;
var dragX = 0;
var dragY = 0;

function getText(text) {

    if (config.Text[text]) {
        return config.Text[text];
    } else {
        return 'UNDEFINED';
    }

}

function hexToRgb(hex) {

    var shorthandRegex = /^#?([a-f\d])([a-f\d])([a-f\d])$/i;
    hex = hex.replace(shorthandRegex, function(m, r, g, b) {
        return r + r + g + g + b + b;
    });

    var result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
    return result ? {
        r: parseInt(result[1], 16),
        g: parseInt(result[2], 16),
        b: parseInt(result[3], 16)
    } : null;
}

function playSound(file) {
    if (audioPlayer != null) {
        audioPlayer.pause();
    }

    audioPlayer = new Audio("../sounds/" + file + ".mp3");
    audioPlayer.volume = 0.1;

    var didPlayPromise = audioPlayer.play();

    if (didPlayPromise === undefined) {
        audioPlayer = null;
    } else {
        didPlayPromise.then(_ => {}).catch(error => {
            audioPlayer = null;
        })
    }
}

function findAvailableSpot(inv, x, y) {

    for (let g = 0; g < InventoryParms[inv].slots; g++) {

        var testAvail = getSlots(g, x, y, InventoryParms[inv].rows, inv)

        if (testAvail != null) {
            var fail = false;

            for (let i = 0; i < testAvail.length; i++) {

                if ($('#' + inv).find('#slot-' + testAvail[i]).attr('slot') == null || $('#' + inv).find('#slot-' + testAvail[i]).attr('occupied') == "1") {

                    fail = true;
                }

            }

            if (!fail) {

                return g;
                break;
            }
        }

    }

    return null;

}

function getSlots(startSlot, x, y, rows, inv) {

    var slots = [];

    if ($('#' + inv).find('#slot-' + startSlot).attr('holder') == "1") {
        slots.push(1);
    } else {

        for (let i = startSlot; i < startSlot + (y * rows); i += rows) {

            if (i + x > Math.ceil((i + 1) / rows) * rows) {
                return null;
            }

            for (let g = i; g < i + x; g++) {

                slots.push(g);
            }
        }

    }

    return slots;

}

function isOverlap(el) {

    var fail = false;

    for (const [key, value] of Object.entries(InventoryParms)) {

        if ($('#' + key).parent().is(el) || !$('#' + key).parent().length) {
            return;
        }

        var rect1 = $('#' + key).parent()[0].getBoundingClientRect();
        var rect2 = $(el)[0].getBoundingClientRect();

        var overlap = !(rect1.right < rect2.left ||
            rect1.left > rect2.right ||
            rect1.bottom < rect2.top ||
            rect1.top > rect2.bottom)

        if (overlap) {
            fail = true;

            if (rect1.top + $('#' + key).parent().height() + 10 + $(el).height() < screen.height - 20) {
                $(el).css({
                    top: rect1.top + $('#' + key).parent().height() + 10 + 'px',

                })
            } else if (rect1.left + $('#' + key).parent().width() + 10 + $(el).width() < screen.width - 20) {
                $(el).css({
                    top: minHeight + 'px',
                    left: rect1.left + $('#' + key).parent().width() + 10 + 'px',

                })
            } else {
                fail = false
            }

            break;
        }

    }

    return fail;

}

//UNFINISHED
function findAvailableScreenPlace(el) {

    if (Settings['autoplacing']) {

        minHeight = screen.height;

        for (const [key, value] of Object.entries(InventoryParms)) {

            if (value) {
                if (!value.hidden) {
					if($('#' + key).parent().offset()) { 
						var off = $('#' + key).parent().offset().top
						if (off < minHeight) {
							minHeight = off;
						}
					} else {
						minHeight = 20;
					}
                }
            }

        }

        if (minHeight > screen.height / 2) {
            minHeight = 20;
        }

        var tries = 0

        while (isOverlap(el)) {

            if (tries > 100) {
                return;
            }
            tries += 1;

        }

    }

}

function createHolder(name, slots, rows, content, label, locationX, locationY, restrictedTo, hidden, type) {
    if (InventoryParms[name] != null) {
        return;
    }

    Inventories[name] = content;
    InventoryParms[name] = {
        slots: slots,
        rows: rows,
        label: label,
        x: locationX,
        y: locationY,
        restrictedTo: restrictedTo,
        hidden: hidden,
        type: type
    }
	


    var base = '<div class="clearfix borderbox inventoryBox" inventory="'+name+'" holder="1"  style="left: 1300px; top: 20px;" ><!-- group -->';

	base = base + '<div class="header"><div class="label holder" style= "background-color: transparent !important; color: white">'+label+'</div></div>' +
	'   <div class="clearfix grpelem inventory holder" id="'+name+'" style="width: '+(45*rows)+'; height: '+(slots/rows) *45+'; outline-color: '+Settings['inventorycolor']+'"><!-- group -->';

    /*
	base = base + '<div class="header"><div class="label holder" style="background-color: '+Settings['inventorycolor']+'; color: '+Settings['labelcolor']+'">'+label+'</div></div>' +
	'   <div class="clearfix grpelem inventory holder" id="'+name+'" style="width: '+(45*rows)+'; height: '+(slots/rows) *45+'; outline-color: '+Settings['inventorycolor']+'"><!-- group -->';
    */

	base = base +'    <div class="slot" holder="1" id="slot-1" slot="1" occupied="0" inventory="'+name+'" data-sizePolicy="fixed" style=" outline-color: '+Settings['slotborder']+'; background-image: url(' + urls[label] + '); background-color: '+Settings['slotcolor']+'; width: '+((45*rows) - 2)+'; height: '+((slots/rows) *45 - 2)+'; " data-pintopage="page_fixedLeft"><!-- simple frame --></div>';

	base = base + '   </div>'+

	'  </div>';


	$('#main_container').append(base);

    //TOGGLES CHANGE OPACITY WHEN INACTIVE
    if ($('#hat-' + cid).is(":hidden")) {
        $('#toggleclothes').css('opacity', '0.5');
    }
    if ($('#primary-' + cid).is(":hidden")) {
        $('#toggleweapons').css('opacity', '0.5');
    }
    if ($('#content-' + cid).is(":hidden")) {
        $('#toggleinventory').css('opacity', '0.5');
    }
    if (!$('.settings-container').length) {
        $('#togglesettings').css('opacity', '0.5');
    }

    findAvailableScreenPlace($('#' + name).parent())

    for (const [key, value] of Object.entries(content)) {

        addItem(key, name)

    }

    $('#' + name).parent().addClass('pulse');
    setTimeout(() => {
        $('#' + name).parent().removeClass('pulse');
    }, 500)

    $(".inventoryBox").draggable({

        start: function(e, ui) {

            if ($(this).attr('inventory') != 'content-' + cid && $(this).attr('holder') != "1") {

                recentInventory = $(this).attr('inventory');
            }

            $(this).appendTo('#main_container');

        },
        stop: function(e, ui) {

            InventoryParms[$(this).attr('inventory')].x = $(this).css("left");
            InventoryParms[$(this).attr('inventory')].y = $(this).css("top");

        },

        handle: ".label"

    });

    if (hidden) {
        $('#' + name).parent().hide();
    }

}

function closeInventory(name) {

    if (name == 'content-' + cid) {
        closeMenu();
    } else {
        if (recentInventory == name) {
            recentInventory = null;
        }
        $.post('https://core_inventory/closeInventory', JSON.stringify({
            inventory: name,
            data: InventoryParms[name]
        }));
        InventoryParms[name] = null;
        Inventories[name] = null;
        $("#" + name).parent().remove();
    }

}

var num = 0;

function createInventory(name, slots, rows, content, label, locationX, locationY, hidden, type, restrictedTo) {

    

    if (InventoryParms[name] != null) {
        return;
    }

    Inventories[name] = content;
    InventoryParms[name] = {
        slots: slots,
        rows: rows,
        label: label,
        x: locationX,
        y: locationY,
        hidden: hidden,
        type: type,
        restrictedTo: restrictedTo
    }
		
	if (name.includes("content-char")) {
		
		if (name != "content-" + yourhexmother) {
			var base = '<div class="clearfix borderbox inventoryBox " inventory="' + name + '" holder="0"  style="left: ' + "793px" + '; top: ' + "14px" + '" ><!-- group -->';
			
			base = base + '<div class="header"><div class="label" style="background-color: ' + Settings['inventorycolor'] + '; color: ' + Settings['labelcolor'] + '">' + label + '</div><div class="close" onclick="closeInventory(\'' + name + '\')">' +
				'<svg viewBox="0 0 1024 1024" class="close-icon">' +
				'      <path' +
				'        d="M512 0c-282.77 0-512 229.23-512 512s229.23 512 512 512 512-229.23 512-512-229.23-512-512-512zM512 928c-229.75 0-416-186.25-416-416s186.25-416 416-416 416 186.25 416 416-186.25 416-416 416z"' +
				'      ></path>' +
				'      <path' +
				'        d="M672 256l-160 160-160-160-96 96 160 160-160 160 96 96 160-160 160 160 96-96-160-160 160-160z"' +
				'      ></path>' +
				'    </svg>' +
				'' + getText('close') + '</div></div>' +
				'   <div class="clearfix grpelem inventory " id="' + name + '" style="width: ' + (59 * rows) + '; grid-template-columns: repeat(' + rows + ', 59px); outline-color: ' + Settings['inventorycolor'] + '">';	   
        } else {
			var base = '<div class="clearfix borderbox inventoryBox " inventory="' + name + '" holder="0"  style="left: ' + "51px" + '; top: ' + "16px" + '" ><!-- group -->';
			
			base = base + '<div class="header" style = "float: left;"><div class="label" style="background-color: ' + Settings['inventorycolor'] + '; color: ' + Settings['labelcolor'] + '">' + label + '</div><div class="close" onclick="closeInventory(\'' + name + '\')">' +
				'<svg viewBox="0 0 1024 1024" class="close-icon">' +
				'      <path' +
				'        d="M512 0c-282.77 0-512 229.23-512 512s229.23 512 512 512 512-229.23 512-512-229.23-512-512-512zM512 928c-229.75 0-416-186.25-416-416s186.25-416 416-416 416 186.25 416 416-186.25 416-416 416z"' +
				'      ></path>' +
				'      <path' +
				'        d="M672 256l-160 160-160-160-96 96 160 160-160 160 96 96 160-160 160 160 96-96-160-160 160-160z"' +
				'      ></path>' +
				'    </svg>' +
				'' + getText('close') + '</div></div><div id="st_weight"></div><div id="f_weight""><div id="in_weight""></div></div>' +
				'   <div class="clearfix grpelem inventory " id="'+name+'" style="width: '+(59*rows)+'; grid-template-columns: repeat('+rows+', 59px); outline-color: '+Settings['inventorycolor']+'">';		
		}

    }else{
		if (name.includes("primary")) { 
			if (name != "primary-" + yourhexmother) {
				var base = '<div class="clearfix borderbox inventoryBox " inventory="' + name + '" holder="0"  style="left: ' + "1554px" + '; top: ' + "197px" + '" ><!-- group -->';

				base = base + '<div class="header"><div class="label" style="background-color: ' + Settings['inventorycolor'] + '; color: ' + Settings['labelcolor'] + '">' + label + '</div><div class="close" onclick="closeInventory(\'' + name + '\')">' +
					'<svg viewBox="0 0 1024 1024" class="close-icon">' +
					'      <path' +
					'        d="M512 0c-282.77 0-512 229.23-512 512s229.23 512 512 512 512-229.23 512-512-229.23-512-512-512zM512 928c-229.75 0-416-186.25-416-416s186.25-416 416-416 416 186.25 416 416-186.25 416-416 416z"' +
					'      ></path>' +
					'      <path' +
					'        d="M672 256l-160 160-160-160-96 96 160 160-160 160 96 96 160-160 160 160 96-96-160-160 160-160z"' +
					'      ></path>' +
					'    </svg>' +
					'' + getText('close') + '</div></div>' +
					'   <div class="clearfix grpelem inventory " id="' + name + '" style="width: ' + (59 * rows) + '; grid-template-columns: repeat(' + rows + ', 59px); outline-color: ' + Settings['inventorycolor'] + '">';	   
					
					
			} else {
				var base = '<div class="clearfix borderbox inventoryBox " inventory="' + name + '" holder="0"  style="left: ' + locationX + '; top: ' + locationY + '" ><!-- group -->';
				
				base = base + '<div class="header"><div class="label" style="background-color: ' + Settings['inventorycolor'] + '; color: ' + Settings['labelcolor'] + '">' + label + '</div><div class="close" onclick="closeInventory(\'' + name + '\')">' +
					'<svg viewBox="0 0 1024 1024" class="close-icon">' +
					'      <path' +
					'        d="M512 0c-282.77 0-512 229.23-512 512s229.23 512 512 512 512-229.23 512-512-229.23-512-512-512zM512 928c-229.75 0-416-186.25-416-416s186.25-416 416-416 416 186.25 416 416-186.25 416-416 416z"' +
					'      ></path>' +
					'      <path' +
					'        d="M672 256l-160 160-160-160-96 96 160 160-160 160 96 96 160-160 160 160 96-96-160-160 160-160z"' +
					'      ></path>' +
					'    </svg>' +
					'' + getText('close') + '</div></div>' +
					'   <div class="clearfix grpelem inventory " id="' + name + '" style="width: ' + (59 * rows) + '; grid-template-columns: repeat(' + rows + ', 59px); outline-color: ' + Settings['inventorycolor'] + '">';	              
			}				
  
		} else if (name.includes("secondry")) { 
			if (name != "secondry-" + yourhexmother) {
				var base = '<div class="clearfix borderbox inventoryBox " inventory="' + name + '" holder="0"  style="left: ' + "1550px" + '; top: ' + "477px" + '" ><!-- group -->';

				base = base + '<div class="header"><div class="label" style="background-color: ' + Settings['inventorycolor'] + '; color: ' + Settings['labelcolor'] + '">' + label + '</div><div class="close" onclick="closeInventory(\'' + name + '\')">' +
					'<svg viewBox="0 0 1024 1024" class="close-icon">' +
					'      <path' +
					'        d="M512 0c-282.77 0-512 229.23-512 512s229.23 512 512 512 512-229.23 512-512-229.23-512-512-512zM512 928c-229.75 0-416-186.25-416-416s186.25-416 416-416 416 186.25 416 416-186.25 416-416 416z"' +
					'      ></path>' +
					'      <path' +
					'        d="M672 256l-160 160-160-160-96 96 160 160-160 160 96 96 160-160 160 160 96-96-160-160 160-160z"' +
					'      ></path>' +
					'    </svg>' +
					'' + getText('close') + '</div></div>' +
					'   <div class="clearfix grpelem inventory " id="' + name + '" style="width: ' + (59 * rows) + '; grid-template-columns: repeat(' + rows + ', 59px); outline-color: ' + Settings['inventorycolor'] + '">';	   
					
					
			} else {
				var base = '<div class="clearfix borderbox inventoryBox " inventory="' + name + '" holder="0"  style="left: ' + locationX + '; top: ' + locationY + '" ><!-- group -->';
				
				base = base + '<div class="header"><div class="label" style="background-color: ' + Settings['inventorycolor'] + '; color: ' + Settings['labelcolor'] + '">' + label + '</div><div class="close" onclick="closeInventory(\'' + name + '\')">' +
					'<svg viewBox="0 0 1024 1024" class="close-icon">' +
					'      <path' +
					'        d="M512 0c-282.77 0-512 229.23-512 512s229.23 512 512 512 512-229.23 512-512-229.23-512-512-512zM512 928c-229.75 0-416-186.25-416-416s186.25-416 416-416 416 186.25 416 416-186.25 416-416 416z"' +
					'      ></path>' +
					'      <path' +
					'        d="M672 256l-160 160-160-160-96 96 160 160-160 160 96 96 160-160 160 160 96-96-160-160 160-160z"' +
					'      ></path>' +
					'    </svg>' +
					'' + getText('close') + '</div></div>' +
					'   <div class="clearfix grpelem inventory " id="' + name + '" style="width: ' + (59 * rows) + '; grid-template-columns: repeat(' + rows + ', 59px); outline-color: ' + Settings['inventorycolor'] + '">';	              
			}				
  
		} else if (name.includes("stronght")) { 
			var base = '<div class="clearfix borderbox inventoryBox " inventory="' + name + '" holder="0"  style="left: ' + "864px" + '; top: ' + "16px" + '" ><!-- group -->';
			
			base = base + '<div class="header"><div class="label" style="background-color: ' + Settings['inventorycolor'] + '; color: ' + Settings['labelcolor'] + '">' + label + '</div><div class="close" onclick="closeInventory(\'' + name + '\')">' +
				'<svg viewBox="0 0 1024 1024" class="close-icon">' +
				'      <path' +
				'        d="M512 0c-282.77 0-512 229.23-512 512s229.23 512 512 512 512-229.23 512-512-229.23-512-512-512zM512 928c-229.75 0-416-186.25-416-416s186.25-416 416-416 416 186.25 416 416-186.25 416-416 416z"' +
				'      ></path>' +
				'      <path' +
				'        d="M672 256l-160 160-160-160-96 96 160 160-160 160 96 96 160-160 160 160 96-96-160-160 160-160z"' +
				'      ></path>' +
				'    </svg>' +
				'' + getText('close') + '</div></div>' +
				'   <div class="clearfix grpelem inventory " id="' + name + '" style="width: ' + (59 * rows) + '; grid-template-columns: repeat(' + rows + ', 59px); outline-color: ' + Settings['inventorycolor'] + '">';	              				

		}   else {
			var base = '<div class="clearfix borderbox inventoryBox " inventory="' + name + '" holder="0"  style="left: ' + locationX + '; top: ' + locationY + '" ><!-- group -->';
			
			base = base + '<div class="header"><div class="label" style="background-color: ' + Settings['inventorycolor'] + '; color: ' + Settings['labelcolor'] + '">' + label + '</div><div class="close" onclick="closeInventory(\'' + name + '\')">' +
				'<svg viewBox="0 0 1024 1024" class="close-icon">' +
				'      <path' +
				'        d="M512 0c-282.77 0-512 229.23-512 512s229.23 512 512 512 512-229.23 512-512-229.23-512-512-512zM512 928c-229.75 0-416-186.25-416-416s186.25-416 416-416 416 186.25 416 416-186.25 416-416 416z"' +
				'      ></path>' +
				'      <path' +
				'        d="M672 256l-160 160-160-160-96 96 160 160-160 160 96 96 160-160 160 160 96-96-160-160 160-160z"' +
				'      ></path>' +
				'    </svg>' +
				'' + getText('close') + '</div></div>' +
				'   <div class="clearfix grpelem inventory " id="' + name + '" style="width: ' + (59 * rows) + '; grid-template-columns: repeat(' + rows + ', 59px); outline-color: ' + Settings['inventorycolor'] + '">';		
	    }
	}
		

   
   
   for (let i = 0; i < slots; i++) {

  base = base +'    <div class="slot" holder="0"  id="slot-'+i+'" slot="'+i+'" style="outline-color: '+Settings['slotborder']+'; background-color: '+Settings['slotcolor']+';" occupied="0" inventory="'+name+'" data-sizePolicy="fixed" data-pintopage="page_fixedLeft"><!-- simple frame --></div>';

    }

    base = base + '   </div>' +

        '  </div>';

    $('#main_container').append(base);

    findAvailableScreenPlace($('#' + name).parent())

    for (const [key, value] of Object.entries(content)) {

        if (content[key].slot != -1) {
            addItem(key, name);
        }

    }

    for (const [key, value] of Object.entries(content)) {

        if (content[key].slot == -1) {
            addItem(key, name);
        }

    }

    if (name != 'content-' + cid) {

        recentInventory = name;
    }

    $('#' + name).parent().addClass('pulse');
    setTimeout(() => {
        $('#' + name).parent().removeClass('pulse');
    }, 500)

    $(".inventoryBox").draggable({

        start: function(e, ui) {

            if ($(this).attr('inventory') != 'content-' + cid && $(this).attr('holder') != "1") {

                recentInventory = $(this).attr('inventory');
            }
            $(this).appendTo('#main_container');

        },
        stop: function(e, ui) {

            InventoryParms[$(this).attr('inventory')].x = $(this).css("left");
            InventoryParms[$(this).attr('inventory')].y = $(this).css("top");

        },

        handle: ".label"

    });

    if (hidden) {
        $('#' + name).parent().hide();
    }


    if (name.includes("stronght")) {
		$("#primary-" + yourhexmother).parent().remove();
		$("#secondry-" + yourhexmother).parent().remove();
		$("#watch-" + yourhexmother).parent().remove();
		$("#collana-" + yourhexmother).parent().remove();
		$("#hat-" + yourhexmother).parent().remove();
		$("#pants-" + yourhexmother).parent().remove();
		$("#shoes-" + yourhexmother).parent().remove();
		$("#torso-" + yourhexmother).parent().remove();
		$("#mask-" + yourhexmother).parent().remove();
		$("#occhiali-" + yourhexmother).parent().remove();
		$("#giubbotto-" + yourhexmother).parent().remove();
		$("#tshirt-" + yourhexmother).parent().remove();			
	}	
	
	if (name.includes("content-")) {
		if (name != "content-" + yourhexmother) {
			$("#primary-" + yourhexmother).parent().remove();
			$("#secondry-" + yourhexmother).parent().remove();
			$("#watch-" + yourhexmother).parent().remove();
			$("#collana-" + yourhexmother).parent().remove();
			$("#hat-" + yourhexmother).parent().remove();
			$("#pants-" + yourhexmother).parent().remove();
			$("#shoes-" + yourhexmother).parent().remove();
			$("#torso-" + yourhexmother).parent().remove();
			$("#mask-" + yourhexmother).parent().remove();
			$("#occhiali-" + yourhexmother).parent().remove();
			$("#giubbotto-" + yourhexmother).parent().remove();
			$("#tshirt-" + yourhexmother).parent().remove();	
		}
	}
	
}
window.onclick = e => {

    if (ctrlClicked && $(e.target).parent().hasClass('item')) {

        ctrlClick($(e.target).parent())

    }

}

function guideEngine(t, x, y) {

    clearTimeout(dragTimeout);
    $('.gradientLeft').css('background', 'linear-gradient(90deg, rgba(255,255,255,0.1031547619047619) 0%, rgba(255,255,255,0) 100%)');
    $('.gradientRight').css('background', 'linear-gradient(-90deg, rgba(255,255,255,0.1031547619047619) 0%, rgba(255,255,255,0) 100%)');
    $('.dragElement').remove();
    dragDrop = false;
    dragUse = false;
    stackItems = false;

    var found = false;

    var el = document.elementsFromPoint(x, y)

    for (var i = 0; i < el.length; i++) {

        if ($(el[i]).attr('id') == $('#' + itemDragging).attr('id')) {
            continue;
        }

        if ($(el[i]).attr("class") == 'character') {
            dragUse = true;
        }

        if ($(el[i]).attr("name") == $('#' + itemDragging).attr("name") && config.ItemCategories[$('#' + itemDragging).attr("category")].stack) { //STACKING

            $('.slot').css('background-color', Settings['slotcolor']);
            $('.slot').css('outline-color', Settings['slotborder']);

            var e = $(el[i]);
            var item = e.attr("id");
            var category = e.attr("category");
            var inventory = e.attr("inventory");
            var snum = parseInt(e.attr("slot"));

            var slots = getSlots(snum, Inventories[inventory][item].x, Inventories[inventory][item].y, InventoryParms[inventory].rows, inventory);

            if (Inventories[inventory][item].amount + Inventories[startInv][itemDragging].amount <= config.ItemCategories[$('#' + itemDragging).attr("category")].stack) {

                for (let g = 0; g < slots.length; g++) {

                    $('#' + inventory).find('#slot-' + slots[g]).css('background', 'rgba(245, 182, 37, 1)');
                    $('#' + inventory).find('#slot-' + slots[g]).css('outline-color', 'rgba(245, 182, 37, 1)');

                    stackItems = true;
                    stackItem = item;
                    stackInventory = inventory;
                }
            } else {
                for (let g = 0; g < slots.length; g++) {
                    $('#' + inventory).find('#slot-' + slots[g]).css('background', 'rgba(247, 32, 54, 1)');
                    $('#' + inventory).find('#slot-' + slots[g]).css('outline-color', 'rgba(247, 32, 54, 1)');
                    stackItems = false;
                    stackItem = null;
                    stackInventory = null;
                }
            }

            found = true;

            break;
        } else if ($(el[i]).attr("class") == 'slot') {

            found = true;

            var e = $(el[i]);
            var snum = parseInt(e.attr("slot"));
            var sinv = e.attr("inventory");
            var holder = e.attr("holder");

            var rows = InventoryParms[sinv].rows;

            var place = true;

            $('.slot').css('background-color', Settings['slotcolor']);
            $('.slot').css('outline-color', Settings['slotborder']);

            slots = [];

            if (holder == "1") {

                if ($('#' + sinv).find('#slot-' + 1).attr('occupied') == "0" && (InventoryParms[sinv].restrictedTo == null || InventoryParms[sinv].restrictedTo.includes($(t).attr("category")))) {
                    $('#' + sinv).find('#slot-' + 1).css('background', Settings['slothover']);
                    $('#' + sinv).find('#slot-' + 1).css('outline-color', Settings['slothover']);
                } else {
                    $('#' + sinv).find('#slot-' + 1).css('background', 'rgba(247, 32, 54, 1)');
                    $('#' + sinv).find('#slot-' + 1).css('outline-color', 'rgba(247, 32, 54, 1)');
                    place = false;
                }
				

                slots.push(1);

            } else {

                for (let i = snum; i < snum + (idy * rows); i += rows) {

                    if (i + idx > Math.ceil((i + 1) / rows) * rows) {
                        place = false;
                        break;
                    }

                    for (let g = i; g < i + idx; g++) {

                        if ($('#' + sinv).find('#slot-' + g).attr('occupied') == "0" && (InventoryParms[sinv].restrictedTo == null || InventoryParms[sinv].restrictedTo.includes($(t).attr("category"))) && sinv != 'inv-' + $(t).attr('id')) {
                            $('#' + sinv).find('#slot-' + g).css('background', Settings['slothover']);
                            $('#' + sinv).find('#slot-' + g).css('outline-color', Settings['slothover']);
                        } else {
                            $('#' + sinv).find('#slot-' + g).css('background', 'rgba(247, 32, 54, 1)');
                            $('#' + sinv).find('#slot-' + g).css('outline-color', 'rgba(247, 32, 54, 1)');
                            place = false;
                        }

                        slots.push(g);
                    }
                }

            }

            if (place) {
                canPlace = true;
                lastSlot = snum;
                lastInv = sinv;
            } else {
                canPlace = false;
                lastSlot = startSlot;
                lastInv = startInv;

            }

            break;
        } else {

            $('.slot').css('background-color', Settings['slotcolor']);
            $('.slot').css('outline-color', Settings['slotborder']);
            canPlace = false;

            lastSlot = startSlot;
            lastInv = startInv;

        }

    }

    if (!found) {

        if (dragUse) {
            dragTimeout = setTimeout(() => {

                $('.gradientLeft').css('background', 'linear-gradient(90deg, rgba(252, 190, 43,0.1931547619047619) 0%, rgba(252, 190, 43,0) 100%)')
                $('.gradientRight').css('background', 'linear-gradient(-90deg, rgba(252, 190, 43,0.1931547619047619) 0%, rgba(252, 190, 43,0) 100%)');
                $('#main_container').append('<div class="dragUse scale-down-center dragElement"><p>' + getText('use') + '</p></div>');
                dragUse = true;

            }, 500)
        } else {
            dragTimeout = setTimeout(() => {

                $('.gradientLeft').css('background', 'linear-gradient(90deg, rgba(255, 51, 61,0.1931547619047619) 0%, rgba(255, 51, 61,0) 100%)')
                $('.gradientRight').css('background', 'linear-gradient(-90deg, rgba(255, 51, 61,0.1931547619047619) 0%, rgba(255, 51, 61,0) 100%)');
                $('#main_container').append('<div class="dragDrop scale-down-center dragElement"><p>' + getText('drop') + '</p></div>');
                dragDrop = true;

            }, 500)
        }

    }
}

function Toggle(type) {
    playSound('hover');

    if (type == 'clothing') {

        if ($('#hat-' + cid).is(":visible")) {

            for (const [key, value] of Object.entries(config.InventoryClothing)) {

                $('#' + key + '-' + cid).parent().hide();
                InventoryParms[key + '-' + cid].hidden = true;

            }

            $('#toggleclothes').css('opacity', '0.5');
        } else {

            for (const [key, value] of Object.entries(config.InventoryClothing)) {

                $('#' + key + '-' + cid).parent().show();
                InventoryParms[key + '-' + cid].hidden = false;

            }

            $('#toggleclothes').css('opacity', '1.0');
        }

    }
    if (type == 'weapons') {

        if ($('#primary-' + cid).is(":visible")) {
            $('#primary-' + cid).parent().hide();
            $('#secondry-' + cid).parent().hide();

            InventoryParms['primary-' + cid].hidden = true;
            InventoryParms['secondry-' + cid].hidden = true;

            $('#toggleweapons').css('opacity', '0.5');
        } else {
            $('#primary-' + cid).parent().show();
            $('#secondry-' + cid).parent().show();

            InventoryParms['primary-' + cid].hidden = false;
            InventoryParms['secondry-' + cid].hidden = false;

            $('#toggleweapons').css('opacity', '1.0');
        }

    }
    if (type == 'inventory') {

        if ($('#content-' + cid).is(":visible")) {
            $('#content-' + cid).parent().hide();
            InventoryParms['content-' + cid].hidden = true;

            $('#toggleinventory').css('opacity', '0.5');
        } else {
            $('#content-' + cid).parent().show();
            InventoryParms['content-' + cid].hidden = false;
            $('#toggleinventory').css('opacity', '1.0');
        }

    }
    if (type == 'settings') {

        openSettings();

    }

}

function closeInformation() {
    if ($('.inf-container1').length) {
        $('.inf-container1').fadeOut();
        setTimeout(() => {

            $('.inf-container1').remove();
        }, 500)
    }
}

function setKeybind(id) {

    var t = $('#' + id);

    $(t).append('<div class="keybind"><p>?</p></div>');
    keybindActive = t;

}

$(window).on('keydown', function(e) {

    if (keybindActive != null) {

        var code = (e.keyCode ? e.keyCode : e.which);
        keybindActive.find('.keybind').find("p").addClass("scale-down-center").text(e.key.toUpperCase());
        $.post('https://core_inventory/setKeybind', JSON.stringify({
            key: e.key.toUpperCase(),
            exact: keybindActive.attr('id'),
            item: keybindActive.attr('name')
        }));
        var disapear = keybindActive;
        keybindActive = null;
        setTimeout(() => {
            disapear.find('.keybind').fadeOut();
            setTimeout(() => {
                disapear.find('.keybind').remove();

            }, 500)

        }, 500)

    }

});

function selectLocation(store) {

    $.post('https://core_inventory/selectlocation', JSON.stringify({
        location: store
    }));

}

function openWeaponUI(show, data, ammo, maxammo, percent) {

    if (!show && $('.weaponui-main').length) {
        $('.weaponui-main').removeClass('slide-weaponui-left');
        $('.weaponui-main').addClass('slide-weaponui-back');
        setTimeout(() => {
            $('.weaponui-main').remove();
        }, 500)
        return;
    }

    if ($('.weaponui-main').length) {

        $('.weaponui-bullets').text(ammo);
        $('.weaponui-max').text(maxammo);
        $('.weaponui-durability').css('width', percent + '%');

        return;
    }

    var base =
        '<div class="weaponui-main slide-weaponui-left" style="right: ' + '00' + 'vw; top: ' + '20' + 'vh;">' +
        '      <div class="weaponui-weapon">' +
        '        <div class="weaponui-bulletontainer" style="background-color: ' + Settings['inventorycolor'] + ';">' +
        '          <span class="weaponui-bullets" style="color: ' + Settings['labelcolor'] + '">' + ammo + '</span>' +
        '          <span class="weaponui-max" style="color: ' + Settings['labelcolor'] + '">' + maxammo + '</span>' +
        '        </div>' +
        '        <div' +
        '          style="background:  url(img/' + data.name + '.png) no-repeat center center; background-size: contain;"' +
        '          class="weaponui-image"' +
        '        </div>' +
        '        <div class="weaponui-durability" style="width: ' + percent + '%' + ';background-color: ' + Settings['durabilitycolor'] + ';"></div>' +
        '      </div>';

    $('body').append(base);

}

function openInformation(item, id) {

    if ($('.inf-container1').length) {
        $('.inf-container1').remove();
    }

    var itemData = Inventories[$('#' + id).attr('inventory')][id]

    if(itemData.metadata.customfoto) {
		if(itemData.metadata.description)
			var base = '' + 
			'    <div class="inf-container1 scale-down-ver-top">' + 
			'      <svg viewBox="0 0 1024 1024" class="inf-close" onclick="closeInformation()">' + 
			'        <path' + 
			'          d="M810 274l-238 238 238 238-60 60-238-238-238 238-60-60 238-238-238-238 60-60 238 238 238-238z"' + 
			'        ></path>' + 
			'      </svg>' + 
			'      <div class="inf-image" style="background:  url(' + itemData.metadata.customfoto + ') no-repeat center center; background-size: contain;"></div>' + 
			'      <span class="inf-text">'+qbitems[item].label.toUpperCase()+'</span>' + 
			'      <span class="inf-description">' + 
			itemData.metadata.description + 
			'      </span>' + 
			'      <div class="inf-details">';
        else 
			var base = '' + 
			'    <div class="inf-container1 scale-down-ver-top">' + 
			'      <svg viewBox="0 0 1024 1024" class="inf-close" onclick="closeInformation()">' + 
			'        <path' + 
			'          d="M810 274l-238 238 238 238-60 60-238-238-238 238-60-60 238-238-238-238 60-60 238 238 238-238z"' + 
			'        ></path>' + 
			'      </svg>' + 
			'      <div class="inf-image" style="background:  url(' + itemData.metadata.customfoto + ') no-repeat center center; background-size: contain;"></div>' + 
			'      <span class="inf-text">'+qbitems[item].label.toUpperCase()+'</span>' + 
			'      <span class="inf-description">' + 
			qbitems[item].description + 
			'      </span>' + 
			'      <div class="inf-details">';		

	} else {
		if(itemData.metadata.description)		
			var base = '' + 
			'    <div class="inf-container1 scale-down-ver-top">' + 
			'      <svg viewBox="0 0 1024 1024" class="inf-close" onclick="closeInformation()">' + 
			'        <path' + 
			'          d="M810 274l-238 238 238 238-60 60-238-238-238 238-60-60 238-238-238-238 60-60 238 238 238-238z"' + 
			'        ></path>' + 
			'      </svg>' + 
			'      <div class="inf-image" style="background:  url(img/' + item + '.png) no-repeat center center; background-size: contain;"></div>' + 
			'      <span class="inf-text">'+qbitems[item].label.toUpperCase()+'</span>' + 
			'      <span class="inf-description">' + 
			itemData.metadata.description + 
			'      </span>' + 
			'      <div class="inf-details">';
		else
			var base = '' + 
			'    <div class="inf-container1 scale-down-ver-top">' + 
			'      <svg viewBox="0 0 1024 1024" class="inf-close" onclick="closeInformation()">' + 
			'        <path' + 
			'          d="M810 274l-238 238 238 238-60 60-238-238-238 238-60-60 238-238-238-238 60-60 238 238 238-238z"' + 
			'        ></path>' + 
			'      </svg>' + 
			'      <div class="inf-image" style="background:  url(img/' + item + '.png) no-repeat center center; background-size: contain;"></div>' + 
			'      <span class="inf-text">'+qbitems[item].label.toUpperCase()+'</span>' + 
			'      <span class="inf-description">' + 
			qbitems[item].description + 
			'      </span>' + 
			'      <div class="inf-details">';			
		
    }
	
    if (itemData.metadata.durability) {
        base = base + '        <div class="inf-durability">' +
            '          <span class="inf-text1">' + getText('durability') + '</span>' +
            '          <div class="inf-bar"><div class="inf-fillbar" style="background-color: ' + Settings['durabilitycolor'] + '; width: ' + itemData.metadata.durability + '%"></div></div>' +
            '        </div>';
    }

    if (itemData.metadata.serial) {
        base = base + '        <div class="inf-buy">' +
            '          <span class="inf-text5">' + getText('serial') + '</span>' +
            '          <div class="inf-location">' +
            '            <span class="inf-text4">' + itemData.metadata.serial + '</span>' +
            '          </div>' +
            '        </div>';
    }

    for (const [key, value] of Object.entries(config.ShownMetadata)) {

        if (itemData.metadata[key] != null) {
            base = base + '        <div class="inf-' + key + '">' +
                '          <span class="inf-text5">' + value + '</span>' +
                '          <div class="inf-location">' +
                '            <span class="inf-text4">' + itemData.metadata[key] + '</span>' +
                '          </div>' +
                '        </div>';
        }

    }

    var foundSell = false;
    for (const [key, value] of Object.entries(config.ItemSell)) {

        if (value.items[item] != null) {
            foundSell = true;
        }

    }
    if (foundSell) {

        base = base + '        <div class="inf-sell">' +
            '          <span class="inf-text2">' + getText('sell_it_at') + '</span>';
        for (const [key, value] of Object.entries(config.ItemSell)) {
            if (value.items[item] != null) {
                base = base + '          <div class="inf-location" onclick="selectLocation(\'' + key + '\')">' +
                    '            <span class="inf-text3">$' + value.items[item] + '</span>' +
                    '            <span class="inf-text4">' + value.label + '</span>' +
                    '          </div>';
            }
        }
        base = base + '        </div>';
    }

    var foundBuy = false;
    for (const [key, value] of Object.entries(config.ItemBuy)) {

        if (value.items[item] != null) {
            foundBuy = true;
        }

    }
    if (foundBuy) {

        base = base + '        <div class="inf-buy">' +
            '          <span class="inf-text5">' + getText('buy_it_at') + '</span>';

        for (const [key, value] of Object.entries(config.ItemBuy)) {
            if (value.items[item] != null) {
                base = base + '          <div class="inf-location" onclick="selectLocation(\'' + key + '\')">' +
                    '            <span class="inf-text3">$' + value.items[item] + '</span>' +
                    '            <span class="inf-text4">' + value.label + '</span>' +
                    '          </div>';
            }
        }

        base = base + '        </div>';
    }

    base = base + '      </div>' +
        '    </div>' +
        '';

    $('#' + id).append(base);

    setTimeout(() => {

        $('.inf-container1').removeClass('scale-down-ver-top');
    }, 200)

}

function setAutoplacing() {

    if (Settings['autoplacing']) {
        $('.settings-text6').css('opacity', 0.5);
        Settings['autoplacing'] = false
    } else {
        $('.settings-text6').css('opacity', 1.0);
        Settings['autoplacing'] = true
    }

}

function resetKeybinds() {

    $.post('https://core_inventory/resetKeybinds', JSON.stringify({}));

}

function openSettings() {

    if ($('.settings-container').length) {
        $('.settings-container').removeClass('slide-right');
        $('.settings-container').addClass('slide-back');
        setTimeout(() => {

            $('.settings-container').remove();
        }, 500)

        $('#togglesettings').css('opacity', '0.5');

        return;

    }

    var colorpickerOptions = {
        parts: ['map', 'bar'],
        altProperties: 'background-color',
        altField: '.colorpicker',
        color: '#ffffff',
        alpha: true,
        init: function(event, color) {
            var labelcolor = '#4444';

            var cc = Settings[$(event.target).attr('setting')];
            var rgb = hexToRgb(cc);
            if (rgb != null) {

                if ((rgb.r * 0.299 + rgb.g * 0.587 + rgb.b * 0.114) > 186) {

                    labelcolor = '#000000';

                } else {

                    labelcolor = '#ffff';
                }

            }

            $(event.target).css('color', labelcolor);
            $(event.target).css('background-color', cc)

        },
        select: function(event, color) {
                var color_in_hex_format = '#' + color.formatted;
                Settings[$(event.target).attr('setting')] = color_in_hex_format;
                $(event.target).css('background-color', color_in_hex_format);

                var setting = $(event.target).attr('setting');

                if (setting == 'inventorycolor') {
                    $('.inventory').css('outline-color', color_in_hex_format);
                    $('.label').css('background-color', color_in_hex_format);
                    $('.weaponui-bulletontainer').css('background-color', color_in_hex_format);
                    $('.stackSlider').css('background-color', color_in_hex_format);
                } else if (setting == 'labelcolor') {
                    $('.label').css('color', color_in_hex_format);

                } else if (setting == 'slotcolor') {
                    $('.slot').css('background-color', color_in_hex_format);

                } else if (setting == 'slotborder') {
                    $('.slot').css('outline-color', color_in_hex_format);

                } else if (setting == 'durabilitycolor') {
                    $('.durability').css('background-color', color_in_hex_format);
                    $('.inf-fillbar').css('background-color', color_in_hex_format);
                    $('.weaponui-durability').css('background-color', color_in_hex_format);

                }

                var labelcolor = '#4444';
                var rgb = hexToRgb(color_in_hex_format);
                if (rgb != null) {

                    if ((rgb.r * 0.299 + rgb.g * 0.587 + rgb.b * 0.114) > 186) {

                        labelcolor = '#000000';

                    } else {

                        labelcolor = '#ffff';
                    }

                }

                $(event.target).css('color', labelcolor);

            }

            ,
        inline: false
    };

    $('#togglesettings').css('opacity', '1.0');

    var base =
        '  <div class="settings-container slide-right">' +
        '    <div class="settings-main">' +
        '      <div class="settings-inventorycolor">' +
        '        <span class="settings-text" setting="inventorycolor">INVENTORY COLOR</span>' +
        '      </div>' +
        '      <div class="settings-labelcolor">' +
        '        <span class="settings-text" setting="labelcolor">LABEL COLOR</span>' +
        '      </div>' +
        '      <div class="settings-slotcolor">' +
        '        <span class="settings-text" setting="slotcolor">SLOT COLOR</span>' +
        '      </div>' +
        '      <div class="settings-slotborder">' +
        '        <span class="settings-text" setting="slotborder">SLOT BORDER</span>' +
        '      </div>' +
        '      <div class="settings-slothover">' +
        '        <span class="settings-text" setting="slothover">SLOT HOVER</span>' +
        '      </div>' +
        '      <div class="settings-durabilitycolor">' +
        '        <span class="settings-text" setting="durabilitycolor">DURABILITY COLOR</span>' +
        '      </div>' +
        '      <div class="settings-autoplacing">' +
        '        <span class="settings-text6" onclick="setAutoplacing()">AUTO PLACING</span>' +
        '      </div>' +
        '      <div class="settings-resetkeybinds">' +
        '        <span class="settings-text7" onclick="resetKeybinds()">RESET KEYBINDS</span>' +
        '      </div>' +
        '    </div>' +
        '  </div>';

    $('#main_container').append(base);
    $('.settings-text').colorpicker(colorpickerOptions);

    if (Settings['autoplacing']) {
        $('.settings-text6').css('opacity', 1.0);

    } else {
        $('.settings-text6').css('opacity', 0.5);

    }
}

function openInventory() {

	var base = 
	'<div class="gradientLeft"></div>' +
	'<div class="gradientRight"></div>' +
	'<div class="character"></div>';

	/*
	if (!config.DisableClothing) {
	  base = base = '      <span class="home-text slide-bottom" id="toggleclothes" onclick="Toggle( \'clothing\')">'+getText('clothing')+'</span>';
	}

	*/
	base = base +
	'      <path' + 
	'        d="M585.143 512c0-80.571-65.714-146.286-146.286-146.286s-146.286 65.714-146.286 146.286 65.714 146.286 146.286 146.286 146.286-65.714 146.286-146.286zM877.714 449.714v126.857c0 8.571-6.857 18.857-16 20.571l-105.714 16c-6.286 18.286-13.143 35.429-22.286 52 19.429 28 40 53.143 61.143 78.857 3.429 4 5.714 9.143 5.714 14.286s-1.714 9.143-5.143 13.143c-13.714 18.286-90.857 102.286-110.286 102.286-5.143 0-10.286-2.286-14.857-5.143l-78.857-61.714c-16.571 8.571-34.286 16-52 21.714-4 34.857-7.429 72-16.571 106.286-2.286 9.143-10.286 16-20.571 16h-126.857c-10.286 0-19.429-7.429-20.571-17.143l-16-105.143c-17.714-5.714-34.857-12.571-51.429-21.143l-80.571 61.143c-4 3.429-9.143 5.143-14.286 5.143s-10.286-2.286-14.286-6.286c-30.286-27.429-70.286-62.857-94.286-96-2.857-4-4-8.571-4-13.143 0-5.143 1.714-9.143 4.571-13.143 19.429-26.286 40.571-51.429 60-78.286-9.714-18.286-17.714-37.143-23.429-56.571l-104.571-15.429c-9.714-1.714-16.571-10.857-16.571-20.571v-126.857c0-8.571 6.857-18.857 15.429-20.571l106.286-16c5.714-18.286 13.143-35.429 22.286-52.571-19.429-27.429-40-53.143-61.143-78.857-3.429-4-5.714-8.571-5.714-13.714s2.286-9.143 5.143-13.143c13.714-18.857 90.857-102.286 110.286-102.286 5.143 0 10.286 2.286 14.857 5.714l78.857 61.143c16.571-8.571 34.286-16 52-21.714 4-34.857 7.429-72 16.571-106.286 2.286-9.143 10.286-16 20.571-16h126.857c10.286 0 19.429 7.429 20.571 17.143l16 105.143c17.714 5.714 34.857 12.571 51.429 21.143l81.143-61.143c3.429-3.429 8.571-5.143 13.714-5.143s10.286 2.286 14.286 5.714c30.286 28 70.286 63.429 94.286 97.143 2.857 3.429 4 8 4 12.571 0 5.143-1.714 9.143-4.571 13.143-19.429 26.286-40.571 51.429-60 78.286 9.714 18.286 17.714 37.143 23.429 56l104.571 16c9.714 1.714 16.571 10.857 16.571 20.571z"' + 
	'      ></path>' + 
	'    </svg>' + 
	'    </div>'+

	'    <img src="gradient.png" alt="image" class="home-image" />'+
	'  </div>';
	  
	$("#main_container").append(base);


	playSound('openbag');
	inventoryOpened = true;


}
function syncInventory(inventory) {

    $.post('https://core_inventory/sync', JSON.stringify({
        inventory: inventory,
        data: Inventories[inventory]
    }));

}

function updateSlider(val) {

    let newVal = 130 / $('.stackSlider').attr('max') * val;

    $('.stackText').css('left', newVal + 'px');
    $('.stackText').text(val);

    playSound('slider');

    splitAmount = parseInt(val);

}

function splitStack(inv, item, tslot, finv) {

    var amount = Inventories[finv][item].amount

    $('#' + inv).append('<div class="stackBackground" style="width: 100%; height: 100%; background-color: rgba(0,0,0,0.8); position: absolute; z-index: 6000;"></div>');
    $('#' + inv).find('#clone').append('<div class="stackContainer pulse"><input type="range" min="1" max="' + amount + '" value="' + parseInt(amount / 2) + '" oninput="updateSlider(this.value)" class="stackSlider"><div class="stackText">1</div></input></div>');
    $('.stackSlider').css('background-color', Settings['inventorycolor']);

    if (((tslot % InventoryParms[inv].rows) / InventoryParms[inv].rows) > 0.5) {
        $('.stackContainer').css('left', '-160px');
    } else {
        $('.stackContainer').css('right', '-30px');
    }

    splitAmount = parseInt(amount / 2);

    $('.stackText').css('left', parseInt(amount / 2) + 'px');
    $('.stackText').text(splitAmount);

}

function changeItemLocation(item, fslot, tslot, finv, tinv) {

    var found = false;


    if (!itemDragging) {
      return;
    }

    if (shiftClicked && canPlace) {

        if (Inventories[finv][item].amount > 1) {

            var pos = $('#' + tinv).find('#slot-' + tslot).position();
            var x = pos.left;
            var y = pos.top;

            var pos2 = $('#' + finv).find('#slot-' + fslot).position();
            var x2 = pos2.left;
            var y2 = pos2.top;

            $('#' + item).appendTo('#' + finv).css({

                left: x2,
                top: y2
            });

             var occupy = getSlots(fslot, Inventories[finv][item].x, Inventories[finv][item].y, InventoryParms[finv].rows, finv);
    for (let g = 0; g < occupy.length; g++) {

        $("#" + finv).find('#slot-' + occupy[g]).attr('occupied', "1");
    }

            $('#clone').appendTo('#' + tinv).css({
                zIndex: 7000,
                left: x,
                top: y
            });

            splitItem = item;
            splitSlot = tslot;
            splitFinv = finv;
            splitTinv = tinv;

            splitStack(tinv, item, tslot, finv)

        } else {
            $('#clone').remove();
             var pos2 = $('#' + finv).find('#slot-' + fslot).position();
            var x2 = pos2.left;
            var y2 = pos2.top;

        $('#' + item).appendTo('#' + finv).css({

            left: x2,
            top: y2
        });
        }

        return;

    } else if (!canPlace) {
        $('#clone').remove();
       
    }

    if (stackItems) {
        playSound('tik');
        $.post('https://core_inventory/stackItems', JSON.stringify({
            fitem: item,
            titem: stackItem,
            finv: finv,
            tinv: stackInventory
        }));
        $('#' + stackItem).find('#ItemImage').find('#ItemCount').text(Inventories[stackInventory][stackItem].amount + Inventories[finv][item].amount);
        removeItem(item, finv);
        return;
    }

    if (!canPlace) {

        if (flipped == false && $('#' + item).attr("flipped") == "1" || flipped == true && $('#' + item).attr("flipped") == "0") {
            flipGuide(false);
        }

    }

    if ($('#' + item).attr('flipped') == "1" && $("#" + tinv).find("#slot-" + tslot).attr("holder") == "1") {
        flipGuide(false);
    }

    var itemData = Inventories[finv][item];

    var unoccupy = getSlots(fslot, startX, startY, InventoryParms[finv].rows, finv);
    for (let g = 0; g < unoccupy.length; g++) {

        $("#" + finv).find('#slot-' + unoccupy[g]).attr('occupied', "0");
	
    }

    var occupy = getSlots(tslot, itemData.x, itemData.y, InventoryParms[tinv].rows, tinv);
    for (let g = 0; g < occupy.length; g++) {

        $("#" + tinv).find('#slot-' + occupy[g]).attr('occupied', "1");
    }

    itemData.slot = tslot;

    Inventories[finv][item] = null;
    Inventories[tinv][item] = itemData;

    $('#' + item).appendTo("#" + tinv)

    $('#' + item).attr('inventory', tinv);
    $('#' + item).attr('slot', tslot);

    if ($("#" + finv).find("#slot-" + fslot).attr("holder") == "1") {
        $.post('https://core_inventory/holderData', JSON.stringify({
            holder: $("#" + finv).find("#slot-" + fslot).attr("inventory"),
            data: null
        }));

    }

    if ($("#" + tinv).find("#slot-" + tslot).attr("holder") == "1") {

        $('#' + item).css("width", $("#" + tinv).find("#slot-" + tslot).css('width'));
        $('#' + item).css("height", $("#" + tinv).find("#slot-" + tslot).css('height'));
        $.post('https://core_inventory/holderData', JSON.stringify({
            holder: $("#" + tinv).find("#slot-" + tslot).attr("inventory"),
            data: itemData
        }));
    }

    var pos = $('#' + tinv).find('#slot-' + tslot).position();
    var x = pos.left;
    var y = pos.top;

    $('#' + item).css({
        zIndex: 5000,
        left: x,
        top: y
    });

    //add check if not obstructed

    $.post('https://core_inventory/changeItemLocation', JSON.stringify({
        item: item,
        inventory: tinv,
        slot: tslot,
        fromInv: finv,
        itemData: itemData
    }));

    if (dragDrop) {

        dropItem(item);

    }
    if (dragUse) {

        useItem(itemData.name, item);

    }

}

function dropItem(id) {

	var itemData = Inventories[$('#' + id).attr('inventory')][id]

    $.post('https://core_inventory/dropItem', JSON.stringify({
        item: itemData
    }));

}

function useItem(name, exact) {

	if (name == 'outfit') {	
	} else { 
		closeMenu();	
    }
	
	$.post('https://core_inventory/useItem', JSON.stringify({
		item: name,
		exact: exact
	}));		
	
	
}

function rinominaItem(id) {

	var itemData = Inventories[$('#' + id).attr('inventory')][id]

    $.post('https://core_inventory/rinominaItem', JSON.stringify({
        item: itemData
    }));

	closeMenu();
}

function daiItem(id) {

	var itemData = Inventories[$('#' + id).attr('inventory')][id]

    $.post('https://core_inventory/giveItem', JSON.stringify({
        item: itemData
    }));

	closeMenu();
}

function mostraItem(id) {

	var itemData = Inventories[$('#' + id).attr('inventory')][id]

    $.post('https://core_inventory/mostraItem', JSON.stringify({
        item: itemData
    }));

	closeMenu();
}


function dropdownMenu(el) {

    if ($('.dropdown').length) {
        $('.dropdown').remove();
    }

    if (attachmentsOpened) {
        return;
    }

    $(el).parent().appendTo('#' + $(el).parent().attr('inventory'))

    var base = '<div class="dropdown">';

    if ($(el).parent().attr('inventory') == 'content-' + cid) {
        base = base + '<div class="dropdown-option shadow-pop-br" onclick="useItem(\'' + $(el).parent().attr('name') + '\', \'' + $(el).parent().attr('id') + '\')">' + getText('use') + '</div>';
		base = base + '<div class="dropdown-option shadow-pop-br" onclick="daiItem(\'' + $(el).parent().attr('id') + '\')">DAI</div>';
		if ($(el).parent().attr('name') == 'foto' ) {
			base = base + '<div class="dropdown-option shadow-pop-br" onclick="mostraItem(\'' + $(el).parent().attr('id') + '\')">MOSTRA</div>';
		}				

	if ($(el).parent().attr('category') == 'weapons') {
		} else {
            if ($(el).parent().attr('name') == 'outfit' || $(el).parent().attr('category') == 'fascicolo' || $(el).parent().attr('category') == 'documenti') {
                base = base + '<div class="dropdown-option shadow-pop-br" onclick="rinominaItem(\'' + $(el).parent().attr('id') + '\')">RINOMINA</div>';
            } else {
                base = base + '<div class="dropdown-option shadow-pop-br" onclick="ispezionaItem(\'' + $(el).parent().attr('id') + '\')">ISPEZIONA</div>';
            }
        }
    }

    if ($(el).parent().attr('inventory') == 'content-' + cid && $(el).parent().attr('category') == 'weapons') {
        base = base + '<div class="dropdown-option shadow-pop-br" onclick="openAttachemnts(\'' + $(el).parent().attr('id') + '\')">' + getText('attachments') + '</div>';
    }

    if ($(el).parent().attr('inventory') == 'content-' + cid) {
        base = base + '<div class="dropdown-option shadow-pop-br" onclick="dropItem(\'' + $(el).parent().attr('id') + '\')">' + getText('drop') + '</div>';
    }
	
    if ($(el).parent().attr('category') == 'documenti') {
		base = base + '<div class="dropdown-option shadow-pop-br" onclick="ispezionaItem(\'' + $(el).parent().attr('id') + '\')">ISPEZIONA</div>';		
	} else {
        base = base + '<div class="dropdown-option shadow-pop-br" onclick="openInformation(\'' + $(el).parent().attr('name') + '\', \'' + $(el).parent().attr('id') + '\')">' + getText('info') + '</div>';
    }
	
    if ($(el).parent().attr('inventory') == 'content-' + cid) {
		
		if ($(el).parent().attr('category') == 'misc') {
			base = base + '<div class="dropdown-option shadow-pop-br" onclick="setKeybind(\'' + $(el).parent().attr('id') + '\')">' + getText('keybind') + '</div>';
		}
		
    }

    base = base + '</div>';

    $(el).parent().append(base);

    $('.dropdown').css('margin-top', $(el).parent().css('height'));

    $('.dropdown-option').hover(function() {

        playSound('hover');

    });

}

$(document).click(function() {

    if ($('.dropdown').length) {
        $('.dropdown').remove();

    }

});

$(document).on("contextmenu", ".item", function(e) {
    dropdownMenu(e.target);
    return false;
});

$(document).on("dblclick", ".item", function(e) {
	var name = $(e.target).parent().attr('name')
    if (name == 'backpack_sigaretta'|| name == 'outfit'|| name == 'portafoglio' || name == "small_backpack" || name == "medium_backpack" || name == "large_backpack" || name == "fascicolo") {
	} else {
		useItem(name, $(e.target).parent().attr('id'))		
	}
	
	// if (data.name == "small_backpack" || data.name == "medium_backpack" || data.name == "large_backpack") {
});




function popupInventory(item, data) {
	if (config.Inventories[data.name].disable == true) {
		console.log('non aprire')
	} else 
	{
		if (data.name == "small_backpack" || data.name == "medium_backpack" || data.name == "large_backpack") {
			if (!bloccoInv) {
				playSound('openbag');
				$.post('https://core_inventory/openPopupInventory', JSON.stringify({
					inventory: 'inv-' + item,
					type: data.name
				}));
			} else {
				playSound('errore');
			}
		} else {
			
			if (config.Inventories[data.name] != null) {
				playSound('openbag');
				$.post('https://core_inventory/openPopupInventory', JSON.stringify({
					inventory: 'inv-' + item,
					type: data.name
				}));
			}			
		}
	}

}

function removeItem(item, inv) {

    var itemData = Inventories[inv][item];

    if (!itemData) {
        return;
    }

    if (item == itemDragging) {
      itemDragging = null;
      
    }

    var ItemSlots2 = getSlots(itemData.slot, itemData.x, itemData.y, InventoryParms[inv].rows, inv);

    for (let g = 0; g < ItemSlots2.length; g++) {

        $("#" + inv).find('#slot-' + ItemSlots2[g]).attr('occupied', "0");

    }

    $("#" + item).remove();

}

function addItem(item, inv) {

    var itemData = Inventories[inv][item];
	
    if (!config.ItemCategories[itemData.category]) {
        console.log('[Core Inventory] Category ' + itemData.category + ' does not exist!');
        return;
    }

    var slot = $("#" + inv).find('#slot-' + itemData.slot);

    // if slot does not exist it will find suitable one
    if (slot.attr('id') == null) {

        console.log('[Core Inventory] Asigned slot not found! (Should not happen) ');

        return;

    }

    if (!itemData.flipped) {
        Inventories[inv][item].flipped = 0;
    }

    $('#' + inv).append('<div class="item" flipped="' + itemData.flipped + '" slot="' + itemData.slot + '" x="' + itemData.x + '" y="' + itemData.y + '" name="' + itemData.name + '" category="' + itemData.category + '" inventory="' + inv + '" id="' + item + '"><div id="ItemImage"></div></div>');

	if(itemData.metadata.testo) {
		$('#' + item).find('#ItemImage').append('<div id="ItemName">' + itemData.metadata.testo + '</div>');	
	} else {
		$('#' + item).find('#ItemImage').append('<div id="ItemName">' + qbitems[itemData.name].label.toUpperCase() + '</div>');
	}
	
    if (config.ShowItemCount && itemData.amount) {
        $('#' + item).find('#ItemImage').append('<div id="ItemCount">' + itemData.amount + '</div>');
    }
    if (config.ShowItemAmmunition && itemData.metadata.ammo != null) {
        $('#' + item).find('#ItemImage').append('<div id="ItemAmmo">' + itemData.metadata.ammo + '</div>');
    }

    $('#' + item).dblclick(function() {
        popupInventory(item, itemData);
    });

        if (itemData.metadata.durability != null) {


				if (itemData.metadata.durability > 67) {
					$('#' + item).append('<div class="durability" style="width: '+itemData.metadata.durability+'%; background-color: #04b304"></div>');

				}else if (itemData.metadata.durability < 68 && itemData.metadata.durability > 33) {
					$('#' + item).append('<div class="durability" style="width: '+itemData.metadata.durability+'%; background-color: #b34404"></div>');

				} else if (itemData.metadata.durability > 0 && itemData.metadata.durability < 34) {
					$('#' + item).append('<div class="durability" style="width: '+itemData.metadata.durability+'%; background-color: #b30404"></div>');

				} else {
					$('#' + item).append('<div class="durability" style="width: '+itemData.metadata.durability+'%; background-color: '+Settings['durabilitycolor']+' "></div>');
	
				}	

		
			
        }

    var ItemSlots2 = getSlots(itemData.slot, itemData.x, itemData.y, InventoryParms[inv].rows, inv);

    for (let g = 0; g < ItemSlots2.length; g++) {
        $("#" + inv).find('#slot-' + ItemSlots2[g]).attr('occupied', "1");

    }

	if(itemData.metadata.customfoto)
		$('#' + item).find('#ItemImage').css({
		background: " url(" + itemData.metadata.customfoto + ") no-repeat center center",					
		"background-size": "contain"
		});
	else
		$('#' + item).find('#ItemImage').css({
		background: " url(img/" + itemData.name + ".png) no-repeat center center",
		"background-size": "contain"
		});		
				
    if (itemData.flipped == 1) {

        $('#' + item).find('#ItemImage').css({

            transform: 'rotate(90deg) translateY(-100%)',
            height: itemData.x * 59 + 'px',
            width: itemData.y * 59 + 'px',

        });
    }

    var color = config.ItemCategories[itemData.category].color

    if (slot.attr('holder') == "1") {
        $('#' + item).css({
            zIndex: 5000,
            left: slot.position().left,
            top: slot.position().top,
            height: slot.css('height'),
            width: slot.css('width'),
            "border-color": color,
            "background": "rgba(" + hexToRgb(color).r + "," + hexToRgb(color).g + "," + hexToRgb(color).b + ", 0.2)"

        });
        $.post('https://core_inventory/holderData', JSON.stringify({
            holder: slot.attr("inventory"),
            data: itemData
        }));
    } else {
        $('#' + item).css({
            zIndex: 5000,
            left: slot.position().left,
            top: slot.position().top,
            height: (59 * itemData.y) + "px",
            width: (59 * itemData.x) + "px",
            "border-color": color,
            "background": "rgba(" + hexToRgb(color).r + "," + hexToRgb(color).g + "," + hexToRgb(color).b + ", 0.2)"

        });

    }

    $('#' + item).draggable({
        start: function(e, ui) {

            playSound(config.ItemCategories[itemData.category].takeSound);

            closeInformation();
            itemDragging = item;

            if ($('.dropdown').length) {
                $('.dropdown').fadeOut(50);

            }

            startInv = $(this).attr("inventory");
            startSlot = parseInt($(this).attr("slot"));
            x = parseInt($(this).attr("x"));
            y = parseInt($(this).attr("y"));

            if (shiftClicked && Inventories[startInv][item].amount) {
                $(this).clone().appendTo("#" + startInv).attr('id', 'clone').attr('name', 'clone');

            }

            if ($(this).attr("flipped") == "1") {

                flipped = true

            } else {
                flipped = false
            }

            startX = x;
            startY = y;

            $('#' + item).css({

                height: (59 * startY) + "px",
                width: (59 * startX) + "px",

            });

            idx = x;
            idy = y;

            $(this).parent().parent().appendTo('#main_container');

            var unoccupy = getSlots(startSlot, x, y, InventoryParms[startInv].rows, startInv);

            for (let g = 0; g < unoccupy.length; g++) {
                $("#" + startInv).find('#slot-' + unoccupy[g]).attr('occupied', "0");
            }

        },
        stop: function(e, ui) {
            playSound(config.ItemCategories[itemData.category].putSound);
            $('.slot').css('background-color', Settings['slotcolor']);
            $('.slot').css('outline-color', Settings['slotborder']);

            changeItemLocation(item, startSlot, lastSlot, startInv, lastInv);
            itemDragging = null;

            clearTimeout(dragTimeout);
            $('.gradientLeft').css('background', 'linear-gradient(90deg, rgba(255,255,255,0.1031547619047619) 0%, rgba(255,255,255,0) 100%)');
            $('.gradientRight').css('background', 'linear-gradient(-90deg, rgba(255,255,255,0.1031547619047619) 0%, rgba(255,255,255,0) 100%)');
            $('.dragElement').remove();
            dragDrop = false;

        },
        drag: function() {

            var pos = $(this).offset();
            var x = pos.left;
            var y = pos.top;

            guideEngine(this, x + (59 / 2), y + (59 / 2));
        }
    });

}

function closeAttachments() {

    $.post('https://core_inventory/closeAttachments', JSON.stringify({}));

    $('#suppressor').parent().remove();
    $('#flashlight').parent().remove();
    $('#grip').parent().remove();
    $('#scope').parent().remove();
    $('#finish').parent().remove();
    $('#clip').parent().remove();

    Inventories['suppressor'] = null;
    Inventories['flashlight'] = null;
    Inventories['grip'] = null;
    Inventories['scope'] = null;
    Inventories['finish'] = null;
    Inventories['clip'] = null;

    InventoryParms['suppressor'] = null;
    InventoryParms['flashlight'] = null;
    InventoryParms['grip'] = null;
    InventoryParms['scope'] = null;
    InventoryParms['finish'] = null;
    InventoryParms['clip'] = null;

    var canvas = document.querySelector('#canvas');
    var context = canvas.getContext('2d');
    context.clearRect(0, 0, canvas.width, canvas.height);

    for (const [key, value] of Object.entries(InventoryParms)) {
        if (value != null) {
            if (!value.hidden) {

                $('#' + key).parent().show();
            }
        }

    }

    $('#content-' + cid).parent().animate({
        top: attachmentContentPos.top + 'px',
        left: attachmentContentPos.left + 'px'
    }, 500, function() {
        InventoryParms['content-' + cid].x = attachmentContentPos.left;
        InventoryParms['content-' + cid].y = attachmentContentPos.top;

    });
    attachmentsOpened = false;
}

function ispezionaItem(id) {


attachmentsOpened = true;
attachmentContentPos = $('#content-'+cid).parent().offset();

for (const [key, value] of Object.entries(InventoryParms)) {
     $('#' + key).parent().hide();
}

 var itemData = Inventories[$('#' + id).attr('inventory')][id]
 $.post('https://core_inventory/setupIspeziona', JSON.stringify({item: itemData }));
playSound('open_bass');
}


function openAttachemnts(weapon) {

    attachmentsOpened = true;
    attachmentContentPos = $('#content-' + cid).parent().offset();

    for (const [key, value] of Object.entries(InventoryParms)) {
        $('#' + key).parent().hide();
    }

    $.post('https://core_inventory/setupAttachments', JSON.stringify({
        data: Inventories['content-' + cid][weapon],
        weapon: weapon
    }));
    playSound('open_bass');
}

function attachmentContent(data, field) {

    if (data.metadata.attachments[field]) {
        return {
            [data.metadata.attachments[field].id]: data.metadata.attachments[field]
        };
    } else {
        return {};
    }

}

function setupAttachments(data, suppressor, flashlight, grip, scope, finish, clip) {
	Toggle('inventory')
	if (suppressor) {
	  createHolder('suppressor', 4, 2,  attachmentContent(data, 'suppressor'), getText('suppressor'), suppressor['x'] + '%' , suppressor['y'] + '%', 'component_suppressor', false, 'attachments')
	}
	if (flashlight){
	  createHolder('flashlight', 4, 2,  attachmentContent(data, 'flashlight'), getText('flashlight'), flashlight['x'] + '%' , flashlight['y'] + '%', 'component_flashlight', false, 'attachments')
	}
	if (grip) {
	  createHolder('grip', 4, 2,  attachmentContent(data, 'grip'), getText('grip'), grip['x'] + '%' , grip['y'] + '%', 'component_grip', false, 'attachments')
	}
	if (scope) {
	  createHolder('scope', 4, 2,  attachmentContent(data, 'scope'), getText('scope'), scope['x'] + '%' , scope['y'] + '%', 'component_scope', false, 'attachments')
	}
	if (finish) {
	  createHolder('finish', 4, 2,  attachmentContent(data, 'finish'), getText('finish'), finish['x'] + '%' , finish['y'] + '%', 'component_finish', false, 'attachments')
	}
	if (clip) {
	  createHolder('clip', 4, 2,  attachmentContent(data, 'clip'), getText('clip'), clip['x'] + '%' , clip['y'] + '%', 'component_clip', false, 'attachments')
	}

}

function rand(max) {
    return Math.floor(Math.random() * max);
}

function drawLine(context, x1, y1, x2, y2) {

    context.beginPath();
    context.moveTo(x1, y1);
    context.lineTo(x2, y2);
    context.strokeStyle = '#ffff';
    context.stroke();
}

function drawAttachmentLines(suppressor, flashlight, grip, scope, finish, clip) {

    var canvas = document.querySelector('#canvas');
    var context = canvas.getContext('2d');

    canvas.width = $(window).width(); //document.width is obsolete
    canvas.height = $(window).height(); //document.height is obsolete

    context.clearRect(0, 0, canvas.width, canvas.height);

    if (suppressor) {
        let start = $('#suppressor').offset();
        drawLine(context, start.left + 42, start.top + 42, (suppressor['x'] * document.body.clientWidth), (suppressor['y'] * document.body.clientHeight))
    }
    if (flashlight) {
        let start = $('#flashlight').offset();
        drawLine(context, start.left + 42, start.top + 42, (flashlight['x'] * document.body.clientWidth), (flashlight['y'] * document.body.clientHeight))
    }
    if (grip) {
        let start = $('#grip').offset();
        drawLine(context, start.left + 42, start.top + 42, (grip['x'] * document.body.clientWidth), (grip['y'] * document.body.clientHeight))
    }
    if (scope) {
        let start = $('#scope').offset();
        drawLine(context, start.left + 42, start.top + 42, (scope['x'] * document.body.clientWidth), (scope['y'] * document.body.clientHeight))
    }
    if (finish) {
        let start = $('#finish').offset();
        drawLine(context, start.left + 42, start.top + 42, (finish['x'] * document.body.clientWidth), (finish['y'] * document.body.clientHeight))
    }
    if (clip) {
        let start = $('#clip').offset();
        drawLine(context, start.left + 42, start.top + 42, (clip['x'] * document.body.clientWidth), (clip['y'] * document.body.clientHeight))
    }

}

function prepareChangeLocaton(item, fslot, tslot, finv, tinv) {

    startInv = finv;
    startSlot = fslot
    x = parseInt($('#' + item).attr("x"));
    y = parseInt($('#' + item).attr("y"));

    if ($('#' + item).attr("flipped") == "1") {

        flipped = true

    } else {
        flipped = false
    }

    startX = x;
    startY = y;

    $('#' + item).css({

        height: (59 * startY) + "px",
        width: (59 * startX) + "px",

    });

    idx = x;
    idy = y;
    itemDragging = item;

    $('#' + item).parent().parent().appendTo('#main_container');

    var unoccupy = getSlots(startSlot, x, y, InventoryParms[startInv].rows, startInv);

    for (let g = 0; g < unoccupy.length; g++) {
        $("#" + startInv).find('#slot-' + unoccupy[g]).attr('occupied', "0");
    }

    changeItemLocation(item, fslot, tslot, finv, tinv)
    itemDragging = null;

}

function ctrlClick(item) {

    var inventory = item.attr('inventory');
    var id = item.attr('id');
    var slot = item.attr('slot');
    var x = item.attr('x');
    var y = item.attr('y');
    var category = item.attr('category');

    if (inventory == 'content-' + cid) {

        //CATEGORY MATCH
        for (const [key, value] of Object.entries(InventoryParms)) {

            if (value.restrictedTo != null) {

                if (value.restrictedTo.includes(category) && !value.hidden) {

                    if ($('#' + key).find('#slot-' + 1).attr('occupied') == "0" && $('#' + key).find('#slot-' + 1).attr('holder') == "1") {

                        playSound(config.ItemCategories[category].putSound);
                        prepareChangeLocaton(id, parseInt(slot), 1, inventory, key)
                        return
                    }

                }

            }

        }

        if (InventoryParms[recentInventory] != null) {

            if (!InventoryParms[recentInventory].hidden && $('#' + recentInventory).find('#slot-' + 1).attr('holder') == "0") {

                var newSlot = findAvailableSpot(recentInventory, parseInt(x), parseInt(y));

                if (newSlot == null) {
                    console.log('[Core Inventory] Ctrl click No slot found!');
                } else {

                    playSound(config.ItemCategories[category].putSound);
                    prepareChangeLocaton(id, parseInt(slot), newSlot, inventory, recentInventory)
                    return
                }
            }

        }

    } else if (!InventoryParms['content-' + cid].hidden) {

        var newSlot = findAvailableSpot('content-' + cid, parseInt(x), parseInt(y));

        if (newSlot == null) {
            console.log('Not enough space');
        } else {

            playSound(config.ItemCategories[category].putSound);
            prepareChangeLocaton(id, parseInt(slot), newSlot, inventory, 'content-' + cid)
            return
        }

    }

}

function flipGuide(guide) {

    if (itemDragging != null) {

        var save = idx;

        idx = idy;
        idy = save;

        $('#' + itemDragging).attr("x", idx);
        $('#' + itemDragging).attr("y", idy);

        Inventories[startInv][itemDragging].x = idx;
        Inventories[startInv][itemDragging].y = idy;

        $('#' + itemDragging).css({
            zIndex: 5000,

            height: $('#' + itemDragging).css("width"),
            width: $('#' + itemDragging).css("height")

        });

        if ($('#' + itemDragging).attr("flipped") == "0") {
            $('#' + itemDragging).attr("flipped", "1");
            Inventories[startInv][itemDragging].flipped = 1;
            $('#' + itemDragging).find('#ItemImage').css({

                transform: 'rotate(90deg) translateY(-100%)',
                height: idx * 59 + 'px',
                width: idy * 59 + 'px',

            });
        } else {
            $('#' + itemDragging).attr("flipped", "0");
            Inventories[startInv][itemDragging].flipped = 0;
            $('#' + itemDragging).find('#ItemImage').css({

                transform: 'rotate(0deg)',
                height: idy * 59 + 'px',
                width: idx * 59 + 'px',

            });
        }

        if (guide) {
            var dom = $('#' + itemDragging)[0];
            var position = $(dom).offset();
            var x = position.left;
            var y = position.top;

            guideEngine(dom, x + (59 / 2), y + (59 / 2))
        }

    }

}


var antilag = false
//KEY CLICKED
$(document).keyup(function(e) {
    if (e.keyCode === 27 || e.keyCode === 9) {

        if (attachmentsOpened) {
            closeAttachments();
        } else {
            closeMenu();
        }

    }
    if (e.keyCode === 82) {

        flipGuide(true);

    }
    if (e.keyCode === 86) {

        overlayCheck();

    }
    if (e.keyCode == 17) {
        ctrlClicked = false;
    }
    if (e.keyCode == 16) {
        shiftClicked = false;
        if (splitAmount) {
			if (!antilag) {
				antilag = true 
				playSound('tik');
				$('.stackBackground').remove();
				$('.stackContainer').remove();
				$('#clone').remove();
				$.post('https://core_inventory/splitItems', JSON.stringify({
					fitem: splitItem,
					tslot: splitSlot,
					finv: splitFinv,
					tinv: splitTinv,
					stack: splitAmount
				}));
				splitAmount = null;
				splitItem = null;
				splitSlot = null;
				splitFinv = null;
				splitTinv = null;
				setTimeout(() => {  antilag = false }, 5000);
			} else {
				playSound('errore');
				closeMenu()
			}
        }
    }

}).keydown(function(e) {
    if (e.keyCode == 17) {
        ctrlClicked = true;
    }
    if (e.keyCode == 16) {
        shiftClicked = true;
    }
});

function closeMenu() {
    $.post('https://core_inventory/close', JSON.stringify({
        data: InventoryParms,
        settings: Settings
    }));

    Inventories = {};
    InventoryParms = {};

    $('#main_container').fadeOut();
    timeout = setTimeout(function() {
        $("#main_container").html("");
        inventoryOpened = false;

    }, 400);

}

//DRAGGING
document.addEventListener('mousedown', e => {

    if (!$(e.target).hasClass('ui-draggable-handle')) {
        dragX = e.pageX;
        dragY = e.pageY;
        $.post('https://core_inventory/registerMouse', JSON.stringify({}));
        dragging = true
    }
});
document.addEventListener('mouseup', () => dragging = false);
document.addEventListener('mousemove', e => {

    if (dragging && !itemDragging) {
        var x = dragX - e.pageX;
        var y = dragY - e.pageY;

        $.post('https://core_inventory/mouseMovement', JSON.stringify({
            x: x,
            y: y
        }));
    }

});

function playClickSound() {
    var audio = document.getElementById("clickaudio");
    audio.volume = 0.05;
    audio.play();
}

window.addEventListener('message', function(event) {

    var edata = event.data;

    if (edata.type == 'addItem') {

        addItem(edata.item, edata.inventory)

    }
    if (edata.type == 'removeItem') {

        removeItem(edata.item, edata.inventory)

    }

    if (edata.type == 'openBase') {

        cid = edata.cid;
        config = edata.config;
        qbitems = edata.qbitems;
        if (edata.settings != null) {
            Settings = edata.settings;
        }
        $('#main_container').fadeIn();
        openInventory();

    }

    if (edata.type == 'Sync') {

        var newData = edata.data.content;

        if (Inventories[edata.inventory] == null) {
            return;
        }

        // REMOVE FROM INVENTORY ITEM THAT ARENT ANYMORE THERE
        for (const [key, value] of Object.entries(Inventories[edata.inventory])) {

            if (!newData[key] && $('#' + key).attr("inventory") == edata.inventory) {

                removeItem(key, edata.inventory);

            }
        }

        //ADD REMOVE ITEMS IF THEY ARE HERE
        for (const [key, value] of Object.entries(newData)) {

            if ($('#' + key).length) {

                if (parseInt($('#' + key).attr("slot")) != parseInt(value.slot)) {

                    removeItem(key, edata.inventory);
                    Inventories[edata.inventory][key] = newData[key]

                    addItem(key, edata.inventory);

                } else {
                    Inventories[edata.inventory][key] = newData[key]

                    //STACKING
                    if (value.amount) {
                        if (parseInt($('#' + key).find('#ItemImage').find('#ItemCount').text()) != parseInt(value.amount)) {
                            $('#' + key).find('#ItemImage').find('#ItemCount').text(value.amount);
                        }
                    }

                }

            } else {
                Inventories[edata.inventory][key] = newData[key]

                addItem(key, edata.inventory);

            }

        }

    }
    if (edata.type == 'setupAttachments') {

        setupAttachments(edata.data, edata.suppressor, edata.flashlight, edata.grip, edata.scope, edata.finish, edata.clip);

    }

    if (edata.type == 'attachmentLine') {
        drawAttachmentLines(edata.suppressor, edata.flashlight, edata.grip, edata.scope, edata.finish, edata.clip)
    }

    if (edata.type == 'openHolder') {
        createHolder(edata.name, edata.slots, edata.rows, edata.content, edata.label, edata.locationX, edata.locationY, edata.restrictedTo, edata.hidden, edata.invType);
    }
		
    if (edata.type == 'openInventory') {

        createInventory(edata.name, edata.slots, edata.rows, edata.content, edata.label, edata.locationX, edata.locationY, edata.hidden, edata.invType, edata.restrictedTo);

    }
    if (edata.type == 'playSound') {
        playSound(edata.sound)

    }
    if (edata.type == 'forceClose') {
        closeMenu()
    }	

    if (edata.type == 'weaponUI') {
        openWeaponUI(edata.show, edata.data, edata.ammo, edata.maxammo, edata.percent);
    }
    if (edata.type == 'updateWeight') {
        yourhexmother = edata.steam
	    pesoattuale = edata.pesoattuale
		pesomassimo = edata.pesomassimo
		$('#st_weight').html(pesoattuale/1000 + " / " + pesomassimo/1000 + " KG");
		
		var value = pesoattuale / pesomassimo * 100; 
		var color1 = '#01F06B';
		var color = '#01F06B';

		if(value <= 45)
			color = '#01F06B';
		else if(value <= 65)
			color = '#F04301';
		else if(value <= 95)
			color = '#F02501';
		else color = '#CC0E00';

		value = 390 / 100 * (pesoattuale / pesomassimo * 100);

		$('#in_weight').css('width', value);
		var colorbg = 'linear-gradient(to right, ' + color1 + ', ' + color + " " + value + 'px )';
		$('#in_weight').css('background', colorbg);
	
    }	
	
	if(edata.type == "bloccoBorsone") {
		bloccoInv = edata.yes
	}
	
	

});