($) ->
	$.toggleSwitch =
		version: "1.0.03"
		setDefaults: (options) ->
			$.extend defaults, options

	$.fn.toggleSwitch = (options) ->
		method = typeof arguments[0] is "string" and arguments[0]
		args = method and Array::slice.call(arguments, 1) or arguments
		self = (if (@length is 0) then null else $.data(this[0], "toggle"))
		if self and method and @length
			if method.toLowerCase() is "object"
				return self
			else if self[method]
				result = undefined
				@each (i) ->
					r = $.data(this, "toggle")[method].apply(self, args)
					if i is 0 and r
						unless not r.jquery
							result = $([]).add(r)
						else
							result = r
							false
					else result = result.add(r) if !!r and !!r.jquery

				return result or this
			else
				return this
		else
			return @each(->
				new toggle(this, options)
			)

	counter = 0
	$.browser.iphone = (navigator.userAgent.toLowerCase().indexOf("iphone") > -1)
	toggle = (input, options) ->
		self = this
		$input = $(input)
		id = ++counter
		disabled = false
		width = {}
		mouse =
			dragging: false
			clicked: null

		dragStart =
			position: null
			offset: null
			time: null

		options = $.extend({}, defaults, options, (if !!$.metadata then $input.metadata() else {}))
		bDefaultLabelsUsed = (options.labelOn is ON and options.labelOff is OFF)
		allow = ":checkbox, :radio"
		unless $input.is(allow)
			return $input.find(allow).toggle(options)
		else return if $.data($input[0], "toggle")
		$.data $input[0], "toggle", self
		options.resizeHandle = not bDefaultLabelsUsed if options.resizeHandle is "auto"
		options.resizeContainer = not bDefaultLabelsUsed if options.resizeContainer is "auto"
		@toggle = (t) ->
			toggle = (if (arguments.length > 0) then t else not $input[0].checked)
			$input.attr("checked", toggle).trigger "change"

		@disable = (t) ->
			toggle = (if (arguments.length > 0) then t else not disabled)
			disabled = toggle
			$input.attr "disabled", toggle
			$container[(if toggle then "addClass" else "removeClass")] options.classDisabled
			options.disable.apply self, [ disabled, $input, options ] if $.isFunction(options.disable)

		@repaint = ->
			positionHandle()

		@destroy = ->
			$([ $input[0], $container[0] ]).unbind ".toggle"
			$(document).unbind ".toggle_" + id
			$container.after($input).remove()
			$.data $input[0], "toggle", null
			options.destroy.apply self, [ $input, options ] if $.isFunction(options.destroy)

		$input.wrap("<div title=\"" + $input[0].title + "\" class=\"" + $.trim(options.classContainer + " " + options.className) + "\" />").after "<div class=\"" + options.classHandle + "\"></div>" + "<div class=\"" + options.classLabelOff + "\"><span><label>" + options.labelOff + "</label></span></div>" + "<div class=\"" + options.classLabelOn + "\"><span><label>" + options.labelOn + "</label></span></div>"
		$container = $input.parent()
		$handle = $input.siblings("." + options.classHandle)
		$offlabel = $input.siblings("." + options.classLabelOff)
		$offspan = $offlabel.children("span")
		$onlabel = $input.siblings("." + options.classLabelOn)
		$onspan = $onlabel.children("span")
		if options.resizeHandle or options.resizeContainer
			width.onspan = $onspan.outerWidth()
			width.offspan = $offspan.outerWidth()
		if options.resizeHandle
			width.handle = Math.min(width.onspan, width.offspan)
			$handle.css "width", width.handle
		else
			width.handle = $handle.width()
		if options.resizeContainer
			width.container = (Math.max(width.onspan, width.offspan) + width.handle + 20)
			$container.css "width", width.container
			$offlabel.css "width", width.container
		else
			width.container = $container.width()
		handleRight = width.container - width.handle
		positionHandle = (animate) ->
			checked = $input[0].checked
			x = (if (checked) then handleRight else 0)
			animate = (if (arguments.length > 0) then arguments[0] else true)
			if animate and options.enableFx
				$handle.stop().animate
					left: x
				, options.duration, options.easing
				$onlabel.stop().animate
					width: x + 4
				, options.duration, options.easing
				$onspan.stop().animate
					marginLeft: x - handleRight
				, options.duration, options.easing
				$offspan.stop().animate
					marginRight: -x
				, options.duration, options.easing
			else
				$handle.css "left", x
				$onlabel.css "width", x + 4
				$onspan.css "marginLeft", x - handleRight
				$offspan.css "marginRight", -x

		positionHandle false
		getDragPos = (e) ->
			e.pageX or (if (e.originalEvent.changedTouches) then e.originalEvent.changedTouches[0].pageX else 0)

		$container.bind "mousedown.toggle touchstart.toggle", (e) ->
			return if $(e.target).is(allow) or disabled or (not options.allowRadioUncheck and $input.is(":radio:checked"))
			e.preventDefault()
			mouse.clicked = $handle
			dragStart.position = getDragPos(e)
			dragStart.offset = dragStart.position - (parseInt($handle.css("left"), 10) or 0)
			dragStart.time = (new Date()).getTime()
			false

		if options.enableDrag
			$(document).bind "mousemove.toggle_" + id + " touchmove.toggle_" + id, (e) ->
				return unless mouse.clicked is $handle
				e.preventDefault()
				x = getDragPos(e)
				unless x is dragStart.offset
					mouse.dragging = true
					$container.addClass options.classHandleActive
				pct = Math.min(1, Math.max(0, (x - dragStart.offset) / handleRight))
				$handle.css "left", pct * handleRight
				$onlabel.css "width", pct * handleRight + 4
				$offspan.css "marginRight", -pct * handleRight
				$onspan.css "marginLeft", -(1 - pct) * handleRight
				false
		$(document).bind "mouseup.toggle_" + id + " touchend.toggle_" + id, (e) ->
			return false unless mouse.clicked is $handle
			e.preventDefault()
			changed = true
			if not mouse.dragging or (((new Date()).getTime() - dragStart.time) < options.clickOffset)
				checked = $input[0].checked
				$input.attr "checked", not checked
				options.click.apply self, [ not checked, $input, options ] if $.isFunction(options.click)
			else
				x = getDragPos(e)
				pct = (x - dragStart.offset) / handleRight
				checked = (pct >= 0.5)
				changed = false if $input[0].checked is checked
				$input.attr "checked", checked
			$container.removeClass options.classHandleActive
			mouse.clicked = null
			mouse.dragging = null
			if changed
				$input.trigger "change"
			else
				positionHandle()
			false

		$input.bind("change.toggle", ->
			positionHandle()
			if $input.is(":radio")
				el = $input[0]
				$radio = $((if el.form then el.form[el.name] else ":radio[name=" + el.name + "]"))
				$radio.filter(":not(:checked)").toggle "repaint"
			options.change.apply self, [ $input, options ] if $.isFunction(options.change)
		).bind("focus.toggle", ->
			$container.addClass options.classFocus
		).bind "blur.toggle", ->
			$container.removeClass options.classFocus

		if $.isFunction(options.click)
			$input.bind "click.toggle", ->
				options.click.apply self, [ $input[0].checked, $input, options ]
		@disable true if $input.is(":disabled")
		if $.browser.msie
			$container.find("*").andSelf().attr "unselectable", "on"
			$input.bind "click.toggle", ->
				$input.triggerHandler "change.toggle"
		options.init.apply self, [ $input, options ] if $.isFunction(options.init)

	defaults =
		duration: 200
		easing: "swing"
		labelOn: "YES"
		labelOff: "NO"
		resizeHandle: "auto"
		resizeContainer: "auto"
		enableDrag: true
		enableFx: true
		allowRadioUncheck: false
		clickOffset: 120
		className: ""
		classContainer: "toggle-container"
		classDisabled: "toggle-disabled"
		classFocus: "toggle-focus"
		classLabelOn: "toggle-label-on"
		classLabelOff: "toggle-label-off"
		classHandle: "toggle-handle"
		classHandleActive: "toggle-active-handle"
		init: null
		change: null
		click: null
		disable: null
		destroy: null

	ON = defaults.labelOn
	OFF = defaults.labelOff