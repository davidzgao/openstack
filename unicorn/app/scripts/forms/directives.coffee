'use strict'

directives = angular.module('Form.directives', [])

directives.directive('formBuilder', ["$formCommit", ($formCommit) ->
  ###
  # The base directive for build form framework.
  # Initial the wizard, buttons action and step validation.
  ###
  return {
    restrict: 'A'
    replace: true
    scope: {
      formOptions: '='
    }
    templateUrl: '../views/form/form.html'
    controller: ["$scope", ($scope) ->
      validateStep = (currentStepInd) ->
        currentStep = $scope.formOptions.steps[currentStepInd]
        stepFlag = false
        if currentStep.sorted_fields
          for field in currentStep.sorted_fields
            for fieK, fieV of field
              if typeof field[fieK] == 'object'
                fieldObj = field[fieK]
              if fieldObj
                if fieldObj.value != undefined and
                fieldObj.value != null and !fieldObj.invalidate
                  stepFlag = true
                else
                  if fieldObj.alternative
                    stepFlag = true
                  else if fieldObj.invalidate
                    stepFlag = false
                  else if fieldObj.restrictions
                    if !fieldObj.restrictions.required
                      stepFlag = true
                    else
                      stepFlag = false
                      $scope.$broadcast "#{fieK}"
                  else
                    $scope.$broadcast "#{fieK}"
                    stepFlag = false
              if !stepFlag
                return false
          return stepFlag

      $scope.stepChange = (direction) ->
        if direction == 'next'
          if validateStep($scope.form.currentStep)
            $scope.form.currentStep += 1
            $scope.form.steps[$scope.form.currentStep]['invalidate'] =
            false
          else
            $scope.form.steps[$scope.form.currentStep]['invalidate'] =
            true
        else if direction == 'prev'
          $scope.form.currentStep -= 1
        else if direction == 'commit'
          if validateStep($scope.form.currentStep)
            $formCommit $scope.form, $scope.formUpdate

      # The transfer station of message which
      # from each field scope
      $scope.$on 'alternative', (event, detail) ->
        $scope.$broadcast 'altChange', detail
        event.stopPropagation()

      $scope.$on 'decide', (event, detail) ->
        if !detail.targets
          $scope.$broadcast "decideOpts", null
        else
          $scope.$broadcast "decideOpts", detail
        event.stopPropagation()

      $scope.$on 'filter', (event, detail) ->
        if !detail.targets
          $scope.$broadcast "filterOpts", null
        else
          for item, results of detail.targets
            resList = []
            for res in results
              resList.push res.toString()
            $scope.$broadcast "filterOpts", {
              key: item
              value: resList
            }
        event.stopPropagation()

      #(TODO)ZhengYue: Replace this logical via field
      # Limit number input at select assgin ip address.
      $scope.$on 'assign_ip', (event, target) ->
        if not $scope.formOptions.steps[4]
          return
        baseFields = $scope.formOptions.steps[4].sorted_fields
        if target
          for fieldK, fieldV of baseFields
            if fieldV['number']
              fieldV['number']['editable'] = false
              fieldV['number']['value'] = 1
        else
          for fieldK, fieldV of baseFields
            if fieldV['number']
              fieldV['number']['editable'] = true
        event.stopPropagation()
    ]
    link: (scope, ele, attr) ->
      init = () ->
        scope.note = {
          prevStep: _("Prev Step")
          nextStep: _("Next Step")
          commit: _("Commit")
        }
      init()
      scope.$watch 'formOptions', (newVal, oldVal) ->
        if newVal
          scope.form = scope.formOptions
          scope.formUpdate = scope.form.update
  }
])
.directive 'formView', ['$modal', '$compile', '$http', '$cleanScope',
($modal, $compile, $http, $cleanScope) ->
  return {
    restrict: 'A'
    replace: true
    scope: {
      formOptions: '='
      target: '='
    }
    link: (scope, ele, attr) ->
      scope.$watch 'formOptions', (newVal, oldVal) ->
        if newVal
          if newVal.view == 'modal'
            modalCall = ->
              modalInstace = $modal.open {
                windowClass: "form-window"
                backdrop: 'static'
                templateUrl: '../views/form/form_modal_view.html'
                controller: ['$scope', '$modalInstance',
                  'formOptions', ($scope, $modalInstance, form) ->
                    $scope.formOptions = form
                    $.formModal = $modalInstance
                    $scope.close = () ->
                      $cleanScope()
                      $modalInstance.close()
                      if $.formModal
                        $.formModal = undefined
                ]
                resolve: {
                  formOptions: ->
                    scope.formOptions
                }
              }
            modalCall()
          else if newVal.view == 'flat'
            $http.get '../views/form/form_flat_view.html'
              .success (data) ->
                ele.html($compile(data)(scope))
  }
]
.directive 'flatField', [() ->
  return {
    restrict: 'A'
    replace: true
    scope: {
      flatField: '='
      key: '='
      state: '='
    }
    templateUrl: '../views/form/_flat_field.html'
    link: (scope, ele, attr) ->
  }
]
.directive 'fieldDispatcher', ['$compile', '$judgingByTag',
'$fieldValidator', ($compile, $judgingByTag, $fieldValidator) ->
  # Interface for build field
  return {
    restrict: 'A'
    replace: true
    scope: {
      field: '='
      key: '='
    }
    templateUrl: '../views/form/field_dispatcher.html'
    link: (scope, ele, attr) ->
      # Distribute the specific IMPL by field tag
      # Hidden the id field at view
      if scope.field.default_value and !scope.field.dep
        return

      scope.$on scope.key, (event, detail) ->
        $fieldValidator scope.field

      if scope.field.dep
        # Dep is a especial field, high priority
        # NOTE(ZhengYue): This a simple dep
        if scope.key == scope.field.dep.source
          # Action source
          scope.matchedField = 'custom-radio'
        else
          # Action target
          scope.matchedField = 'alternative'
      else
        # dispense by tag and datatype
        scope.matchedField = $judgingByTag(scope.field)

      # Render form field component by matched field tag
      matchedDirective = "form-#{scope.matchedField}-field"
      eleStr = "<div #{matchedDirective} key=key field=field></div>"
      if scope.matchedField == 'ip-input'
        eleStr = "<div #{matchedDirective} key=key field=field class='ip-input-area'></div>"
      fieldEle = $compile(eleStr)(scope)
      ele.append(fieldEle)
  }
]
.directive 'formIp', [() ->
  return {
    restrict: 'A'
    templateUrl: '../views/form/ip_input.html'
    replace: true
    scope: {
      address: '='
      validate: '&'
      set: '='
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
      $scope.validateCall = (passage, set) ->
        $scope.validate(passage, set)
    ]
    link: (scope, ele, attr) ->
      scope.init = () ->
        address = scope.address
        value = ''
        for pass, index in address.passages
          if pass.default != undefined
            if index != 3
              value = "#{value}#{pass.default}."
            else
              value = "#{value}#{pass.default}"
          else
            if index != 3
              value = "#{value}."
        if address.showCidr
          value = "#{value}/#{address.cidr.default}"
        address.value = value
      scope.init()
  }
]
.directive 'fieldValue', ['$http', '$window', ($http, $window) ->
  return {
    restrict: 'A'
    replace: true
    scope: {
      fieldValue: '='
      key: '='
    }
    templateUrl: '../views/form/_field_value.html'
    link: (scope) ->
      keyWordsMap = {
        instancess: 'servers'
        clusters: 'os-clusters'
      }
      if scope.fieldValue
        if scope.fieldValue.display_value
          scope.fieldValue.display_value =
            scope.fieldValue.display_value[scope.fieldValue.value]
        field = scope.fieldValue
        if field.key_words
          serverURL = $window.$UNICORN.settings.serverURL
          if field.tag == 'multi-select'
            scope.fieldValue.values = []
            for fieldV in field.value
              field.key_words = keyWordsMap[field.key_words] || field.key_words
              spec = fieldV
              if fieldV instanceof Object
                if fieldV['uuid']
                  spec = fieldV['uuid']
                  objKey = 'uuid'
                if fieldV['id']
                  spec = fieldV['id']
                  objKey = 'id'
              sourceURL = "#{serverURL}/#{field.key_words}/#{spec}"
              $http.get sourceURL
                .success (data, status) ->
                  if data
                    if data.name
                      scope.fieldValue.values.push data.name
                    else
                      scope.fieldValue.values.push fieldV
                  else
                    scope.fieldValue.values.push fieldV
          else if field.tag == 'complex_select'
            scope.fieldValue.values = []
            for fieldV in field.value
              if fieldV.subnet_id
                subnetURL = "#{serverURL}/subnets/#{fieldV.subnet_id}"
                $http.get subnetURL
                  .success (data, status) ->
                    if fieldV.fixed_ip
                      scope.fieldValue.values.push {
                        subnet: data.name
                        fixed_ip: fieldV.fixed_ip
                      }
                    else
                      scope.fieldValue.values.push {
                        subnet: data.name
                      }
          else
            if field.tag == 'update-input'
              adjustment = _ "Value after adjustment"
              scope.fieldValue.display_value = "#{adjustment}: #{field.value}"
            if field.source == 'floating_ip_pool'
              sourceURL = "#{serverURL}/networks/#{field.value[0].pool_id}"
              $http.get sourceURL
                .success (data, status) ->
                  if data
                    scope.fieldValue.display_value = data.name
                  if field.value[0].ip_address
                    scope.fieldValue.display_value += " #{field.value[0].ip_address}"
            else
              field.key_words = keyWordsMap[field.key_words] || field.key_words
              sourceURL = "#{serverURL}/#{field.key_words}/#{field.value}"
              $http.get sourceURL
                .success (data, status) ->
                  if data
                    if data.name
                      scope.fieldValue.display_value = data.name
                    else
                      scope.fieldValue.display_value = field.value
                  else
                      scope.fieldValue.display_value = field.value
        else
          if not scope.fieldValue.display_value
            scope.fieldValue.display_value = field.value
  }
]

