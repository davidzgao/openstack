'use strict'

angular.module('Cross.admin.volume')
  .controller 'admin.volume.VolumeDetailCtr', ($scope, $volumeDetail) ->

    adminVolumeOptions =
      dashboard: 'admin'
      slug: 'volume'
      tabs: [
        {
          name: _('Overview')
          url: 'admin.volume.volumeId.overview'
          available: true
        }
      ]

    $volumeDetail $scope, adminVolumeOptions
