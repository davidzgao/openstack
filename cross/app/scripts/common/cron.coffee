###*
Default settings
###
$cross.jqCron =
  jqCronDefaultSettings:
    texts: {}
    monthdays: [
      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18,
      19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31
    ]
    hours: [
      0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17,
      18, 19, 20, 21, 22, 23
    ]
    minutes: [
      0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18,
      19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35,
      36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52,
      53, 54, 55, 56, 57, 58, 59
    ]
    lang: "en"
    enabled_minute: false
    enabled_hour: true
    enabled_day: true
    enabled_week: true
    enabled_month: true
    enabled_year: true
    multiple_dom: false
    multiple_month: false
    multiple_mins: false
    multiple_dow: false
    multiple_time_hours: false
    multiple_time_minutes: false
    numeric_zero_pad: false
    default_period: "day"
    default_value: ""
    no_reset_button: true
    disabled: false
    bind_to: null
    bind_method:
      set: ($element, value) ->
        (if $element.is(":input") then $element.val(value) else $element.data("jqCronValue", value))
        return

      get: ($element) ->
        (if $element.is(":input") then $element.val() else $element.data("jqCronValue"))


###*
Custom extend of json for jqCron settings.
We don't use jQuery.extend because simple extend does not fit our needs, and deep extend has a bad
feature for us : it replaces keys of "Arrays" instead of replacing the full array.
###
(($) ->
  extend = (dst, src) ->
    for i of src
      if $.isPlainObject(src[i])
        dst[i] = extend((if dst[i] and $.isPlainObject(dst[i]) then dst[i] else {}), src[i])
      else if $.isArray(src[i])
        dst[i] = src[i].slice(0)
      else dst[i] = src[i]  if src[i] isnt `undefined`
    dst

  @jqCronMergeSettings = (obj) ->
    extend extend({}, $cross.jqCron.jqCronDefaultSettings), obj or {}

  return
).call this, jQuery

###*
Shortcut to get the instance of jqCron instance from one jquery object
###
(($) ->
  $.fn.jqCronGetInstance = ->
    @data "jqCron"

  return
).call this, jQuery

###*
Main plugin
###
(($) ->
  $.fn.jqCron = (settings) ->
    saved_settings = settings || {}
    @each ->
      cron = undefined
      saved = undefined
      $this = $(this)
      settings = jqCronMergeSettings(saved_settings)
      translations = settings.texts[settings.lang]
      if typeof (translations) isnt "object" or $.isEmptyObject(translations)
        console and console.error("Missing translations for language \"" + settings.lang + "\". " + "Please include jqCron." + settings.lang + ".js or manually provide " + "the necessary translations when calling $.fn.jqCron().")
        return
      unless settings.jquery_container
        if $this.is(":container")
          settings.jquery_element = $this.uniqueId("jqCron")
        else if $this.is(":autoclose")
          $this.next(".jqCron").remove()  if $this.next(".jqCron").length is 1
          settings.jquery_element = $("<span class=\"jqCron\"></span>").uniqueId("jqCron").insertAfter($this)
        else
          console and console.error(settings.texts[settings.lang].error1.replace("%s", @tagName))
          return
      settings.bind_to = settings.bind_to or $this  if $this.is(":input")
      if settings.bind_to
        if settings.bind_to.is(":input")
          settings.bind_to.blur ->
            value = settings.bind_method.get(settings.bind_to)
            $this.jqCronGetInstance().setCron value
            return

        saved = settings.bind_method.get(settings.bind_to)
        cron = new jqCron(settings)
        cron.setCron saved
      else
        cron = new jqCron(settings)
      $(this).data "jqCron", cron
      return


  return
).call this, jQuery

###*
jqCron class

 set cron (string like * * * * *)
 sanitize
 1 possibility
 1 possibility
 4 possibilities
 4 possibilities
 4 possibilities
 8 possibilities
