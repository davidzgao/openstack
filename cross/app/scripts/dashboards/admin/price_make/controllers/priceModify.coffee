'use strict'

angular.module('Cross.admin.price_make')
  .controller 'admin.price_make.PriceModifyCtr', ($scope, $http, $state, $window,
  $q) ->
    newModal = (new PriceModifyModal())
    newModal.initial($scope, {
      $http: $http
      $window: $window
      $state: $state
      $q: $q
    })
    serverUrl = $CROSS.settings.serverURL
    baseUrl = "#{serverUrl}/prices"

    $scope.note.modal.save = _("ModifyConfirm")
    $http.get(baseUrl).success (price)->
      priceMap = {}
      for i in price
        priceMap[i.name] = i.price

      $scope.form['cpu'] = priceMap['cpu']
      $scope.form['ram'] = priceMap['ram']
      $scope.form['volume'] = priceMap['volume']
      $scope.form['network'] = priceMap['network']

class PriceModifyModal extends $cross.Modal
  title: "PriceModify"
  slug: "PriceModify"

  fields: ->
    [{
      slug: "cpu"
      label: _ ("Price CPU")
      tag: "input"
      restrictions:
        required: false
        len: [1, 35]
    }, {
      slug: "ram"
      label: _ ("Price Ram")
      tag: "input"
      restrictions:
        required: false
        len: [1, 255]
    }, {
      slug: "volume"
      label: _ ("Price Volume")
      tag: "input"
      restrictions:
        required: false
        len: [1, 255]
    }, {
      slug: "network"
      label: _ ("Price Network")
      tag: "input"
      restrictions:
        required: false
        len: [1, 255]
    }]

  handle: ($scope, options)->
    $http = options.$http
    $q = options.$q
    serverUrl = $CROSS.settings.serverURL
    form = $scope.form
    $state = options.$state
    DEFAULT_DATE = (new Date('2014.12.1')).getTime()
    data =
      cpu: form['cpu']
      ram: form['ram']
      volume: form['volume']
      network: form['network']
    baseUrl = "#{serverUrl}/prices"
    cpuPrice = $http.put "#{baseUrl}/cpu", {price: data.cpu, name: 'cpu'}
    ramPrice = $http.put "#{baseUrl}/ram", {price: data.ram, name: 'ram'}
    volumePrice = $http.put "#{baseUrl}/volume", {price: data.volume, name: 'volume'}
    networkPrice = $http.put "#{baseUrl}/network", {price: data.network, name: 'network'}
    updatePrices = [cpuPrice, ramPrice, volumePrice, networkPrice]
    $q.all updatePrices
      .then (values) ->
        options.callback false
        $state.go 'admin.price_make', {}, {reload: true}
        toastr.success _("Successfully to update prices.")
      , (error) ->
        toastr.error _("Failed to update prices.")
        options.callback false
