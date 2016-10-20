'use strict'

angular.module('Unicorn.dashboard.instance')
  .controller 'dashboard.instance.InstanceDetailCtr', ($scope, $http,
  $window, $q, $stateParams, $state, $animate) ->

    # NOTE(ZhengYue): Be sure declare the detail_tabs and
    # bind it to $scope, then instantize the detail obj.
    $scope.detail_tabs = [
      {
        name: _('Overview'),
        url: 'dashboard.instance.instanceId.overview',
        available: true
      }
      {
        name: _('Log'),
        url: 'dashboard.instance.instanceId.log',
        available: true
      }
      {
        name: _('Console'),
        url: 'dashboard.instance.instanceId.console',
        available: true
      }
      {
        name: _('Monitor'),
        url: 'dashboard.instance.instanceId.monitor',
        available: false
      }
      {
        name: _('Topology'),
        url: 'dashboard.instance.instanceId.topology',
        available: false
      }
    ]

    # NOTE(liuhaobo) : Disable the monitor of instance
    # when the hypervisor_type is vmware.
    if $UNICORN.settings.hypervisor_type.toLocaleLowerCase() != "vmware"
      $scope.detail_tabs[3].available = true
    # NOTE(liuhaobo) : Disable the topology of instance
    # when the use_neutron is true.
    if $UNICORN.settings.use_neutron == true
      $scope.detail_tabs[4].available = true

    $scope.currentId = $stateParams.instanceId
    instanceDetail = new $unicorn.DetailView()
    instanceDetail.init($scope, {
      $stateParams: $stateParams
      $state: $state
      itemId: $scope.currentId
    })
    $unicorn.serverLog $http, $window, $scope.currentId, 10, (log) ->
      if !log
        $scope.detail_tabs[1].available = false

  .controller 'dashboard.instance.InstanceOverviewCtr', ($scope, $http,
  $window, $q, $stateParams, $state, $animate) ->
    $scope.$emit('tabDetail')
    $scope.currentId = $stateParams.instanceId
    $scope.detailItem = {
      info: _("Detail Info")
      flavorInfo: _("Flavor Info")
      volumeInfo: _("Attached Volumnes")
      volume: _("Volume")
      attachTo: _("attached on")
      noneVolume: _("No attached volume")
      noneFloating: _("None Floating IP Binded")
      item: {
        name: _("Name")
        id: _("ID")
        status: _("Status")
        user: _("User")
        create_at: _("Create At")
        fixed: _("FixedIP")
        floating: _("FloatingIP")
        image: _("Image")
      }
      flavorItem: {
        cpu: _("CPU")
        ram: _("RAM")
        disk: _("Disk")
      }
    }

    $scope.server_detail = ''
    $scope.getServer = () ->
      $unicorn.serverGet $http, $q, $scope.currentId, (server) ->
        if !server
          toastr.error _("Failed to get server detail!")
          $scope.server_detail = 'error'
          return
        detail_tabs = $scope.$parent.detail_tabs
        if server.status == 'ERROR'
          for tab, index in detail_tabs
            if tab.url != 'dashboard.instance.instanceId.overview'
              $scope.$parent.detail_tabs[index].available = false
        $scope.server_detail = server
        $scope.server_detail.statusClass = server.status
        $scope.server_detail.status = _(server.status)
        if $scope.server_detail.image_name == null
          $scope.server_detail.imageName = _("deleted")
        else
          $scope.server_detail.imageName = server.image_name
        if server.disk == 0 or server.disk == "0"
          $scope.server_detail.disk = _ "default"
        else
          $scope.server_detail.disk = server.disk + " GB"

    $scope.getServer()