###
# init
(($) ->
  jqCron = (settings) ->
    newSelector = ($block, multiple, type) ->
      selector = new jqCronSelector(_self, $block, multiple, type)
      selector.$.bind "selector:open", ->
        n = jqCronInstances.length

        while n--
          unless jqCronInstances[n] is _self
            jqCronInstances[n].closeSelectors()
          else
            o = _selectors.length

            while o--
              _selectors[o].close()  unless _selectors[o] is selector
        return

      selector.$.bind "selector:change", ->
        boundChanged = false
        return  unless _initialized
        if settings.multiple_mins is settings.multiple_time_minutes
          if selector is _selectorMins
            boundChanged = _selectorTimeM.setValue(_selectorMins.getValue())
          else boundChanged = _selectorMins.setValue(_selectorTimeM.getValue())  if selector is _selectorTimeM
        boundChanged or _$obj.trigger("cron:change", _self.getCron())
        return

      _selectors.push selector
      selector
    _initialized = false
    _self = this
    _$elt = this
    _$obj = $("<span class=\"jqCron-container\"></span>")
    _$blocks = $("<span class=\"jqCron-blocks\"></span>")
    _$blockPERIOD = $("<span class=\"jqCron-period\"></span>")
    _$blockDOM = $("<span class=\"jqCron-dom\"></span>")
    _$blockMONTH = $("<span class=\"jqCron-month\"></span>")
    _$blockMINS = $("<span class=\"jqCron-mins\"></span>")
    _$blockDOW = $("<span class=\"jqCron-dow\"></span>")
    _$blockTIME = $("<span class=\"jqCron-time\"></span>")
    _$cross = $("<span class=\"jqCron-cross\">&#10008;</span>")
    _selectors = []
    _selectorPeriod = undefined
    _selectorMins = undefined
    _selectorTimeH = undefined
    _selectorTimeM = undefined
    _selectorDow = undefined
    _selectorDom = undefined
    _selectorMonth = undefined
    @disable = ->
      _$obj.addClass "disable"
      settings.disable = true
      _self.closeSelectors()
      return

    @isDisabled = ->
      settings.disable is true

    @enable = ->
      _$obj.removeClass "disable"
      settings.disable = false
      return

    @getCron = ->
      period = _selectorPeriod.getValue()
      items = [
        "*"
        "*"
        "*"
        "*"
        "*"
      ]
      items[0] = _selectorMins.getCronValue()  if period is "hour"
      if period is "day" or period is "week" or period is "month" or period is "year"
        items[0] = _selectorTimeM.getCronValue()
        items[1] = _selectorTimeH.getCronValue()
      items[2] = _selectorDom.getCronValue()  if period is "month" or period is "year"
      items[3] = _selectorMonth.getCronValue()  if period is "year"
      items[4] = _selectorDow.getCronValue()  if period is "week"
      items.join " "

    @setCron = (str) ->
      return  unless str
      try
        str = str.replace(/\s+/g, " ").replace(/^ +/, "").replace(RegExp(" +$"), "")
        mask = str.replace(/[^\* ]/g, "-").replace(/-+/g, "-").replace(RegExp(" +", "g"), "")
        items = str.split(" ")
        _self.error _self.getText("error2")  unless items.length is 5
        if mask is "*****"
          _selectorPeriod.setValue "minute"
        else if mask is "-****"
          _selectorPeriod.setValue "hour"
          _selectorMins.setCronValue items[0]
          _selectorTimeM.setCronValue items[0]
        else if mask.substring(2, mask.length) is "***"
          _selectorPeriod.setValue "day"
          _selectorMins.setCronValue items[0]
          _selectorTimeM.setCronValue items[0]
          _selectorTimeH.setCronValue items[1]
        else if mask.substring(2, mask.length) is "-**"
          _selectorPeriod.setValue "month"
          _selectorMins.setCronValue items[0]
          _selectorTimeM.setCronValue items[0]
          _selectorTimeH.setCronValue items[1]
          _selectorDom.setCronValue items[2]
        else if mask.substring(2, mask.length) is "**-"
          _selectorPeriod.setValue "week"
          _selectorMins.setCronValue items[0]
          _selectorTimeM.setCronValue items[0]
          _selectorTimeH.setCronValue items[1]
          _selectorDow.setCronValue items[4]
        else if mask.substring(3, mask.length) is "-*"
          _selectorPeriod.setValue "year"
          _selectorMins.setCronValue items[0]
          _selectorTimeM.setCronValue items[0]
          _selectorTimeH.setCronValue items[1]
          _selectorDom.setCronValue items[2]
          _selectorMonth.setCronValue items[3]
        else
          _self.error _self.getText("error4")
        _self.clearError()
      return

    @closeSelectors = ->
      n = _selectors.length

      while n--
        _selectors[n].close()
      return

    @getId = ->
      _$elt.attr "id"

    @getText = (key) ->
      text = settings.texts[settings.lang][key] or null
      if typeof (text) is "string" and text.match("<b")
        text = text.replace(/(<b *\/>)/g, "</span><b /><span class=\"jqCron-text\">")
        text = "<span class=\"jqCron-text\">" + text + "</span>"
      text

    @getHumanText = ->
      texts = []
      _$obj.find("> span > span:visible").find(".jqCron-text, .jqCron-selector > span").each ->
        text = $(this).text().replace(/\s+$/g, "").replace(/^\s+/g, "")
        text and texts.push(text)
        return

      texts.join(" ").replace /\s:\s/g, ":"

    @getSettings = ->
      settings

    @error = (msg) ->
      console and console.error("[jqCron Error] " + msg)
      _$obj.addClass("jqCron-error").attr "title", msg
      throw msgreturn

    @clearError = ->
      _$obj.attr("title", "").removeClass "jqCron-error"
      return

    @clear = ->
      _selectorDom.setValue []
      _selectorDow.setValue []
      _selectorMins.setValue []
      _selectorMonth.setValue []
      _selectorTimeH.setValue []
      _selectorTimeM.setValue []
      _self.triggerChange()
      return

    @init = ->
      n = undefined
      i = undefined
      list = undefined
      return  if _initialized
      settings = jqCronMergeSettings(settings)
      settings.jquery_element or _self.error(_self.getText("error3"))
      _$elt = settings.jquery_element
      _$elt.append _$obj
      _$obj.data "id", settings.id
      _$obj.data "jqCron", _self
      _$obj.append _$blocks
      settings.no_reset_button or _$obj.append(_$cross)
      (not settings.disable) or _$obj.addClass("disable")
      _$blocks.append _$blockPERIOD
      _$blocks.append _$blockDOM
      _$blocks.append _$blockMONTH
      _$blocks.append _$blockMINS
      _$blocks.append _$blockDOW
      _$blocks.append _$blockTIME
      _$cross.click ->
        _self.isDisabled() or _self.clear()
        return

      _$obj.bind "cron:change", (evt, value) ->
        return  unless settings.bind_to
        settings.bind_method.set and settings.bind_method.set(settings.bind_to, value)
        _self.clearError()
        return

      _$blockPERIOD.append _self.getText("text_period")
      _selectorPeriod = newSelector(_$blockPERIOD, false, "period")
      settings.enabled_minute and _selectorPeriod.add("minute", _self.getText("name_minute"))
      settings.enabled_hour and _selectorPeriod.add("hour", _self.getText("name_hour"))
      settings.enabled_day and _selectorPeriod.add("day", _self.getText("name_day"))
      settings.enabled_week and _selectorPeriod.add("week", _self.getText("name_week"))
      settings.enabled_month and _selectorPeriod.add("month", _self.getText("name_month"))
      settings.enabled_year and _selectorPeriod.add("year", _self.getText("name_year"))
      _selectorPeriod.$.bind "selector:change", (e, value) ->
        _$blockDOM.hide()
        _$blockMONTH.hide()
        _$blockMINS.hide()
        _$blockDOW.hide()
        _$blockTIME.hide()
        if value is "hour"
          _$blockMINS.show()
        else if value is "day"
          _$blockTIME.show()
        else if value is "week"
          _$blockDOW.show()
          _$blockTIME.show()
        else if value is "month"
          _$blockDOM.show()
          _$blockTIME.show()
        else if value is "year"
          _$blockDOM.show()
          _$blockMONTH.show()
          _$blockTIME.show()
        return

      _selectorPeriod.setValue settings.default_period
      _$blockMINS.append _self.getText("text_mins")
      _selectorMins = newSelector(_$blockMINS, settings.multiple_mins, "minutes")
      i = 0
      list = settings.minutes

      while i < list.length
        _selectorMins.add list[i], list[i]
        i++
      _$blockTIME.append _self.getText("text_time")
      _selectorTimeH = newSelector(_$blockTIME, settings.multiple_time_hours, "time_hours")
      i = 0
      list = settings.hours

      while i < list.length
        _selectorTimeH.add list[i], list[i]
        i++
      _selectorTimeM = newSelector(_$blockTIME, settings.multiple_time_minutes, "time_minutes")
      i = 0
      list = settings.minutes

      while i < list.length
        _selectorTimeM.add list[i], list[i]
        i++
      _$blockDOW.append _self.getText("text_dow")
      _selectorDow = newSelector(_$blockDOW, settings.multiple_dow, "day_of_week")
      i = 0
      list = _self.getText("weekdays")

      while i < list.length
        _selectorDow.add i + 1, list[i]
        i++
      _$blockDOM.append _self.getText("text_dom")
      _selectorDom = newSelector(_$blockDOM, settings.multiple_dom, "day_of_month")
      i = 0
      list = settings.monthdays

      while i < list.length
        _selectorDom.add list[i], list[i]
        i++
      _$blockMONTH.append _self.getText("text_month")
      _selectorMonth = newSelector(_$blockMONTH, settings.multiple_month, "month")
      i = 0
      list = _self.getText("months")

      while i < list.length
        _selectorMonth.add i + 1, list[i]
        i++
      $("body").click ->
        i = undefined
        n = _selectors.length
        i = 0
        while i < n
          _selectors[i].close()
          i++
        return

      _initialized = true
      _self.setCron settings.default_value  if settings.default_value
      return

    @triggerChange = ->
      _$obj.trigger "cron:change", _self.getCron()
      return

    jqCronInstances.push this
    @$ = _$obj
    try
      @init()
      _self.triggerChange()
    return
  jqCronInstances = []
  @jqCron = jqCron
  return
).call this, jQuery