formFieldCompontents = []

class UpdateInputField extends $unicorn.FormField
  slug: 'UpdateInput'
  templateName: 'updateinput'
  controller: ['$scope', '$injector', ($scope, $injector) ->
    $fieldValidator = $injector.get('$fieldValidator')
    $scope.validator = (field, index) ->
      $fieldValidator field
    $scope.init = () ->
      field = $scope.field

      if field.value
        field.value = field.value - field.source
      else
        field.value = 0

      $scope.dataType = 'number'
      if not field.restrictions
        $scope.dataType = 'text'
      else
        if not field.restrictions.number
          $scope.dataType = 'text'

      $scope.currentValue = _("Current number")
      # Extrace unit from field label
      unitPat = /.*\((.*)\)/
      unitMatch = unitPat.exec(field.label)
      if unitMatch
        $scope.unit = _ unitMatch[1]
      else
        $scope.unit = _ 'Pieces'

      $scope.placeholder = _ "Increase Number"
  ]
formFieldCompontents.push UpdateInputField

class InputField extends $unicorn.FormField
  slug: 'StandardInput'
  templateName: 'standard-input'
  controller: ["$scope", "$injector", ($scope, $injector) ->
    $fieldValidator = $injector.get('$fieldValidator')
    $scope.validator = (field, $index) ->
      $fieldValidator field
    $scope.passwordToText = (event) ->
      target = $(event.currentTarget)
      passwordField = target.siblings('input')
      if passwordField.attr('type') == 'password'
        passwordField.attr('type', 'text')
        target.removeClass('glyphicon-eye-open')
        target.addClass('glyphicon-eye-close')
      else
        passwordField.attr('type', 'password')
        target.removeClass('glyphicon-eye-close')
        target.addClass('glyphicon-eye-open')
      return
  ]
