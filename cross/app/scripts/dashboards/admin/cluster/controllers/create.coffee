'use strict'
angular.module('Cross.admin.cluster')
  .controller 'admin.cluster.ClusterCreateCtr', ($scope, $http, $window, $q, $state, $log) ->
    (new ClusterCreateModal()).initial($scope,
      {$http: $http, $window: $window, $q: $q, $state: $state})

    $scope.title = {
      allComputes: _("Computes List")
      computesInCluster: _("Selected Computes")
      noAvilable: _("No Available Computes")
      noComputes: _("No Selected")
    }

    $scope.selectedHosts = []
    $scope.availableHosts = []
    $cross.getAvailableHosts $http, $window, $q, '', (data, selected) ->
      for host in data
        item =
          text: host.name
          value: host.id
        $scope.availableHosts.push item

    $scope.addToRight = (hostId) ->
      clickedItem = {}
      angular.forEach $scope.availableHosts, (item, index) ->
        if hostId == item.value
          clickedItem = item
          $scope.availableHosts.splice(index, 1)
          $scope.selectedHosts.push clickedItem
          return

    $scope.addToLeft = (hostId) ->
      clickedItem = {}
      angular.forEach $scope.selectedHosts, (item, index) ->
        if hostId == item.value
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

    $scope.modal.steps[0].fields[1].default = typeList
    if typeList and typeList.length
      $scope.form['base']['hypervisor_type'] = typeList[0].value

class ClusterCreateModal extends $cross.Modal
  title: _ "Create Cluster"
  slug: "create_cluster"
  single: false
  steps: ['base', 'computes']
  parallel: true

  step_base: ->
    name: _ "Cluster Info"
    fields:
      [{
        slug: "name"
        label: _("Name")
        tag: "input"
        restrictions:
          required: true
      },{
        slug: "hypervisor_type"
        label: _("Hypervisor Type")
        default: []
        tag: "select"
        restrictions:
          required: true
      }]
  step_computes: ->
    name: _ "Choose Compute Nodes"
    fields:
      [{
        slug: "host_list"
        label: _("Host List")
        tag: "select"
        default: []
        restrictions:
          required: false
      },{
        slug: "member"
        label: _("Cluster Member")
        tag: "select"
        default: []
        restrictions:
          required: false
      }]

  handle: ($scope, options) ->
    base = $scope.form.base
    base['availability_zone'] = base.name
    params =
      name: base.name
      availability_zone: base.name
    $cross.createCluster options.$http, options.$window, params,
    (err, data) ->
      # NOTE: err as a mark for creating cluser.
      if not err
        clusterId = data.id
        toastr.success _("Success create cluster!")
        if $scope.selectedHosts.length > 0
          for host in $scope.selectedHosts
            paramsAdd =
              clusterId: clusterId
              params:
                add_host:
                  host: host.text
            $cross.updateClusterNodes options.$http, options.$window,
            paramsAdd, (data) ->
              toastr.options.closebutton = true
        meta_params =
          clusterId: clusterId
          params:
            set_metadata:
              metadata:
                hypervisor_type: base['hypervisor_type']
        if base.shared_storage
          meta_params.clusterId.params.set_metadata.metadata.shared_storage = base.shared_storage

        $cross.updateClusterNodes options.$http, options.$window,
        meta_params, (data) ->
          toastr.options.closebutton = true

        options.$state.go 'admin.cluster', null, {reload: true}
      else
        options.callback false
