'use strict'

services = angular.module('Form.services', [])

services.constant '$formTypeMap', {
  'create_instance': _("Create Instance")
  'create_volume': _("Create Volume")
  'create_floating_ip': _("Create Floating IP")
}

services.factory '$loadTemplate', ["$http", "$window", "$log", ($http,
  $window, $log) ->
    return (type, $scope, callback) ->
      # TODO(ZhengYue): Add Loading tips
      $scope.showFormLoading = true
      serverURL = $window.$UNICORN.settings.serverURL
      loadTemplateURL = "#{serverURL}/load_template/#{type}"
      $http.get loadTemplateURL
        .success (data, status, headers) ->
          $scope.showFormLoading = false
          callback data, $scope
        .error (error) ->
          $scope.showFormLoading = false
          $log.error "Error at load workflow template."
  ]
  .factory '$randomName', () ->
    return (num) ->
      chars = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0',\
      'a', 'b', 'c', 'd', 'e', 'd', 'e', 'f', 'g', 'h', 'i', 'j',\
      'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v',\
      'w', 'x', 'y', 'z']
      res = ""

      for n in [1..num]
        id = Math.ceil(Math.random()*35)
        res += chars[id]

      return res
  .factory '$dataLoader', ['$loadTemplate', '$state', '$formTypeMap',
  '$http', '$window', '$randomName', ($loadTemplate, $state, $formTypeMap,
  $http, $window, $randomName) ->
  # Used to get specific workflow form origin data by workflow id/type
  # and do some initial parse.
    return ($scope, type, view, data, detail) ->
      if (typeof String.prototype.endsWith != 'function')
        String.prototype.endsWith = (suffix) ->
          return this.indexOf(suffix, this.length - suffix.length) != -1
      if data
        wf_id = data.id
      else
        wf_id = type

      preProcessing = (data, $scope, state) ->
        if $unicorn.wfTypesMap
          if $unicorn.wfTypesMap[type]
            type = $unicorn.wfTypesMap[type]
        formOptions = {
          title: $formTypeMap[type] || type || 'None'
          slug: type || 'None'
          single: false
          steps: []
          content: data.content
          state: state
          id: wf_id
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
          interferences = data.interferences
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
              if fieK == 'name'
                fieV.value = "instance-#{$randomName(6)}" if not fieV.value
              if fieK == 'number'
                fieV.value = 1
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
                  if fieK == keyRels[fieK].source
                    if step.fields[fieK].value
                      keyRels[fieK].current = step.fields[fieK].value
                    else if step.fields[fieK].value == 0
                      keyRels[fieK].current = 0
                    else if step.fields[fieK].value == false
                      keyRels[fieK].current = false
                  step.fields[fieK].dep = keyRels[fieK]

              if keyInters
                if keyInters.hasOwnProperty(fieK)
                  step.fields[fieK].interf = keyInters[fieK]

              # Sort the fields in step by index
              if fieV.index != undefined
                sortedFields[fieV.index] = {}
                sortedFields[fieV.index][fieK] = fieV

            if sortedFields.length > 0
              step.sorted_fields = sortedFields
              delete step.fields

            if step.page == 'handle_request'
              if !detail
                continue
            formOptions.steps.push step
          formOptions.currentStep = 0
        $scope.formOptions = formOptions
        $scope.formOptions.view = view
        $scope.formOptions.update = $scope.formUpdate
        #   when the wfType is create_volume and vmware
        # instance, set a notice flag.
        hypervisor = $UNICORN.settings.hypervisor_type
        if type == 'create_volume'\
        and hypervisor.toLowerCase() == 'vmware'
          $scope.formOptions.applyVolumeFlag = true
          $scope.formOptions.applyVolumeNotice = _ "Notice: \
          volume can only attach to instance which has powered \
          off."
        $scope.dataLoading = false

      if data
        $scope.formUpdate = true
        preProcessing data.content, $scope, data.state
      else
        $scope.formUpdate = false
        $loadTemplate type, $scope, preProcessing
  ]
  .factory '$judgingByTag', ['$log', ($log) ->
    return (field) ->
      if field.tag == 'text' or field.tag == 'password'
        return 'standard-input'
      else if field.tag == 'update-input'
        return 'update-input'
      else if field.tag == 'item'
        return 'select-button'
      else if field.tag == 'select' or field.tag == 'list'
        return 'select-list'
      else if field.tag == 'radio button' or field.tag == 'Radio Button'
        return 'standard-radio'
      else if field.tag == 'slide'
        field.value = field.restrictions.min
        return 'slide'
      else if field.tag == 'duration' or field.tag == 'datetext'
        return 'duration-input'
      else if field.tag == 'multi-select'
        return 'muti-select'
      else if field.tag == 'complex_select'
        return 'complex-select'
      else if field.tag == 'textarea'
        return 'standard-input'
      else if field.tag == 'checkbox'
        return 'checkbox'
      else if field.tag == 'ip_input'
        return 'ip-input'
      else if field.tag == 'vacancy'
        return 'vacancy'
      else
        $log.error "Tag of field has not matched!", field
  ]
  .factory '$formCommit', ["$http", "$window", "$log", "$state",
  "$rootScope", ($http, $window, $log, $state, $rootScope) ->
    return (formOpts, update) ->

      cleanScope = () ->
        delete $rootScope.field_interference
        delete $rootScope.field_decide

      WORKFLOW_INIT_STATE = 1
      requestData = {
        content: {}
        request_type_id: formOpts.id
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
          if content.assembly
            assembly = content.assembly
            assembly.target_values = {}
          for param in fields
            for fieldName, fieldV of param
              if typeof param[fieldName] == 'object'
                if fieldV.alternative
                  continue
                # NOTE: Add input value and source to be value if tag
                # is 'update-input'
                if fieldV.tag == 'update-input'
                  if not fieldV.value
                    fieldV.value = 0
                  requestData.content[fieldName] = \
                  fieldV.value + fieldV.source
                else
                  requestData.content[fieldName] = fieldV.value
                if groups
                  if allSources.indexOf(fieldName) >= 0
                    delete requestData.content[fieldName]
                    for group in groups
                      if group.source.indexOf(fieldName) >=0
                        group[group.target][fieldName] = fieldV.value
                if assembly
                  sourceFields = assembly.source_fields
                  if fieldName == assembly.target_field
                    assembly.source_value = fieldV.value
                  else if sourceFields.indexOf(fieldName) > 0
                    assembly.target_values[fieldName] = fieldV.value
        else
          # TODO (ZhengYue): Handle unsorted fields

      if groups
        for group in groups
          groupObj = {}
          requestData.content[group.target] = group[group.target]
      if assembly
        assemblyValues = []
        if typeof assembly.source_value is 'string'
          valueObj = {}
          value = assembly.source_value
          valueObj[assembly.keys_from_source] = value
          if assembly.target_values
            for targetName, targetValue of assembly.target_values
              if targetValue[value]
                valueObj[assembly.keys_from_target] = targetValue[value]
          assemblyValues.push valueObj
        else
          for value in assembly.source_value
            valueObj = {}
            valueObj[assembly.keys_from_source] = value
            if assembly.target_values
              for targetName, targetValue of assembly.target_values
                if targetValue[value]
                  valueObj[assembly.keys_from_target] = targetValue[value]
            assemblyValues.push valueObj
        requestData.content[assembly.target_field] = assemblyValues

      requestData.content.request_type_id = requestData.request_type_id
      serverURL = $window.$UNICORN.settings.serverURL
      cleanScope()
      if update
        updateURL = "#{serverURL}/workflow-requests/#{formOpts.id}"
        if requestData.state == 3
          requestData.content.handle_result = undefined
          requestDate.state = 1
        requestData.content = JSON.stringify(requestData.content)
        $http.put updateURL, requestData
          .success (data, status, headers) ->
            # TODO(ZhengYue): Use Callback replace the action
            $state.go 'dashboard.application', {}, {reload: true}
            toastr.success _("Success Update apply!")
            if $.formModal
              $.formModal.close()
              $.formModal = undefined
          .error (error) ->
            toastr.error _("Sorry, failed to update apply!")
      else
        workflowRequestURL = "#{serverURL}/workflow-requests"
        requestData.content = JSON.stringify(requestData.content)
        $http.post workflowRequestURL, requestData
          .success (data, status, headers) ->
            toastr.success _("Success to commit apply!")
            if $.formModal
              $.formModal.close()
              $.formModal = undefined
          .error (error) ->
            toastr.error _("Sorry, Error at commit the apply!")
  ]
  .factory '$fieldValidator', [() ->
    return (field) ->
      raiseError = (field, tips) ->
        field.error_tips = tips
        field.invalidate = true
      cleanError = (field) ->
        field.error_tips = null
        field.invalidate = false

      if field.invalidate and field.custom
        # NOTE(ZhengYue): The custom flag show the do validate
        # by the field itself.
        return
      if field.tag == 'vacancy'
        if not field.value
          field.value = field.tag
        cleanError(field)
        return
      rest = field.restrictions
      if !rest
        cleanError(field)
        return
      val = field.value
      if rest.required and (field.datatype == 'string' or 'extend')
        if !val
          raiseError field, _("This field can't be null!")
          return
        if val.length == 0
          raiseError field, _("This field can't be null!")
          return
        if field.datatype != 'string'
          if not /^[0-9]*$/.test(val)
            raiseError field, _("Must be a number.")
            return
          else
            tmpValue = Number(field.value)
            # Check range of field value
            if rest.range
              if rest.range.length == 2
                if tmpValue > rest.range[1] or \
                tmpValue < rest.range[0]
                  rangeTip = _ "The number must between: "
                  raiseError field, "#{rangeTip}#{rest.range[0]}~#{rest.range[1]}."
                  return
                else
                  cleanError(field)
                  field.value = tmpValue
            else
              cleanError(field)
              field.value = tmpValue
        cleanError(field)

      if rest.required and field.tag == 'multi-select'
        if !val
          raiseError field, _("Select one item at last!")
          return

      if rest.length
        len = rest.length
        if len[1] < val.length
          raiseError field, (_("Length must less than") + len[1])
        else if len[0] > val.length
          raiseError field, (_("Length must long than") + len[0])
        else
          cleanError(field)

      if rest.email
        re = /\S+@\S+\.\S+/
        if not re.test(val)
          raiseError field, _("Email format error.")
        else
          cleanError(field)

      if rest.reg
        if rest.reg == 'true'
          rest.reg = ///[-\da-zA-Z`=\\\[\];',./~!@#$%^&*()_+|{}:"<>?]*
                 ((\d+[a-zA-Z]+[-`=\\\[\];',./~!@#$%^&*()_+|{}:"<>?]+)
                 |(\d+[-`=\\\[\];',./~!@#$%^&*()_+|{}:"<>?]+[a-zA-Z]+)
                 |([a-zA-Z]+\d+[-`=\\\[\];',./~!@#$%^&*()_+|{}:"<>?]+)
                 |([a-zA-Z]+[-`=\\\[\];',./~!@#$%^&*()_+|{}:"<>?]+\d+)
                 |([-`=\\\[\];',./~!@#$%^&*()_+|{}:"<>?]+\d+[a-zA-Z]+)
                 |([-`=\\\[\];',./~!@#$%^&*()_+|{}:"<>?]+[a-zA-Z]+\d+))
                 [-\da-zA-Z`=\\\[\];',./~!@#$%^&*()_+|{}:"<>?]*///
        if not rest.reg.test(val)
          raiseError field, _(rest.tip || "Field format error.")
        else
          cleanError(field)

      if field.datatype == 'number'
        if not /^[0-9]*$/.test(val)
          raiseError field, _("Must be a number.")
        else
          field.value = Number(field.value)
          cleanError(field)
        if !field.invalidate
          if rest.min
            if val < rest.min
              raiseError field, _(["The value must greater than %s", rest.min])
            else if val > rest.max
              raiseError field, _(["The value must less than %s", rest.max])

  ]
  .factory '$cleanScope', ['$rootScope', ($rootScope) ->
    return () ->
      delete $rootScope.field_interference
      delete $rootScope.field_decide
  ]