###*
jqCronSelector class

only work with jQuery UI
###
(($) ->
  jqCronSelector = (_cron, _$block, _multiple, _type) ->
    array_unique = (l) ->
      i = 0
      n = l.length
      k = {}
      a = []
      while i < n
        k[l[i]] or (k[l[i]] = 1 and a.push(l[i]))
        i++
      a
    _self = this
    _$list = $("<ul class=\"jqCron-selector-list\"></ul>")
    _$title = $("<span class=\"jqCron-selector-title\"></span>")
    _$selector = $("<span class=\"jqCron-selector\"></span>")
    _values = {}
    _value = []
    _hasNumericTexts = true
    _numeric_zero_pad = _cron.getSettings().numeric_zero_pad
    @getValue = ->
      (if _multiple then _value else _value[0])

    @getCronValue = ->
      return "*"  if _value.length is 0
      cron = [_value[0]]
      i = undefined
      s = _value[0]
      c = _value[0]
      n = _value.length
      i = 1
      while i < n
        if _value[i] is c + 1
          c = _value[i]
          cron[cron.length - 1] = s + "-" + c
        else
          s = c = _value[i]
          cron.push c
        i++
      cron.join ","

    @setCronValue = (str) ->
      values = []
      m = undefined
      i = undefined
      n = undefined
      if str isnt "*"
        until str is ""
          m = str.match(/^\*\/([0-9]+),?/)
          if m and m.length is 2
            i = 0
            while i <= 59
              values.push i
              i += (m[1] | 0)
            str = str.replace(m[0], "")
            continue
          m = str.match(/^([0-9]+)-([0-9]+)\/([0-9]+),?/)
          if m and m.length is 4
            i = (m[1] | 0)
            while i <= (m[2] | 0)
              values.push i
              i += (m[3] | 0)
            str = str.replace(m[0], "")
            continue
          m = str.match(/^([0-9]+)-([0-9]+),?/)
          if m and m.length is 3
            i = (m[1] | 0)
            while i <= (m[2] | 0)
              values.push i
              i++
            str = str.replace(m[0], "")
            continue
          m = str.match(/^([0-9]+),?/)
          if m and m.length is 2
            values.push m[1] | 0
            str = str.replace(m[0], "")
            continue
          return
      _self.setValue values
      return

    @close = ->
      _$selector.trigger "selector:close"
      return

    @open = ->
      _$selector.trigger "selector:open"
      return

    @isOpened = ->
      _$list.is ":visible"

    @addValue = (key) ->
      values = (if _multiple then _value.slice(0) else [])
      values.push key
      _self.setValue values
      return

    @removeValue = (key) ->
      if _multiple
        i = undefined
        newValue = []
        i = 0
        while i < _value.length
          newValue.push _value[i]  unless key is [_value[i]]
          i++
        _self.setValue newValue
      else
        _self.clear()
      return

    @setValue = (keys) ->
      i = undefined
      newKeys = []
      saved = _value.join(" ")
      keys = [keys]  unless $.isArray(keys)
      _$list.find("li").removeClass "selected"
      keys = array_unique(keys)
      keys.sort (a, b) ->
        ta = typeof (a)
        tb = typeof (b)
        if ta is tb and ta is "number"
          a - b
        else
          (if String(a) is String(b) then 0 else ((if String(a) < String(b) then -1 else 1)))

      if _multiple
        i = 0
        while i < keys.length
          if keys[i] of _values
            _values[keys[i]].addClass "selected"
            newKeys.push keys[i]
          i++
      else
        if keys[0] of _values
          _values[keys[0]].addClass "selected"
          newKeys.push keys[0]
      _value = newKeys
      unless saved is _value.join(" ")
        _$selector.trigger "selector:change", (if _multiple then keys else keys[0])
        return true
      false

    @getTitleText = ->
      getValueText = (key) ->
        (if (key of _values) then _values[key].text() else key)

      return _cron.getText("empty_" + _type) or _cron.getText("empty")  if _value.length is 0
      cron = [getValueText(_value[0])]
      i = undefined
      s = _value[0]
      c = _value[0]
      n = _value.length
      i = 1
      while i < n
        if _value[i] is c + 1
          c = _value[i]
          cron[cron.length - 1] = getValueText(s) + "-" + getValueText(c)
        else
          s = c = _value[i]
          cron.push getValueText(c)
        i++
      cron.join ","

    @clear = ->
      _values = {}
      _self.setValue []
      _$list.empty()
      return

    @add = (key, value) ->
      _hasNumericTexts = false  unless (value + "").match(/^[0-9]+$/)
      value = "0" + value  if _numeric_zero_pad and _hasNumericTexts and value < 10
      $item = $("<li>" + value + "</li>")
      _$list.append $item
      _values[key] = $item
      $item.click ->
        if _multiple and $(this).hasClass("selected")
          _self.removeValue key
        else
          _self.addValue key
          _self.close()  unless _multiple
        return
      if $item.length
        $item.eq(0).trigger 'click'

      return

    @$ = _$selector
    _$block.find("b:eq(0)").after(_$selector).remove()
    _$selector.addClass("jqCron-selector-" + _$block.find(".jqCron-selector").length).append(_$title).append(_$list).bind("selector:open", ->
      if _hasNumericTexts
        nbcols = 1
        n = _$list.find("li").length
        if n > 5 and n <= 16
          nbcols = 2
        else if n > 16 and n <= 23
          nbcols = 3
        else if n > 23 and n <= 40
          nbcols = 4
        else nbcols = 5  if n > 40
        _$list.addClass "cols" + nbcols
      _$list.show()
      return
    ).bind("selector:close", ->
      _$list.hide()
      return
    ).bind("selector:change", ->
      _$title.html _self.getTitleText()
      return
    ).click((e) ->
      e.stopPropagation()
      return
    ).trigger "selector:change"
    $.fn.disableSelection and _$selector.disableSelection()
    _$title.click (e) ->
      (if (_self.isOpened() or _cron.isDisabled()) then _self.close() else _self.open())
      return

    _self.close()
    _self.clear()
    return
  @jqCronSelector = jqCronSelector
  return
).call this, jQuery

