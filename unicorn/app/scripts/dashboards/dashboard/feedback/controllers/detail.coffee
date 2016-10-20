'use strict'

angular.module("Unicorn.dashboard.feedback")
  .controller "dashboard.feedback.FeedbackDetailCtr", ($scope, $http,
  $q, $window, $state, $stateParams) ->
    $scope.currentId = $stateParams.feedbackId
    $scope.detail_tabs = [
      {
        name: _("Overview")
        url: 'dashboard.feedback.feedbackId.overview'
        available: true
      }
      {
        name: _("Reply")
        url: 'dashboard.feedback.feedbackId.reply'
        available: true
      }
    ]
    feedbackDetail = new $unicorn.DetailView()
    feedbackDetail.init($scope, {
      $stateParams: $stateParams
      $state: $state
      itemId: $scope.currentId
    })
  .controller 'dashboard.feedback.feedbackOverviewCtr', ($scope, $http,
  $q, $window, $state, $stateParams) ->
    $scope.$emit('tabDetail', 'untreated.feedback.html')
    $scope.currentId = $stateParams.feedbackId
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

    $scope.getFeedback = () ->
      serverURL = $window.$UNICORN.settings.serverURL
      feedbackURL = "#{serverURL}/feedbacks/#{$scope.currentId}"
      $http.get(feedbackURL)
        .success (data, status, headers) ->
          data.status = $scope.stateMap[data.state]
          $scope.feedback = data

    $scope.getFeedback()
  .controller 'dashboard.feedback.feedbackReplyCtr', ($scope, $http,
  $q, $window, $state, $stateParams) ->
    $scope.$emit('tabDetail', 'untreated.feedback.html')
    $scope.currentId = $stateParams.feedbackId

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

    $scope.currentPage = 1
    $scope.pageSize = 3

    serverURL = $window.$UNICORN.settings.serverURL
    $scope.getFeedback = () ->
      feedbackURL = "#{serverURL}/feedbacks/#{$scope.currentId}"
      $http.get(feedbackURL)
        .success (data, status, headers) ->
          if data.state == 2 or data.state == 0
            $scope.canReply = false
          $scope.feedback = data

    feedbackReply = ($http, $window, content, callback) ->
      replyURL = "#{serverURL}/feedback_replies"
      $http.post replyURL, content
        .success (data, status, headers) ->
          toastr.success _("Success to reply feedback!")
          callback data
        .error (data, status, headers) ->
          toastr.error _("Failed to reply feedback, try later!")

    feedbackReplies = ($http, $window, $q, feedId,
    query, callback) ->
      replyURL = "#{serverURL}/feedback_replies?"
      cPage = "current_page=#{query.currentPage}"
      pSize = "&page_size=#{query.pageSize}"
      feedback = "&feedback_id=#{feedId}"
      replyParams = "#{replyURL}#{cPage}#{pSize}#{feedback}"
      $http.get replyParams
        .success (data) ->
          callback data

    $scope.getPageCountList = (currentPage, pageCount, maxCounts) ->
      __LIST_MAX__ = maxCounts
      list = []
      if pageCount <= __LIST_MAX__
        index = 0

        while index < pageCount
          list[index] = index
          index++
      else
        start = currentPage - Math.ceil(__LIST_MAX__ / 2)
        start = (if start < 0 then 0 else start)
        start = (if start + __LIST_MAX__ >= pageCount\
                  then pageCount - __LIST_MAX__ else start)
        index = 0

        while index < __LIST_MAX__
          list[index] = start + index
          index++
      return list

    $scope.getReply = () ->
      query = {
        currentPage: $scope.currentPage - 1
        pageSize: $scope.pageSize
      }
      feedbackReplies $http, $window, $q, $scope.currentId,
      query, (data) ->
        $scope.replies = data.list
        userList = []
        for reply in $scope.replies
          if reply.admin_id
            userList.push reply.admin_id
          else
            reply.user_name = _ 'MySelf'
        params =
          params:
            fields: '["name"]'
            ids: JSON.stringify userList
        $http.get "#{serverURL}/users/query", params
          .success (adminMap) ->
            for reply in $scope.replies
              if reply.admin_id
                reply.user_name = adminMap[reply.admin_id].name
        $scope.replyTotal = data.total
        $scope.pageTotal = Math.ceil(data.total / $scope.pageSize)
        $scope.showPages = $scope.getPageCountList($scope.currentPage,
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

    $scope.changePage = (pageCode) ->
      $scope.currentPage = $scope.showPages[pageCode] + 1

    $scope.commitReply = () ->
      if $scope.submitEnableClass == "btn-disable"
        return false
      else
        $scope.submitEnableClass = "btn-disable"
        replyContent = {
          content: $scope.feed.newReply
          feedback_id: $scope.currentId
        }
        feedbackReply $http, $window, replyContent, (data) ->
          if data
            $scope.feed.newReply = ''
            $scope.currentPage = 1
            $scope.getReply()
            refresh = $scope.$parent.$parent.refresResource
            (refresh && typeof(refresh) == "function") && refresh()
