'use strict'

angular.module('Cross.admin.image')
  .controller 'admin.image.ImageDetailCtr', ($scope, $imageDetail) ->
    adminImageOptions =
      dashboard: 'admin'
      slug: 'image'
      tabs: [
        {
          name: _('Overview')
          url: 'admin.image.imageId.overview'
          available: true
        }
      ]

    $imageDetail $scope, adminImageOptions