formFieldCompontents.push InputField

class CustomRadio extends $unicorn.FormField
  slug: 'CustomRadio'
  templateName: 'radio'
  controller: ['$scope', '$injector', ($scope, $injector) ->
    $scope.init = () ->
      $scope.sources = []
      if $scope.field.source
        for alt, index in $scope.field.source
          source = {
            name: alt
            value: alt
            available: true
          }
          $scope.sources.push source

      if $scope.field.dep
        dep = $scope.field.dep
        if dep.source == $scope.key
          $scope.switchRatio = (itemValue, index) ->
            $scope.field.value = itemValue
            $scope.field.invalidate = false
            $scope.$emit dep.action, {
              source: dep.source
              targets: dep.target
              index: index
            }
      setDefaultValue = () ->
        if $scope.field.value == undefined
          dep = $scope.field.dep
          for source, index in $scope.sources
            if source.available
              $scope.field.value = source.value
              if dep
                $scope.$emit dep.action, {
                  source: dep.source
                  targets: dep.target
                  index: index
                }
              break
          if $scope.field.value == undefined
            $scope.field.error_tips = _("No Available Option!")
            $scope.field.invalidate = true

      setDefaultValue()

      $scope.filterCallback = (detail) ->
        if not detail
          return
        if detail.key == $scope.key
          values = detail.value
          for alt, index in $scope.sources
            if values.indexOf(alt.value) >= 0
              $scope.sources[index].available = true
            else
              $scope.sources[index].available = false
              if $scope.field.value == alt.value
                $scope.field.value = undefined
          setDefaultValue()
  ]
