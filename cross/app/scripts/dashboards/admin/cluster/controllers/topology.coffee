'use strict'

angular.module 'Cross.admin.cluster'
  .controller 'admin.cluster.ClusterTopologyCtr', ($scope, $http,
  $window, $q, $stateParams, $state) ->
    topologyView = angular.element('.host-topology-view')

    $scope.currentId = $stateParams.clusterId
    if !$scope.currentId
      return
    baseURL = $window.$CROSS.settings.serverURL
    httpHyper = $http.get "#{baseURL}/os-hypervisors/detail"
    httpInstances = $http.get "#{baseURL}/servers?all_tenants=true"
    if $scope.currentId != '0'
      httpCluster = $http.get "#{baseURL}/os-aggregates/#{$scope.currentId}"
      $q.all([httpCluster, httpHyper, httpInstances])
        .then (values) ->
          cluster = values[0].data
          clusters = [cluster]
          hypers = values[1].data
          vms = values[2].data
          hostView = $cross.topologyUtils.initialTopology(clusters, hypers, vms, true)
          $scope.topology =
            hostView: hostView
    else
      $q.all([httpHyper, httpInstances])
        .then (values) ->
          hypers = values[0].data
          vms = values[1].data
          hosts = []
          for hyper in hypers
            hosts.push hyper.hypervisor_hostname
          clusters = [{
            hosts: hosts
            id: 0
            name: 'default'
            hypervisor_type: 'QEMU'
          }]
          hostView = $cross.topologyUtils.initialTopology(clusters, hypers, vms, true)
          $scope.topology =
            hostView: hostView

    $scope.$on('$destroy', () ->
      # Clear the document for the next render
      if $scope.topology
        $scope.topology = undefined
        topologyView.html('')
    )
