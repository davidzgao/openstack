'use strict'

angular.module 'Cross.admin.cluster'
  .controller 'admin.cluster.ClusterDetailCtr', ($scope, $http,
  $window, $q, $stateParams, $state, $selected) ->
    $scope.detailItem = {
      info: _("Detail Info")
      item: {
        name: _("Name")
        id: _("ID")
        hypervisor_type: _("Hypervisor Type")
        hypervisor_version: _("Hypervisor Version")
        share_storage: _("Shared Storage")
        hosts: _("Compute Nodes")
        instances: _("Instances Counts")
        cpu_counts: _("CPU Counts")
        cpu_used: _("CPU Used")
        mem_counts: _("Mem Counts")
        mem_used: _("Mem Used")
      }
      resourceInfo: _("Resource Info")
      edit: _("Edit")
      save: _("Save")
      cancel: _("Cancel")
    }
    $scope.inputInValidate = false

    $scope.ori_cluster_name = ''
    $scope.ori_cluster_hyper = ''
    $scope.ori_cluster_shared = ''

    $scope.canEdit = 'btn-enable'

    $scope.currentId = $stateParams.clusterId
    $selected $scope
    if !$scope.currentId
      return

    $scope.checkSelect = () ->
      angular.forEach $scope.clusters, (cluster, index) ->
        if cluster.isSelected == true and String(cluster.id) != String($scope.currentId)
          $scope.clusters[index].isSelected = false
        if String(cluster.id) == String($scope.currentId)
          $scope.clusters[index].isSelected = true

    $scope.checkSelect()

    $scope.inEdit = 'fixed'
    $scope.editing = false

    $scope.edit = () ->
      if $scope.canEdit == 'btn-disable'
        return false
      if $scope.inEdit == 'fixed'
        $scope.inEdit = 'editing'
        $scope.editing = true
      else
        $scope.inEdit = 'fixed'
        $scope.editing = false
        return

    $scope.cancel = () ->
      $scope.inputInValidate = false
      $scope.inputTips = ""
      $scope.inEdit = 'fixed'
      $scope.editing = false
      $scope.cluster_detail.name = $scope.ori_cluster_name
      $scope.cluster_detail.metadata.shared_storage = \
        $scope.ori_cluster_shared

    $scope.checkName = () ->
      name = $scope.cluster_detail.name
      if !name
        $scope.validate = 'ng-invalid'
        $scope.inputInValidate = true
        $scope.inputTips = _ "Cannot be empty."
      else
        $scope.validate = ''
        $scope.inputInValidate = false
        $scope.inputTips =  ""

    $scope.save = () ->
      $scope.checkName()
      if $scope.inputInValidate
        $scope.checkName()
      else
        $scope.inEdit = 'fixed'
        $scope.editing = false

        updated_name = false
        $cross.getCluster $http, $window, $scope.currentId, (cluster) ->
          $scope.ori_cluster_name = cluster.name
        if $scope.cluster_detail.name != $scope.ori_cluster_name
          updated_name = true
          # Update cluster name
          options = {
            hypervisor_type: $scope.cluster_detail.hypervisor_type
            name: $scope.cluster_detail.name
          }
          $cross.updateCluster $http, $window, $scope.currentId,
          options, (data) ->
            toastr.success _("Success update cluster!")
        if $scope.cluster_detail.metadata.shared_storage !=
        $scope.ori_cluster_shared
          # Update cluster metadata
          options = {
            clusterId: $scope.currentId
            params: {
              set_metadata: {
                metadata:
                  shared_storage: $scope.cluster_detail.metadata.shared_storage
              }
            }
          }
          $cross.updateClusterNodes $http, $window, options, (data) ->
            toastr.options.closebutton = true
            if updated_name == false
              toastr.success _("Success update cluster!")

    $scope.getDetailCluster = (clusterRef) ->
      _QEMU = "QEMU"
      _VMWARE = "VMware vCenter Server"
      _ENABLED_MAP = {
        '0': _("No"),
        '1': _("Yes")
      }

      clusterDetail = clusterRef
      # Compute cluster resource usage for different type backend.
      if clusterDetail.hypervisor_type == _QEMU
        cpu_used = 0
        cpu_total = 0
        mem_used = 0
        mem_total = 0
        running_vms = 0
        hosts = 0
        for node in clusterDetail.compute_nodes
          cpu_used += node['vcpus_used']
          cpu_total += node['vcpus']
          mem_used += node['memory_mb'] - node['free_ram_mb']
          mem_total += node['memory_mb']
          running_vms += node['running_vms']
          hosts += 1
        clusterDetail.metadata['cpu_used'] = cpu_used
        clusterDetail.metadata['cpu_total'] = cpu_total
        clusterDetail.metadata['mem_used'] = mem_used
        clusterDetail.metadata['mem_total'] = mem_total
        clusterDetail.metadata['running_vms'] = running_vms
        clusterDetail.metadata['num_hosts'] = hosts
      else if clusterDetail.hypervisor_type == _VMWARE
        cpu_used = 0
        mem_used = 0
        running_vms = 0
        for node in clusterDetail.compute_nodes
          for server in node['physical_servers']
            cpu_used += server['cpu_usage']
            mem_used += server['memory_mb_used']
            running_vms += server['running_vms']
        clusterDetail.metadata['cpu_used'] = cpu_used
        clusterDetail.metadata['mem_used'] = mem_used
        clusterDetail.metadata['running_vms'] = running_vms
        clusterDetail.metadata['das_enabled'] = \
          _ENABLED_MAP[clusterDetail.metadata['das_enabled']]
        clusterDetail.metadata['drs_enabled'] = \
          _ENABLED_MAP[clusterDetail.metadata['drs_enabled']]

      return clusterDetail

    $scope.getCluster = () ->
      $cross.getCluster $http, $window, $scope.currentId, (cluster) ->
        $scope.ori_cluster_name = cluster.name
        $scope.ori_cluster_hyper = cluster.hypervisor_type
        $scope.ori_cluster_shared = cluster.metadata.shared_storage
        $scope.cluster_detail = cluster

        $scope.runningVMs = 0
        $cross.getAvailableHosts $http, $window, $q, $scope.currentId,
        (avail, selected) ->
          serverURL = $window.$CROSS.settings.serverURL
          hosts_req = []
          for host in selected
            req = $http.get "#{serverURL}/os-hypervisors/#{host.id}"
            hosts_req.push req
          $q.all(hosts_req)
            .then (values) ->
              runningVMs = 0
              for hyper in values
                runningVMs += hyper.data.running_vms
              $scope.runningVMs = runningVMs

    getDefaultCluster = (hosts) ->
      _QEMU = "QEMU"

      defaultCluster = {
        hosts: hosts
        id: 0
        name: 'default'
        metadata:
          shared_storage: 'N/A'
        hypervisor_type: _QEMU
      }
      return defaultCluster

    if $scope.currentId == '0'
      # Fake default cluster detail.
      serverURL = $window.$CROSS.settings.serverURL
      hypervisorParams = "#{serverURL}/os-hypervisors"
      $http.get hypervisorParams
        .success (data) ->
          $scope.cluster_detail = getDefaultCluster data
          $scope.runningVMs = 0
          for host in data
            $cross.getHost $http, $window, host.id, (detail) ->
              $scope.runningVMs += detail.running_vms
    else
      $scope.getCluster()

    if $scope.currentId
      $scope.detail_show = "detail_show"
    else
      $scope.detail_show = "detail_hide"

    $scope.cluster_detail_tabs = [
      {
        name: _('Overview'),
        url: 'admin.cluster.clusterId.overview',
        available: true
      }
      {
        name: _('Topology'),
        url: 'admin.cluster.clusterId.topology',
        available: true
      }
    ]

    $scope.checkActive = () ->
      for tab in $scope.cluster_detail_tabs
        if tab.url == $state.current.name
          tab.active = 'active'
        else
          tab.active = ''

    $scope.panle_close = () ->
      $state.go 'admin.cluster'
      $scope.detail_show = false

    $scope.checkActive()

    $scope.$on '$stateChangeSuccess', (event, toState, toParams, fromState, fromParams) ->
      $scope.checkActive()
