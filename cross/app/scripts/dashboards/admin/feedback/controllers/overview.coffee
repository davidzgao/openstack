'use strict'

angular.module('Cross.admin.feedback')
  .controller 'admin.feedback.FeedbackOverviewCtr', ($scope, $http,
  $window, $q, $stateParams, $state) ->
    $scope.currentId = $stateParams.feedId

    $scope.stateMap = {
      0: _("Untreated")
      1: _("Processing")
      2: _("Closed")
    }
    $scope.detailItem = {
      info: _("Feedback Info")
      replay: _("Detail Of Replies")
      item: {
        title: _("Title")
        id: _ "ID"
        createAt: _ "Create At"
        lastReply: _ "Recent Reply"
        user: _ "Reporter"
        project: _ "Belong Project"
        initial: _ "Initial Content"
        status: _ "Status"
      }
    }

    serverURL = $window.$CROSS.settings.serverURL
    $scope.getFeedback = () ->
      $cross.feedback $http, $window, $q, $scope.currentId, (data) ->
        data.status = $scope.stateMap[data.state]
        $scope.feedback = data
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
              $scope.feedback.project_name = project_name
            if user_name
              $scope.feedback.user_name = user_name

    $scope.getFeedback()
  .controller 'admin.feedback.FeedbackReplyCtr', ($scope, $http,
  $window, $q, $stateParams, $state, $cookieStore) ->
    $scope.currentId = $stateParams.feedId

    currentUserId = $cookieStore.get('currentUserId')

    REPLY_MAX_LENGTH = 350

    $scope.addReplyTips = _("Add new reply.")
    $scope.addReply = _("Commit")
    $scope.feed = {}
    $scope.feed.newReply = ""
    $scope.submitEnableClass = "btn-disable"

    $scope.detailItem = {
      replay: _("Detail Of Replies")
      item: {
        initial: _ "Initial Content"
      }
    }

    $scope.noReply = _("No Replies!")
    $scope.replies = []
    $scope.replyTotal = 0
    $scope.showFooter = false
    $scope.canReply = true

    $scope.changePage = (pageCode) ->
      $scope.currentPage = $scope.showPages[pageCode] + 1

    $scope.currentPage = 1
    $scope.pageSize = 3

    $scope.getFeedback = () ->
      $cross.feedback $http, $window, $q, $scope.currentId, (data) ->
        if data.state == 2
          $scope.canReply = false
        $scope.feedback = data

    $scope.getReply = () ->
      query = {
        currentPage: $scope.currentPage - 1
        pageSize: $scope.pageSize
      }
      $cross.feedbackReplies $http, $window, $q, currentUserId,
      $scope.currentId, query, (data) ->
        $scope.replies = data.list
        $scope.replyTotal = data.total
        $scope.pageTotal = Math.ceil(data.total / $scope.pageSize)
        $scope.showPages = $cross.getPageCountList($scope.currentPage,
        $scope.pageTotal, 3)
        if $scope.showPages.length >= 2
          $scope.showFooter = true

    $scope.getFeedback()
    $scope.getReply()

    $scope.$watch 'currentPage', (newVal, oldVal) ->
      if newVal != oldVal
        $scope.getReply()

    $scope.feed.validate = ''
    $scope.checkReply = () ->
      if REPLY_MAX_LENGTH > $scope.feed.newReply.length > 0
        $scope.submitEnableClass = "btn-enable"
        $scope.feed.validate = ''
        $scope.feed.tips = ''
      if $scope.feed.newReply.length > REPLY_MAX_LENGTH
        $scope.feed.validate = 'invalidate'
        $scope.submitEnableClass = "btn-disable"
        $scope.feed.tips = _('Length must less than ') + REPLY_MAX_LENGTH
      if $scope.feed.newReply.length == 0
        $scope.submitEnableClass = "btn-disable"
        $scope.feed.validate = 'invalidate'
        $scope.feed.tips = _('Reply could not empty!')

    $scope.commitReply = () ->
      if $scope.submitEnableClass == "btn-disable"
        return false
      else
        $scope.submitEnableClass = "btn-disable"
        replyContent = {
          content: $scope.feed.newReply
          feedback_id: $scope.currentId
          admin_id: currentUserId
        }
        $cross.feedbackReply $http, $window, replyContent, (data) ->
          if data
            $scope.feed.newReply = ''
            $scope.currentPage = 1
            $scope.getReply()
            refresh = $scope.$parent.$parent.refresResource
            (refresh && typeof(refresh) == "function") && refresh()
