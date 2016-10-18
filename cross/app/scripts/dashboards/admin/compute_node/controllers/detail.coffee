'use strict'

angular.module 'Cross.admin.compute_node'
  .controller 'admin.compute_node.HostDetailCtr', ($scope, $http,
  $window, $q, $stateParams, $state) ->
    $scope.detailItem = {
      info: _("Detail Info")
      item: {
        name: _("Name")
        id: _("ID")
        ip: _("IP")
        hypervisor_type: _("Hypervisor Type")
        hypervisor_version: _("Hypervisor Version")
        share_storage: _("Shared Storage")
        hosts: _("Compute Nodes")
        instances: _("Instances Counts")
        cpu_counts: _("CPU Counts")
        cpu_used: _("CPU Used")
        mem_counts: _("Mem Counts")
        mem_used: _("Mem Used")
        disk_counts: _("Disk Counts")
        disk_used: _("Disk Used")
        vendor: _("Vendor")
        arch: _("Arch")
        cores: _("Cores")
        sockets: _("Sockets")
        threads: _("Threads")
        model: _("Model")
      }
      resourceInfo: _("Resource Info")
      cpu_info: _("CPU Info")
      edit: _("Edit")
      save: _("Save")
      cancel: _("Cancel")
    }
    $scope.inputInValidate = false

    $scope.ori_cluster_name = ''
    $scope.ori_cluster_hyper = ''
    $scope.ori_cluster_shared = ''

    $scope.canEdit = 'btn-enable'

    $scope.currentId = $stateParams.hostId
    if !$scope.currentId
      return

    $scope.checkSelect = () ->
      angular.forEach $scope.hosts, (host, index) ->
        if host.isSelected == true and host.id != parseInt $scope.currentId
          $scope.hosts[index].isSelected = false
        if host.id == $scope.currentId
          $scope.hosts[index].isSelected = true

    $scope.checkSelect()

    $scope.getHost = () ->
      $cross.getHost $http, $window, $scope.currentId, (host) ->
        $scope.host_detail = host
        $scope.host_detail.cpu_info = JSON.parse(host.cpu_info)

    $scope.getHost()

    $scope.detailShow = () ->
      container = angular.element('.ui-view-container')
      $scope.detailHeight = $(window).height() - container.offset().top
      $scope.detailHeight -= 50
      $scope.detailWidth = container.width() * 0.75

    if $scope.currentId
      $scope.detail_show = "detail_show"
    else
      $scope.detail_show = "detail_hide"

    $scope.detailShow()

    $scope.host_detail_tabs = [
      {
        name: _('Overview'),
        url: 'admin.compute_node.hostId/:hostName.overview',
        available: true
      }
      {
        name: _('Monitor'),
        url: 'admin.compute_node.hostId/:hostName.monitor',
        available: true
      }
    ]

    $scope.checkSelect = () ->
      $scope.$emit("selected", $scope.currentId)
    $scope.checkSelect()

    $scope.checkActive = () ->
      for tab in $scope.host_detail_tabs
        if tab.url == $state.current.name
          tab.active = 'active'
        else
          tab.active = ''

    $scope.panle_close = () ->
      $state.go 'admin.compute_node'
      $scope.detail_show = false

    $scope.checkActive()

    $scope.$on '$stateChangeSuccess', (event, toState, toParams, fromState, fromParams) ->
      $scope.checkActive()
