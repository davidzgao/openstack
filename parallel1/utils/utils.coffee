# Copyright (c) 2014. This file is confidential and proprietary.
# All Rights Reserved, Microchild Technologies (http://www.microchild.com)

'use strict'

events = require('events')

module.exports.utils =
  ###*
   # Get public URL by mode,
   # if not exist, return null.
   # Example:
   #        var utils = require('utils').utils
   #        utils.getURLByCatalog(catalog, mode);
   #
   #     @param {Object} catalog this must be a Array
   #     @param {String} mode service type
   #     @returns {*}
  ###
  getURLByCatalog: (catalog, mode, adminURL=false) ->
    for end in catalog
      if end.type == mode and not adminURL
        return end.endpoints[0].publicURL
      else if end.type == mode
        return end.endpoints[0].adminURL
    return

  getURLByRegions: (regions, mode, adminURL=false) ->
    for region in regions
      if region.active == true
        endpoints = region.endpoints
        for endpoint in endpoints
          if endpoint.type == mode and not adminURL
            return endpoint.publicURL
          else if endpoint.type == mode
            return endpoint.adminURL
      else
        continue
    return

  getURLByRegion: (regions, regionName, mode, adminURL=false) ->
    for region in regions
      if region.name == regionName
        endpoints = region.endpoints
        for endpoint in endpoints
          if endpoint.type == mode and not adminURL
            return endpoint.publicURL
          else if endpoint.type == mode
            return endpoint.adminURL
      else
        continue
    return

  getStoreHash: (currentRegion, resource) ->
    if resource
      hash = "#{currentRegion}-#{resource}"
    else
      hash = "#{currentRegion}-"
    return hash

  ###*
   # Format date time as 'YY-MM-D h:m:s'
  ###
  getFormatTime: ->
    date = new Date()
    year = date.getFullYear()
    month = date.getMonth() + 1
    day = date.getDate()
    hour = date.getHours()
    minutes = date.getMinutes()
    seconds = date.getSeconds()
    day = (day < 10 ? "0" : "") + day
    hour = (hour < 10 ? "0" : "") + hour
    minutes = (minutes < 10 ? "0" : "") + minutes
    seconds = (seconds < 10 ? "0" : "") + seconds
    "#{year}-#{month}-#{day} #{hour}:#{minutes}:#{seconds}"

  isEmptyObject: (obj) ->
    return !Object.keys(obj).length

  urlHashEncode: (encoder, originStr, type) ->
    if !type
      type = "base64"
    return encoder.update(originStr).digest(type)

  getLimit: (request) ->
    limit = undefined
    if request.query
      limitFrom = request.query.limit_from
      limitTo = request.query.limit_to
      if limitFrom and limitTo
        limit =
          from: Number(limitFrom) + 1
          to: Number(limitTo) + 1
    return limit

  resourceCheck: () ->
    events.EventEmitter.call(this)
    return

