###*
# class Modal.
#
###
class Modal
  @_NOTE_:
    title: "Modal"
    cancel: "Cancel"
    save: "Create"
    stepPrevious: "Previous"
    stepNext: "Next"
  @_DEFAULT_STEP: 0

  title: "Modal"
  slug: "modal"
  containFile: false
  single: true
  steps: []
  parallel: false
  modalLoading: false

  ###*
  # Step next action.
  #
  ###
  _nextStep: (scope, options) ->
    step = scope.modal.steps[scope.modal.stepIndex]
    validate = true
    opts = options
    obj = opts.$this
    btn = angular.element(".modal-#{obj.slug} .cross-modal-footer button")
    btn.attr "disabled", true
    # TODO(Li Xipeng): Loading is in need.
    for field in step.fields
      opts.step = step.slug
      opts.field = field.slug
      if field.type == 'hidden'
        continue
      if scope.tips[step.slug][field.slug]
        validate = false
        continue
      if not field.restrictions
        continue
      if not field.restrictions.required
        continue
      if not obj.validator(scope, opts)
        validate = false

    if validate
      obj.showLoading()
      obj.nextStep scope, options, (isAllowed) ->
        if isAllowed
          scope.modal.stepIndex += 1
          scope.modal.currentStep = scope.modal.steps[scope.modal.stepIndex].slug
        setTimeout ->
          btn.removeAttr "disabled"
          obj.clearLoading()
          return true
        , 300
    else
      btn.removeAttr "disabled"
      return true

  nextStep: (scope, options, callback) ->
    callback true

  ###*
  # Step previous action.
  #
  ###
  previousStep: (scope, options) ->
    scope.modal.stepIndex -= 1
    scope.modal.currentStep = scope.modal.steps[scope.modal.stepIndex].slug

  jumpStep: (scope, options) ->
    obj = options.$this
    scope.modal.stepIndex = options.index
    scope.modal.currentStep = scope.modal.steps[scope.modal.stepIndex].slug
  ###*
  # close action.
  #
  ###
  close: (scope, options) ->
    scope.$close()

  ###*
  # Validate spect field.
  #
  # Options in options param:
  #   `step`: Optional, step slug.
  #   `field`: field slug.
  #
  # Restrictions in scope:
  #   keys were bult with step, "_", field.
  #
  # Avaliable options restrictions:
  #   `required`: Optional(true|false). If true,
  #               field value cannot be empty.
  #   `number`:   Optional(true|false). If true,
  #               field value must be a number(int).
  #   `float`:    Optional(true|false). if true,
  #               field value must be a int or two decimals
  #               at most.
  #   `ipv4`:     Optional(true|false). If true,
  #               field value must be a ipv4 address.
  #   `ipv6`:     Optional(true|false). If true,
  #               field value must be a ipv6 address.
  #   `ip`:       Optional(true|false). If true,
  #               field value must be a ip address.
  #   `len`:      Optional(number list). If set, first field
  #               means min length of field value(required).
  #               if second field is set(not required), it
  #               validate max length of field value.
  #   `email`:    Optional(true|false). If true,
  #               field value must match E-Mail format.
  #   `regex`:    Optional([regular express, notice]).
  #   `func`:     Optional(function (scope, field value)).
  #
  # @params scope: {object}
  # @params options: {object}
  # @return: {bool}
  ###
  validator: (scope, options) ->
    rs = null
    step = options.step
    field = options.field
    sortKey = field

    if step
      val = scope.form[step][field]
      sortKey = "#{step}_#{sortKey}"
    else
      val = scope.form[field]

    # if val is object, we do not need to
    # validate this field.
    if typeof val == "object" and val != null
      return true
    # delete space at the begin or the end.
    val = if not val && val != 0 then "" else val
    val = String(val).replace(/(^\s*)|(\s*$)/g, "")
    restrictions = scope.restrictions[sortKey]

    # if no restrictions, return true.
    if not restrictions
      return true

    # if field not required and is empty, return true.
    if restrictions.required && val == ""
      rs = _("Cannot be empty.")
      if step
        scope.tips[step][field] = rs
      else
        scope.tips[field] = rs
      return false

    if restrictions.func
      rs = restrictions.func(scope, val)
    if not rs and restrictions.regex
      if not restrictions.regex[0].test(val)
        rs = restrictions.regex[1]
    if not rs and restrictions.float
      if not /^\d+(\.[0-9]{1,2})?$/.test(val)\
      or /^0{2}/.test(val)
        rs = _("Must be a number and two decimal places at most.")
    if not rs and restrictions.number
      if not /^[0-9]*$/.test(val)
        rs = _("Must be a number.")
        if restrictions.range
          range = restrictions.range
          if range[0] > Number(val) > range[1]
            rs = _("Must between ") + range[0] + '~' + rangep[1]
        if step
          scope.tips[step][field] = rs
        return false
    else if restrictions.ipv4
      IPv4 = "^((25[0-5]|2[0-4]\\d|[01]?\\d\\d?)\.)" +\
             "{3}(25[0-5]|2[0-4]\\d|[01]?\\d\\d?)$"
      reIPv4 = new RegExp(IPv4)
      if not reIPv4.test(val)
        rs = _("Must be IPv4.")
    else if restrictions.ipv6
      reIPv6 = /^([\da-fA-F]{1,4}:){7}[\da-fA-F]{1,4}$/
      if not reIPv6.test(val)
        rs = _("Must be IPv6.")
    else if restrictions.ip
      IPv4 = "^((25[0-5]|2[0-4]\\d|[01]?\\d\\d?)\.)" +\
             "{3}(25[0-5]|2[0-4]\\d|[01]?\\d\\d?)$"
      reIPv4 = new RegExp(IPv4)
      reIPv6 = /^([\da-fA-F]{1,4}:){7}[\da-fA-F]{1,4}$/
      if not reIPv4.test(val) and not reIPv6.test(val) and val
        rs = _("Must be an IP address.")
    else if restrictions.cidr
      cidr = "^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.)" +\
             "{3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5]){1}" +\
             "(\/([0-9]|[1-2][0-9]|3[0-2])){1}"
      reCidr = new RegExp(cidr)
      if not reCidr.test(val)
        rs = _("Must be cidr.")
    else if restrictions.email
      re = /\S+@\S+\.\S+/
      if not re.test(val)
        rs = _("Email format error.")

    if not rs && restrictions.len
      len = val.length
      if restrictions.len[0] > len
        rs = _("Length shoud be longer than ") +
             restrictions.len[0]
      else if restrictions.len[1] && restrictions.len[1] < len
        rs = _("Length shoud be shorter than ") +
             restrictions.len[1]

    if step
      scope.tips[step][field] = rs
    else
      scope.tips[field] = rs

    if rs then false else true

  ###*
  # handle form action.
  #
  ###
  _handle: (scope, options) ->
    obj = options.$this
    btn = angular.element(".modal-#{obj.slug} .cross-modal-footer button")
    btn.attr "disabled", true
    validate = true
    if not scope.modal.single
      if not scope.modal.parallel
        step = scope.modal.steps[scope.modal.stepIndex]
        opts = options
        for field in step.fields
          opts.step = step.slug
          opts.field = field.slug
          if field.type == 'hidden'
            continue
          if not obj.validator(scope, opts)
            validate = false
      else
        counter = 0
        loop
          break if counter > scope.modal.stepIndex
          step = scope.modal.steps[counter]
          opts = options
          for field in step.fields
            opts.step = step.slug
            opts.field = field.slug
            if field.type == 'hidden'
              continue
            if not obj.validator(scope, opts)
              validate = false
              scope.tips[step.slug].stepError = true
              scope.jumpStep scope, counter
          counter += 1
    else
      opts = options || {}
      for field in scope.modal.fields
        if field.type == 'hidden'
          continue
        opts.field = field.slug
        if not obj.validator(scope, opts)
          validate = false

    options.callback = (validated) ->
      obj.clearLoading()
      if validated
        scope.$close()
      btn.removeAttr "disabled"
      return true
    if validate
      obj.showLoading()
      obj.handle(scope, options)
    else
      btn.removeAttr "disabled"
      return false

  ###*
  # This could define by user himself(herself).
  # Default options in options:
  #   `$this`: A allocate Modal object.
  #
  # @return: {bool}
  ###
  handle: (scope, options) ->
    return true

  ###*
  # Initial modal.
  #
  ###
  initial: ($scope, options) ->
    ###
    # If field.tag  = custom ,can use custom field
    # template based on using common template.
    # the field.templateUrl is the absolute  path to
    # field template.
    ###
    obj = Modal
    # initial note.
    $scope.note = $scope.note || {}
    modal = $scope.note.modal || {}
    for note of obj._NOTE_
      modal[note] = _(obj._NOTE_[note])
    modal.save = _(@save) || _(obj._NOTE_.save)
    modal.title = _(@title)
    modal.save = _(@save)
    if @save != "Modify"
      modal.save = _ "Create"
    $scope.note.modal = modal
    options = options || {}
    options.$this = @

    # handle close action.
    close = @close
    $scope.close = ->
      close $scope, options

    if not @single
      # handle step next action.
      nextStep = @_nextStep
      $scope.stepNext = ->
        nextStep $scope, options
      # handle step previous action.
      previousStep = @previousStep
      $scope.stepPrevious = ->
        previousStep $scope, options

      if @parallel
        jumpStep = @jumpStep
        $scope.jumpStep = (step, index) ->
          opts = options
          opts.step = step
          opts.index = index
          jumpStep $scope, opts

    # handle validator.
    validator = @validator
    $scope.validator = (field, step) ->
      opts = options
      opts.field = field
      opts.step = step
      validator $scope, opts
    # handle save action.
    handle = @_handle
    $scope.handle = ->
      handle $scope, options

    # Initial moal.
    $scope.modal = $scope.modal || {}
    $scope.modal.modalLoading = @modalLoading
    if not @modalLoading
      clearLoading = @clearLoading
      $scope.$watch "modal.modalLoading", (val) ->
        $scope.modal.modalLoading = true
        if val != undefined
          clearLoading()
    $scope.modal.single = @single
    $scope.modal.parallel = @parallel
    $scope.modal.slug = @slug
    $scope.modal.containFile = @containFile
    $scope.restrictions = {}
    $scope.form = $scope.form || {}
    $scope.tips = $scope.tips || {}
    if not @single
      $scope.modal.stepIndex = obj._DEFAULT_STEP
      $scope.modal.steps = []

      # initial steps.
      for step in @steps
        stepDetail = @["step_#{step}"]()
        detail =
          slug: step
          name: stepDetail.name
          fields: []
        # NOTE(ZhengYue): Support independent template of step
        if stepDetail.template
          detail.template = stepDetail.template
        $scope.form[step] = {}
        $scope.tips[step] = {}
        for field in stepDetail.fields
          if not field.slug
            continue
          $scope.form[step][field.slug] = null
          if field.tag == 'select'
            if field.default and field.default.length
              $scope.form[step][field.slug] = field.default[0].value
          $scope.tips[step][field.slug] = null
          if field.restrictions
            $scope.restrictions["#{step}_#{field.slug}"] =\
                                         field.restrictions
          detail.fields.push field
        $scope.modal.steps.push detail
    else
      fields = @fields()
      $scope.modal.fields = []
      for field in fields
        if not field.slug
          continue
        $scope.form[field.slug] = null
        $scope.form[field.slug] = null
        if field.tag == 'select'
          if field.default and field.default.length
            $scope.form[field.slug] = field.default[0].value
        $scope.tips[field.slug] = null
        $scope.modal.fields.push field
        if field.restrictions
          $scope.restrictions[field.slug] =\
                          field.restrictions
    if @steps and @steps.length
      $scope.modal.currentStep = @steps[0]

  clearLoading: ->
    loading = angular.element(".modal .modal-loading")
    loading.fadeOut('fast')
    return

  showLoading: ->
    loading = angular.element(".modal .modal-loading")
    loading.fadeIn('fast')
    return

$cross.Modal = Modal
