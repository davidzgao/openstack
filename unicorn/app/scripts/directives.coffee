'use strict'

###*
 #
 #Directives
 #
###
angular.module("Unicorn.directives", [])
  .directive "desktopToken", () ->
    return {
      restrict: "E"
      template: "<iframe src='' style='display:none;' id='cloud_desktop'></iframe>"
      link: ($scope, $ele) ->
        ele = $ele.find("iframe")[0]
        url = "#{$UNICORN.settings.cloud_desktop}login"
        ele.setAttribute('src', url)
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

          if $unicorn.animateSector and $ele.find("path").length > 0
            $inner = $ele.find(".sector-inner").eq(0)
            $outer = $ele.find(".sector-outer").eq(0)
            percent = val
            innerSize = $inner.width()
            outerSize = $outer.width()
            path = $ele.find("path")[0]
            $unicorn.animateSector path,
              centerX: outerSize / 2
              centerY: outerSize / 2
              startDegrees: 0
              endDegrees: parseInt(3.60 * percent)
              innerRadius: innerSize / 2
              outerRadius: outerSize / 2
              animate: true
    }
  .directive "networkTopologyDirective", ->
    {
      restrict: "C"
      scope:
        val: "="
      link: ($scope, $ele) ->
        $scope.$watch "val", (netView) ->
          if not netView
            return
          options = {}
          $unicorn.topology.drawNetView netView, $ele, options
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
          $unicorn.topology.drawHostView hostView, $ele, options
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
        defaultZhCN = $unicorn.jqCron.jqCronDefaultSettings.texts.zh_CN
        $unicorn.jqCron.jqCronDefaultSettings.texts.zh_CN = defaultZhCN || zhCN
        $target = angular.element "##{$attr.target}"
        cronSetting = $UNICORN.settings.cronSetting
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
                ngModel.$setViewValue fieldVals[val].value
                clkAct.html fieldVals[val].text
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
          $list = select.find(".wrap-select-list")
          initialOpts $list, $ele
          $selectedOpt = $ele.find("option[selected]")
          if $selectedOpt.length
            listArea.attr "value", $selectedOpt.eq(0).html()
            clkAct.html $selectedOpt.eq(0).html()
        return
    }
  .directive('unicornConfirm', ['$modal', '$templateCache', ($modal, $templateCache) ->
    ModalInstanceCtrl = ($scope, $modalInstance, action, items,
    slug, addition, tips) ->
      names = []
      for item in items
        if item.name
          names.push(item.name)
        else if item.display_name
          names.push(item.display_name)
        else if item.label
          names.push(item.label)
        else if item.ip
          names.push(item.ip)
        else
          names.push(item.id)
      actionLower = action.toLowerCase()
      $scope.note =
        title: _("#{actionLower}") + _("action")
      nameStr = if names.length then ": #{names.join(', ')}" else ''
      slug = if slug then _("#{slug}") else ''
      $scope.message = _("Are you sure to ") +
                       _("#{actionLower}") +
                       "#{slug}#{nameStr}?"
      if tips
        $scope.message = tips
      if addition
        $scope.addition = true
        $scope.addition_message = addition.message
        $scope.addition_choice = addition.default

      $scope.cancelBtn = _ "Cancel"
      $scope.action = action
      $scope.ok = () ->
        $modalInstance.addition_choice = $scope.addition_choice
        $modalInstance.close()

      $scope.cancel = () ->
        $modalInstance.dismiss('cancel')

      $scope.additionChange = () ->
        if $scope.addition_choice == true
          $scope.addition_choice = false
        else
          $scope.addition_choice = true

    return {
      restrict: 'A',
      scope: {
        unicornConfirm: '&'
        items: '='
        addition: '='
        alarm: '='
      },
      link: (scope, element, attrs) ->
        modalCall = () ->
          modalInstance = $modal.open {
            templateUrl: '../views/common/_unicorn_confirm_footer.html'
            controller: ["$scope",
              "$modalInstance",
              "action",
              "items",
              "slug",
              "addition",
              "tips",
              ModalInstanceCtrl]
            resolve: {
              action: ->
                attrs.unicornConfirmAction || _('Confirm')
              items: ->
                scope.items || []
              slug: ->
                attrs.slug
              addition: ->
                scope.addition
              tips: ->
                attrs.tips
            }
          }

          modalInstance.result.then( () ->
            if scope.addition
              scope.addition.default = modalInstance.addition_choice
            scope.unicornConfirm({
              items: scope.items
              addition: modalInstance.addition_choice
            })
          )

        scope.$watch 'items', (items) ->
          if scope.alarm
            element.unbind()
            element.bind 'click', scope.unicornConfirm
          else if items
            enabledStatus = ['btn-enable', 'enabled']
            if items.length > 0 and attrs.actionEnable in enabledStatus
              element.unbind()
              element.bind 'click', modalCall
            else
              element.unbind 'click', modalCall
          if attrs.allowEmptyItems
            element.unbind()
            element.bind 'click', modalCall
        , true
    }
  ])
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
      },
      templateUrl: '../views/common/unicorn_switch_button.html'
      link: (scope, element, attrs) ->
        scope.switchAlternate = scope.status
        scope.verbose = scope.verbose || scope.status
        scope.trunOn = () ->
          scope.action()
        scope.trunOff = () ->
          scope.action()
    }
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
  .directive "tooltip", () ->
    return {
      restrict: 'A'
      scope:
        name: '='
        content: '='
      link: (scope, element, attrs) ->
        $(element).hover( () ->
          $(element).tooltip({
            html: true
            title: () ->
              return "<div class='tips'><li>" + scope.name + "</li><li>" + scope.content + "</li></div>"
          })
          $(element).tooltip('show')
        )
    }
  .directive "exPopover", () ->
    return {
      restrict: 'A'
      scope:
        name: '='
        content: '='
      link: (scope, element, attrs) ->
        $(element).popover({
          placement: 'auto'
          trigger: 'hover'
          title: _ scope.name
          content: _ scope.content
          container: $(element)
        })
    }
  .directive 'leftTime', [() ->
    return {
      restrict: 'A'
      replace: true
      template: "<span>{{parsedTime}}<span>"
      scope: {
        status: '='
        time: '='
      }
      link: (scope, ele, attr) ->
        hourEdge = 60 * 60
        dayEdge = hourEdge * 24
        monthEdge = dayEdge * 30
        yearEdge = monthEdge * 12

        scope.parsedTime = ''
        time = scope.time
        if time == null
          scope.parsedTime = _("Forever Use")
          return
        if Number(time) == 0
          scope.parsedTime = 0
          return
        if not time and scope.status == 'BUILD'
          scope.parsedTime = _("Collecting..")
          return
        if time
          if time > 60 and time < hourEdge
            minutes = parseInt(time / 60.0)
            seconds = parseInt((parseFloat(time / 60.0) - parseInt(time / 60.0)) * 60)
            if seconds == 0
              parsedTime = minutes + _('Minutes')
            else
              parsedTime = minutes + _('Minutes') + seconds + _('Seconds')
            scope.parsedTime = parsedTime
          else if time >= hourEdge and time < dayEdge
            hours = time / hourEdge
            hoursInt = parseInt(hours)
            minutes = parseInt((parseFloat(hours) - hoursInt) * 60)
            if minutes == 0
              parsedTime = hoursInt + _("Hours")
            else
              parsedTime = hoursInt + _("Hours") + minutes + _("Minutes")
            scope.parsedTime = parsedTime
          else if time >= dayEdge and time < monthEdge
            days = time / dayEdge
            dayInt = parseInt(days)
            hours = parseInt((parseFloat(days) - dayInt) * 24)
            if hours == 0
              parsedTime = dayInt + _("Days")
            else
              parsedTime = dayInt + _("Days") + hours + _("Hours")
            scope.parsedTime = parsedTime
          else if time >= monthEdge and time < yearEdge
            month = time / monthEdge
            monthInt = parseInt(month)
            days = parseInt((parseFloat(month) - monthInt) * 30)
            if days == 0
              parsedTime = monthInt + _("Month")
            else
              parsedTime = monthInt + _("Month") + days + _("Days")
            scope.parsedTime = parsedTime
          else if time >= yearEdge
            year = time / yearEdge
            yearInt = parseInt(year)
            month = parseInt((parseFloat(year) - yearInt) * 12)
            if month == 0
              parsedTime = yearInt + _("Years")
            else
              parsedTime = yearInt + _("Years") + month + _("Month")
            scope.parsedTime = parsedTime
          return
    }
  ]
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
      ]

      link: (scope, ele, attrs) ->
        scope.edit = _('Edit')
        scope.save = _('Save')
        scope.canc = _('Cancel')
    }
  ]
  .directive "simpleTooltip", () ->
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
      templateUrl: '../views/common/ip_input.html'
      replace: true
      scope: {
        address: '='
      }
      controller: ['$scope', ($scope) ->
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
      ]
      link: (scope, ele, attr) ->
        scope.init = () ->
          address = scope.address
          value = ''
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