formFieldCompontents.push CustomRadio

class StandardRadio extends $unicorn.FormField
  slug: 'StandardRadio'
  templateName: 's_radio'
  controller: ['$scope', ($scope) ->
    $scope.switchRatio = (index) ->
      $scope.field.value = $scope.field.source[index]
  ]
  link: (scope, ele, attr) ->
    init = () ->
      if scope.field.source.length > 0
        scope.field.value = scope.field.source[0]
    init()
formFieldCompontents.push StandardRadio

class Alternative extends $unicorn.FormField
  slug: 'Alternative'
  templateName: 'alt'
  controller: ["$scope", "$injector", ($scope,
  $injector) ->
    $fieldValidator = $injector.get('$fieldValidator')
    $judgingByTag = $injector.get('$judgingByTag')
    $compile = $injector.get('$compile')
    $scope.validator = (field, $index) ->
      $fieldValidator field

    $scope.init = (scope, ele, attr) ->
      $scope.matchedField = $judgingByTag($scope.field)
      dep = $scope.field.dep
      if dep.current != undefined
        if $scope.key == dep.current
          $scope.active = 'active'
          $scope.field.alternative = false
          if $scope.field.restrictions
            $scope.field.restrictions['required'] = true
          else
            $scope.field.restrictions = {
              required: true
            }
        else
          $scope.field.alternative = true
          if $scope.field.restrictions
            $scope.field.restrictions['required'] = false
          else
            $scope.field.restrictions = {
              required: false
            }
      else
        for tar, index in dep.target
          if tar == $scope.key
            $scope.index = index
            if index == 0
              $scope.active = 'active'
              $scope.field.alternative = false
            else
              $scope.field.alternative = true
      $scope.$on 'altChange', (event, detail) ->
        if detail.source == dep.source
          if $scope.key == detail.targets[detail.index]
            $scope.active = 'active'
            $scope.field.alternative = false
            $scope.field.restrictions['required'] = true
            # TODO(ZhengYue): Replace this logical by field limit
            if $scope.key == 'assign'
              $scope.$emit 'assign_ip', true
            else if $scope.key == 'auto'
              $scope.$emit 'assign_ip'
          else
            $scope.field.alternative = true
            $scope.active = null

      matchedDirective = "form-#{scope.matchedField}-field"
      eleStr = "<div #{matchedDirective} key=key field=field></div>"
      if scope.matchedField == 'ip-input'
        eleStr = "<div #{matchedDirective} key=key field=field class='ip-input-area'></div>"
      fieldEle = $compile(eleStr)(scope)
      ele.append(fieldEle)
  ]
formFieldCompontents.push Alternative

