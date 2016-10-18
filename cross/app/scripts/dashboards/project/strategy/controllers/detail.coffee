'use strict'

angular.module('Cross.project.strategy')
  .controller 'project.strategy.StrategyDetailCtr', ($scope, $http, $window,
                                                   $q, $stateParams, $state, $animate) ->
    serverUrl = $CROSS.settings.serverURL
    $scope.detailItem = {
      save: _("Save")
      edit: _("Edit")
      cancel: _("Cancel")
      actions: _("Actions")
      info: _("Detail Info")
      flavorInfo: _("Flavor Info")
      item: {
        name: _("Name")
        status: _("Status")
        rotation: _("Rotation")
        target: _("Target")
        rule: _("Rule")
        triggerAt: _("Trigger At")
        timeout: _("Trigger timeout(s)")
      }
      floavorItem: {
        cpu: _("CPU")
        ram: _("RAM")
        disk: _("Disk")
      }
    }

    $scope.currentId = $stateParams['strategyId']

    $scope.editing = false

    $scope.edit = ->
      $scope.editing = true

    $scope.cancel = ->
      $scope.editing = false


    MAX_NAME_LEN = 32
    $scope.validator = (item, number) ->
      val = $scope.modal[item]
      if val == undefined
        val = ""
      if val.length >= MAX_NAME_LEN
        $scope.tips[item] = _('Must be shorter than 33')
        return false
      else if val == ""
        $scope.tips[item] = _('Can not be empty')
        return false
      if number
        if not /^[0-9]*$/.test(val)
          $scope.tips[item] = _("Must be a number.")
          return false
      $scope.tips[item] = ''
      return true

    $scope.tips = {}
    $scope.save = ->
      if not $scope.validator($scope.modal.timeout, true)
        return
      if not $scope.validator($scope.modal.rotation, true)
        return

      serverUrl = $CROSS.settings.serverURL
      body =
        timeout: $scope.modal.timeout
        parameters: {}
        template:
          interval: $scope.modal.interval
          server: $scope.template.template.server
          type: $scope.template.template.type
          task_type: 'cron'
          rotation: $scope.modal.rotation
      $http.put "#{serverUrl}/rules/#{$scope.currentId}", body
        .success ->
          $scope.template.template.interval = $scope.modal.interval
          $scope.template.triggerAt = $cross.utils.transCron $scope.modal.interval
          $scope.rule.timeout = $scope.modal.timeout
          $scope.template.template.rotation = $scope.modal.rotation
          toastr.success _("Successfully update rule: ") + $scope.rule.name
          $scope.cancel()
        .error (err) ->
          console.error "Failed to update rule:", err
          toastr.error _("Failed to update rule: ") + $scope.rule.name

    $scope.panle_close = () ->
      $animate.enabled(true)
      $state.go 'project.strategy'
      $scope.detail_show = false

    $scope.detailShow = ->
      container = angular.element('.ui-view-container')
      $scope.detailHeight = $(window).height() - container.offset().top
      $scope.detailHeight -= 50
      $scope.detailWidth = container.width() * 0.78

    if $scope.currentId
      $scope.detail_show = "detail_show"
    else
      $scope.detail_show = "detail_hide"
    $scope.detailShow()
    $window.onresize = ->
      $scope.detailShow()

    getStrategy = () ->
      ruleHttp = $http.get "#{serverUrl}/rules/#{$scope.currentId}"
      tempHttp = $http.get "#{serverUrl}/rules/#{$scope.currentId}/template"
      $q.all [ruleHttp, tempHttp]
        .then (rs) ->
          ruleTypeDict = {}
          for type in $CROSS.settings.ruleTypes
            ruleTypeDict[type.slug] = type
          rule = rs[0].data
          template = rs[1].data
          $scope.rule = rule
          $scope.rule.status = _($scope.rule.status)
          template.triggerAt = $cross.utils.transCron template.template.interval
          $scope.template = template
          $scope.modal =
            interval: template.template.interval
            rotation: template.template.rotation
            timeout: rule.timeout
          sources =
            instance:
              url: "#/project/instance/:id/overview"
              getUrl: "#{serverUrl}/servers/query"
              list: []
          if ruleTypeDict[template.template.type]
            ruleType = ruleTypeDict[template.template.type]
            $scope.template.rule = _(ruleType['name'])
            if sources[ruleType['sourceType']]
              params =
                params:
                  fields: '["name"]'
                  ids: JSON.stringify [template.template.server]
              type = ruleType['sourceType']
              $http.get sources[type].getUrl, params
                .success (rs) ->
                  if rs[template.template.server]
                    template.targetUrl = sources[type].url.replace ":id", template.template.server
                    template.target = rs[template.template.server].name
                .error (err) ->
                  console.log "Failed to get source:", template.template.server
        .catch (err) ->
          console.log err, "Failed to get projects/servers name"

    getStrategy()
