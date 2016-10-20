window.$UNICORN = window.$UNICORN || {}
preInitial =
  removeElement: (_element) ->
    _parentElement = _element.parentNode
    if _parentElement
      _parentElement.removeChild _element

  uaMatch: (ua) ->
    ua = ua.toLowerCase()
    match = /(edge)\/([\w.]+)/.exec(ua) ||
            /(opr)[\/]([\w.]+)/.exec(ua) ||
            /(chrome)[ \/]([\w.]+)/.exec(ua) ||
            /(version)(applewebkit)[ \/]([\w.]+).*(safari)[ \/]([\w.]+)/.exec(ua) ||
            /(webkit)[ \/]([\w.]+).*(version)[ \/]([\w.]+).*(safari)[ \/]([\w.]+)/.exec(ua) ||
            /(webkit)[ \/]([\w.]+)/.exec(ua) ||
            /(opera)(?:.*version|)[ \/]([\w.]+)/.exec(ua) ||
            /(msie) ([\w.]+)/.exec(ua) ||
            ua.indexOf("trident") >= 0 && /(rv)(?::| )([\w.]+)/.exec(ua) ||
            ua.indexOf("compatible") < 0 && /(mozilla)(?:.*? rv:([\w.]+)|)/.exec(ua) || []

    pMatch = /(ipad)/.exec(ua) ||
             /(iphone)/.exec(ua) ||
             /(android)/.exec(ua) ||
             /(windows phone)/.exec(ua) ||
             /(win)/.exec(ua) ||
             /(mac)/.exec(ua) ||
             /(linux)/.exec(ua) ||
             /(cros)/.exec(ua) || []
    return {
      browser: match[5] or match[3] or match[1] or ""
      version: match[2] or match[4] or "0"
      versionNumber: match[4] or match[2] or "0"
      platform: pMatch[0] or ""
    }
  browser: ->
    matched = preInitial.uaMatch(window.navigator.userAgent)
    browser = {}
    if matched.browser
      browser[matched.browser] = true
      browser.version = matched.version
      browser.versionNumber = parseInt(matched.versionNumber, 10)
    browser[matched.platform] = true  if matched.platform

    # These are all considered mobile platforms, meaning they run a mobile browser
    browser.mobile = true  if browser.android or browser.ipad or browser.iphone or browser["windows phone"]

    # These are all considered desktop platforms, meaning they run a desktop browser
    browser.desktop = true  if browser.cros or browser.mac or browser.linux or browser.win

    # Chrome, Opera 15+ and Safari are webkit based browsers
    browser.webkit = true  if browser.chrome or browser.opr or browser.safari

    # IE11 has a new token so we will assign it msie to avoid breaking changes
    # IE12 disguises itself as Chrome, but adds a new Edge token.
    if browser.rv or browser.edge
      ie = "msie"
      matched.browser = ie
      browser[ie] = true

    # Opera 15+ are identified as opr
    if browser.opr
      opera = "opera"
      matched.browser = opera
      browser[opera] = true
    # Stock Android browsers are marked as Safari on Android.
    if browser.safari and browser.android
      android = "android"
      matched.browser = android
      browser[android] = true

    # mozilla match as firefox
    if browser.mozilla and matched.browser == 'mozilla'
      firefox = 'firefox'
      matched.browser = firefox

    # mozilla match as firefox
    if browser.msie and matched.browser == 'msie'
      msie = 'ie'
      matched.browser = msie

    # Assign the name and platform variable
    browser.name = matched.browser
    browser.platform = matched.platform
    return browser

  isBrowserFit: (browser, browserAllowed) ->
    for bro in browserAllowed
      if bro.name == browser.name
        if bro.version == "*"
          return true
        else if bro.version <= browser.versionNumber
          return true
    return false

  stopLoading: ->
    # stop loading.
    if window.stop
      window.stop()
    else if document.execCommand
      document.execCommand "stop"
    else
      throw "browser not support!!"
    location.stop()

  checkBrowser: ->
    browserAllowed = $UNICORN.settings.allowBrowsers
    current = preInitial.browser()
    brCheck = document.getElementById("_unicorn_browser_check")
    if preInitial.isBrowserFit(current, browserAllowed)
      preInitial.removeElement brCheck
      return true
    children = brCheck.children
    title = children[0]
    browsers = children[1]
    locale = $UNICORN.settings.locale || 'en'
    titleMsg =
      'en': "Browsers behind are supported"
      'zh_cn': "\u76ee\u524d\u53ea\u652f\u6301\u4ee5\u4e0b\u6d4f\u89c8\u5668"
    title.innerHTML = titleMsg[locale]
    allNodes = ""
    for bro in browserAllowed
      url = "href='#{bro.url}'"
      classes = "class='item browser_#{bro.name}'"
      allNodes += "<a #{classes} #{url}>"
      inner = bro.name
      if bro.version != "*"
        inner += "#{bro.version}+"
      allNodes += "#{inner}</a>"
    browsers.innerHTML = allNodes
    brCheck.style.display = 'block'
    loading = document.getElementById("_unicorn_pre_loading")
    app = document.getElementById("_unicorn_app_main")
    preInitial.removeElement loading
    preInitial.removeElement app

# initial settings
$UNICORN.settings = settings
window.settings = undefined
preInitial.checkBrowser()