class SelectList extends $unicorn.FormField
  slug: 'SelectList'
  templateName: 'select_list'
  controller: ['$scope', '$injector', ($scope, $injector) ->
    $rootScope = $injector.get('$rootScope')
    $scope.selectedChange = (itemId) ->
      for source in $scope.field.source
        if source.id == itemId
          source.active = true
          $scope.field.value = source.id
        else
          source.active = false
    $scope.init = (scope, ele, attr) ->
      scope.tips = {
        noSource: _("No Available ") + _ scope.key
      }

      # Add interf relation in rootScope at first timo
      if scope.field.interf and not scope.field.alternative
        interf = scope.field.interf
        value = scope.field.value
        if interf
          if not $rootScope.field_decide
            $rootScope.field_decide = []
          if scope.field.source.length > 0 and not value
            value = [scope.field.source[0]]
          $rootScope.field_decide.push {
            source: interf.source
            value: value
            targets: interf.target
          }

      init = () ->
        if !scope.field.editable
          return
        scope.editable = true
        if scope.field.interf
          interf = scope.field.interf
          if interf.source == scope.key
            scope.selectedChange = (itemId) ->
              for source in scope.field.source
                if source.id == itemId
                  source.active = true
                  scope.field.value = source.id
                  # Send message for parent scope,
                  # notify may interference other field.
                  scope.$emit interf.action, {
                    source: interf.source
                    targets: source.limits
                  }
                else
                  source.active = false
            if scope.field.source.length > 0
              scope.selectedChange(scope.field.source[0])
        if scope.field.source.length > 0
          scope.field.source[0].active = true
          scope.field.value = scope.field.source[0].id
          # NOTE Add initial interference for other field
          if interf and not scope.field.alternative
            if scope.field.source[0].limits
              $rootScope.field_interference = []
              limits = scope.field.source[0].limits
              for limitK, limitV of limits
                init_interf = {key: limitK, value: limitV}
                $rootScope.field_interference.push init_interf
              scope.$emit interf.action, {
                source: interf.source
                targets: limits
              }

      init()

      scope.$watch 'field', (newVal, oldVal) ->
        if scope.field.interf and not scope.field.alternative
          interf = scope.field.interf
          if interf.source == scope.key
            # The source of action
            scope.$emit interf.action, {
              targets: interf.target
              source: interf.source
              value: [scope.field.value]
            }
            for source in scope.field.source
              if source.active == true
                scope.$emit interf.action, {
                  source: interf.source
                  targets: source.limits
                }
              break
      , true
  ]
formFieldCompontents.push SelectList

class SelectButton extends $unicorn.FormField
  slug: 'SelectButton'
  templateName: 'select_button'
  controller: ['$scope', '$injector', ($scope, $injector) ->
    $rootScope = $injector.get('$rootScope')
    $scope.itemClicked = (item) ->
      if $scope.optionsObjs[item.toString()].available == false
        return
      $scope.field.value = item

    $scope.init = (scope, ele, attr) ->
      scope.optionsObjs = {}
      sourceItemType = ''

      # Add handler for enable/disable at view.
      for opt, index in scope.field.source
        sourceItemType = typeof opt
        optObj = {available: true}
        # Choice the first to be field value
        if scope.field.value
          if scope.field.value == opt
            optObj.active = true
        else
          if index == 0
            optObj.active = true
            scope.field.value = opt
        scope.optionsObjs[opt] = optObj

      # INITIAL: Set initial status of options by interference.
      init_interfs = $rootScope.field_interference
      initLimits = []
      if init_interfs
        for init_interf in init_interfs
          if init_interf.key == scope.key
            for limit in init_interf.value
              initLimits.push limit.toString()
            avQueue = []
            for opt, avail of scope.optionsObjs
              if initLimits.indexOf(opt) < 0
                if scope.field.value
                  if scope.field.value.toString() == opt
                    scope.field.value = null
                  if avQueue.length > 0
                    scope.field.value = avQueue[0]
                avail.available = false
              else
                avail.available = true
                avQueue.push opt
                if !scope.field.value
                  scope.field.value = opt

      scope.filterCallback = (detail) ->
        if !detail
          # NOTE (ZhengYue): No detail info, go for no limits.
          for opt, avail of scope.optionsObjs
            avail.available = true
          return
        if scope.key == detail.key
          # Catch the limits related current key
          avQueue = []
          for opt, avail of scope.optionsObjs
            if detail.value.indexOf(opt) < 0
              if scope.field.value
                if scope.field.value.toString() == opt
                  scope.field.value = null
                if avQueue.length > 0
                  scope.field.value = avQueue[0]
              avail.available = false
              scope.optionsObjs[opt] = avail
            else
              avail.available = true
              avQueue.push opt
              if !scope.field.value
                scope.field.value = opt
        else
          # Ignore the irrelevant with current key.
          return

      scope.$watch "field", (newVal, oldVal) ->
        fieldV = newVal.value
        if fieldV
          for optK, optV of scope.optionsObjs
            if optK == fieldV.toString()
              optV.active = true
            else
              optV.active = false
        else
          for optK, optV of scope.optionsObjs
            optV.active = false
      , true
  ]
formFieldCompontents.push SelectButton

