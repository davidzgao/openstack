'use strict'

angular.module('Cross.admin.user')
  .controller 'admin.user.UserProjectCtr', ($scope, $http, $q,
  $window, $stateParams) ->
    userId = $stateParams.uId
  .controller 'admin.user.UserProjectsManage', ($scope, $http, $q,
  $window, $stateParams, $state) ->
    if !$stateParams.uId or $stateParams.uId == ''
      $state.go 'admin.user'
    $scope.userId = $stateParams.uId

    $scope.title = {
      all_project: _("Project List")
      belongs: _("Belongs Projects")
    }

    $scope.tipsNoAvailableProjects = _("No Available Project")
    $scope.tipsNoBelongs = _("No projects belongs")

    $scope.originBelongs = []
    $cross.listProjects $http, $window, $q, {}, (allProjects) ->
      $cross.listProjectsOfUser $http, $window, $scope.userId, (data) ->
        $cross.getUser $http, $window, $scope.userId, (user, status) ->
          adminProject = $window.$CROSS.settings.adminProject
          primaryProject = user.tenantId
          belongs = data.projects
          for project, index in allProjects
            if project.name == adminProject
              allProjects.splice(index, 1)
              break

          for project in belongs
            $scope.originBelongs.push project.id
            if project.id == primaryProject
              project.edit = false
            else
              project.edit = true
            for pro, index in allProjects
              if project.id == pro.id
                allProjects.splice(index, 1)
                break
          $scope.allProjects = allProjects
          $scope.belongs = belongs

    (new ProjectsModal()).initial($scope,
    {$http: $http, $window: $window})
    $scope.note.modal.save = _("Update")

    $scope.addToLeft = (projectId) ->
      clickedProject = {}
      angular.forEach $scope.allProjects, (project, index) ->
        if projectId == project.id
          clickedProject = project
          clickedProject.edit = true
          $scope.allProjects.splice(index, 1)
          $scope.belongs.push clickedProject
          return

    $scope.addToRight = (projectId) ->
      clieckedProject = {}
      angular.forEach $scope.belongs, (project, index) ->
        if projectId == project.id
          clickedProject = project
          $scope.belongs.splice(index, 1)
          $scope.allProjects.push clickedProject
          return

    $scope.close = () ->
      $state.go "admin.user"
      return

    escapeRegExp = (str) ->
      return str.replace(/([.*+?^=!:${}()|\[\]\/\\])/g, "\\$1")

    $scope.search = {}
    $scope.searchAllProject = (project) ->
      if !$scope.search.all
        return true
      regex = new RegExp('\\b' + escapeRegExp($scope.search.all), 'i')
      return regex.test(project.name)

    $scope.searchBelongs = (project) ->
      if !$scope.search.belong
        return true
      regex = new RegExp('\\b' + escapeRegExp($scope.search.belong), 'i')
      return regex.test(project.name)

    $scope.update = () ->
      selectedProjects = $scope.belongs
      projectAtRight = []
      addedProjects = []
      removedProjects = []

      # Classify the projects at left and right
      for project in selectedProjects
        projectAtRight.push project.id
        if project.id in $scope.originBelongs
          continue
        else
          addedProjects.push project

      for projectId in $scope.originBelongs
        if projectId in projectAtRight
          continue
        else
          removedProjects.push projectId

      removedSuccess = 0
      addedSuccess = []
      angular.forEach removedProjects, (projectId, index) ->
        options = {
          projectId: projectId
          userId: $scope.userId
        }
        $cross.removeRole $http, $window, options, (data, status) ->
          if status == 200 or status == '200'
            toastr.success(_("Success separate project!"))
            $state.go 'admin.user', {}, {reload: true}
          else
            toastr.error(_("Failed separate project!"))

      if addedProjects.length == 0
        $state.go "admin.user"
        return

      $cross.listRoles $http, $window, $q, {}, (roles) ->
        defaultRole = $window.$CROSS.settings.defaultRole
        roleId = ''
        for role in roles[0]
          if role.name == defaultRole
            roleId = role.id
            break
        angular.forEach addedProjects, (project, index) ->
          options = {
            projectId: project.id
            roleId: roleId
            userId: $scope.userId
          }
          $cross.assginRole $http, $window, options, (data, status) ->
            if status == 200 or status == '200'
              toastr.success(_("Success join in project!"))
              $state.go 'admin.user', {}, {reload: true}
            else
              toastr.error(_("Failed join in successful!"))

      $state.go "admin.user"

class ProjectsModal extends $cross.Modal
  title: _("Assign Project")
  slug: "user_project_manage"

  fields: ->
    [{
      slug: "project_list"
      label: _ "Project List"
      tag: "select"
      default: []
      restrictions:
        required: false
    }, {
      slug: "belongs"
      label: _("Belong Project")
      tag: "select"
      default: []
      restrictions:
        required: false
    }]
