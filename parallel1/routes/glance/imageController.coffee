# Copyright (c) 2014. This file is confidential and proprietary.
# All Rights Reserved, Microchild Technologies (http://www.microchild.com)

'use strict'

controllerBase = require('../controller').ControllerBase
formidable = require('../../utils/incoming_form')
redis = require('ecutils').redis
storage = require('ecutils').storage
async = require('async')
utils = require('../../utils/utils').utils

###*
 # image controller.
###
class ImageController extends controllerBase

  constructor: () ->
    options =
      service: 'image'
      profile: 'images'
    super(options)
    @redisClient = redis.connect(
      'redis_host': redisConf.host
      'redis_password': redisConf.pass
      'redis_port': redisConf.port)

  config: (app)->
    obj = @
    download = @download
    profile = "/#{@profile}"
    search = @search
    if @adder
      profile = "/#{@adder}/#{@profile}"

    app.get "#{profile}/:imageId/download", (req, res) ->
      if not controllerBase.checkToken req, res
        return
      download req, res, obj
    app.get "#{profile}/search", (req, res) ->
      if not controllerBase.checkToken req, res
        return
      search req, res, obj

    @debug = 'production' != app.get('env')
    @storage = new storage.Storage({
      redis_client: @redisClient
      debug: @debug
    })
    super(app)

  @queryRelative: (options, callback) ->
    storage = options.storage
    storage.getObjectsByIds options.params, (err, data) ->
      if err
        resource_type = options.params.resource_type
        logger.error "Failed to get #{resource_type} as: ", err
        callback err, []
      else
        callback null, data

  @assembleQuery: (images) ->
    projectIds = []
    for image in images
      if image.owner not in projectIds
        projectIds.push image.owner
    projectOptions =
      params:
        ids: projectIds
        fields: ['name']
        resource_type: 'projects'
    return [projectOptions]

  index: (req, res, obj, detail=false) ->
    limit = utils.getLimit(req)
    if not req.query.all_tenants
      req.query.owner = req.session.tenant.id
    else
      delete req.query.all_tenants
    delete req.query.limit_from
    delete req.query.limit_to
    delete req.query._
    delete req.query._cache
    listCallback = (err, images) ->
      if err
        logger.error err
        res.send err, err.code
      else
        options = ImageController.assembleQuery(images.data)
        options[0].storage = obj.storage
        async.map(options, ImageController.queryRelative,
        (err, results) ->
          if err
            res.send images
          else
            projectMap = results[0]
            for image in images.data
              if projectMap[image.owner]
                image.project_name = projectMap[image.owner].name
              else
                image.project_name = ''

            res.send images
        )
    # NOTE: Remove image which status equal 'DELETED'
    queryStatus = ["queued", "saving", "active"]
    if req.query.ec_image_type
      query_cons =
        ec_image_type: [req.query.ec_image_type]
    else
      query_cons = {}
    if req.query.is_public == 'true'
      query_cons['is_public'] = ['true']
    storeHash = utils.getStoreHash(req.session.current_region, 'images')
    if not req.query.snapshot
      query_cons['status'] = queryStatus
      if req.query.owner
        query_cons['owner'] = [req.query.owner]
      obj.storage.getObjectsByKeyValues
        resource_type: storeHash
        query_cons: query_cons
        require_detail: true
        condition_relation: 'and'
        limit: limit
        debug: obj.debug
      , (err, images) ->
        listCallback(err, images)
    else
      query_cons['properties@image_type'] = ['snapshot']
      if req.query.owner
        query_cons['owner'] = [req.query.owner]
      obj.storage.getObjectsByKeyValues
        resource_type: storeHash
        query_cons: query_cons
        require_detail: true
        condition_relation: 'and'
        limit: limit
        debug: obj.debug
      , (err, images) ->
        listCallback(err, images)

  search: (req, res, obj) ->
    limit = utils.getLimit(req)
    if not req.query.all_tenants
      req.query.owner = req.session.tenant.id
    else
      delete req.query.all_tenants
    delete req.query.limit_from
    delete req.query.limit_to
    delete req.query._
    delete req.query._cache
    listCallback = (err, images) ->
      if err
        logger.error err
        res.send err, err.code
      else
        options = ImageController.assembleQuery(images.data)
        options[0].storage = obj.storage
        async.map(options, ImageController.queryRelative,
        (err, results) ->
          if err
            res.send images
          else
            projectMap = results[0]
            for image in images.data
              if projectMap[image.owner]
                image.project_name = projectMap[image.owner].name
              else
                image.project_name

            res.send images
        )
    query_cons = {}
    if req.query.searchKey and req.query.searchValue
      query_cons[req.query.searchKey] = [req.query.searchValue]

    storeHash = utils.getStoreHash(req.session.current_region, 'images')
    if !req.query.snapshot
      obj.storage.getObjectsByKeyValues
        resource_type: storeHash
        query_cons: query_cons
        require_detail: req.query.require_detail
        condition_relation: 'and'
        limit: limit
        debug: obj.debug
      , (err, images) ->
        listCallback(err, images)
    else
      query_cons['properties@image_type'] = ['snapshot']

      obj.storage.getObjectsByKeyValues
        resource_type: storeHash
        query_cons: query_cons
        require_detail: true
        condition_relation: 'and'
        limit: limit
        debug: obj.debug
      , (err, images) ->
        listCallback(err, images)

  show: (req, res, obj) ->
    storeHash = utils.getStoreHash(req.session.current_region, 'images')
    obj.storage.getObject
      resource_type: storeHash
      id: req.params.id
    , (err, image) ->
      if err
        logger.error "Failed to get #{obj.alias} as:", err
        res.send err, controllerBase._ERROR_400
      else
        res.send image

  create: (req, res, obj) ->
    imageMeta = req.headers['x-image-meta'] || "{}"
    imageMeta = unescape(imageMeta)
    params =
      data: JSON.parse imageMeta
    client = controllerBase.getClient req, obj

    uploader = client[obj.alias].create params, (err, img)->
      if err
        logger.error "Failed to create #{obj.alias} as: ", err
        res.send err, obj._ERROR_400
      else
        img.status = 'saving'
        if img.created_at
          img.created = img.created_at
          delete img.created_at
        if img.updated_at
          img.updated = img.updated_at
          delete img.updated_at
        imageType = 'image'
        if img.properties
          imageType = img.properties.image_type || 'image'
        if img.metadata
          imageType = img.metadata.image_type || 'image'
        if imageType == 'backup' || imageType == 'snapshot'
          imageType = 'backup'
        img.ec_image_type = imageType
        storeHash = utils.getStoreHash(req.session.current_region, 'images')
        opts =
          hash_prefix: storeHash
          data: img
        obj.storage.updateObject opts, (image) ->
          res.send image
    # if uploader, handle file chunk
    if uploader
      # NOTE(liuhaobo):
      #     Forward request content directly to glance API
      req.pipe(uploader.request)

  del: (req, res, obj) ->
    params =
      id: req.params.id
    client = controllerBase.getClient req, obj
    client[obj.alias].del params, (err, data) ->
      if err
        logger.error "Failed to delete #{obj.alias} as: ", err
        res.send err, obj._ERROR_400
      else
        storeHash = utils.getStoreHash(req.session.current_region, 'images')
        obj.storage.getObject
          resource_type: storeHash
          id: params.id
        , (err, image) ->
          if err
            logger.error "Failed to get #{obj.alias} as: ", err
            res.send err, controllerBase_ERROR_400
          else
            image.status = 'deleting'
            delete image.fetch_at
            opts =
              hash_prefix: storeHash
              data: image
              fetch_at: image.fetch_at
              need_fresh: true
            obj.storage.updateObject opts, (img) ->
              res.send img
    return

  download: (req, resp, obj) ->
    client = controllerBase.getClient req, obj
    name = req.query.name
    params =
      id: req.params['imageId']
    resp.setHeader 'Content-disposition', "attachment; filename=#{name}"
    request = client[obj.alias].download params
    request.pipe(resp)

  update: (req, resp, obj)->
    params =
      data: req.body
      id: req.params.id
    client = controllerBase.getClient req, obj
    client[obj.alias].update params, (err, img) ->
      if err
        logger.error "Failed to update #{obj.alias} as: ", err
        resp.send err, obj._ERROR_400
      else
        if img.created_at
          img.created = img.created_at
          delete img.created_at
        if img.updated_at
          img.updated = img.updated_at
          delete img.updated_at
        imageType = 'image'
        if img.properties
          imageType = img.properties.image_type || 'image'
        if img.metadata
          imageType = img.metadata.image_type || 'image'
        if imageType == 'backup' || imageType == 'snapshot'
          imageType = 'backup'
        img.ec_image_type = imageType

        opts =
          hash_prefix: 'images'
          data: img
        obj.storage.updateObject opts, (err) ->
          if !err
            resp.send img
          else
            logger.error err
            resp.send err, err.code



    return

module.exports = ImageController
