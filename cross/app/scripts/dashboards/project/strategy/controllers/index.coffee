'use strict'

###*
 # @ngdoc function
 # @name Cross.controller:MainCtrl
 # @description
 # # MainCtrl
 # Controller of the Cross
###
angular.module('Cross.project.strategy')
  .controller 'project.strategy.StrategyCtr', ($scope, $http, $window, $q,
                                         $state, $interval, $templateCache,
                                         $compile, $animate) ->
    serverUrl = $window.$CROSS.settings.serverURL

    $scope.note =
      title: _("Strategy")
      buttonGroup:
        create: _("Create")
        delete: _("Delete")
        refresh: _("Refresh")

    # Category for instance action
    $scope.batchActionEnableClass = 'btn-disable'

    # For sort at table header
    $scope.sort = {
      reverse: false
    }

    # For tabler footer and pagination or filter
    $scope.showFooter = false
    $scope.pagingOptions =
      showFooter: $scope.showFooter

    $scope.abnormalStatus = [
      'error'
    ]

    $scope.columnDefs = [
      {
        field: "name"
        displayName: _("Name")
        cellTemplate: '<div class="ngCellText enableClick" data-toggle="tooltip" data-placement="top" title="{{item.name}}"><a ng-bind="item[col.field]" ui-sref="project.strategy.strategyId({strategyId:item.id})"></a></div>'
      }
      {
        field: "rule"
        displayName: _("Rule")
        cellTemplate: '<div class="ngCellText" data-toggle="tooltip" data-placement="top" title="{{item.rule}}">{{item.rule}}<a href="{{item.targetUrl}}">{{item.target}}</a></div>'
      }
      {
        field: "created_at"
        displayName: _("Created at")
        cellTemplate: '<div ng-bind="item[col.field]"></div>'
      }
      {
        field: "status"
        displayName: _("Status")
        cellTemplate: '<div ng-bind="item[col.field]"></div>'
      }
    ]
    # --End--
    # Category for instance action
    $scope.singleSelectedItem = {}

    # Variates for dataTable
    # --start--

    # For checkbox select
    $scope.AllSelectedItems = false
    $scope.NoSelectedItems = true

    $scope.filterOptions =
      filterText: '',
      useExternalFilter: true

    $scope.rules = []

    $scope.rulesOpts = {
      pagingOptions: $scope.pagingOptions
      showCheckbox: true
      columnDefs: $scope.columnDefs
      pageMax: 5
    }

    # Function for get paded instances and assign class for
    # element by status
    setPagingData = (pagedData) ->
      $scope.rules = pagedData
      # Compute the total pages
      $scope.rulesOpts.data = $scope.rules

    # --End--

    # Functions for handle event from action

    $scope.selectedItems = []
    # TODO(ZhengYue): Add batch action enable/disable judge by status
    $scope.selectChange = () ->
      if $scope.selectedItems.length == 1
        $scope.NoSelectedItems = false
        $scope.batchActionEnableClass = 'btn-enable'
      else if $scope.selectedItems.length > 1
        $scope.NoSelectedItems = false
        $scope.batchActionEnableClass = 'btn-enable'
      else
        $scope.NoSelectedItems = true
        $scope.batchActionEnableClass = 'btn-disable'
        $scope.singleSelectedItem = {}

    # Functions about interaction with rule
    # --Start--

    listDetailedRules = ($http, $window, $q, callback) ->
      $http.get("#{serverUrl}/rules/detail").success (rules) ->
        tempHttps = []
        for rule in rules
          tempHttp = $http.get "#{serverUrl}/rules/#{rule.id}/template"
          tempHttps.push tempHttp
        if not tempHttps.length
          callback rules

        $q.all tempHttps
          .then (res) ->
            temDict = {}
            for rs in res
              temDict["tmp_#{rs.data.id}"] = rs.data.template
            ruleSmps = []
            ruleTypeDict = {}
            for type in $CROSS.settings.ruleTypes
              ruleTypeDict[type.slug] = type

            sources =
              instance:
                url: "#/project/instance/:id/overview"
                getUrl: "#{serverUrl}/servers/query"
                list: []
            for rule in rules
              tmp = temDict["tmp_#{rule.raw_template_id}"]
              type = ruleTypeDict[tmp.type]
              if not type
                continue
              if sources[type.sourceType]
                if tmp.server not in sources[type.sourceType].list
                  sources[type.sourceType].list.push tmp.server
              item =
                id: rule.id
                name: rule.name
                created_at: rule.created_at
                status: _(rule.status)
                targetId: tmp.server
                rule: $cross.utils.transCron(tmp.interval) + _(type.name)
              ruleSmps.push item
            callback ruleSmps

            # get sources name behind.
            sourceHttps = []
            for sor of sources
              params =
                params:
                  fields: '["name"]'
                  ids: JSON.stringify sources[sor].list
              sourceHttps.push $http.get sources[sor].getUrl, params
            $q.all sourceHttps
              .then (finalSources) ->
                index = 0
                for sr of sources
                  sour = finalSources[index].data
                  if not sour
                    continue
                  for sor in ruleSmps
                    if sour[sor.targetId]
                      sor.targetUrl = sources[sr].url.replace ":id", sor.targetId
                      sor.target = sour[sor.targetId].name
                  index += 1
                $scope.rules = ruleSmps

    # Function for async list instances
    getPagedDataAsync = (callback) ->
      listDetailedRules $http, $window, $q, (pools) ->
        setPagingData(pools)
        (callback && typeof(callback) == "function") && callback()

    getPagedDataAsync()

    # Callback after instance list change
    ruleCallback = (newVal, oldVal) ->
      if newVal != oldVal
        selectedItems = []
        for rule in newVal
          if rule.isSelected == true
            selectedItems.push rule
        $scope.selectedItems = selectedItems

    $scope.$watch('rules', ruleCallback, true)

    $scope.$watch('selectedItems', $scope.selectChange, true)

    ruleDelete = ($http, $window, ruleId, callback) ->
      $http.delete "#{serverUrl}/rules/#{ruleId}"
        .success (rs) ->
          callback(200)
        .error (err) ->
          callback(err.status)

    # Reallocate selected servers
    $scope.deleteRule = () ->
      angular.forEach $scope.selectedItems, (item, index) ->
        range = item.id
        name = item.name || ruleId
        ruleDelete $http, $window, range, (response) ->
          # TODO(ZhengYue): Add some tips for success or failed
          if response == 200
            toastr.success(_('Successfully delete rule: ') + name)
            $state.go 'project.strategy', {}, {reload: true}

    # TODO(ZhengYue): Add loading status
    $scope.refresResource = (resource) ->
      tbody = angular.element('tbody.cross-data-table-body')
      tbody.hide()
      loadCallback = () ->
        tbody.show()
      getPagedDataAsync(loadCallback)
