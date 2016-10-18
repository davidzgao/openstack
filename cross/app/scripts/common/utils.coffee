$cross.utils =
  _HYPERVISOR_TYPE_:
    qemu: "QEMU"
    vmware: "VMWare Vcenter"
  _RAND_KEEPER_: 1

  prettyTime: (time, curDate, format) ->
    if not time
        return ""
    localTime = new Date(time + 'Z').getTime()

    curDate = curDate or new Date().getTime()
    curDate = new Date(curDate)

    if time.indexOf('T') != -1
        time = time.split 'T'
    else
      time = time.split ' '
      curDate = curDate.split ' '

    yy = time[0].split '-'
    mm = time[1].split ':'

    pYear = parseFloat(yy[0])
    pMonth = parseFloat(yy[1]) - 1
    pDay = parseFloat(yy[2])
    pHour = parseFloat(mm[0])
    pMinute = parseFloat(mm[1])
    pSec = parseFloat(mm[2])
    date = Date.UTC pYear, pMonth, pDay, pHour, pMinute, pSec, 0

    cYear = curDate.getUTCFullYear()
    cMonth = curDate.getUTCMonth()
    cDay = curDate.getUTCDate()
    cHour = curDate.getUTCHours()
    cMinute = curDate.getUTCMinutes() + 1
    cSec = curDate.getUTCSeconds()
    cuDate = Date.UTC cYear, cMonth, cDay, cHour, cMinute, cSec, 0

    diff = ((cuDate - date) / 1000)
    day_diff = ~~(diff / 86400)
    if isNaN(day_diff)
      return
    else if diff < 0
      day_diff = -day_diff
      diff = -diff
      if day_diff >= 366
        return Math.ceil(day_diff / 365) + _(' y latter')
      else if day_diff == 0 && diff < 60
        return diff + _(" s latter")
      else if day_diff == 0 && diff < 120
        return 1 + _(' min latter')
      else if day_diff == 0 && diff < 3600
        return Math.floor(diff / 60) + _(" min latter")
      else if day_diff && diff < 7200
        return 1 + _(' h latter')
      else if day_diff == 0 && diff < 86400
        return Math.floor(diff / 3600) + _(" h latter")
      else if day_diff == 0 && day_diff == 1
        return _("tomorrow")
      else if day_diff < 7
        return day_diff + _(" d latter")
      else if day_diff < 31
        return Math.ceil(day_diff / 7) + _(" w latter")
      else
        return Math.ceil(day_diff / 30) + _(" m latter")

    minAll = cHour * 60 * 60 + cMinute * 60 + cSec
    if day_diff >= 365
      return Math.ceil(day_diff / 365) + _(" y ago")
    else if day_diff == 0 && diff < minAll
      if day_diff == 0 && diff < 60
        return diff + _(" s ago")
      else if day_diff == 0 && diff < 120
        return 1 + _(' min ago')
      else if day_diff == 0 && diff < 3600
        return Math.floor(diff / 60) + _(" min ago")
      else if day_diff && diff < 7200
        return 1 + _(' h ago')
      else if day_diff == 0 && diff < 86400
        return Math.floor(diff / 3600) + _(" h ago")
    if format
      return localTime
    else if day_diff == 0 && diff < 86400
      return _("Yesterday")
    else if day_diff < 7
      return day_diff + _(" d ago")
    else if day_diff < 31
      return Math.ceil(day_diff / 7) + _(" w ago")
    else if day_diff < 365
      return Math.ceil(day_diff / 30) + _(" m ago")

  rand: (num, keep=$cross.utils._RAND_KEEPER_) ->
    if angular.isNumber(num)
      keep = Number keep
      if isNaN(keep) or keep < 0
        keep = $cross.utils._RAND_KEEPER_
      keeper = Math.pow(100, keep)
      num = Math.round(num * keeper) / keeper
    return num

  getRamFix: (num) ->
    if num < 1024
      return "#{num}MB"
    if num < 1024 * 1024
      return "#{$cross.utils.rand(num/1024)}GB"
    if num < 1024 * 1024 * 1024
      return "#{$cross.utils.rand(num/1024/1024)}TB"
    return "#{$cross.utils.rand(num/1024/1024/1024)}PB"

  getDiskFix: (num) ->
    if num < 1024
      return "#{num}GB"
    if num < 1024 * 1024
      return "#{$cross.utils.rand(num/1024)}TB"
    return "#{$cross.utils.rand(num/1024/1024)}PB"

  getByteFix: (num) ->
    if num < 1024
      return "#{num}B"
    if num < 1024 * 1024
      return "#{$cross.utils.rand(num/1024)}KB"
    if num < 1024 * 1024 * 1024
      return "#{$cross.utils.rand(num/1024/1024)}MB"
    if num < 1024 * 1024 * 1024 * 1024
      return "#{$cross.utils.rand(num/1024/1024/1024)}GB"
    if num < 1024 * 1024 * 1024 * 1024 * 1024
      return "#{$cross.utils.rand(num/1024/1024/1024/1024)}TB"
    return "#{$cross.utils.rand(num/1024/1024/1024/1024/1024)}PB"
  ###
  # Translate cron format to readable words.
  #
  ###
  transCron: (cron) ->
    weekdays = [
      _('monday'), _('tuesday'), _('wednesday'), _('thursday'),
      _('friday'), _('saturday'), _('sunday')
    ]
    months = [
      _('January'), _('February'), _('March'),
      _('April'), _('May'), _('June'), _('July'),
      _('August'), _('September'), _('October'),
      _('November'), _('December')
    ]
    if typeof cron == "string"
      cronSplit = cron.split(" ")
      adder = ""
      if cron.length >= 5
        if cronSplit[4] != "*"
          adder += _("every week at ") + weekdays[(cronSplit[4] - 1) % 7]
        if cronSplit[3] != "*"
          adder += _("every year at ") + months[(cronSplit[3] - 1) % 12]
        if cronSplit[2] != "*" and cronSplit[3] == "*"
          adder += _("every month at ") + cronSplit[2] + _("st")
        else if cronSplit[2] != "*"
          adder += cronSplit[2] + _("st")
        if cronSplit[1] != "*" and cronSplit[4] == "*" and cronSplit[3] == "*"
          adder += _("every day at ")
          adder += (if parseInt(cronSplit[1]) < 10 then "0" else "") + cronSplit[1]
        else if cronSplit[1] != "*"
          adder += (if parseInt(cronSplit[1]) < 10 then "0" else "") + cronSplit[1]
        if cronSplit[0] != "*" and cronSplit[1] == "*"
          adder += _("every hour at ")
          adder += (if parseInt(cronSplit[0]) < 10 then "0" else "") + cronSplit[0]
          adder += _("minite(s)")
        else if cronSplit[0] != "*"
          adder += (if parseInt(cronSplit[0]) < 10 then ":0" else ":") + cronSplit[0]
        else if cronSplit[0] == "*"
          adder += "every minute"
      return adder

  ##*
  # The following init data which will be used in the topology
  # display.
  ##
  _prepare_networks_: (networks, subnets, routers, ports, instance)->
    # prepare subnets.
    subs = {}
    for sub in subnets
      subs["sub_#{sub.id}"] =
        "name": sub.name
        "enable_dhcp": sub.enable_dhcp
        "network_id": sub.network_id
        "gateway_ip": sub.gateway_ip
        "cidr": sub.cidr
        "id": sub.id

    # prepare networks
    nets = {}
    for net in networks
      nets["net_#{net.id}"] = net
      subnets = net.subnets
      nets["net_#{net.id}"].subnets = {}
      for sub in subnets
        nets["net_#{net.id}"].subnets["sub_#{sub}"] = subs["sub_#{sub}"] or {}

    # prepare routers
    rts = {}
    for router in routers
      rts["router_#{router.id}"] = router

    # prepare servers
    servers = {}
    servers["instance_#{instance.id}"] = instance

    # return networks dict
    return {
      networks: nets
      subnets: subs
      routers: rts
      servers: servers
      ports: ports
    }

  _shared_networks_: (nets) ->
    shared = []
    for net in nets
      if net['shared']
        shared.push net.id
    return shared

  init: (networks, subnets, routers, ports, instance) ->
    shared = $cross.utils._shared_networks_(networks)
    res = $cross.utils._prepare_networks_(networks, subnets, routers, ports, instance)
    res.shared = shared
    return res
