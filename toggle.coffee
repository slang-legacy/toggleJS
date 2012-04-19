###
	toggleJS jQuery Plug-in

	Licensed under the Apache License, Version 2.0 (the "License");
	you may not use this file except in compliance with the License.
	You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License.
###

#TODO: make toggle change with l/r arrow keys when on keyboard focus
($) ->
	defaults =
		duration: 200 #the speed of the animation
		easing: "swing" #the easing animation to use
		labelOn: "On" #the text to show when toggled on
		labelOff: "Off" #the text to show when toggled off
		resizeHandle: "auto" #determines if handle should be resized
		resizeContainer: "auto" #determines if container should be resized
		enableDrag: true #determines if we allow dragging
		enableFx: true #determines if we show animation
		allowRadioUncheck: false #determine if a radio button should be able to be unchecked
		clickOffset: 120 #if millseconds between a mousedown & mouseup event this value, then considered a mouse click

		#define the class statements
		className: ""
		classContainer: "toggle-container"
		classDisabled: "toggle-disabled"
		classFocus: "toggle-focus"
		classLabelOn: "toggle-label-on"
		classLabelOff: "toggle-label-off"
		classHandle: "toggle-handle"
		classHandleActive: "toggle-active-handle"

		#event handlers
		init: null #callback that occurs when a toggle is initialized
		change: null #callback that occurs when the button state is changed
		click: null #callback that occurs when the button is clicked
		disable: null #callback that occurs when the button is disabled/enabled
		destroy: null #callback that occurs when the button is destroyed

	ON = defaults.labelOn
	OFF = defaults.labelOff

	#set default options
	$.toggleSwitch =
		version: "1.0.03"
		setDefaults: (options) ->
			$.extend defaults, options

	$.fn.toggleSwitch = (options) ->
		method = typeof arguments[0] is "string" and arguments[0]
		args = method and Array::slice.call(arguments, 1) or arguments
		#get a reference to the first toggle found
		self = (if (@length is 0) then null else $.data(this[0], "toggle"))

		#if a method is supplied, execute it for non-empty results
		if self and method and @length
			#if request a copy of the object, return it
			if method.toLowerCase() is "object"
				self
			#if method is defined, run it and return either it's results or the chain
			else if self[method]
				#define a result variable to return to the jQuery chain
				result = undefined
				@each (i) ->
					#apply the method to the current element
					r = $.data(this, "toggle")[method].apply(self, args)
					#if first iteration we need to check if we're done processing or need to add it to the jquery chain
					if i is 0 and r
						#if this is a jQuery item, we need to store them in a collection
						unless not r.jquery
							result = $([]).add(r)
						else #otherwise, just store the result and stop executing
							result = r
							#since we're a non-jQuery item, just cancel processing further items
							false
						#keep adding jQuery objects to the results
					else result = result.add(r) if !!r and !!r.jquery

				#return either the results (which could be a jQuery object) or the original chain
				result or this
				#everything else, return the chain
			else
				this #initializing request (only do if toggle not already initialized)
		else
			#create a new toggle for each object found
			@each ->
				new toggle(this, options)
	#count instances
	counter = 0

	#detect iPhone
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

		#make a copy of the options and use the metadata if provided
		options = $.extend({}, defaults, options, (if !!$.metadata then $input.metadata() else {}))
		#check to see if we're using the default labels
		bDefaultLabelsUsed = (options.labelOn is ON and options.labelOff is OFF)
		#set valid field types
		allow = ":checkbox, :radio"

		#only do for checkboxes buttons, if matches inside that node
		unless $input.is(allow)
			return $input.find(allow).toggle(options)
		
		#if toggle already exists, stop processing
		else return if $.data($input[0], "toggle")

		#store a reference to this marquee
		$.data $input[0], "toggle", self

		#if using the "auto" setting, then don't resize handle or container if using the default label (since we'll trust the CSS)
		options.resizeHandle = not bDefaultLabelsUsed if options.resizeHandle is "auto"
		options.resizeContainer = not bDefaultLabelsUsed if options.resizeContainer is "auto"

		@toggle = (t) ->
			#toggles the state of a button (or can turn on/off)
			toggle = (if (arguments.length > 0) then t else not $input[0].checked)
			$input.attr("checked", toggle).trigger "change"

		@disable = (t) ->
			#disable/enable the control
			toggle = (if (arguments.length > 0) then t else not disabled)
			#mark the control disabled
			disabled = toggle
			#mark the input disabled
			$input.attr "disabled", toggle
			#set the diabled styles
			$container[(if toggle then "addClass" else "removeClass")] options.classDisabled
			#run callback
			options.disable.apply self, [ disabled, $input, options ] if $.isFunction(options.disable)

		@repaint = ->
			positionHandle()

		@destroy = ->
			#this will destroy the toggle style
			$([ $input[0], $container[0] ]).unbind ".toggle" #remove behaviors
			$(document).unbind ".toggle_" + id
			$container.after($input).remove() #move the checkbox to it's original location
			$.data $input[0], "toggle", null #kill the reference
			options.destroy.apply self, [ $input, options ] if $.isFunction(options.destroy) #run callback

		#create toggle switch
		unless $input[0].dataset.labeloff
			labelOff = options.labelOff
		else
			labelOff = $input[0].dataset.labeloff
		unless $input[0].dataset.labelon
			labelOn = options.labelOn
		else
			labelOn = $input[0].dataset.labelon
		
		$input.wrap("<div title=\"" + $input[0].title + "\" class=\"" + $.trim(options.classContainer + " " + options.className) + "\" />").after "<div class=\"" + options.classHandle + "\"></div>" + "<div class=\"" + options.classLabelOff + "\"><span><label>" + labelOff + "</label></span></div>" + "<div class=\"" + options.classLabelOn + "\"><span><label>" + labelOn + "</label></span></div>"
		
		$container = $input.parent()
		$handle = $input.siblings("." + options.classHandle)
		$offlabel = $input.siblings("." + options.classLabelOff)
		$offspan = $offlabel.children("span")
		$onlabel = $input.siblings("." + options.classLabelOn)
		$onspan = $onlabel.children("span")

		#if we need to do some resizing, get the widths only once
		if options.resizeHandle or options.resizeContainer
			width.onspan = $onspan.outerWidth()
			width.offspan = $offspan.outerWidth()
		
		#automatically resize the handle
		if options.resizeHandle
			width.handle = Math.min(width.onspan, width.offspan)
			$handle.css "width", width.handle
		else
			width.handle = $handle.width()

		#automatically resize the control
		if options.resizeContainer
			width.container = (Math.max(width.onspan, width.offspan) + width.handle + 20)
			$container.css "width", width.container
			#adjust the off label to match the new container size
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

		#place the buttons in their default location
		positionHandle false #todo: fix this to be based off of current value of radio?
		getDragPos = (e) ->
			e.pageX or (if (e.originalEvent.changedTouches) then e.originalEvent.changedTouches[0].pageX else 0)

		#monitor mouse clicks in the container
		$container.bind "mousedown.toggle touchstart.toggle", (e) ->
			#abort if disabled or allow clicking the input to toggle the status (if input is visible)
			return if $(e.target).is(allow) or disabled or (not options.allowRadioUncheck and $input.is(":radio:checked"))
			e.preventDefault()
			mouse.clicked = $handle
			dragStart.position = getDragPos(e)
			dragStart.offset = dragStart.position - (parseInt($handle.css("left"), 10) or 0)
			dragStart.time = (new Date()).getTime()
			false

		#make sure dragging support is enabled
		if options.enableDrag
			#monitor mouse movement on the page
			$(document).bind "mousemove.toggle_" + id + " touchmove.toggle_" + id, (e) ->
				#if we haven't clicked on the container, cancel event
				return unless mouse.clicked is $handle
				e.preventDefault()
				x = getDragPos(e)
				unless x is dragStart.offset
					mouse.dragging = true
					$container.addClass options.classHandleActive

				pct = Math.min(1, Math.max(0, (x - dragStart.offset) / handleRight)) #make sure number is between 0 and 1
				$handle.css "left", pct * handleRight
				$onlabel.css "width", pct * handleRight + 4 #overcome 3px border radius
				$offspan.css "marginRight", -pct * handleRight
				$onspan.css "marginLeft", -(1 - pct) * handleRight
				false

		#monitor when the mouse button is released
		$(document).bind "mouseup.toggle_" + id + " touchend.toggle_" + id, (e) ->
			return false unless mouse.clicked is $handle
			e.preventDefault()
			changed = true #track if the value has changed
			#if not dragging or click time under a certain millisecond, then just toggle
			if not mouse.dragging or (((new Date()).getTime() - dragStart.time) < options.clickOffset)
				checked = $input[0].checked
				$input.attr "checked", not checked
				#run callback
				options.click.apply self, [ not checked, $input, options ] if $.isFunction(options.click)
			else
				x = getDragPos(e)
				pct = (x - dragStart.offset) / handleRight
				checked = (pct >= 0.5)
				changed = false if $input[0].checked is checked #if the value is the same, don't run change event
				$input.attr "checked", checked
			$container.removeClass options.classHandleActive #remove the active handler class
			mouse.clicked = null
			mouse.dragging = null
			#run any change event for the element
			if changed
				$input.trigger "change"
			else
				#if the value didn't change, just reset the handle
				positionHandle()
			false

		#animate when we get a change event
		$input.bind("change.toggle", ->
			positionHandle() #move handle
			if $input.is(":radio")#if a radio element, then we must repaint the other elements in it's group to show them as not selected
				el = $input[0]
				#try to use the DOM to get the grouped elements, but if not in a form get by name attr
				$radio = $((if el.form then el.form[el.name] else ":radio[name=" + el.name + "]"))
				$radio.filter(":not(:checked)").toggle "repaint" #repaint the radio elements that are not checked
			#run callback
			options.change.apply self, [ $input, options ] if $.isFunction(options.change)
		#if the element has focus, we need to highlight the container
		.bind "focus.toggle" ->
			$container.addClass options.classFocus
		.bind "blur.toggle" ->
			$container.removeClass options.classFocus

		#if a click event is registered, we must register on the checkbox so it's fired if triggered on the checkbox itself
		if $.isFunction(options.click)
			$input.bind "click.toggle", ->
				options.click.apply self, [ $input[0].checked, $input, options ]
		@disable true if $input.is(":disabled") #if the field is disabled, mark it as such

		#shit for IE
		if $.browser.msie
			#disable text selection in IE, other browsers are controlled via CSS (because other browsers were designed correctly)
			#IE needs to register to the "click" event (because it is gay) to make changes immediately (the change event only occurs on blur)
			$container.find("*").andSelf().attr "unselectable", "on"
			$input.bind "click.toggle", ->
				$input.triggerHandler "change.toggle"
		
	options.init.apply(self, [$input, options]) if $.isFunction(options.init) #run the init callback