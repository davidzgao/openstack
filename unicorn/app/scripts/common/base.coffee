# define a namespace $unicorn
window.$unicorn =
  _debounce: (func, threshold, execAsap) ->

    timeout = undefined
    debounced = ->
      obj = @
      args = arguments
      delayed = ->
        if not execAsap
          func.apply obj, args
        timeout = null

      if timeout
        clearTimeout timeout
      else if execAsap
        func.apply obj, args

      timeout = setTimeout delayed, threshold || 100
    return debounced

  smartresize: ->
    angular.element.fn['smartresize'] = (fn) ->
      if fn
        @.bind 'resize', $unicorn._debounce(fn)
      else
        @.trigger 'smartresize'

  # define locale
  locale: {}

  initialPermissions: (cbk) ->
    # NOTE(liuhaobo): This XHR is used to get hypervisor_type&
    # enable_lbaas and storage in $UNICORN.settings.hypervisor_type&
    # $UNICORN.settings.enable_lbaas.
    #
    # NOTE(liuhaobo):Change the ajax async dispatch to sync dispatch
    # by use $.when() function.
    $.when(
      $.ajax({
        url: "#{$UNICORN.settings.serverURL}/regions"
        type: "GET"
        xhrFields:
          withCredentials: true
      }),
      $.ajax({
        url: "#{$UNICORN.settings.serverURL}/auth?getService=1"
        type: "GET"
        xhrFields:
          withCredentials: true
      })
    ).then((regions, services) ->
      for region in regions[0]
        if region.active
          extra = region.extra or {}
          $UNICORN.settings.region = region.name
          $UNICORN.settings.enable_ceph = extra.enable_ceph or\
                                          false
          $UNICORN.settings.enable_lbaas = extra.enable_lbaas or\
                                           false
          $UNICORN.settings.hypervisor_type = extra.hypervisor_type or\
                                              $UNICORN.settings.defaultHypervisorType or\
                                              "QEMU"
      $UNICORN.permissions = services[0]

      for service in services[0]
        if service == 'network'
          useNeutron = true
          break
      if useNeutron == true
        $UNICORN.settings.use_neutron = true
      else
        $UNICORN.settings.use_neutron = false

      cbk() if cbk
    ).fail((error) ->
      cbk(401) if cbk
    )

  checkLocation: () ->
    hash = location.hash
    if hash == '#/login'
      return true

  initialLocal: (locale) ->
    try
      transData = $.ajax({
        url: "locale/#{locale}.json"
        type: "GET"
        async: false
      }).responseText
      $unicorn.locale = JSON.parse(transData)
    catch error
      console.log "Load locale failed: %s", error

  checkDash: (cbk) ->
    $.ajax({
      url: "#{$UNICORN.settings.serverURL}/auth?unicorn=1"
      type: "GET"
      xhrFields:
        withCredentials: true
      success: (userData) ->
        $UNICORN.person = userData
        cbk() if cbk
      error: (err, status) ->
        console.error "Check error: ", err
        location.hash = '#/login'
        location.reload()
    })

  initialCentBox: ->
    $ele = angular.element('.unicorn-frame-main-center')
    if $ele.length
      topHeight = angular.element('.unicorn-frame-main-top-tool')
                       .css('height')
      windowHeight = angular.element(".unicorn-frame-left").height()
      $leftBar = angular.element(".unicorn-frame-left .unicorn-tool-nav")
      $eleHeight = parseInt(windowHeight)
      $ele.css({height: $eleHeight - $ele.offset().top})

      $leftBar.css {height: "#{$eleHeight-$leftBar.offset().top}px"}

  animateSector: (path, options) ->
    endDegrees = options.endDegrees
    endDegrees = if endDegrees < 360 then endDegrees else 359.999
    new_opts = options
    new_opts.endDegrees = 0
    timeDelta = parseInt(360 * 2 / endDegrees)
    if options.animate
      intervalId = setInterval ->
        new_opts.endDegrees += 2
        if new_opts.endDegrees >= endDegrees
          new_opts.endDegrees = endDegrees
          clearInterval intervalId
        $unicorn.annularSector path, options
      , timeDelta

  ###* Options:
   # - centerX, centerY: coordinates for the center of the circle
   # - startDegrees, endDegrees: fill between these angles, clockwise
   # - innerRadius, outerRadius: distance from the center
   # - thickness: distance between innerRadius and outerRadius
   #   You should only specify two out of three of the radii and thickness
  ###
  annularSector: (path, options) ->
    opts = $unicorn.optionsWithDefaults options
    p = [
      [opts.cx + opts.r2 * Math.cos(opts.startRadians),
       opts.cy + opts.r2 * Math.sin(opts.startRadians)],
      [opts.cx + opts.r2 * Math.cos(opts.closeRadians),
       opts.cy + opts.r2 * Math.sin(opts.closeRadians)],
      [opts.cx + opts.r1 * Math.cos(opts.closeRadians),
       opts.cy + opts.r1 * Math.sin(opts.closeRadians)],
      [opts.cx + opts.r1 * Math.cos(opts.startRadians),
       opts.cy + opts.r1 * Math.sin(opts.startRadians)],
    ]

    angleDiff = opts.closeRadians - opts.startRadians
    largeArc = if angleDiff % (Math.PI * 2) > Math.PI then 1 else 0
    cmds = []
    cmds.push "M#{p[0].join()}"
    cmds.push "A#{[opts.r2,opts.r2,0,largeArc,1,p[1]].join()}"
    cmds.push "L#{p[2].join()}"
    cmds.push "A#{[opts.r1,opts.r1,0,largeArc,0,p[3]].join()}"
    cmds.push "z"
    path.setAttribute 'd', cmds.join(' ')

  optionsWithDefaults: (o) ->
    # Create a new object so that we don't mutate the original
    o2 =
      cx: o.centerX || 0
      cy: o.centerY || 0
      startRadians: (o.startDegrees || 0) * Math.PI / 180
      closeRadians: (o.endDegrees || 0) * Math.PI / 180

    t = if o.thickness != undefined then o.thickness else 100
    if o.innerRadius != undefined
      o2.r1 = o.innerRadius

    o2.r1 = if o.outerRadius then o.outerRadius - t else 200 -t
    o2.r2 = if o.outerRadius then o.outerRadius else o2.r1 + t
    o2.r1 = if o2.r1 < 0 then 0 else o2.r1
    o2.r2 = if o2.r2 < 0 then 0 else o2.r2
    return o2

  getPageCountList: (currentPage, pageCount, maxCounts) ->
    __LIST_MAX__ = maxCounts
    list = []
    if pageCount <= __LIST_MAX__
      index = 0

      while index < pageCount
        list[index] = index
        index++
    else
      start = currentPage - Math.ceil(__LIST_MAX__ / 2)
      start = (if start < 0 then 0 else start)
      start = (if start + __LIST_MAX__ >= pageCount\
                then pageCount - __LIST_MAX__ else start)
      index = 0

      while index < __LIST_MAX__
        list[index] = start + index
        index++
    return list

  removeLoading: ->
    $("#_unicorn_pre_loading").remove()

  _toText: (text) ->
    len = text.length
    if len == 0
      return ""
    str = $unicorn.locale[text[0]] || text[0]
    if len == 2 and typeof text[1] == 'object'
      for key of text[1]
        str = str.replace("%(#{key})s", _(text[1][key]))
      return str
    counter = 1
    loop
      break if str.indexOf('%s') == -1
      str = str.replace "%s", (text[counter] || '')
      counter += 1
    return str

$unicorn.initial = ->
  # set toastr options
  toastr.options =
    closebutton: true
    hideDuration: 500
    extendedTimeOut: 500
    showMethod: 'slideDown'
    hideMethod: 'slideUp'
    timeOut: 3000
  $.ajaxSetup {
    headers:
      'X-platform': $UNICORN.settings.platform || 'Unicorn'
  }
  $unicorn.smartresize()
  $unicorn.initialCentBox()
  angular.element(window).smartresize ->
    $unicorn.initialCentBox()
  angular.element(".unicorn-frame-left").ready ->
    $unicorn.initialCentBox()

  # set locale
  $unicorn.initialLocal $UNICORN.settings.locale

  # set i18n text.
  window._ = (text) ->
    if text instanceof Array
      return $unicorn._toText(text)
    else if typeof text != 'string'
      return text
    trans = $unicorn.locale[text]
    return if trans then trans else text

# initial $unicorn util before loading app
$unicorn.initial()
