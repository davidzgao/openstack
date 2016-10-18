'use strict'

###*
 #
 #Directives
 #
###
angular.module("Cross.directives", [])
  .directive "exPopover", () ->
    return {
      restrict: 'A'
      scope:
        content: '='
      link: (scope, element, attrs) ->
        scope.$watch 'content', (contentNew, contentOld) ->
          $(element).popover('destroy')
          if contentNew != contentOld and contentOld == undefined
            $(element).popover({
              placement: 'top'
              trigger: 'hover'
              content: _ scope.content
            })
        , true
    }

  .directive "sectorDirective", ->
    {
      restrict: "C"
      scope:
        val: "="
      link: ($scope, $ele) ->
        $scope.$watch 'val', (val) ->
          # If val data not ready, skip.
          if val == undefined
            return

          if $cross.animateSector and $ele.find("path").length > 0
            $inner = $ele.find(".sector-inner").eq(0)
            $outer = $ele.find(".sector-outer").eq(0)
            percent = val
            innerSize = $inner.width()
            outerSize = $outer.width()
            path = $ele.find("path")[0]
            $cross.animateSector path,
              centerX: outerSize / 2
              centerY: outerSize / 2
              startDegrees: 0
              endDegrees: parseInt(3.60 * percent)
              innerRadius: innerSize / 2
              outerRadius: outerSize / 2
              animate: true
    }

  .directive "detailPanel", ->
    {
      restrict: "C"
      link: ($scope, $ele) ->
        resizeDetailPanel = ->
          container = angular.element ".ui-view-container"
          if not container.length
            return
          height = angular.element(window).height()
          detailHeight = height - container.offset().top
          actionGroup = container.find('.action_group')
          if actionGroup.children().length != 0
            detailHeight -= 50
          detailWidth = container.width() * 0.79
          $scope.detailWidth = detailWidth
          $scope.detailHeight = detailHeight

        resizeDetailPanel()
        angular.element(window).on 'resize', ->
          resizeDetailPanel()

        $scope.$on '$stateChangeSuccess', (event, toState) ->
          resizeDetailPanel()
    }
  .directive "networkTopologyDirective", ->
    {
      restrict: "C"
      scope:
        val: "="
      link: ($scope, $ele) ->
        $scope.$watch "val", (netView) ->
          # If topology or hostView data not ready, skip.
          if not netView
            return
          options = {}
          $cross.topology.drawNetView netView, $ele, options
    }
  .directive "hostTopologyDirective", ->
    {
      restrict: "C"
      scope:
        val: "="
      link: ($scope, $ele) ->
        $scope.$watch "val", (hostView) ->
          # If topology or hostView data not ready, skip.
          if not hostView
            return

          #options =
          #  type: "star"
          options = {}
          $cross.topology.drawHostView hostView, $ele, options
    }
  .directive "detailScroll", ->
    {
      restrict: "A"
      link: (scope, ele) ->
        ele.bind('mousewheel DOMMouseScroll', () ->
          # NOTE(ZhengYue): Provisional measures to fix scroll of
          # detail tab.
          originalEvent = event.originalEvent
          if originalEvent
            if originalEvent == 'wheel'
              originalEvent.wheelDelta = -120
            else if originalEvent.type == 'DOMMouseScroll'
              originalEvent.detail = 3
        )
    }
  .directive "fixSize", ->
    {
      restrict: "C"
      scope:
        val: "="
      link: ($scope, $ele, $attr) ->
        fixW = $attr['fixW'] || 2
        fixH = $attr['fixH'] || 1
        resize = ->
          $ele.css 'height', $ele.width() * fixH / fixW
        resize()
        $(window).on 'resize', ->
          resize()
    }
  .directive "cronDriective", ->
    {
      restrict: "C"
      scope:
        val: "="
      link: ($scope, $ele, $attr) ->
        # set zhCN.
        zhCN =
          empty: _('every')
          empty_minutes: _('every')
          empty_time_hours: _('every hour')
          empty_time_minutes: _('every minute')
          empty_day_of_week: _('every day')
          empty_day_of_month: _ 'every day'
          empty_month: _('every month')
          name_minute: _('minute')
          name_hour: _('hour')
          name_day: _('day')
          name_week: _('week')
          name_month: _('month')
          name_year: _('year')
          text_period: "#{_('every')} <b />"
          text_mins: " #{_('at')} <b />#{_('minite(s)')}"
          text_time: " #{_('at')} <b />:<b />"
          text_dow: " #{_('on')} <b />"
          text_month: " #{_('of')} <b />"
          text_dom: " #{_('on')} <b />"
          error1: 'The tag %s is not supported !'
          error2: 'Bad number of elements'
          error3: 'The jquery_element should be set into jqCron settings'
          error4: 'Unrecognized expression'
          weekdays: [
            _('monday'), _('tuesday'), _('wednesday'), _('thursday'),
            _('friday'), _('saturday'), _('sunday')
          ]
          months: [
            _('January'), _('February'), _('March'),
            _('April'), _('May'), _('June'), _('July'),
            _('August'), _('September'), _('October'),
            _('November'), _('December')
          ]
        defaultZhCN = $cross.jqCron.jqCronDefaultSettings.texts.zh_CN
        $cross.jqCron.jqCronDefaultSettings.texts.zh_CN = defaultZhCN || zhCN
        $target = angular.element "##{$attr.target}"
        cronSetting = $CROSS.settings.cronSetting
        if not cronSetting
          cronSetting =
            enabled_minute: false
            enabled_year: false
            enabled_month: false
            multiple_month: false
            multiple_mins: false
            multiple_time_hours: false
            multiple_time_minutes: false
            lang: 'zh_CN'
        ngModel = $target.controller("ngModel")
        defaultValue = "0 0 * * *"
        if $attr.defaultvalue != undefined
          defaultValue = $attr.defaultvalue
        ngModel.$setViewValue defaultValue
        cronSetting['default_value'] = defaultValue
        cronSetting['bind_to'] = $target
        cronSetting['bind_method'] =
          set: ($tar, val) ->
            $tar[0].value = val
            ngModel.$setViewValue val
        $ele.jqCron(cronSetting)
        return
    }
  .directive "selectDirective", ->
    {
      restrict: "C"
      scope:
        val: "="
        ngModel: "="
      link: ($scope, $ele, $attr) ->
        name = $ele.attr "name"
        select = $ele.siblings "[target='#{name}']"
        if not select.length
          select = angular.element("<div></div>")
          select.addClass "wrap-select-field"
          select.addClass "wrap-selection"
          select.attr "target", name

          # initial selected field.
          clkAct = angular.element "<div></div>"
          clkAct.addClass "wrap-select-clk"
          clkAct.addClass "wrap-selection"
          clkAct.appendTo select
          # initial selected side.
          side = angular.element "<div></div>"
          side.addClass "wrap-select-side"
          side.addClass "wrap-selection"
          side.appendTo select

        # initial options.
        initialOpts = ($list, $select) ->
          inner = $select.html()
          $list.html inner
          $list.unbind "change"
          $list.bind "change", ->
            val = $list.val()
            $select.find("option").each ->
              $opt = angular.element @
              if $opt.val() == val
                fieldVals = $scope.val
                ngModel = $select.controller("ngModel")
                if fieldVals[val]
                  ngModel.$setViewValue fieldVals[val].value
                  clkAct.html fieldVals[val].text
                else
                  ngModel.$setViewValue $opt.val()
                  clkAct.html $opt.html()
                return false

        listArea = angular.element "<select></select>"
        listArea.addClass "wrap-select-list"
        initialOpts listArea, $ele
        listArea.appendTo select

        classes = $attr.class
        for cls in classes.split(" ")
          if cls and cls != "selectDirective"
            select.addClass cls
        $ele.hide()
        select.insertAfter $ele

        listArea.bind 'focus', ->
          $this = angular.element @
          $this.parent().addClass 'focus'
          return true

        listArea.bind 'blur', ->
          $this = angular.element @
          $this.parent().removeClass 'focus'
          return true

        $scope.$watch "ngModel", (options) ->
          val = $scope.val
          key = null
          if val
            for ek in val
              if ek.value == options
                key = ek.text
                break
          if key != null
            listArea.attr "value", key
            clkAct.html key

        $scope.$watch "val", (options) ->
          if $scope.items
            return
          $list = select.find(".wrap-select-list")
          initialOpts $list, $ele
          $selectedOpt = $ele.find("option[selected]")
          if $selectedOpt.length
            listArea.attr "value", $selectedOpt.eq(0).html()
            clkAct.html $selectedOpt.eq(0).html()
        return
    }
  .directive "actionButton", () ->
    return {
      restrict: 'A'
      transclude: true
      scope: {
        'buttons': '='
        'items': '='
      }
      templateUrl: '../views/common/action_buttons.html'
      link: (scope, ele, attr) ->
        scope.more = _ 'More Action'
        scope.fresh = _ 'Refresh'
        if !scope.buttons
          return
        if scope.buttons.hasMore
          scope.moreAction = scope.buttons.buttonGroup
        if scope.buttons.searchOpts
          scope.searchOpts = scope.buttons.searchOpts
          scope.search = () ->
            scope.searchOpts.searchAction(scope.searchOpts.searchKey,
            scope.searchOpts.val)
        scope.actions = scope.buttons.buttons
        scope.$watch 'actions', (newVal) ->
          if !scope.actions
            return
          for action in scope.actions
            if action.enable
              action.action_enable = 'enabled'
            else
              action.action_enable = 'btn-disable'
            if action.restrict
              if !action.restrict.batch
                if scope.items.length > 1
                  action.enable = false
        , true

        scope.$watch 'items', (newVal) ->
          if !scope.actions
            return
          for action in scope.actions
            if action.restrict
              if !action.restrict.batch
                if scope.items.length > 1
                  action.enable = false

          if !scope.moreAction
            return
          scope.$watch 'moreAction', (newVal) ->
            for action in scope.moreAction
              if action.enable
                action.action_enable = 'enabled'
              else
                action.action_enable = 'btn-disable'
        , true
  }
  .directive('checklistModel', ['$parse', '$compile', ($parse, $compile) ->
    # contains
    contains = (arr, item) ->
      if angular.isArray(arr)
        for val in arr
          if angular.equals val, item
            return true
      return false

    # add
    add = (arr, item) ->
      if not angular.isArray(arr)
        arr = []
      if item in arr
          return arr
      arr.push item
      return arr

    # remove
    remove = (arr, item) ->
      if not angular.isArray(arr)
        return arr
      counter = 0
      len = arr.length
      loop
        break if counter >= len
        val = arr[counter]
        if angular.equals val, item
          arr.splice counter, 1
          break
        counter += 1
      return arr

    postLinkFn = (scope, elem, attrs) ->
      # compile with `ng-model` pointing to `checked`
      $compile(elem)(scope)

      # getter / setter for original model
      getter = $parse attrs.checklistModel
      setter = getter.assign

      # value added to list
      value = $parse(attrs.checklistValue) scope.$parent

      # watch UI checked change
      elem.bind "mousedown", ->
        current = getter scope.$parent
        if not scope.checked
          setter scope.$parent, add(current, value)
        else
          setter scope.$parent, remove(current, value)

      # watch original model change
      scope.$parent.$watch(attrs.checklistModel, (newArr, oldArr) ->
        scope.checked = contains(newArr, value)
      , true)

    {
      restrict: 'A'
      priority: 1000
      terminal: true
      scope: true
      compile: ($ele, $attrs) ->
        tagName = $ele[0].tagName
        if tagName != 'INPUT' || !$ele.attr('type', 'checkbox')
          throw 'checklist-model should be applied' +\
                ' to `input[type="checkbox"]`.'

        if !$attrs.checklistValue
          throw 'You should provide `checklist-value`.'

        # exclude recursion
        $ele.removeAttr 'checklist-model'

        # local scope var storing individual checkbox model
        $ele.attr 'ng-model', 'checked'

        return postLinkFn
    }
  ])
  .directive "formAutofillFix", ->
    return (scope, elem, attrs) ->
        elem.prop('method', 'POST')

        # Fix autofill issues where Angular doesn't
        # know about autofilled inputs.
        elem.unbind("submit").submit (e) ->
          e.preventDefault()
          elem.find('input, textarea, select')
            .trigger('input').trigger('change').trigger('keydown')
          scope.$apply attrs.ngSubmit
  .directive "editInPlace", () ->
    return {
      restrict: 'E'
      scope:
        value: '='
        action: '='
      template: '<span ng-click="edit()" ng-bind="value"></span><input ng-model="value"></input>'
      link: (scope, ele, attr) ->
        inputElement = angular.element(ele.children()[1])
        ele.addClass('edit-in-place')
        scope.edit = () ->
          scope.editing = true
          ele.addClass('active')
          inputElement[0].focus()

        inputElement.on('blur', () ->
          scope.editing = false
          ele.removeClass('active')
          scope.action()
        )
    }
  .directive "arrow", () ->
    return {
      restrict: 'A'
      scope: true
      link: (scope, ele, attr) ->
        if attr.class == 'accordion-tip'
        else
          collapse = ele.parent().parent()
          scope.$watch () ->
            if collapse.hasClass('in')
              opendHead = collapse.siblings('.panel-heading')
              accordionTip = opendHead.children().children().children()
              scope.tip = 'open'
            else
              scope.tip = 'close'
          , (newVal) ->
    }
  .directive "switchButton", () ->
    return {
      restrict: 'A',
      scope: {
        status: '='
        verbose: '='
        action: '&'
        enable: '='
        loading: '='
      },
      templateUrl: '../views/common/cross_switch_button.html'
      link: (scope, element, attrs) ->
        if scope.enable == undefined
          scope.enable = true
        scope.switchAlternate = scope.status
        scope.verbose = scope.verbose || scope.status
        scope.trunOn = () ->
          scope.action()
        scope.trunOff = () ->
          scope.action()
    }
  .directive 'loadImage', ['$http', '$window', ($http, $window) ->
    return {
      restrict: 'A'
      scope:
        url: '='
        item: '='
      link: (scope, element, attrs) ->
        img = new Image()
        serverURL = $window.$CROSS.settings.serverURL
        imageURL = "#{serverURL}/#{scope.url}"
        img.width = 200
        img.height = 60
        if scope.item
          if scope.item.imageData
            scope.imageSrc = scope.item.imageData
            img.src = scope.imageSrc
            $(element).append img
            return

        if scope.url
          $http.get imageURL
            .success (data) ->
              image = data.image
              scope.imageSrc = "data:image/#{image.type};base64,#{image.data}"
              img.src = scope.imageSrc
              if scope.item
                scope.item.imageData = img.src
              $(element).append img
    }]
  .directive "detailTab", ['$state', ($state) ->
    return {
      restrict: 'A',
      scope: {
        tabs: '='
      },
      templateUrl: '../views/common/detail_tabs.html',
      link: (scope, element, attrs) ->
        scope.detail_tabs = scope.tabs

        scope.panel_close = () ->
          stateName = $state.current.name
          names = stateName.split('.')
          if names.length >= 2
            $state.go "#{names[0]}.#{names[1]}"
    }]
  .directive "detailTips", () ->
    return {
      restrict: 'A',
      scope: {
        detail: '='
        flag: '='
      },
      templateUrl: '../views/common/detail_tips.html',
      link: (scope, element, attrs) ->
        scope.checking = true
        scope.loading = true
        scope.error = false
        scope.nodata = false
        scope.errorTips = _("Failed to load data!")

        scope.$watch 'detail', (newVal, oldVal) ->
          if newVal
            scope.loading = false
            scope.checking = false
          if !newVal
            scope.loading = true
            scope.checking = true
          if newVal == 'error'
            scope.loading = false
            scope.error = true
    }
  .directive 'resourceUsage', ['$state', ($state) ->
    return {
      restrict: 'C'
      scope: false
      link: (scope, element, attrs) ->
        linkMap = {
          instance: 'project.instance'
          vcpu: 'project.instance'
          ram: 'project.instance'
          volume: 'project.volume'
          volumeCapacity: 'project.volume'
          snapshot: ['project.volume', {tab: 'backup'}]
          floatingIP: 'project.public_net'
          securityGroup: 'project.security_group'
        }
        circle = $(element)
        circle.bind 'click', () ->
          clicked = attrs.val.split('.')[1]
          link = linkMap[clicked]
          if typeof link == 'string'
            $state.go link
          else if link instanceof Array
            $state.go link[0], link[1]
    }]
  .directive 'detailStitcher', [() ->
    return {
      restrict: 'A'
      templateUrl: '../views/common/detail_stitcher.html',
      replace: false
      scope: {
        source: '='
        keySet: '='
      }
      controller: ['$scope', '$element', ($scope, $element) ->
        $scope.editItem = (item) ->
          item.ori_value = $scope.source[item.key]
          item.inEdit = 'editing'

        $scope.editAction = (title) ->
          $scope.validate(title)
          if !title.inValidate
            title.editAction(title.key, $scope.source[title.key])
            title.inEdit = ''

        $scope.cancel = (title) ->
          title.inValidate = false
          title.validate = ''
          $scope.source[title.key] = title.ori_value
          title.inEdit = ''

        $scope.validate = (title) ->
          if title.restrictions
            if title.restrictions.len
              len = $scope.source[title.key].length
              if title.restrictions.len[0] > len
                title.inValidate = true
                title.validate = 'ng-invalid'
                title.errorTips = _('Length shoud be longer than ') +
                  title.restrictions.len[0]
              else if title.restrictions.len[1] < len
                title.inValidate = true
                title.validate = 'ng-invalid'
                title.errorTips = _('Length shoud be shorter than ') +
                  title.restrictions.len[1]
              else
                title.inValidate = false
                title.validate = ''
            if title.restrictions.ip
              val = $scope.source[title.key]
              IPv4 = "^((25[0-5]|2[0-4]\\d|[01]?\\d\\d?)\.)" +\
                     "{3}(25[0-5]|2[0-4]\\d|[01]?\\d\\d?)$"
              reIPv4 = new RegExp(IPv4)
              reIPv6 = /^([\da-fA-F]{1,4}:){7}[\da-fA-F]{1,4}$/
              if not reIPv4.test(val) && not reIPv6.test(val)
                rs = _("Must be an IP address.")
                title.inValidate = true
                title.validate = 'ng-invalid'
                title.errorTips = rs
              else
                title.inValidate = false
                title.validate = ''
      ]

      link: (scope, ele, attrs) ->
        scope.edit = _('Edit')
        scope.save = _('Save')
        scope.canc = _('Cancel')
    }
  ]
  .directive "tooltip", () ->
    return {
      restrict: 'A'
      scope:
        content: '='
      link: (scope, element, attrs) ->
        if !scope.content
          return
        if scope.content.length == 0
          return
        $(element).hover( () ->
          $(element).tooltip({
            html: true
            title: () ->
              return "<div class='tips'>" + scope.content + "</div>"
          })
          $(element).tooltip('show')
        )
    }
  .directive 'ipInput', [() ->
    return {
      restrict: 'A'
      templateUrl: '../views/common/ip_input.html',
      replace: true
      scope: {
        address: '='
        validate: '&'
        set: '='
      }
      controller: ["$scope", ($scope) ->
        int = /^[0-9]*$/
        $scope.checkValue = (type, index) ->
          $scope.init()
          if type == 'passage'
            passage = $scope.address.passages[index]
            value = passage.default
            if int.test(value)
              passage.invalidate = false
            else
              passage.invalidate = true
        $scope.validateCall = (passage, set) ->
          $scope.validate(passage, set)
      ]
      link: (scope, ele, attr) ->
        scope.init = () ->
          address = scope.address
          value = ''
          if not address
            return
          for pass, index in address.passages
            if pass.default != undefined
              if index != 3
                value = value + pass.default + '.'
              else
                value = value + pass.default
            else
              if index != 3
                value = value + '.'
          if address.showCidr
            value = value + '/' + address.cidr.default
          address.value = value
        scope.init()
    }
  ]
  .directive 'ipRange', ['$http', ($http) ->
    return {
      restrict: 'A'
      templateUrl: '../views/common/ip_range.html'
      replace: true
      scope: {
        ipRange: '='
        network: '='
      }
      controller: ['$scope', ($scope) ->
        $scope.selectIp = (ipIndex) ->
          for ip, index in $scope.passages
            if index == ipIndex
              ip.focused = 'focus'
            else
              ip.focused = ''
              $scope.$emit 'ip-canceled', {
                fixed_ip: ip
                network_id: $scope.network
              }
      ]
      link: (scope, ele, attr) ->
        availableCheck = (fixedIp, networkId, callback) ->
          body = {
            resource_type: 'networks'
            param: {
              network_id: networkId
              port_address: fixedIp
            }
          }
          serverURL = $CROSS.settings.serverURL
          url = "#{serverURL}/resource_check"
          $http.post url, body
            .success (data) ->
              if data
                callback data.is_available
              else
                callback false
            .error (err) ->
              callback false

        scope.validate = (address, networkId) ->
          sitCheck = (passage, sit) ->
            sit = parseInt(sit)
            ranges = passage.range
            exRange = true
            for range in ranges
              if sit >= parseInt(range.start) and \
              sit <= parseInt(range.end)
                exRange = false
                break
            if exRange
              return false
            else
              return true

          ipString = address.value
          ipTest = /^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$/
          if not ipTest.test(ipString)
            address.invalid = 'invalid'
            address.err_tip = _ 'Error format for ip address.'
            scope.$emit "ip-validate-result", false
            return false
          else
            ipPat = /\d+.\d+.\d+.(\d+)/
            ipMat = ipPat.exec(ipString)
            if ipMat
              lastSit = ipMat[1]
              res = sitCheck(address.passages[3], lastSit)
              if res
                address.invalid = 'valid'
                address.err_tip = ''
                # Check this ip is avaiable
                avCallback = (available) ->
                  if not available
                    address.invalid = 'invalid'
                    address.err_tip = _ 'This ip has been used.'
                    scope.$emit "ip-validate-result", false
                  else
                    scope.$emit 'ip-confirmed', {
                      fixed_ip: address.value
                      network_id: scope.network
                    }
                res = availableCheck(address.value, networkId, avCallback)
              else
                address.invalid = 'invalid'
                address.err_tip = _ 'The last sit of ip address not in available range.'
                scope.$emit "ip-validate-result", false
        getIpInputObj = (ipSets) ->
          ipPassage = []
          ipStage = ''
          for ip in ipSets
            if typeof ip == 'string'
              ipPassage.push {
                default: parseInt(ip)
                disable: true
              }
              ipStage = "#{ipStage}#{ip}"
            else
              edges = ip
              rangeTips = _ "Available range: "
              for edge, index in edges
                rangeTips = "#{rangeTips}#{edge.start}~#{edge.end}"
                if index == edges.lengeh - 1
                  rangeTips = "#{rangeTips}."
                else
                  rangeTips = "#{rangeTips}, "
              lastSit = {
                disable: false
                range: edges
                tip: rangeTips
              }
              ipPassage.push lastSit
          res = {
            passages: ipPassage
            showCidr: false
            validate: scope.validate
          }
          return res

        getSets = (subnet) ->
          cidr = subnet.cidr
          ipSegs = cidr.split('.')
          allocations = subnet.allocation_pools
          last_sit = []
          if allocations
            for pool in allocations
              start = pool.start.split('.')[3]
              end = pool.end.split('.')[3]
              last_sit.push({
                start: start
                end: end
              })
          else
            last_sit.push({
              start: 1
              end: 254
            })

          return [ipSegs[0], ipSegs[1], ipSegs[2], last_sit]
        ipSets = []
        for subnet in scope.ipRange
          ipSet = getSets(subnet)
          passage = getIpInputObj(ipSet)
          if $CROSS.settings.use_neutron
            passage.subnet_id = subnet.id
          ipSets.push passage
        scope.passages = ipSets
    }
  ]