class MutiSelect extends $unicorn.FormField
  slug: 'MutiSelect'
  templateName: 'muti_select_list'
  controller: ['$scope', '$injector', ($scope, $injector) ->
    $rootScope = $injector.get('$rootScope')
    $scope.selectedChange = (itemId) ->
      values = []
      for item in $scope.field.source
        if item.id == itemId
          #(NOTE): Handle at last one be selected
          if item.selected and $scope.field.value.length > 1
            item.selected = false
          else
            item.selected = true
        if item.selected
          values.push item.id
      $scope.field.value = values

    $scope.init = (scope, ele, attr) ->
      noneTip = _ "No available "
      key = _ scope.key
      scope.tips = {
        noSource: _ "#{noneTip}#{key}"
      }

      # Add interf relation in rootScope at first time
      if scope.field.interf
        interf = scope.field.interf
        value = scope.field.value
        if interf
          if not $rootScope.field_decide
            $rootScope.field_decide = []
          if scope.field.source.length > 0 and not value
            value = [scope.field.source[0]]
          $rootScope.field_decide.push {
            source: interf.source
            value: value
            targets: interf.target
          }

      init = () ->
        if scope.field.value
          savedVals = []
          for savedVal in scope.field.value
            if typeof savedVal == 'object'
              savedVals.push savedVal['uuid'] || savedVal['id']
            else
              savedVals.push savedVal
          values = savedVals
          for source in scope.field.source
            if values.indexOf(source.id) >= 0
              source.selected = true
          scope.field.value = values
        else
          vals = []
          if scope.field.source
            source = scope.field.source
            if source.length > 0
              source[0].selected = true
              vals.push source[0].id
            else
              scope.field.invalidate = true
          scope.field.value = vals
        if !scope.field.editable
          return
        scope.editable = true
      init()

      scope.$watch 'field', (newVal, oldVal) ->
        if scope.field.interf
          interf = scope.field.interf
          if interf.source == scope.key
            # The source of action
            scope.$emit interf.action, {
              targets: interf.target
              source: interf.source
              value: scope.field.value
            }
      , true
]
formFieldCompontents.push MutiSelect

class ComSelect extends $unicorn.FormField
  slug: 'ComplexSelect'
  templateName: 'complex_select_list'
  controller: ['$scope', '$injector', ($scope, $injector) ->
    $rootScope = $injector.get('$rootScope')

    $scope.selectedChange = (index) ->
      for item in $scope.field.source
        if index == item.id
          item.selected = true
          $scope.field.value = item.selectedSubItem.id
        else
          item.selected = false

    $scope.subSelected = (item, id) ->
      for sub in item.subnets
        if id == sub.id
          sub.selected = true
          item.selectedSubItem = sub
          $scope.field.value = item.selectedSubItem.id
        else
          sub.selected = false

    $scope.init = (scope, ele, attr) ->
      noneTip = _ "No available "
      key = _ scope.key
      scope.tips = {
        noSource: _ "#{noneTip}#{key}"
      }

      if not scope.field.value
        for item, index in scope.field.source
          item.subnets[0].selected = true
          item.selectedSubItem = item.subnets[0]
          if index == 0
            item.selected = true
            scope.field.value = item.selectedSubItem.id
      else
        sub_id = scope.field.value[0].subnet_id
        for item, index in scope.field.source
          for subnet in item.subnets
            if subnet.id == sub_id
              subnet.selected = true
              item.selected = true
              item.selectedSubItem = subnet
              $scope.field.value = item.selectedSubItem.id
            else
              item.selectedSubItem = subnet

      # Add interf relation in rootScope at first time
      if scope.field.interf
        interf = scope.field.interf
        value = scope.field.value
        if interf
          if not $rootScope.field_decide
            $rootScope.field_decide = []
          $rootScope.field_decide.push {
            source: interf.source
            value: scope.field.value
            targets: interf.target
          }

      scope.$watch 'field', (newVal, oldVal) ->
        if scope.field.interf
          interf = scope.field.interf
          if interf.source == scope.key
            # The source of action
            scope.$emit interf.action, {
              targets: interf.target
              source: interf.source
              value: scope.field.value
            }
      , true
  ]

formFieldCompontents.push ComSelect

