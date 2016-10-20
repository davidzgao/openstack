'use strict'

###
# filters
#
#
###
angular.module('Unicorn.filters', [])
  .filter 'limit', ->
    return (text, index) ->
      if text and text.length > index
        return text.slice(0, index) + '...'
      else
        return text
  .filter 'i18n', ->
    return (text) ->
      if typeof text == "string"
        return _(text)
      return text
  .filter 'unitSwitch', ->
    return (number, withUnit) ->
      switched = ''
      unit = 'MB'
      if number < 1024
        switched = number / 1024
        unit = 'GB'
      else if number < 1024 ** 2
        switched = number / 1024
        unit = 'GB'
      else if number < 1024 ** 3
        switched = number / 1024 ** 2
        unit = 'TB'
      else if number < 1024 ** 4
        switched = number / 1024 ** 3
        unit = 'PB'

      if switched % 1 != 0
        switched = switched.toFixed(1)

      if withUnit
        switched = "#{switched} #{unit}"

      return switched
  .filter 'fixed', ->
    return (number) ->
      number.toFixed(2)
  .filter 'dateLocalize', ->
    return (utcDate) ->
      if !utcDate
        return
      if utcDate.indexOf('Z') > 0
        dt = new Date(utcDate).getTime()
      else
        dt = new Date(utcDate + 'Z').getTime()
      return dt
  .filter 'parseNull', ->
    return (str) ->
      free = _("None")
      if str
        if str == '' or str == 'null'
          return "<#{free}>"
        return str
      else
        return "<#{free}>"
  .filter 'prettyDate', ->
    return (date) ->
      if (typeof date) == 'number'
        return date
      if date
        return $unicorn.utils.prettyTime(date)
      else
        return _("Forever Use")
  .filter 'reverse', ->
    return (items) ->
      return items.slice().reverse()
