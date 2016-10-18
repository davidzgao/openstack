'use strict'

angular.module('Cross.project.image')
  .controller 'project.image.ImageDetailCtr', ($scope, $imageDetail) ->
    projectImageOptions =
      dashboard: 'project'
      slug: 'image'
      tabs: [
        {
          name: _('Overview')
          url: 'project.image.imageId.overview'
          available: true
        }
      ]

    $imageDetail $scope, projectImageOptions
