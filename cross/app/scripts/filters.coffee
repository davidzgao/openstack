'use strict'

###
# filters
#
#
###
angular.module('Cross.filters', [])
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

      if withUnit and withUnit[1] == 'B'
        if number < 1024
          switched = number
          unit = 'B'
        else if number < 1024 ** 2
          switched = number / 1024
          unit = 'KB'
        else if number < 1024 ** 3
          switched = number / 1024 ** 2
          unit = 'MB'
        else if number < 1024 ** 4
          switched = number / 1024 ** 3
          unit = 'GB'
        else if number < 1024 ** 5
          switched = number / 1024 ** 3
          unit = 'TB'
        else if number < 1024 ** 6
          switched = number / 1024 ** 3
          unit = 'PB'

      if switched % 1 != 0
        switched = switched.toFixed(1)

      if withUnit and withUnit[0]
        switched = "#{switched} #{unit}"

      return switched
  .filter 'fixed', ->
    return (number) ->
      number.toFixed(2)
  .filter 'dateLocalize', ->
      return (utcDate) ->
        if utcDate
          index = utcDate.indexOf('Z')
          if index > 0
            utcDate = utcDate.substring(0, index)
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
  .filter 'onlyPos', ->
    return (number) ->
      if number
        if (typeof number) == 'number'
          if number < 0
            return _("None")
          else
            return number
        else
          return number
      else
        return number
  .filter 'reverse', ->
    return (items) ->
      return items.slice().reverse()
  .filter 'number', ->
    return (items) ->
      try
        data = Number(items)
      catch
        data = items
      return data
