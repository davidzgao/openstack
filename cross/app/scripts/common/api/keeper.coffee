'use strict'

$cross.feedbackReplies = ($http, $window, $q, currentUserId,
feedId, query, callback) ->
  serverURL = $window.$CROSS.settings.serverURL
  replyURL = "#{serverURL}/feedback_replies?"
  cPage = "current_page=#{query.currentPage}"
  pSize = "&page_size=#{query.pageSize}"
  feedback = "&feedback_id=#{feedId}"
  replyParams = "#{replyURL}#{cPage}#{pSize}#{feedback}"

  usersURL = "#{serverURL}/users"
  users = $http.get(usersURL)
    .then (response) ->
      return response.data

  replyes = $http.get replyParams
    .then (response) ->
      return response.data

  $q.all([users, replyes])
    .then (values) ->
      userMap = {}
      for user in values[0].data
        userMap[user.id] = user.name

      replyes = values[1]
      for reply in replyes.list
        if reply.admin_id == null
          reply.admin_id = currentUserId
        reply.admin_name = userMap[reply.admin_id] || 'null'

      callback replyes

$cross.feedback = ($http, $window, $q, feedId, callback) ->
  serverURL = $window.$CROSS.settings.serverURL
  feedbackURL = "#{serverURL}/feedbacks/#{feedId}"
  usersURL = "#{serverURL}/users"
  projectsURL = "#{serverURL}/projects"

  users = $http.get(usersURL)
    .then (response) ->
      return response.data
  projects = $http.get(projectsURL)
    .then (response) ->
      return response.data
  feedback = $http.get(feedbackURL)
    .then (response) ->
      return response.data

  $q.all([feedback, users, projects])
    .then (values) ->
      userMap = {}
      projectMap = {}
      for user in values[1]
        userMap[user.id] = user.name
      for project in values[2]
        projectMap[project.id] = project.name
      feedback = values[0]
      feedback.user_name = userMap[feedback.user_id] || 'null'
      feedback.project_name = projectMap[feedback.project_id] || 'null'
      callback feedback

$cross.feedbackReply = ($http, $window, content, callback) ->
  serverURL = $window.$CROSS.settings.serverURL
  replyURL = "#{serverURL}/feedback_replies"

  $http.post replyURL, content
    .success (data, status, headers) ->
      toastr.success _("Success to reply feedback!")
      callback data
    .error (data, status, headers) ->
      toastr.error _("Failed to reply feedback, try later!")

$cross.closeFeedback = ($http, $window, feedbackId, callback) ->
  serverURL = $window.$CROSS.settings.serverURL
  feedbackURL = "#{serverURL}/feedbacks/#{feedbackId}"
  state = {state: 2}
  $http.put feedbackURL, state
    .success (data, status, headers) ->
      callback data
    .error (data, status, headers) ->
      toastr.error(_("Failed to close feedback: ") + feedbackId)
