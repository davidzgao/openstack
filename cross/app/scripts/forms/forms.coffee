
app = angular.module("Form.builder", [])

app.constant '$formTypeMap', {
  'create_instance': _("Create Instance")
  'create_volume': _("Create Volume")
  'create_floating_ip': _("Create Floating IP")
}

app.factory '$loadTemplate', ["$http", "$window", "$log", ($http,
  $window, $log) ->
    return (type, $scope, callback) ->
      # TODO(ZhengYue): Add Loading tips
      serverURL = $window.$CROSS.settings.serverURL
      loadTemplateURL = "#{serverURL}/load_template"
      requestParams = {"request_type_name": type}
      $http.post loadTemplateURL, requestParams
        .success (data, status, headers) ->
          callback data, $scope
        .error (error) ->
          $log.error "Error at load workflow template."
  ]
  .factory '$dataLoader', ['$loadTemplate', '$state', '$formTypeMap',
  ($loadTemplate, $state, $formTypeMap) ->
  # Used to get specific workflow form origin data by workflow id/type
  # and do some initial parse.
    return ($scope, type, view, data) ->
      if (typeof String.prototype.endsWith != 'function')
        String.prototype.endsWith = (suffix) ->
          return this.indexOf(suffix, this.length - suffix.length) != -1
      preProcessing = (data, $scope, state) ->
        formOptions = {
          title: $formTypeMap[type] || type || 'None'
          slug: type || 'None'
          single: false
          steps: []
          content: data.content
          state: state
          id: $scope.currentId
        }
        pages = data.content.length
        if pages > 1
          morePages = true
        else
          formOptions.single = true

        # Analyze the dependency between fields
        # There are two types of field linkage
        if data.action_control
          action_control = data.action_control
          if action_control.length > 0
            keyRels = {}
            for relation in action_control
              for key in relation.target
                keyRels[key] = relation
              keyRels[relation.source] = relation
        else
          keyRels = undefined

        if data.interferences
          interferences = data.action_control
          if interferences.length > 0
            keyInters = {}
            for interference in interferences
              for target in interference.target
                keyInters[target] = interference
              keyInters[interference.source] = interference
        else
          keyInters = undefined

        if morePages
          for step, index in data.content
            if index == 0
              step.isActive = true
            else
              step.isActive = false

            sortedFields = []
            for fieK, fieV of step.fields
              if state != undefined
                if fieV.datatype == 'extend' and !fieV.display_value
                  if fieV.value and fieK != 'request_type_id'
                    if not fieK.endsWith('s')
                      fieV.key_words = fieK + 's'
                    else
                      fieV.key_words = fieK
              if fieV.default_value and !fieV.value
                if fieV.value != 0
                  fieV.value = fieV.default_value
              if keyRels
                if keyRels.hasOwnProperty(fieK)
                  step.fields[fieK].dep = keyRels[fieK]

              if keyInters
                if keyInters.hasOwnProperty(fieK)
                  step.fields[fieK].interf = keyInters[fieK]

              # HARD CODE(ZhengYue): handle_result
              if fieK == 'handle_result' and fieV.editable
                step.handle_result = true
              # Sort the fields in step by index
              if fieV.index != undefined
                sortedFields[fieV.index] = {}
                sortedFields[fieV.index][fieK] = fieV

            if sortedFields.length > 0
              step.sorted_fields = sortedFields
              delete step.fields

            formOptions.steps.push step
          formOptions.currentStep = 0
        $scope.formOptions = formOptions
        $scope.formOptions.view = view

      if data
        preProcessing data.content, $scope, data.state
      else
        $loadTemplate type, $scope, preProcessing
  ]
  .factory '$judgingByTag', ['$log', ($log) ->
    return (field) ->
      if field.tag == 'text' or field.tag == 'password'
        return 'standardInput.html'
      else if field.tag == 'item'
        return 'selectButton.html'
      else if field.tag == 'select' or field.tag == 'list'
        return 'selectList.html'
      else if field.tag == 'radio button' or field.tag == 'Radio Button'
        return 'standardRadio.html'
      else if field.tag == 'slide'
        field.value = field.restrictions.min
        return 'slide.html'
      else if field.tag == 'duration' or field.tag == 'datetext'
        return 'duration.html'
      else if field.tag == 'multi-select'
        return 'muti-select.html'
      else if field.tag == 'textarea'
        return 'standardInput.html'
      else if field.tag == 'checkbox'
        return 'checkbox.html'
      else
        $log.error "Tag of field has not matched!", field
  ]
  .factory '$formCommit', ["$http", "$window", "$log", "$state", ($http,
  $window, $log, $state) ->
    return (formOpts, update, callback) ->
      WORKFLOW_INIT_STATE = 1
      requestData = {
        content: {}
        request_type_id: formOpts.request_type_id
        state: WORKFLOW_INIT_STATE
      }
      for content in formOpts.content
        if content.sorted_fields
          fields = content.sorted_fields
          if content.group
            groups = []
            allSources = []
            for groupK, groupV of content.group
              groupObj = {}
              groupObj[groupK] = {}
              groupObj.target = groupK
              groupObj.source = groupV
              for item in groupV
                allSources.push item
              groups.push groupObj
          for param in fields
            for fieldName, fieldV of param
              if typeof param[fieldName] == 'object'
                if fieldV.alternative
                  continue
                fieldObj = {}
                fieldObj[fieldName] = fieldV.value
                requestData.content[fieldName] = fieldV.value
                if groups
                  if allSources.indexOf(fieldName) >= 0
                    delete requestData.content[fieldName]
                    for group in groups
                      if group.source.indexOf(fieldName) >=0
                        group[group.target][fieldName] = fieldV.value
        else
          # TODO (ZhengYue): Handle unsorted fields

      if groups
        for group in groups
          groupObj = {}
          requestData.content[group.target] = group[group.target]
      requestData.request_type_id = requestData.content.request_type_id

      serverURL = $window.$CROSS.settings.serverURL
      if update
        updateURL = "#{serverURL}/workflow-requests/#{formOpts.id}"
        if requestData.content.handle_result == 0
          requestData.state = 3
        else
          requestData.state = 2
        requestData.content = JSON.stringify(requestData.content)
        $http.put updateURL, requestData
          .success (data, status, headers) ->
            # TODO(ZhengYue): Use Callback replace the action
            $state.go 'admin.apply', {}, {reload: true}
            toastr.success _("Success approve apply!")
            if callback && typeof(callback) == 'function'
              callback()
          .error (error) ->
            toastr.error _("Sorry, failed to approve apply!")
            if callback && typeof(callback) == 'function'
              callback()
      else
        workflowRequestURL = "#{serverURL}/workflow-requests"
        requestData.content = JSON.stringify(requestData.content)
        $http.post workflowRequestURL, requestData
          .success (data, status, headers) ->
            toastr.success _("Success to commit apply!")
            if $.formModal
              $.formModal.close()
              $.formModal = undefined
            if callback && typeof(callback) == 'function'
              callback()
          .error (error) ->
            toastr.error _("Sorry, Error at commit the apply!")
            if callback && typeof(callback) == 'function'
              callback()
      return
  ]

