
angular.module('Cross.admin.quota')
  .controller 'admin.quota.QuotaCtr', ($scope, $http, $window,
  $q, $state, $tabs) ->
    $scope.slug = _ 'System Quota'
    $scope.tabs = [
      {
        title: _ 'Default quota'
        template: 'quota.tpl.html'
        enable: true
      }
    ]

    $scope.currentTab = 'quota.tpl.html'
    $tabs $scope, 'admin.quota'

    $scope.sort = {
      reverse: false
    }

    $scope.createAction = _ "Modify"
    $scope.deleteAction = _ "Delete"
    $scope.refesh = _ "Refresh"
    $scope.more = _ "More Action"

    $scope.showFooter = true
    $scope.unFristPage = false
    $scope.unLastPage = false
    $scope.columnDefs = [
      {
        field: "name"
        displayName: _("Name"),
        cellTemplate: '<div class="ngCellText" ng-bind="item.key"></div>'
      }
      {
        field: "value"
        displayName: _("Value")
        cellTemplate: '<div class="ngCellText" ng-bind="item.value"></div>'
      }
    ]

    $scope.pagingOptions = {
        pageSizes: [15, 25, 50]
        pageSize: 15
        currentPage: 1
    }

    $scope.quotaOpts = {
      showCheckbox: true
      pagingOptions: $scope.pagingOptions
      columnDefs: $scope.columnDefs
      showCheckbox: false
      sort: $scope.sort
    }
    serverUrl = $window.$CROSS.settings.serverURL

    $cross.getQuota $http, $window, $q, 'default',
    (cinderQuota, novaQuota) ->
      $scope.cinderDefaultQuota = cinderQuota
      $scope.novaDefaultQuota = novaQuota
      $scope.cinderQuota = cinderQuota
      $scope.novaQuota = novaQuota
      noteNova = [
        {
          name: _ "CPU Cores"
          value: "cores"
        }
        {
          name: _ "Instance number"
          value: "instances"
        }
        {
          name: _ "RAM (MB)"
          value: "ram"
        }
        {
          name: _ "vip_floatingip"
          value: "floating_ips"
        }
        {
          name: _ "Security group"
          value: "security_groups"
        }
        {
          name: _ "Keypair"
          value: "key_pairs"
        }
      ]
      noteCinder = [
        {
          name: _ "Volume number"
          value: "volumes"
        }
        {
          name: _ "gigabytes"
          value: "gigabytes"
        }
        {
          name: _ "Snapshot"
          value: "snapshots"
        }
      ]

      dataTable = []
      for item in noteNova
        dataTable.push {value: novaQuota[item.value], key: item.name}
      for item in noteCinder
        dataTable.push {value: cinderQuota[item.value], key: item.name}
      $scope.quotaOpts.data = dataTable
