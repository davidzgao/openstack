# Copyright (c) 2014. This file is confidential and proprietary.
# All Rights Reserved, Microchild Technologies (http://www.microchild.com)

'use strict'

nodemailer = require('nodemailer')

class EmailSender
  transport: global.transport
  constructor: (options) ->
    if EmailSender.confCheck(global.emailConf)
      @conf = global.emailConf
      @host = @conf.smtp_server
      @sender = @conf.sender
      @password = @conf.password
      @sender_name = @conf.sender_name || "EC-Cloud"
      @site_display_name = @conf.site_display_name || "EC-Cloud"
    else
      logger.waring "Config email info error!"
      return
    @mailOptions = {
      from: "#{@sender_name} <#{@sender}>"
      to: options.to
      subject: options.subject
      text: options.text
    }
    if options.html
      @mailOptions.html = options.html

  sendCallback: (error, response) ->
    return true

  @confCheck: (conf) ->
    if !conf.smtp_server or !conf.sender or !conf.password
      return false
    else
      return true

  @getTransport: (conf) ->
    if global.transport
      return global.transport
    else
      global.transport = nodemailer.createTransport({
        host: conf.smtp_server
        auth: {
          user: conf.sender
          pass: conf.password
        }
        tls: {
          rejectUnauthorized: false
        }
      })
      return global.transport

  sendMail: (callback) ->
    smtpTransport = EmailSender.getTransport(@conf)
    smtpTransport.sendMail(@mailOptions,
    (error, response) ->
      if error
        logger.error "Email send error, as ", error
      if callback
        callback(error, response)
    )

exports.EmailSender = EmailSender