class IpInput extends $unicorn.FormField
  slug: 'IpInput'
  templateName: 'ipinput'
  controller: ['$scope', '$injector', ($scope, $injector) ->
    $rootScope = $injector.get('$rootScope')
    $http = $injector.get('$http')

    $scope.ipChange = (ip, ipSets, key) ->
      for ipSet in ipSets
        ipSet.select = ''
      if $scope.field.value
        if $scope.field.value[key]
          delete $scope.field.value[key]
      ip.select = 'selected'

    $scope.selectCancel = (ip, key, $event) ->
      ip.select = ''
      if $scope.field.value
        if $scope.field.value[key]
          delete $scope.field.value[key]
      $event.stopPropagation()

    $scope.init = (scope, ele, attr) ->
      scope.$watch 'field', (newVal, oldVal) ->
        if $unicorn.formUtils.isEmptyObject(newVal.value)
          newVal.invalidate = true
          newVal.error_tips = _ "This field can't be null!"
        else
          newVal.invalidate = false
          newVal.error_tips = ''
      , true
      scope.updateField = (address, set) ->
        if not scope.field.value
          scope.field.value = {}
        scope.field.value[set.key] = address.value

      availableCheck = (field, key, value, callback) ->
        detail = field.available_check
        if detail.body
          body = undefined
          body = $unicorn.formUtils.fillBody(detail.body, key, value)
        serverURL = $UNICORN.settings.serverURL
        url = "#{serverURL}#{detail.url}?rnd=#{new Date().getTime()}"
        $http[detail.method.toLowerCase()] url, body
          .success (data) ->
            if data
              callback data[detail.response_key]
            else
              callback false
          .error (data) ->
            callback false

      scope.validate = (address, sets) ->
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

        if scope.field.value
          if scope.field.value[sets.key]
            delete scope.field.value[sets.key]
        ipString = address.value
        ipTest = /^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$/
        if not ipTest.test(ipString)
          address.invalid = 'invalid'
          address.err_tip = _ 'Error format for ip address.'
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
                else
                  scope.updateField(address, sets)
              if scope.field.available_check
                res = availableCheck(scope.field, sets.key,
                address.value, avCallback)
              else
                address.invalid = 'valid'
                address.err_tip = ''
            else
              address.invalid = 'invalid'
              address.err_tip = _ 'The last sit of ip address not in available range.'

      getIpInputObj = $unicorn.formUtils.getIpInputObj

      getObjFromOri = (value) ->
        matched = false
        if not scope.ipObj
          return null
        for obj in scope.ipObj
          if obj.key == value
            matched = true
            return obj
        if not matched
          return null

      init = () ->
        if !scope.field.editable
          return
        if not scope.field.source
          $log.error "There has none source of field: #{scope.key}"
        scope.editable = true
        if scope.field.interf
          interf = scope.field.interf
          if $rootScope.field_decide
            for fieldDecide in $rootScope.field_decide
              if fieldDecide.source == interf.source and\
              fieldDecide.targets.indexOf(scope.key) > 0
                if fieldDecide.value
                  tmpObjs = []
                  curVal = fieldDecide.value
                  if typeof curVal == 'object'
                    if curVal instanceof Array and curVal.length > 0
                      curVal = curVal[0]
                    curDec = curVal['uuid'] || curVal['id']
                    savedVal = null
                    if curVal['fixed_ip']
                      savedVal = curVal['fixed_ip']
                  else
                    curDec = curVal
                    if scope.field.value and not savedVal
                      savedVal = scope.field.value[curVal]
                  currentSets = scope.field.source[curDec]
                  ipObjValue = getIpInputObj(currentSets.ranges,
                  savedVal, scope.validate)
                  ipObj = {
                    value: ipObjValue
                    key: curDec
                    name: currentSets.name
                  }
                  tmpObjs.push ipObj
                  scope.ipObj = tmpObjs
          scope.decideCallback = (detail) ->
            interf = scope.field.interf
            if detail.source == interf.source and\
            detail.targets.indexOf(scope.key) > 0
              if detail.value
                if scope.field.value
                  # Remove the selected value which not in new
                  # detail.value
                  for selected of scope.field.value
                    inDetail = false
                    for item in detail.value
                      if item == selected
                        inDetail = true
                        break
                    if not inDetail
                      delete scope.field.value[selected]
                tmpObjs = []
                value = detail.value
                # Confirm obj has been in scope before fresh scope
                # reserve 'selected' .etc attr at obj
                obj = getObjFromOri(value)
                if obj
                  tmpObjs.push obj
                else
                  sets = scope.field.source[value]
                  tmpObjs.push {
                    key: value
                    value: getIpInputObj sets.ranges, null, scope.validate
                    name: sets.name
                  }
                scope.ipObj = tmpObjs
      init()
  ]