###*
Generate unique id for each element.
Skip elements which have already an id.
###
(($) ->
  jqUID = 0
  jqGetUID = (prefix) ->
    id = undefined
    loop
      jqUID++
      id = ((prefix or "JQUID") + "") + jqUID
      return id  unless document.getElementById(id)
    return

  $.fn.uniqueId = (prefix) ->
    @each ->
      return  if $(this).attr("id")
      id = jqGetUID(prefix)
      $(this).attr "id", id
      return


  return
).call this, jQuery

###*
Extends jQuery selectors with new block selector
###
(($) ->
  $.extend $.expr[":"],
    container: (a) ->
      (a.tagName + "").toLowerCase() of
        a: 1
        abbr: 1
        acronym: 1
        address: 1
        b: 1
        big: 1
        blockquote: 1
        button: 1
        cite: 1
        code: 1
        dd: 1
        del: 1
        dfn: 1
        div: 1
        dt: 1
        em: 1
        fieldset: 1
        form: 1
        h1: 1
        h2: 1
        h3: 1
        h4: 1
        h5: 1
        h6: 1
        i: 1
        ins: 1
        kbd: 1
        label: 1
        li: 1
        p: 1
        pre: 1
        q: 1
        samp: 1
        small: 1
        span: 1
        strong: 1
        sub: 1
        sup: 1
        td: 1
        tt: 1

    autoclose: (a) ->
      (a.tagName + "").toLowerCase() of
        area: 1
        base: 1
        basefont: 1
        br: 1
        col: 1
        frame: 1
        hr: 1
        img: 1
        input: 1
        link: 1
        meta: 1
        param: 1

  return
).call this, jQuery
