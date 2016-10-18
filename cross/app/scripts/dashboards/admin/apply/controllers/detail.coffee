'use strict'

angular.module 'Cross.admin.apply'
  .controller 'admin.apply.ApplyDetailCtr', ($scope, $http,
  $window, $q, $stateParams, $state, $selected, $detailShow,
  $dataLoader, $formCommit) ->
    $scope.detailItem = {
      info: _("Detail Info")
      item: {
        type: _("Apply Type")
        id: _("Id")
        create_at: _('Create At')
        project_name: _('Project Name')
        user_name: _('User Name')
        result: _('Apply Result')
        agree: _("Agree")
        reject: _("Reject")
        reason: _("Reason")
        cluster: _("Cluster")
      }
      commit: _("Confirm")
      apply_content: _("Apply Content")
      handle_apply: _("Apply Handle")
      default: _("Default")
    }

    applyOptions =
      dashboard: 'admin'
      slug: 'apply'
      tabs: [
        {
          name: _('Overview'),
          url: 'admin.apply.applyId.overview',
          available: true
        }
      ]
    applyDetail = new ApplyDetail(applyOptions)
    applyDetail.init($scope, {
      $http: $http
      $q: $q
      $window: $window
      $state: $state
      $stateParams: $stateParams
      $selected: $selected
      $detailShow: $detailShow
      $dataLoader: $dataLoader
    })

    $scope.approve = {
      agree: true
    }

    $scope.judgeApply = (attitude) ->
      if attitude == 'agree'
        $scope.approve.agree = true
      else
        $scope.approve.agree = false

    $scope.approveCommit = () ->
      dataParams = $formCommit $scope.formOptions, true
      dataParams.content.reject_reason = $scope.approve.reason
      if $scope.approve.agree
        dataParams.content.handle_result = 1
        dataParams.state = 2
        if dataParams.request_type_id == '3'
          dataParams.cluster = $scope.selectedCluster
      else
        dataParams.content.handle_result = 0
        dataParams.state = 3

      serverURL = $window.$CROSS.settings.serverURL
      updateURL = "#{serverURL}/workflow-requests/#{$scope.currentId}"
      dataParams.content = JSON.stringify(dataParams.content)
      $http.put updateURL, dataParams
        .success (data, status, headers) ->
          $state.go 'admin.apply', {}, {reload: true}
          toastr.success _("Success approve apply!")
        .error (error) ->
          toastr.error _("Sorry, failed to approve apply!")
      return

class ApplyDetail extends $cross.DetailView
  getDetail: ($scope, options) ->
    $window = options.$window
    $http = options.$http
    $q = options.$q
    $dataLoader = options.$dataLoader

    serverURL = $window.$CROSS.settings.serverURL
    applyParam = "#{serverURL}/workflow-requests/#{$scope.currentId}"
    $http.get applyParam
      .success (data, status, headers) ->
        $scope.apply_detail = data
        project_id = data.project_id
        user_id = data.user_id
        project = $http.get("#{serverURL}/projects/query", {
          params:
            ids: '["' + project_id + '"]'
            fields: '["name"]'
        })
        user = $http.get("#{serverURL}/users/query", {
          params:
            ids: '["' + user_id + '"]'
            fields: '["name"]'
        })
        $q.all([project, user])
          .then (res) ->
            projectData = res[0].data
            if projectData
              if projectData[project_id]
                project_name = projectData[project_id].name
            userData = res[1].data
            if userData
              if userData[user_id]
                user_name = userData[user_id].name
            if project_name
              $scope.apply_detail.project_name = project_name
            if user_name
              $scope.apply_detail.user_name = user_name
        if data.state == 1
          $scope.canApprove = true
        else
          $scope.canApprove = false
        quotaLimits = $scope.apply_detail.content.quota_limits
        if quotaLimits
          getQuotaLimits(quotaLimits, project_id)
        $dataLoader $scope, data.request_type_name,
        'flat', $scope.apply_detail
      .error (data, status, headers) ->
        toastr.error _("Failed to get apply detail.")

    getQuotaLimits = (quotaLimits, projectId) ->
      limitServices = []
      quotaItemMap = {}
      for limit in quotaLimits
        quotaItemMap[limit.item] = limit
        if limitServices.indexOf(limit.service) < 0
          limitServices.push limit.service

      quotaSets = []
      for service in limitServices
        quotaSetURL = "#{serverURL}/#{service}/os-quota-sets/#{projectId}?usage=true"
        quotaSets.push $http.get(quotaSetURL)
      if quotaSets.length > 0
        $q.all quotaSets
          .then (res, err) ->
            usageSet = {}
            for usage in res
              usageSet = $.extend(usageSet, usage.data)
            out_limit_items = []
            for field, value of quotaItemMap
              if usageSet[field]
                limit = usageSet[field].limit
                used = usageSet[field].in_use
                countOfApply = value.value
                if quotaItemMap.instances
                  if field != 'instances'

                    countOfApply = value.value * quotaItemMap.instances.value
                demand = used + countOfApply
                if demand > limit
                  if field == 'ram'
                    countOfApply = (countOfApply / 1024).toFixed(1)
                    limit = (limit / 1024).toFixed(1)
                  data = {item: field, limit: limit, value: value.value, used: used}
                  msg = "#{_ 'Field'}: #{_ value.field}; #{_ 'Used/Limit'}: #{used}/#{limit}; #{_ 'Count of apply'}: #{countOfApply}"
                  out_limit_items.push {data: data, msg: msg}
            if out_limit_items.length > 0
              $scope.outQuota = {
                status: true
                header: _ 'Important Notes'
                tips: _ 'Current apply has out of project quotas limits, please reject the apply or extend quotas.'
                itemHeader: _ 'Items detail of out limits:'
                items: out_limit_items
              }