formFieldCompontents.push IpInput

class DurationInput extends $unicorn.FormField
  slug: 'DurationInput'
  templateName: 'duration'
  controller: ['$scope', '$injector', ($scope, $injector) ->
    $rootScope = $injector.get('$rootScope')
    $scope.durationCheck = () ->
      val = $scope.duration.value
      if !val
        res = $scope.field.restrictions
        if res
          if res.required
            $scope.field.invalidate = true
            $scope.durationValidate = 'invalid'
            $scope.invalidMsg = _ "This field can't be null!"
          else
            $scope.field.invalidate = false
            $scope.durationValidate = ''
        else
          $scope.field.invalidate = false
          $scope.durationValidate = ''
        return
      if not /^[0-9]*$/.test(val)
        $scope.field.invalidate = true
        $scope.durationValidate = 'invalid'
        $scope.invalidMsg = _ "Must be a number."
      else
        $scope.field.value = $scope.currentUnit.value(val)
        $scope.field.invalidate = false
        $scope.durationValidate = ''

    $scope.selectChange = ($index) ->
      for item, index in $scope.itemOpts
        if index == $index
          item.active = true
          $scope.field.value = item.value
        else
          item.active = false

    $scope.custom = false
    $scope.customAction = _("Custome")
    $scope.selectAction = _("Select")
    $scope.choice = () ->
      $scope.custom = !$scope.custom
      $scope.field.custom = $scope.custom
      if !$scope.custom
        for item in $scope.itemOpts
          if item.active
            $scope.field.value = item.value
            break
      else
        $scope.duration = {}
        $scope.field.invalidate = false
        $scope.durationValidate = ''

    $scope.changeUnit = (index) ->
      $scope.currentUnit = $scope.unitList[index]

    $scope.init = (scope, ele, attr) ->
      scope.duration = {}

      scope.direction = 'dropup'
      if ele[0].offsetTop < 100
        scope.direction = 'dropdown'

      scope.unitList = [{
        verbose: _("Minutes")
        value: (value) -> return value * 60
      }, {
        verbose: _("Hour")
        value: (value) -> return value * 60 * 60
      }, {
        verbose: _("Day")
        value: (value) -> return value * 60 * 60 * 24
      }, {
        verbose: _("Month")
        value: (value) -> return value * 60 * 60 * 24 * 30
      }, {
        verbose: _("Year")
        value: (value) -> return value * 60 * 60 * 24 * 365
      }]

      scope.currentUnit = scope.unitList[0]

      minute = _ "Minutes"
      day = _ "Day"
      week = _ "Week"
      month = _ "Month"
      year = _ "Year"
      scope.itemOpts = [{
        name: "45 #{minute}"
        value: 45 * 60
        active: true
      }, {
        name: "1 #{day}"
        value: 1440 * 60
      }, {
        name: "1 #{week}"
        value: 1440 * 7 * 60
      }, {
        name: "1 #{month}"
        value: 1440 * 30 * 60
      }, {
        name: "1 #{year}"
        value: 1440 * 365 * 60
      }]
      if scope.field.value
        # Active the selected item at update form.
        for item in scope.itemOpts
          if item.value == scope.field.value
            item.active = true
          else
            item.active = false
      else
        scope.field.value = scope.itemOpts[0].value
]
formFieldCompontents.push DurationInput

class CheckboxInput extends $unicorn.FormField
  slug: 'Checkbox'
  templateName: 'checkbox'
  controller: ['$scope', '$injector', ($scope, $injector) ->
    $scope.init = (scope, ele, attr) ->
      init = () ->
        if scope.field.default_value
          scope.field.value = true
        else
          scope.field.value = false
      init()
  ]
formFieldCompontents.push CheckboxInput

class SlideInput extends $unicorn.FormField
  slug: 'Slide'
  templateName: 'slide'
formFieldCompontents.push SlideInput

class VacancyInput extends $unicorn.FormField
  slug: 'Vacancy'
  templateName: 'vacancy'
  controller: ['$scope', '$injector', ($scope, $injector) ->
    $scope.init = (scope, ele, attr) ->
      scope.field.value = scope.field.defautValue || 'vacancy'
  ]
formFieldCompontents.push VacancyInput

for com in formFieldCompontents
  field = new com()
  field.init(directives)
