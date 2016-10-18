'use strict'

class APIResourceWrapper

  constructor: (apiresource, attrs=[]) ->
    @_apiresource = apiresource
    @_attrs = attrs

  getObject: (obj) ->
    wapperedObj = {}
    for attr in obj._attrs
      distAttr = attr
      if ':' in attr
        distAttr = attr.split(':')[1]
      wapperedObj[distAttr] = obj._apiresource[attr]

    return wapperedObj

$cross.APIResourceWrapper = APIResourceWrapper