angular.module("ui.bootstrap-slider", [])
  .directive "slider2", [
    "$parse"
    "$timeout"
    ($parse, $timeout) ->
      return (
        restrict: "AE"
        replace: true
        template: "<input type=\"text\" />"
        require: "ngModel"
        link: ($scope, element, attrs, ngModelCtrl) ->
          $.fn.slider.Constructor::disable = ->
            @picker.off()
            return

          $.fn.slider.Constructor::enable = ->
            @picker.on()
            return

          if attrs.ngChange
            ngModelCtrl.$viewChangeListeners.push ->
              $scope.$apply attrs.ngChange
              return

          options = {}
          options.id = attrs.sliderid  if attrs.sliderid
          options.min = parseFloat(attrs.min)  if attrs.min
          options.max = parseFloat(attrs.max)  if attrs.max
          options.step = parseFloat(attrs.step)  if attrs.step
          options.precision = parseFloat(attrs.precision)  if attrs.precision
          options.orientation = attrs.orientation  if attrs.orientation
          if attrs.value
            if angular.isNumber(attrs.value) or angular.isArray(attrs.value)
              options.value = attrs.value
            else if angular.isString(attrs.value)
              if attrs.value.indexOf("[") is 0
                options.value = angular.fromJson(attrs.value)
              else
                options.value = parseFloat(attrs.value)
          options.range = attrs.range is "true"  if attrs.range
          options.selection = attrs.selection  if attrs.selection
          options.tooltip = attrs.tooltip  if attrs.tooltip
          options.tooltip_separator = attrs.tooltipseparator  if attrs.tooltipseparator
          options.tooltip_split = attrs.tooltipsplit is "true"  if attrs.tooltipsplit
          options.handle = attrs.handle  if attrs.handle
          options.reversed = attrs.reversed is "true"  if attrs.reversed
          options.enabled = attrs.enabled is "true"  if attrs.enabled
          options.natural_arrow_keys = attrs.naturalarrowkeys is "true"  if attrs.naturalarrowkeys
          options.formater = $scope.$eval(attrs.formater)  if attrs.formater
          if options.range and not options.value
            options.value = [ # This is needed, because of value defined at $.fn.slider.defaults - default value 5 prevents creating range slider
              0
              0
            ]
          slider = $(element[0]).slider(options)
          updateEvent = attrs.updateevent or "slide"
          slider.on updateEvent, (ev) ->
            ngModelCtrl.$setViewValue ev.value
            $timeout ->
              $scope.$apply()
              return

            return

          $scope.$watch attrs.ngMax, (value) ->
            if value
              slider.slider('setAttribute', "max", value)
            return

          $scope.$watch attrs.ngModel, (value) ->
            slider.slider "setValue", value, false  if value or value is 0
            return

          if angular.isDefined(attrs.ngDisabled)
            $scope.$watch attrs.ngDisabled, (value) ->
              if value
                slider.slider "disable"
              else
                slider.slider "enable"
              return

          return
      )
  ]
