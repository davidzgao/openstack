'use strict'

angular.module 'Cross.admin.quota'
  .controller 'admin.quota.QuotaCreateCtr', ($scope, $http, $window, $q, $state) ->
    (new ProjectCreateModal()).initial($scope,
      {$http: $http, $window: $window, $q: $q, $state: $state})

    $scope.showAdvance = false
    $scope.advanceTriggerShow = _ "Show Advance Options"
    $scope.advanceTriggerHide = _ "Hide Advance Options"
    $scope.advTrigge = () ->
      $scope.showAdvance = !$scope.showAdvance

    maxQuotaRef = $window.$CROSS.settings.maxQuotaSet

    $cross.getQuota $http, $window, $q, 'default',
    (cinderQuota, novaQuota) ->
      $scope.cinderDefaultQuota = cinderQuota
      $scope.novaDefaultQuota = novaQuota
      $scope.cinderQuota = cinderQuota
      $scope.novaQuota = novaQuota
      $scope.baseNovaQuotaSet = [
        {
          name: _("CPU Cores")
          item: 'cores'
          max: maxQuotaRef.cores
          current: $scope.novaQuota.cores
        }
        {
          name: _("Instance Counts")
          item: 'instances'
          max: maxQuotaRef.instances
          current: $scope.novaQuota.instances
        }
        {
          name: _("Ram")
          item: 'ram'
          max: maxQuotaRef.ram
          current: $scope.novaQuota.ram
          unit: 'MB'
        }
        {
          name: _("Floating IPs")
          item: 'floating_ips'
          max: maxQuotaRef.floating
          current: $scope.novaQuota.floating_ips
        }
      ]

      $scope.baseCinderQuotaSet = [
        {
          name: _("Volume Counts")
          item: 'volumes'
          max: maxQuotaRef.volumes
          current: $scope.cinderQuota.volumes
        }
        {
          name: _("Volume Capacity")
          item: 'gigabytes'
          max: maxQuotaRef.volume_size
          current: $scope.cinderQuota.gigabytes
          unit: 'GB'
        }
      ]
      $scope.advanceNovaQuotaSet = [
        {
          name: _("Key Pairs")
          max: maxQuotaRef.key_paris
          item: 'key_pairs'
          current: $scope.novaQuota.key_pairs
        }
        {
          name: _("Security Groups")
          max: maxQuotaRef.security_groups
          item: 'security_groups'
          current: $scope.novaQuota.security_groups
        }
      ]
      $scope.advanceCinderQuotaSet = [
        {
          name: _("Volume Snapshots")
          max: maxQuotaRef.volume_snapshots
          item: 'snapshots'
          current: $scope.cinderQuota.snapshots
        }
      ]

      $scope.checkInput = (name, type, index, level) ->
        if type[name] == null or !type[name]
          if type == novaQuota
            $scope.novaQuota[name] = 0
            $scope["#{level}NovaQuotaSet"][index].current = 0
          else
            $scope.cinderQuota[name] = 0
            $scope["#{level}CinderQuotaSet"][index].current = 0

class ProjectCreateModal extends $cross.Modal
  title: "Modify Default Quota"
  slug: "create_project"
  single: false
  steps: ['quota']
  save: "Modify"
  parallel: true

  step_quota: ->
    name: _ "Quota Manage"
    fields:
      [{
        slug: "name"
        label: _("Name")
        tag: "input"
        restrictions:
          required: false
      },{
        slug: "description"
        label: _("Description")
        tag: "textarea"
        restrictions:
          required: false
      }]

  handle: ($scope, options) ->
    projectId = "default"
    errorMsg = _ "Failed set default quota"
    successMsg = _ "Success set default quota"

    # Update the default quota for project
    delete $scope.novaQuota['OS-FLV-EXT-DATA:ephemeral']
    delete $scope.novaQuota['disk']
    params = {
      novaQuota:
        $scope.novaQuota
      cinderQuota:
        $scope.cinderQuota
    }
    $cross.updateQuotaClass options.$http, options.$window,
    options.$q, projectId, params, (data) ->
      if data
        toastr.options.closebutton = true
        toastr.success successMsg
        options.$state.go 'admin.quota', {}, {reload: true}
      else
        toastr.error errorMsg
        options.$state.go 'admin.quota', {}, {reload: true}

