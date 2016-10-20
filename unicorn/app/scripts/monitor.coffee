angular.module("Unicorn.directives")
  .directive "commonMonitor", () ->
    return {
      restrict: 'E'
      replace: true
      scope:
        data: "="
      templateUrl: 'views/common/_monitor.html'
      controller: ['$injector', '$scope', '$element', '$attrs', ($injector, $scope, $element, $attrs) ->
        $interval      = $injector.get "$interval"
        $log           = $injector.get "$log"
        $gossipService = $injector.get "$gossipService"

        intervalId = null
        loaded = false
        $scope.$on "$destroy", () ->
          if intervalId
            $interval.cancel intervalId
        $scope.$watch("data", (data) ->
          if not data or loaded
            return false
          CACHE_QUEUE = []
          meter_name = $attrs.meterName
          tag = "#{$attrs.resouce}.#{meter_name}"
          $scope.$on "$gossipService.meter.#{tag}", (ev, meter)->
            if CACHE_QUEUE.length >= 2
              CACHE_QUEUE.pop()
            CACHE_QUEUE.push meter

          Highcharts.setOptions({
            global:
              useUTC: false
            lang:
              months: [_("January"), _("February"), _("March"),
                       _("April"), _("May"), _("June"), _("July"),
                       _("August"), _("September"), _("October"),
                       _("November"), _("December")]
              shortMonths: [_("Jan"), _("Feb"), _("Mar"), _("Apr"),
                            _("May"), _("Jun"), _("Jul"), _("Aug"),
                            _("Sep"), _("Oct") , _("Nov"), _("Dec")]
              weekdays: [_("Sunday"), _("Monday"), _("Tuesday"),
                         _("Wednesday"), _("Thursday"), _("Friday"),
                         _("Saturday")]

          })
          $element.highcharts({
            chart:
              type: 'spline'
              backgroundColor: "#ffffff"
              animation: Highcharts.svg
              events:
                load: () ->
                  series = this.series
                  if not data.real_time
                    return
                  if not series.length
                    return
                  if not series[0]
                    return
                  if loaded
                    return
                  loaded = true
                  if intervalId
                    $interval.cancel intervalId
                  intervalId = setInterval ()->
                    if not CACHE_QUEUE.length
                      return false
                    if not series[0]
                      return false
                    if not series[0].data
                      return false
                    meter = CACHE_QUEUE.pop()
                    x = Date.parse(meter.timestamp)
                    y = meter.counter_volume
                    y = parseFloat((Number(y)).toFixed(2))
                    if not series[0].data.length or series[0].data[series[0].data.length - 1].x < x
                      series[0].addPoint([x, y], true, true)
                    if not CACHE_QUEUE.length
                      return false
                    if not series[1]
                      return false
                    if not series[1].data
                      return false
                    meter = CACHE_QUEUE.pop()
                    x = Date.parse(meter.timestamp)
                    y = meter.counter_volume
                    y = parseFloat((Number(y)).toFixed(2))
                    if not series[1].data.length or series[1].data[series[1].data.length - 1].x < x
                      series[1].addPoint([x, y], true, true)
                  , 10000
            credits:
              enabled: false
            exporting:
              enabled: false
            title:
              text: data.title or $element.attr('title')
            xAxis:
              type: 'datetime'
            yAxis:
              title:
                text: data.unit
              plotLines: [{
                value: 0
                width: 1
                color: '#808080'
              }]
              min: 0
            legend:
              layout: 'vertical'
              align: 'right'
              verticalAlign: 'top'
              x: -10
              y: 100
              borderWidth: 0
            series: data.series
          })
        , true)
      ]
    }
