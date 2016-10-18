'use strict'

angular.module('Cross.project.volume')
  .controller 'project.volume.VolumeDetailCtr', ($scope, $volumeDetail) ->
    projectVolumeOptions =
      dashboard: 'project'
      slug: 'volume'
      tabs: [
        {
          name: _('Overview')
          url: 'project.volume.volumeId.overview'
          available: true
        }
      ]

    $volumeDetail $scope, projectVolumeOptions
