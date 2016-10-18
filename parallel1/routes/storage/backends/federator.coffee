# The API Wapper for Federator storage

request = require('request')
async = require('async')

#NOTE(ZhengYue): Accept unauthorized htpps request.
process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0"

class FederatorClient
  constructor: (conf) ->
    API = conf.API
    @options =
      base_uri: "#{API.protocol}://#{API.host}:#{API.port}"
      host: API.host
      adapter: conf.adapter
    @request_headers = conf.requestHeaders
    authBuffer = new Buffer(conf.auth)
    AUTH = authBuffer.toString('base64')
    @request_headers['Authorization'] = "Basic #{AUTH}"

  _assemble_get_options: (lo) ->
    HEADERS = @request_headers
    options = {
      headers: HEADERS,
      uri: lo,
      method: 'GET'
    }
    return options

  info: (callback) ->
    reqBody = {
      'metadata': {
        'adapter': "#{@options.adapter}",
        'connection': {
            'host': "#{@options.host}"
        }
      }
    }
    HOST = @options.host
    HEADERS = @request_headers
    reqOptions = {
      headers: HEADERS,
      uri: "#{@options.base_uri}/fed_storage",
      method: 'PUT',
      body: JSON.stringify(reqBody)
    }
    obj = @
    request reqOptions, (err, response, body) ->
      if err
        callback(err)

      loca = response.headers.location
      static_filter = '?filter="by_adapter_name"&key=["cdmi-dpl"]'

      if not loca
        loca = "#{reqOptions.uri}#{static_filter}"
      loReq = obj._assemble_get_options(loca)
      request loReq, (error, res, stInfo) ->
        # TODO(ZhengYue): Add Error Handler
        storageName = ''
        if not stInfo
          return callback(storageName)
        stInfo = JSON.parse(stInfo)
        storages = stInfo['metadata']['map']
        for storage of storages
          if storages[storage]
            storageName = storage
        callback storageName

  status: (storageName, callback) ->
    if not storageName
      # TODO(ZhengYue): Add Error Handler
      callback 'ERROR'
    obj = @
    uri = "#{@options.base_uri}/fed_storage/#{storageName}"
    reqOptions = obj._assemble_get_options(uri)

    request reqOptions, (err, response, body) ->
      if err
        callback 'ERROR', null
      info = JSON.parse(body)
      state = info['metadata']['state']
      if state == 'Online'
        state = 'OK'
      callback null, state

  queryPool: (options, callback) ->
    request options, (err, res, poolInfo) ->
      if err
        console.log err, 'error at query pool'
        callback err, []
        return
      else
        poolInfo = JSON.parse(poolInfo)
        callback null, poolInfo

  usage: (storageName, callback) ->
    if not storageName
      # TODO(ZhengYue): Add Error Handler
      callback 'ERROR'
    reqBody = {
      'metadata': {
        'storage': "#{storageName}"
      }
    }
    POOLURI = "#{@options.base_uri}/fed_pool"
    reqOptions = {
      headers: @request_headers,
      uri: POOLURI,
      method: 'PUT',
      body: JSON.stringify(reqBody)
    }
    obj = @
    request reqOptions, (err, res, body) ->
      if err
        # TODO(ZhengYue): Add Error Handler
        callback 'ERROR'
      else
        lo = res.headers.location
        # NOTE(ZhengYue): Patch the exception of headers from
        # API.
        if not lo
          lo = POOLURI + '?filter="by_storage_name"&key=["' + storageName + '"]'
        loOptions = obj._assemble_get_options(lo)
        request loOptions, (error, response, data) ->
          if error
            console.log error, 'error at detail pool'
            callback 'ERROR', null
            return
          poolInfo = JSON.parse(data)
          pools = poolInfo['metadata']['map']
          poolDetail = []
          for pool of pools
            poolUri = "#{POOLURI}/#{pool}"
            poolDetail.push obj._assemble_get_options(poolUri)
          if poolDetail.length > 0
            async.map poolDetail, obj.queryPool, (err, results) ->
              if err
                callback 'ERROR', null
              else
                totalSize = 0
                freeSize = 0
                detail = []
                for index of results
                  poolInfo = results[index]['metadata']
                  if poolInfo['state'] != 'Online'
                    continue
                  capacity = poolInfo['profile']['capacity']
                  totalSize += capacity['totalSize']
                  freeSize += capacity['freeSize']
                  poolDetail = {
                    'totalSize': capacity['totalSize'],
                    'freeSize': capacity['freeSize'],
                    'displayName': poolInfo['displayName'],
                    'status': poolInfo['state'],
                    'provision': {
                      'peakIOPS': poolInfo['provision']['peakIOPS']
                    }
                  }
                  detail.push poolDetail
                usage = {
                  total: totalSize,
                  free: freeSize,
                  unit: 'B',
                  detail: detail
                }
                callback null, usage

module.exports = FederatorClient
