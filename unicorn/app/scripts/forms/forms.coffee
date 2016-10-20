'use strict'

form = angular.module("Form.builder", [
  'Form.services',
  'Form.directives'
])

$unicorn.formUtils = {
  getIpInputObj: (ipSets, val, validate) ->
    ipObjSets = []
    for ipSet in ipSets
      ipPassage = []
      selected = false
      ipStage = ''
      for age in ipSet
        if typeof age == 'string'
          ipPassage.push {
            default: parseInt(age)
            disable: true
          }
          ipStage = "#{ipStage}#{age}."
        else
          edges = age
          rangeTips = _ 'Available range: '
          for edge, index in edges
            rangeTips = "#{rangeTips}#{edge.start}~#{edge.end}"
            if index == edges.length - 1
              rangeTips = "#{rangeTips}."
            else
              rangeTips = "#{rangeTips}, "
          lastSit = {
            disable: false
            range: edges
            tip: rangeTips
          }
          if val
            valArray = val.split('.')
            sit = valArray[valArray.length - 1]
            ipStage = "#{ipStage}#{sit}"
            if val == ipStage
              selected = true
              lastSit['default'] = parseInt(sit)
          ipPassage.push lastSit
      if selected
        ipObjSets.push {
          passages: ipPassage
          validate: validate
          select: 'selected'
          invalid: 'valid'
        }
      else
        ipObjSets.push {
          passages: ipPassage
          validate: validate
        }
    return ipObjSets
  fillBody: (body, key, value) ->
    paramBody = angular.copy(body)
    for paramK, paramV of paramBody
      if paramV instanceof Object
        paramBody[paramK] = this.fillBody(paramV, key, value)
      else if paramV.substr(0, 1) == '@'
        if paramV.substr(1, paramV.length) == 'key'
          paramBody[paramK] = key
        if paramV.substr(1, paramV.length) == 'value'
          paramBody[paramK] = value
    return paramBody
  isEmptyObject: (obj) ->
    if not obj
      return true
    for name of obj
      return false
    return true
}

class FormField
  slug: ''
  templateBaseUrl: '../views/form/_field_'
  templateName: ''
  baseScope: {
    field: '='
    key: '='
  }
  restrict: 'A'
  replace: true
  depends: []

  @buildField: (app, obj) ->
    name = "form#{obj.slug}Field"
    app.directive name, ['$injector', ($injector) ->
      link = obj.link
      return {
        restrict: obj.restrict
        replace: obj.replace
        scope: obj.baseScope
        templateUrl: "#{obj.templateBaseUrl}#{obj.templateName}.html"
        controller: obj.controller
        link: (scope, ele, attr) ->
          _addFilterListener = () ->
            scope.$on 'filterOpts', (event, detail) ->
              if scope.filterCallback
                scope.filterCallback detail
              event.preventDefault()
          _addDecideListener = () ->
            scope.$on 'decideOpts', (event, detail) ->
              if not detail
                return
              if scope.decideCallback
                scope.decideCallback detail
              event.preventDefault()

          addListener = (type) ->
            # Listen the filterOpts message to enable/disable option.
            if type == 'filter'
              _addFilterListener()
            if type == 'decide'
              _addDecideListener()

          if scope.init
            scope.init(scope, ele, attr)
          if scope.field
            interf = scope.field.interf
            if not interf
              return
            targets = interf.target
            if not targets
              return
            if targets.indexOf(scope.key) >= 0
              addListener(interf.action)
      }
    ]
  init: (app) ->
    obj = @
    FormField.buildField app, obj

$unicorn.FormField = FormField
