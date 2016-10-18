'use strict'

angular.module('Cross.admin.compute_node')
  .controller 'admin.compute_node.HostsCtr', ($scope, $http, $window,
  $q, $interval, $state, $tabs) ->
    $scope.slug = _ 'Compute Node'
    $scope.tabs = [
      {
        title: _('Host')
        template: _('host.tpl.html')
        enable: true
      }
    ]

    $scope.currentTab = 'host.tpl.html'
    $tabs $scope, 'admin.compute_node'

    $scope.sort = {
      reverse: false
    }

    $scope.showFooter = true
    $scope.unFristPage = false
    $scope.unLastPage = false

    $scope.columnDefs = [
      {
        field: "name",
        displayName: _("Name"),
        cellTemplate: '<div class="ngCellText enableClick" data-toggle="tooltip" data-placement="top" title="{{item.name}}"><a ui-sref="admin.compute_node.hostId/:hostName.overview({hostId:item.id, hostName:item.hypervisor_hostname})" ng-bind="item.hypervisor_hostname"></a></div>'
      }
      {
        field: "host_ip",
        displayName: _("Host IP"),
        cellTemplate: '<div ng-bind="item[col.field]"></div>'
      }
      {
        field: "running_vms",
        displayName: _("Running VMs"),
        cellTemplate: '<div ng-bind="item[col.field]"></div>'
      }
      {
        field: "hypervisor_type",
        displayName: _("Hypervisor Type"),
        cellTemplate: '<div ng-bind="item[col.field]"></div>'
      }
    ]
    columnDef = {
      field: "service.status",
      displayName: _("Service Status"),
      cellTemplate: '<div class="switch-button compute_node_enable" switch-button status="item.condition" action="addition(item.service.host, item.condition)" loading="item.loading" verbose="item.ENABLED" enable="true"></div>'
    }
    if $CROSS.settings.hypervisor_type.toLocaleLowerCase() != "vmware"
      $scope.columnDefs.push columnDef

    $scope.singleSelectedItem = {}
    $scope.selectedItems = []

    $scope.deleteAction = _("Delete")
    $scope.refesh = _("Refresh")

    $scope.deleteEnableClass = 'btn-disable'

    $scope.selectChange = () ->
      if $scope.selectedItems.length == 0
        $scope.deleteEnableClass = 'btn-disable'
      else
        disabledHost = []
        for host in $scope.selectedItems
          if host.service.status == 'disabled'
            disabledHost.push host
        if disabledHost.length == $scope.selectedItems.length
          $scope.deleteEnableClass = 'btn-enable'
        else
          $scope.deleteEnableClass = 'btn-disable'

    $scope.pagingOptions = {
      pageSizes: [15, 25, 50]
      pageSize: 15
      currentPage: 1
      showFooter: false
    }

    $scope.hosts = []

    hostCallback = (newVal, oldVal) ->
      if newVal != oldVal
        selectedItems = []
        for item in newVal
          if $scope.selectedHostId
            if item.id == parseInt($scope.selectedHostId)
              item.isSelected = true
              $scope.selectedHostId = undefined
          item.name = item.hypervisor_hostname
          if item.service.status == 'enabled'
            item.status = 'active'
            item.ENABLED = _ 'Enabled'
            item.condition = 'on'
          else
            item.status = 'stoped'
            item.ENABLED = _ 'Disabled'
            item.condition = 'off'
          if item.isSelected == true
            selectedItems.push item

        $scope.selectedItems = selectedItems



    $scope.triggerEnable = (nodeName, status) ->
      for node, index in $scope.hosts
        if node.hypervisor_hostname == nodeName
          $scope.hosts[index].loading = true
          break
      params = {
        binary: 'nova-compute'
        host: nodeName
      }
      if status == 'on'
        $cross.disableService $http, $window, params, (data) ->
          if data == 200
            for host, index in $scope.hosts
              if host.hypervisor_hostname == nodeName
                $scope.hosts[index].service.status = 'disabled'
                $scope.hosts[index].loading = false
      else
        $cross.enableService $http, $window, params, (data) ->
          if data == 200
            for host, index in $scope.hosts
              if host.hypervisor_hostname == nodeName
                $scope.hosts[index].service.status = 'enabled'
                $scope.hosts[index].loading = false

    $scope.hostsOpts = {
      pagingOptions: $scope.pagingOptions
      showCheckbox: true
      columnDefs: $scope.columnDefs
      pageMax: 5
      addition: $scope.triggerEnable
    }

    $scope.setPagingData = (pagedData, total) ->
      $scope.hosts = pagedData
      $scope.totalServerItems = total | pagedData.length
      $scope.pageCounts = Math.ceil(total / $scope.pagingOptions.pageSize)
      $scope.hostsOpts.data = $scope.hosts
      $scope.hostsOpts.pageCounts = $scope.pageCounts

      if !$scope.$$phase
        $scope.$apply()

    $scope.getPagedDataAsync = (pageSize, currentPage, callback) ->
      setTimeout(() ->
        currentPage = currentPage - 1
        $cross.listHosts $http, $window, $q,
        (hosts) ->
          $scope.setPagingData(hosts)
          (callback && typeof(callback) == "function") && callback()
      , 300)

    $scope.getPagedDataAsync($scope.pagingOptions.pageSize,
                             $scope.pagingOptions.currentPage)

    watchCallback = (newVal, oldVal) ->
      tbody = angular.element('tbody.cross-data-table-body')
      tfoot = angular.element('tfoot.cross-data-table-foot')
      tbody.hide()
      tfoot.hide()
      loadCallback = () ->
        tbody.show()
        tfoot.show()
      if newVal != oldVal and newVal.currentPage != oldVal.currentPage
        $scope.getPagedDataAsync $scope.pagingOptions.pageSize,
                                 $scope.pagingOptions.currentPage,
                                 loadCallback

    $scope.$watch('pagingOptions', watchCallback, true)

    $scope.$watch('hosts', hostCallback, true)

    $scope.$watch('selectedItems', $scope.selectChange, true)

    # NOTE (ZhengYue): Dangerous!
    $scope.deleteService = () ->
      angular.forEach $scope.selectedItems, (item, index) ->
        serviceId = item.service.id
        $cross.deleteService $http, $window, serviceId, (data) ->
          $cross.listHosts $http, $window, $q,
          (hosts) ->
            $scope.setPagingData(hosts)
            hostCallback()

    $scope.$on('selected', (event, detail) ->
      if $scope.hosts.length > 0
        for host, index in $scope.hosts
          if host.id == parseInt(detail)
            $scope.hosts[index].isSelected = true
          else
            $scope.hosts[index].isSelected = false
      else
        $scope.selectedHostId = detail
    )

    $scope.refresResource = (resource) ->
      tbody = angular.element('tbody.cross-data-table-body')
      tfoot = angular.element('tfoot.cross-data-table-foot')
      tbody.hide()
      tfoot.hide()
      loadCallback = () ->
        tbody.show()
        tfoot.show()
      $scope.getPagedDataAsync($scope.pagingOptions.pageSize,
                               $scope.pagingOptions.currentPage,
                               loadCallback)
