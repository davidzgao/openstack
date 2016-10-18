# Copyright 2012-2013 Beijing Huron Technology Co.Ltd.
#
# Author: Chen Fei <chenfei@hihuron.com>
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.
'use strict'

controllerBase = require('../controller').ControllerBase

###*
 # server controller.
###
class CloudsController extends controllerBase

  constructor: () ->
    options =
      service: 'pubcloud'
      profile: 'clouds'
      adder: 'pubcloud'
    super(options)

module.exports = CloudsController