app.directive 'formBuilder', ["$formCommit", ($formCommit) ->
    return {
      restrict: 'A'
      replace: true
      scope: {
        formOptions: '='
      }
      templateUrl: '../views/form/form.html'
      controller: ["$scope", ($scope) ->
        $scope.approveEnable = true
        $scope.approve = (step) ->
          $scope.approveEnable = false
          callback = () ->
            $scope.approveEnable = true
          $formCommit $scope.formOptions, true, callback

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
          else if direction == 'prev'
            $scope.form.currentStep -= 1
          else if direction == 'commit'
            if validateStep($scope.form.currentStep)
              $formCommit $scope.form

        # The transfer station of message which
        # from each field scope
        $scope.$on 'alternative', (event, detail) ->
          $scope.$broadcast 'altChange', detail

        $scope.$on 'filter', (event, detail) ->
          if !detail.targets
            $scope.$broadcast "filterOpts", null
          else
            for target in detail.targets
              for item, results of target
                resList = []
                for res in results
                  resList.push res.toString()
                $scope.$broadcast "filterOpts", {
                  key: item
                  value: resList
                }
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
    }
  ]
  .directive 'formView', ['$modal', '$compile', '$http',
  ($modal, $compile, $http) ->
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
                  windowClass: "window-larger"
                  backdrop: 'static'
                  templateUrl: '../views/form/form_modal_view.html'
                  controller: ['$scope', '$modalInstance',
                    'formOptions', ($scope, $modalInstance, form) ->
                      $scope.formOptions = form
                      $.formModal = $modalInstance
                      $scope.close = () ->
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
  .directive 'fieldBuilder', ['$http', '$compile', '$judgingByTag',
  ($http, $compile, $judgingByTag) ->
    # Interface for build field
    return {
      restrict: 'A'
      replace: true
      scope: {
        fieldBuilder: '='
        key: '='
      }
      templateUrl: '../views/form/_field_builder.html'
      controller: ["$scope", ($scope) ->
        raiseError = (field, tips) ->
          field.error_tips = tips
          field.invalidate = true
        cleanError = (field) ->
          field.error_tips = null
          field.invalidate = false

        $scope.validator = (field, index) ->
          rest = field.restrictions
          if !rest
            cleanError(field)
            return
          val = field.value
          if rest.required and field.datatype == 'string'
            if !val
              raiseError field, _("This field can't be null!")
              return
            if val.length == 0
              raiseError field, _("This field can't be null!")
              return
            else
              cleanError(field)

          if rest.required and field.tag == 'multi-select'
            if !val
              raiseError field, _("Select one item at last!")
              return

          if rest.length
            len = rest.length
            if len[1] < val.length
              raiseError field, _("Length must less than #{len[1]}")
            else if len[0] > val.length
              raiseError field, _("Length must long than #{len[0]}")
            else
              cleanError(field)

          if rest.email
            re = /\S+@\S+\.\S+/
            if not re.test(val)
              raiseError field, _("Email format error.")
            else
              cleanError(field)

          if field.datatype == 'number'
            if not /^[0-9]*$/.test(val)
              raiseError field, _("Must be a number.")
            else
              cleanError(field)
            if !field.invalidate
              if rest.min
                if val < rest.min
                  raiseError field, _("The value must greater than #{rest.min}")
                else if val > rest.max
                  raiseError field, _("The value must less than #{rest.max}")

      ]
      link: (scope, ele, attr) ->
        # Distribute the specific IMPL by field tag
        scope.field = scope.fieldBuilder
        # Hidden the id field at view
        if scope.field.default_value and !scope.field.dep
          return
        scope.$on scope.key, (event, detail) ->
          scope.validator scope.field

        if scope.field.dep
          # Dep is a especial field, high priority
          # NOTE(ZhengYue): This a simple dep
          if scope.key == scope.field.dep.source
            # Action source
            scope.matchedField = 'radio.html'
          else
            # Action target
            scope.matchedField = 'alternative.html'
        else
          # dispense bu tag and datatype
          scope.matchedField = $judgingByTag(scope.field)
    }
  ]
  .directive 'standardRadio', [() ->
    return {
      restrict: 'A'
      replace: true
      scope: {
        field: '='
        key: '='
      }
      templateUrl: '../views/form/_field_s_radio.html'
      controller: ["$scope", ($scope) ->
        $scope.switchRatio = (index) ->
          $scope.field.value = $scope.field.source[index]
      ]
      link: (scope, ele, attr) ->
        init = () ->
          if scope.field.source.length > 0
            scope.field.value = scope.field.source[0]
        init()
    }
  ]
  .directive 'customRadio', [() ->
    return {
      restrict: 'A'
      replace: true
      scope: {
        field: '='
        key: '='
      }
      templateUrl: '../views/form/_field_radio.html'
      link: (scope, ele, attr) ->
        init = () ->
          if scope.field.dep
            dep = scope.field.dep
            if dep.source == scope.key
              scope.switchRatio = (index) ->
                scope.field.value = scope.field.source[index]
                scope.$emit dep.action, {
                  source: dep.source
                  targets: dep.target
                  index: index
                }
          if scope.field.source.length > 0
            scope.field.value = scope.field.source[0]
        init()
    }
  ]
  .directive 'alternativeField', ['$judgingByTag', ($judgingByTag) ->
    return {
      restrict: 'A'
      replace: true
      scope: {
        field: '='
        key: '='
      }
      templateUrl: '../views/form/_field_alt.html'
      link: (scope, ele, attr) ->
        scope.matchedField = $judgingByTag(scope.field)
        dep = scope.field.dep
        for tar, index in dep.target
          if tar == scope.key
            scope.index = index
            if index == 0
              scope.active = 'active'
              scope.field.alternative = false
            else
              scope.field.alternative = true
        scope.$on 'altChange', (event, detail) ->
          if detail.source == dep.source
            if scope.key == detail.targets[detail.index]
              scope.active = 'active'
              scope.field.alternative = false
            else
              scope.field.alternative = true
              scope.active = null
    }
  ]
  .directive 'slideField', [() ->
    return {
      restrict: 'A'
      replace: true
      scope: {
        field: '='
        key: '='
      }
      templateUrl: '../views/form/_field_slide.html'
      link: (scope, ele, attr) ->
    }
  ]
  .directive 'selectList', ['$rootScope', ($rootScope) ->
    return {
      restrict: 'A'
      replace: true
      scope: {
        field: '='
        key: '='
      }
      templateUrl: '../views/form/_field_select_list.html'
      controller: ["$scope", ($scope) ->
        $scope.selectedChange = (itemId) ->
          for source in $scope.field.source
            if source.id == itemId
              source.active = true
              $scope.field.value = source.id
            else
              source.active = false
      ]
      link: (scope, ele, attr) ->
        scope.tips = {
          noSource: _("No Available #{_(scope.key)}")
          title: _("Select #{_(scope.key)}")
        }
        init = () ->
          if !scope.field.editable
            return
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
            if interf
              if scope.field.source[0].limits
                $rootScope.field_interference = []
                limits = scope.field.source[0].limits
                for limit in limits
                  for limitK, limitV of limit
                    init_interf = {key: limitK, value: limitV}
                    $rootScope.field_interference.push init_interf

        init()

    }
  ]
  .directive 'nestSelectList', ['$rootScope', ($rootScope) ->
    return {
      restrict: 'A'
      replace: true
      scope: {
        field: '='
        key: '='
      }
      templateUrl: '../views/form/_field_select_list.html'
      controller: ["$scope", ($scope) ->
        $scope.selectedChange = (itemId) ->
          if !itemId
            $scope.field.value = undefined
            $scope.defaultValue = true
          else
            $scope.defaultValue = false
          for source in $scope.field.source
            if source.id == itemId
              $scope.defalutValue = false
              source.active = true
              $scope.field.value = source.id
            else
              source.active = false
      ]
      link: (scope, ele, attr) ->
        scope.tips = {
          noSource: _("No Available #{scope.key}")
          title: _("Default")
        }
        init = () ->
          scope.showDefault = false
          if scope.field.restrictions
            if scope.field.restrictions.required
              scope.showDefault = false
          else
            scope.showDefault = true
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
            if scope.showDefault
              scope.defaultValue = true
            else
              scope.field.source[0].active = true
              scope.field.value = scope.field.source[0].id
              # NOTE Add initial interference for other field
              if interf
                if scope.field.source[0].limits
                  $rootScope.field_interference = []
                  limits = scope.field.source[0].limits
                  for limit in limits
                    for limitK, limitV of limit
                      init_interf = {key: limitK, value: limitV}
                      $rootScope.field_interference.push init_interf

        init()
    }
  ]
  .directive 'mutiSelect', ['$rootScope', ($rootScope) ->
    return {
      restrict: 'A'
      replace: true
      scope: {
        field: '='
        key: '='
      }
      templateUrl: '../views/form/_field_muti_select_list.html'
      controller: ["$scope", ($scope) ->
        $scope.selectedChange = (itemId) ->
          for item in $scope.field.source
            if item.id == itemId
              if item.selected
                item.selected = false
              else
                item.selected = true
      ]
      link: (scope, ele, attr) ->
        scope.tips = {
          noSource: _ "No available #{scope.key}"
        }

        scope.$watch 'field', (newVal, oldVal) ->
          if newVal.source
            values = []
            for item in newVal.source
              if item.selected
                values.push item.id

            if values.length > 0
              scope.field.value = values
              scope.field.invalidate = false
            else
              scope.field.value = undefined
        , true
    }
  ]
  .directive 'selectButton', ['$rootScope', ($rootScope) ->
    return {
      restrict: 'A'
      replace: true
      scope: {
        field: '='
        key: '='
      }
      templateUrl: '../views/form/_field_select_button.html'
      controller: ["$scope", ($scope) ->
        $scope.itemClicked = (item) ->
          if $scope.optionsObjs[item.toString()].available == false
            return
          $scope.field.value = item
      ]
      link: (scope, ele, attr) ->
        # TODO Add judge available at init
        scope.optionsObjs = {}
        sourceItemType = ''

        # Add handler for enable/disable at view.
        for opt, index in scope.field.source
          sourceItemType = typeof opt
          optObj = {available: true}
          # Choice the first to be field value
          if index == 0
            optObj.active = true
            scope.field.value = opt
          scope.optionsObjs[opt] = optObj

        # TODO(ZhengYue): Merage the similar code
        init_interfs = $rootScope.field_interference
        if init_interfs
          for init_interf in init_interfs
            if init_interf.key == scope.key
              initLimits = []
              for limit in init_interf.value
                initLimits.push limit.toString()
              for opt, avail of scope.optionsObjs
                if initLimits.indexOf(opt) < 0
                  if scope.field.value
                    if scope.field.value.toString() == opt
                      scope.field.value = null
                  avail.available = false
                else
                  avail.available = true
                  if !scope.field.value
                    scope.field.value = opt
        # Listen the filterOpts message to enable/disable options.
        scope.$on "filterOpts", (event, detail) ->
          if !detail
            for opt, avail of scope.optionsObjs
              avail.available = true
            return
          if scope.key == detail.key
            for opt, avail of scope.optionsObjs
              if detail.value.indexOf(opt) < 0
                if scope.field.value
                  if scope.field.value.toString() == opt
                    scope.field.value = null
                avail.available = false
              else
                avail.available = true
                if !scope.field.value
                  scope.field.value = opt
          else
            for opt, avail of scope.optionsObjs
              avail.available = true

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
    }
  ]
  .directive 'checkBox', [() ->
    return {
      restrict: 'A'
      replace: true
      scope: {
        field: '='
        key: '='
      }
      templateUrl: '../views/form/_field_checkbox.html'
      link: (scope, ele, attr) ->
        init = () ->
          if scope.field.default_value
            scope.field.value = true
          else
            scope.field.value = false
        init()
    }
  ]
  .directive 'durationInput', [() ->
    return {
      restrict: 'A'
      replace: true
      scope: {
        field: '='
        key: '='
      }
      templateUrl: '../views/form/_field_duration.html'
      controller: ["$scope", ($scope) ->
        $scope.selectChange = ($index) ->
          for item, index in $scope.itemOpts
            if index == $index
              item.active = true
              $scope.field.value = item.value
            else
              item.active = false
      ]
      link: (scope, ele, attr) ->
        minute = _ "Minutes"
        day = _ "Day"
        week = _ "Week"
        month = _ "Month"
        year = _ "Year"
        scope.itemOpts = [
          {
            name: "45 #{minute}"
            value: 45
            active: true
          }
          {
            name: "1 #{day}"
            value: 1440
          }
          {
            name: "3 #{day}"
            value: 1440 * 3
          }
          {
            name: "1 #{week}"
            value: 1440 * 7
          }
          {
            name: "1 #{month}"
            value: 1440 * 30
          }
          {
            name: "1 #{year}"
            value: 1440 * 365
          }
        ]
        scope.field.value = scope.itemOpts[0].value
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
            serverURL = $window.$CROSS.settings.serverURL
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
                  objValue = true

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
                  .error (err) ->
                    scope.fieldValue.values = field.value
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
                .error (err) ->
                  scope.fieldValue.display_value = field.value
          else
            if not scope.fieldValue.display_value
              scope.fieldValue.display_value = field.value
    }
  ]
