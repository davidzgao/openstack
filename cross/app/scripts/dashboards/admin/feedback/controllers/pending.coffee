'use strict'

angular.module('Cross.admin.feedback')
  .controller 'admin.feedback.pendingCtr', ($scope, $http, $window, $q,
  $state) ->
    $scope.AllSelectedItems = false
    $scope.NoSelectedItems = true

    $scope.showFooter = true
    $scope.unFristPage = false
    $scope.unLastPage = false

    $scope.totalServerItems = 0
    $scope.pagingOptions = {
      pageSizes: [15]
      pageSize: 15
      currentPage: 1
    }

    $scope.closeAction = _ "Close"
    $scope.refesh = _("Refresh")
    $scope.deleteEnableClass = 'btn-disable'

    $scope.feedbacks = []

    $scope.sort = {
      sortingOrder: "updated_at"
      reverse: true
    }

    $scope.columnDefs = [
      {
        field: 'title'
        displayName: _("Title")
        cellTemplate: '<div class="ngCellText enableClick"><a ui-sref="admin.feedback.feedId.overview({feedId: item.id})" ng-bind="item[col.field]"></a></div>'
      }
      {
        field: 'content'
        displayName: _("Content")
        cellTemplate: '<div class="ngCellText" ng-bind="item[col.field]"></div>'
      }
      {
        field: 'user_name'
        displayName: _("Reporter")
        cellTemplate: '<div class="ngCellText" ng-bind="item[col.field]"></div>'
      }
      {
        field: 'project_name'
        displayName: _("Project")
        cellTemplate: '<div class="ngCellText" ng-bind="item[col.field]"></div>'
      }
      {
        field: 'updated_at'
        displayName: _("Update At")
        cellTemplate: '<div class="ngCellText" >{{item[col.field] | dateLocalize | date:"yyyy-MM-dd HH:mm"}}</div>'
      }
    ]

    $scope.feedbacksOpts = {
      pagingOptions: $scope.pagingOptions
      showCheckbox: true
      columnDefs: $scope.columnDefs
      sort: $scope.sort
      pageMax: 5
    }

    $scope.setPagingData = (pagedData, total) ->
      $scope.feedbacks = pagedData
      $scope.totalServerItems = total
      $scope.pageCounts = Math.ceil(total / $scope.pagingOptions.pageSize)
      $scope.feedbacksOpts.data = $scope.feedbacks
      $scope.feedbacksOpts.pageCounts = $scope.pageCounts

      if !$scope.$$phase
        $scope.$apply()

    $scope.selectedItems = []

    $scope.deleteTips = _ "Are you sure delete feedback: "

    $scope.selectChange = () ->
      if $scope.selectedItems.length >= 1
        $scope.deleteTips = _ "Are you sure close feedback: "
        $scope.deleteEnableClass = 'btn-enable'
        angular.forEach $scope.selectedItems, (item, index) ->
          title = item.title
          if title.length > 15
            title = title.substr(0, 15)
          if index == ($scope.selectedItems.length - 1)
            $scope.deleteTips += title + " ?"
          else
            $scope.deleteTips += title + ", "
      else
        $scope.deleteEnableClass = 'btn-disable'

    $scope.getPagedDataAsync = (pageSize, currentPage, callback) ->
      setTimeout(() ->
        currentPage = currentPage - 1
        serverURL = $window.$CROSS.settings.serverURL
        fixArgs = '/feedbacks?all_project=True'
        pageArg = "&current_page=#{currentPage}&page_size=#{pageSize}"
        if $scope.currentTab == 'pending.tpl.html'
          feedbackParam = ""
        else if $scope.currentTab == 'processing.tpl.html'
          feedbackParam = '&state=1'
        else if $scope.currentTab == 'closed.tpl.html'
          feedbackParam = '&state=2'
        feedURL = "#{serverURL}#{fixArgs}#{pageArg}#{feedbackParam}"
        $http.get(feedURL)
          .success (data, status, headers) ->
            detailedList = []
            userList = []
            projectList = []
            for feedback in data.list
              userList.push feedback.user_id
              projectList.push feedback.project_id
            if userList.length > 0 and projectList.length > 0
              userURL = "#{serverURL}/users/query"
              projectURL = "#{serverURL}/projects/query"
              users = $http.get(userURL, {
                params:
                  ids: JSON.stringify userList
                  fields: '["name"]'
              }).then (response) ->
                return response.data
              projects = $http.get(projectURL, {
                params:
                  ids: JSON.stringify projectList
                  fields: '["name"]'
              }).then (response) ->
                return response.data

              $q.all([users, projects])
                .then (values) ->
                  userMap = values[0]
                  projectMap = values[1]

                  for feedback in data.list
                    userObj = userMap[feedback.user_id]
                    projectObj = projectMap[feedback.project_id]
                    if userObj
                      feedback.user_name = userObj.name
                    else
                      feedback.user_name = _ 'Deleted'
                    if projectObj
                      feedback.project_name = projectObj.name
                    else
                      feedback.project_name = _ 'Deleted'
                  $scope.setPagingData(data.list,
                                       data.total)
            else
              $scope.setPagingData(data.list, data.total)
            (callback && typeof(callback) == "function") && callback()
          .error (data, status, headers) ->
            $scope.setPagingData([], 0)
            toastr.error(_("Failed to get feedbacks!"))
            (callback && typeof(callback) == "function") && callback()
      , 300)

    $scope.getPagedDataAsync($scope.pagingOptions.pageSize,
                             $scope.pagingOptions.currentPage)

    watchCallback = (newVal, oldVal) ->
      $scope.feedbacksOpts.data = null
      if newVal != oldVal and newVal.currentPage != oldVal.currentPage
        $scope.getPagedDataAsync $scope.pagingOptions.pageSize,
                                 $scope.pagingOptions.currentPage

    $scope.$watch('pagingOptions', watchCallback, true)

    feedbackCallback = (newVal, oldVal) ->
      if newVal != oldVal
        selectedItems = []
        for feedback in newVal
          if $scope.selectedFeedbackId
            if ('' + feedback.id + '') == $scope.selectedFeedbackId
              feedback.isSelected = true
              $scope.selectedFeedbackId = undefined
          if feedback.isSelected == true
            selectedItems.push feedback

        $scope.selectedItems = selectedItems

    $scope.$watch('feedbacks', feedbackCallback, true)
    $scope.$watch('selectedItems', $scope.selectChange, true)

    $scope.closeFeedback = () ->
      angular.forEach $scope.selectedItems, (item, index) ->
        feedbackId = item.id
        $cross.closeFeedback $http, $window, feedbackId, (res) ->
          toastr.success(_("Success close feedback: ") + feedbackId)

    $scope.$on 'selected', (event, detail) ->
      if $scope.feedbacks.length > 0
        for feedback in $scope.feedbacks
          if ('' + feedback.id + '') == detail
            feedback.isSelected = true
          else
            feedback.isSelected = false
      else
        $scope.selectedFeedbackId = detail

    $scope.refresResource = (resource) ->
      $scope.feedbacksOpts.data = null
      $scope.getPagedDataAsync($scope.pagingOptions.pageSize,
                               $scope.pagingOptions.currentPage)
