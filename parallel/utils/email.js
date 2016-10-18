(function() {
  'use strict';
  var EmailSender, nodemailer;

  nodemailer = require('nodemailer');

  EmailSender = (function() {
    EmailSender.prototype.transport = global.transport;

    function EmailSender(options) {
      if (EmailSender.confCheck(global.emailConf)) {
        this.conf = global.emailConf;
        this.host = this.conf.smtp_server;
        this.sender = this.conf.sender;
        this.password = this.conf.password;
        this.sender_name = this.conf.sender_name || "EC-Cloud";
        this.site_display_name = this.conf.site_display_name || "EC-Cloud";
      } else {
        logger.waring("Config email info error!");
        return;
      }
      this.mailOptions = {
        from: "" + this.sender_name + " <" + this.sender + ">",
        to: options.to,
        subject: options.subject,
        text: options.text
      };
      if (options.html) {
        this.mailOptions.html = options.html;
      }
    }

    EmailSender.prototype.sendCallback = function(error, response) {
      return true;
    };

    EmailSender.confCheck = function(conf) {
      if (!conf.smtp_server || !conf.sender || !conf.password) {
        return false;
      } else {
        return true;
      }
    };

    EmailSender.getTransport = function(conf) {
      if (global.transport) {
        return global.transport;
      } else {
        global.transport = nodemailer.createTransport({
          host: conf.smtp_server,
          auth: {
            user: conf.sender,
            pass: conf.password
          },
          tls: {
            rejectUnauthorized: false
          }
        });
        return global.transport;
      }
    };

    EmailSender.prototype.sendMail = function(callback) {
      var smtpTransport;
      smtpTransport = EmailSender.getTransport(this.conf);
      return smtpTransport.sendMail(this.mailOptions, function(error, response) {
        if (error) {
          logger.error("Email send error, as ", error);
        }
        if (callback) {
          return callback(error, response);
        }
      });
    };

    return EmailSender;

  })();

  exports.EmailSender = EmailSender;

}).call(this);

//# sourceMappingURL=email.js.map
