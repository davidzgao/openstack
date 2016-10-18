'use strict'

angular.module('Cross.admin.metering')
  .controller 'admin.metering.InstanceDetailCtr', ($scope, $http, $window, $q,$state, $stateParams, $location ) ->
    serverUrl = $CROSS.settings.serverURL
    insRunTime =  $stateParams.run_time
    service =  $stateParams.service
    insCpu =  $stateParams.cpus
    insRam =  $stateParams.mem
    insDisk = $stateParams.disk
    insSize = $stateParams.size
    $scope.insName = $stateParams.name

    $scope.columnDefs = [
      {
        field: "item_name"
        displayName: _("resourceItem")
        cellTemplate: '<div class="ngCellText"><a href="#/admin/metering/instanceDetail?insName={{item[col.field]}}&">{{item[col.field]}}</a></div>'
      }
      {
        field: "item_character"
        displayName: _("Flavor")
        cellTemplate: '<div class="ngCellText">{{item[col.field] | fixed}}</div>'
      }
      {
        field: "run_price"
        displayName: _("Price")
        cellTemplate: '<div class="ngCellText">{{item[col.field] | fixed}}</div>'
      }
    ]
    resourcePriceObj = {}
    columnInfos = []
    $scope.sumPrice =
      title: _("totalPrice")
      num: 0
    $http.get("#{serverUrl}/prices").success (itemList)->
      for i in itemList
        resourcePriceObj[i.name] = i.price
      if service.match("^compute")
        columnInfos.push {field: _("CPU (core)"),nums: insCpu ,price: insCpu*insRunTime*resourcePriceObj.cpu}
        columnInfos.push {field: _("RAM (GB)"),nums: insRam ,price: insRam *insRunTime*resourcePriceObj.ram}
        columnInfos.push {field: _("Disk (GB)"),nums: insDisk ,price: insDisk*insRunTime*resourcePriceObj.volume}
      else if service.match("^volume")
        columnInfos.push {field: _("Disk (GB)"),nums: insSize ,price: insSize*insRunTime*resourcePriceObj.volume}
      $scope.columnInfos = columnInfos
      for col in columnInfos
        $scope.sumPrice.num += col.price

    (new InstanceDetailModal()).initial($scope, {
      $http: $http
      $window: $window
      $state: $state
    })

class InstanceDetailModal extends $cross.Modal
  title: "InstanceDetail"
  slug: "InstanceDetail"
  fields: ->
    [{
      slug: "name"
      label: _ "Name"
      tag: "input"
      restrictions:
        required: true
        len: [1, 35]
    }, {
      slug: "description"
      label: _ "Description"
      tag: "textarea"
      restrictions:
        required: true
        len: [1, 255]
    }]

  handle: ($scope, options)->
    $state = options.$state
    toastr.success "Post creating metering successful"
    options.callback false
    $state.go 'admin.metering', {}, {reload: false}
