'use strict'

angular.module('Cross.admin.cluster')
  .controller 'admin.cluster.ClustersCtr', ($scope, $http, $window,
  $q, $interval, $state, $selectedItem, $tabs) ->
    $scope.slug = _ 'Clusters'
    $scope.tabs = [
      {
        title: _('Cluster')
        template: _('cluster.tpl.html')
        enable: true
      }
    ]

    $scope.currentTab = 'cluster.tpl.html'
    $tabs $scope, 'admin.cluster'

    $scope.sort = {
      reverse: false
    }

    $scope.showFooter = true
    $scope.unFristPage = false
    $scope.unLastPage = false

    $scope.createAction = _("Create")
    $scope.deleteAction = _("Delete")
    $scope.topologyAction = _("Cluster Topology")
    $scope.refesh = _("Refresh")

    $scope.columnDefs = [
      {
        field: "name",
        displayName: _("Name"),
        cellTemplate: '<div class="ngCellText enableClick" data-toggle="tooltip" data-placement="top" title="{{item.name}}"><a ui-sref="admin.cluster.clusterId.overview({clusterId:item.id})" ng-bind="item[col.field]"></a></div>'
      }
      {
        field: "hypervisor_type",
        displayName: _("Hypervisor Type"),
        cellTemplate: '<div ng-bind="item[col.field]"></div>'
      }
      {
        field: "compute_nodes",
        displayName: _("Compute Nodes"),
        cellTemplate: '<div ng-bind="item.hosts.length"></div>'
      }
    ]

    $scope.more = _("More Action")
    $scope.moreActions = [
      {
        action: 'topoloty',
        verbose: _("Topology")
        enable: 'disabled'
        actionTemplate: '<a ui-sref="admin.cluster.clusterId.topology({clusterId: singleSelectedItem.id})" ng-class="action.enable" id="{{action.action}}"><i ng-class="action.action"></i>{{action.verbose}}</a>'
      }
      {
        action: 'compute_nodes',
        verbose: _("Choose Host")
        enable: 'disabled'
        actionTemplate: '<a ui-sref="admin.cluster.cluId.hosts({cluId: singleSelectedItem.id})" ng-class="action.enable" id="{{action.action}}"><i ng-class="action.action"></i>{{action.verbose}}</a>'
      }
    ]

    $scope.singleSelectedItem = {}
    $scope.selectedItems = []

    $scope.deleteEnableClass = 'btn-disable'
    $scope.selectChange = () ->
      if $scope.selectedItems.length == 1
        $scope.singleSelectedItem = $scope.selectedItems[0]
        $scope.deleteEnableClass = 'btn-enable'
        $scope.actionEnableClass = 'btn-enable'
        angular.forEach $scope.moreActions, (action, index) ->
          action.enable = 'enabled'
          if action.action == 'compute_nodes'
            if $scope.selectedItems[0].id == 0
              action.enable = 'disabled'
      else if $scope.selectedItems.length > 1
        $scope.deleteEnableClass = 'btn-enable'
        $scope.singleSelectedItem = {}
        angular.forEach $scope.moreActions, (action, index) ->
          action.enable = 'disabled'
      else
        $scope.singleSelectedItem = {}
        $scope.deleteEnableClass = 'btn-disable'
        angular.forEach $scope.moreActions, (action, index) ->
          action.enable = 'disabled'

    getElement = $interval(() ->
      compute_nodes = angular.element("#compute_nodes")
      compute_nodes.bind 'click', ->
        return false
      if compute_nodes.length
        $interval.cancel(getElement)
    , 300)

    $scope.$watch 'singleSelectedItem', (newVal, oldVal) ->
      compute_nodes = angular.element("#compute_nodes")
      if newVal.id
        compute_nodes.unbind 'click'
      else
        compute_nodes.bind 'click', ->
          return false
    , true

    $scope.pagingOptions = {
      pageSizes: [15, 25, 50]
      pageSize: 15
      currentPage: 1
      showFooter: false
    }

    $scope.clusters = []

    $scope.clustersOpts = {
      pagingOptions: $scope.pagingOptions
      showCheckbox: true
      columnDefs: $scope.columnDefs
      pageMax: 5
    }

    $scope.setPagingData = (pagedData, total) ->
      $scope.clusters = pagedData
      $scope.totalServerItems = total | pagedData.length
      $scope.pageCounts = Math.ceil(total / $scope.pagingOptions.pageSize)
      $scope.clustersOpts.data = $scope.clusters
      $scope.clustersOpts.pageCounts = $scope.pageCounts

      if !$scope.$$phase
        $scope.$apply()

    $scope.getPagedDataAsync = (pageSize, currentPage, callback) ->
      setTimeout(() ->
        currentPage = currentPage - 1
        $cross.listClusters $http, $window, $q,
        (clusters) ->
          for cluster in clusters
            cluster.id = String(cluster.id)
            if cluster.metadata
              if not cluster.metadata.hypervisor_type
                cluster.hypervisor_type = "QEMU"
              else
                cluster.hypervisor_type = cluster.metadata.hypervisor_type
              if not cluster.metadata.shared_storage
                cluster.metadata.shared_storage = _ 'None'
          $scope.setPagingData(clusters)
          (callback && typeof(callback) == "function") && callback()
      , 300)

    $scope.getPagedDataAsync($scope.pagingOptions.pageSize,
                             $scope.pagingOptions.currentPage)

    watchCallback = (newVal, oldVal) ->
      $scope.clustersOpts.data = null
      if newVal != oldVal and newVal.currentPage != oldVal.currentPage
        $scope.getPagedDataAsync $scope.pagingOptions.pageSize,
                                 $scope.pagingOptions.currentPage

    $scope.$watch('pagingOptions', watchCallback, true)

    clusterCallback = (newVal, oldVal) ->
      if newVal != oldVal
        selectedItems = []
        for item in newVal
          if $scope.selectedItemId
            if String(item.id) == String($scope.selectedItemId)
              item.isSelected = true
              $scope.selectedItemId = undefined
          if item.isSelected == true
            selectedItems.push item

        $scope.selectedItems = selectedItems

    $scope.$watch('clusters', clusterCallback, true)

    $scope.$watch('selectedItems', $scope.selectChange, true)

    $scope.deleteCluster = () ->
      serverUrl = $window.$CROSS.settings.serverURL
      angular.forEach $scope.selectedItems, (item, index) ->
        clusterId = item.id
        clusterName = item.name
        actionURL = "#{serverUrl}/os-aggregates/#{clusterId}/action"
        if item.hosts.length > 0
          computeNodes = []
          for host in item.hosts
            hostParam = {
              remove_host: {
                host: String(host)
              }
            }
            removeNode = $http.post actionURL, hostParam
            computeNodes.push removeNode
          $q.all(computeNodes)
            .then (values) ->
              $cross.deleteCluster $http, $window, clusterId, (res) ->
                toastr.success _("Success to delete cluster:") + clusterName
                if index == $scope.selectedItems.length - 1
                  setTimeout(() ->
                    $state.go('admin.cluster', {}, {reload: true})
                  , 100)
            , (err) ->
              toastr.error _("Error at delete clsuter:") + item.name
        else
          $cross.deleteCluster $http, $window, clusterId, (res) ->
            toastr.success _("Success to delete cluster:") + clusterName
            if index == $scope.selectedItems.length - 1
              setTimeout(() ->
                $state.go('admin.cluster', {}, {reload: true})
              , 100)

    $selectedItem $scope, 'clusters'

    $scope.refresResource = (resource) ->
      $scope.clustersOpts.data = null
      $scope.getPagedDataAsync($scope.pagingOptions.pageSize,
                               $scope.pagingOptions.currentPage)
