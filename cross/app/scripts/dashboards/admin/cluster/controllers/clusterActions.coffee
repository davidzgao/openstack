'use strict'

angular.module('Cross.admin.cluster')
  .controller 'admin.cluster.ClusterActionCtr', ($scope, $http,
  $window, $stateParams) ->
    $scope.clusterId = $stateParams.projectId
  .controller 'admin.cluster.ClusterHostsCtr', ($scope, $http,
  $window, $stateParams, $state, $q, $log) ->
    if !$stateParams.cluId or $stateParams.cluId == ''
      $state.go 'admin.cluster'
    $scope.clusterId = $stateParams.cluId

    (new ClusterHostsModal()).initial($scope,
      {
        $http: $http,
        $window: $window,
        $q: $q,
        $state: $state
      })

    $scope.title = {
      allComputes: _("Computes List")
      computesInCluster: _("Selected Computes")
      noAvilable: _("No Available Computes")
      noComputes: _("No Selected")
    }

    $scope.note.modal.save = _("Update")

    $scope.selectedHosts = []
    $scope.availableHosts = []
    $scope.host_list = []
    $cross.getAvailableHosts $http, $window, $q, $scope.clusterId,
    (availHosts, selectedHosts) ->
      for host in availHosts
        item =
          name: host.name
          id: host.id
        $scope.availableHosts.push item
      $scope.selectedHosts = selectedHosts
      for host in selectedHosts
        $scope.host_list.push host.name

    $scope.addToRight = (hostId) ->
      clickedItem = {}
      angular.forEach $scope.availableHosts, (item, index) ->
        if hostId == item.id
          clickedItem = item
          $scope.availableHosts.splice(index, 1)
          $scope.selectedHosts.push clickedItem
          return

    $scope.addToLeft = (hostId) ->
      clickedItem = {}
      angular.forEach $scope.selectedHosts, (item, index) ->
        if hostId == item.id
          clickedItem = item
          $scope.selectedHosts.splice(index, 1)
          $scope.availableHosts.push clickedItem
          return

    $scope.no_available = false
    $scope.no_selected = false
    if $scope.availableHosts.length == 0
      $scope.no_available = true
    if $scope.selectedHosts.length == 0
      $scope.no_selected = true

    $scope.$watch "availableHosts", (newVal, oldVal) ->
      if newVal != oldVal
        if newVal.length == 0
          $scope.no_available = true
        else
          $scope.no_available = false
    , true

    $scope.$watch "selectedHosts", (newVal, oldVal) ->
      if newVal != oldVal
        if newVal.length == 0
          $scope.no_selected = true
        else
          $scope.no_selected = false
    , true

    hypervisorTypes = $window.$CROSS.settings.hypervisorTypes
    if !hypervisorTypes
      $log.error("Configuration Error: Please set hypervisorTypes
         option at config file!")
    typeList = []
    for type in hypervisorTypes
      item = {
        text: type
        value: type
      }
      typeList.push item

    $scope.modal.fields[0].default = typeList

class ClusterHostsModal extends $cross.Modal
  title: _ "Choose Compute Nodes"
  slug: "choose_nodes"
  single: true
  parallel: true

  fields: ->
    [
      {
        slug: "host_list"
        label: _("Host List")
        tag: "select"
        default: []
        restrictions:
          required: false
      },
      {
        slug: "member"
        label: _("Cluster Member")
        tag: "select"
        default: []
        restrictions:
          required: false
      }
    ]

  handle: ($scope, options) ->
    params = {
      clusterId: $scope.clusterId
      params: {
        update_nodes: {
          compute_nodes: []
        }
      }
    }
    removedHosts = []
    addedHosts = []
    for host in $scope.selectedHosts
      if host.name not in $scope.host_list
        addedHosts.push host.name
      else
        continue

    for host in $scope.availableHosts
      if host.name in $scope.host_list
        removedHosts.push host.name
      else
        continue

    for host in addedHosts
      # Add host into cluster
      paramsAdd = {
        clusterId: $scope.clusterId
        params: {
          add_host: {
            host: host
          }
        }
      }
      $cross.updateClusterNodes options.$http, options.$window,
      paramsAdd, (data) ->

    for host in removedHosts
      # Remove host from cluster
      paramsRemove = {
        clusterId: $scope.clusterId
        params: {
          remove_host: {
            host: host
          }
        }
      }
      $cross.updateClusterNodes options.$http, options.$window,
      paramsRemove, (data) ->

    toastr.success _("Success to update cluster nodes!")
    options.$state.go 'admin.cluster', {}, {reload: true}

  close: ($scope, options) ->
    options.$state.go 'admin.cluster'
