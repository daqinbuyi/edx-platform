describe 'Calculator', ->

  KEY =
    TAB   : 9
    ENTER : 13
    ALT   : 18
    ESC   : 27
    SPACE : 32
    LEFT  : 37
    UP    : 38
    RIGHT : 39
    DOWN  : 40

  beforeEach ->
    loadFixtures 'coffee/fixtures/calculator.html'
    @calculator = new Calculator

  describe 'bind', ->
    it 'bind the calculator button', ->
      expect($('.calc')).toHandleWith 'click', @calculator.toggle

    it 'bind the help button', ->
      # These events are bind by $.hover()
      expect($('#calculator_hint')).toHandle 'mouseover'
      expect($('#calculator_hint')).toHandle 'mouseout'
      expect($('#calculator_hint')).toHandle 'keydown'

    it 'prevent default behavior on help button', ->
      $('#calculator_hint').click (e) ->
        expect(e.isDefaultPrevented()).toBeTruthy()
      $('#calculator_hint').click()

    it 'bind the calculator submit', ->
      expect($('form#calculator')).toHandleWith 'submit', @calculator.calculate

    it 'prevent default behavior on form submit', ->
      jasmine.stubRequests()
      $('form#calculator').submit (e) ->
        expect(e.isDefaultPrevented()).toBeTruthy()
        e.preventDefault()
      $('form#calculator').submit()

  describe 'toggle', ->
    it 'focuses the input when toggled', ->

      # Since the focus is called asynchronously, we need to
      # wait until focus() is called.
      didFocus = false
      runs ->
          spyOn($.fn, 'focus').andCallFake (elementName) -> didFocus = true
          @calculator.toggle(jQuery.Event("click"))

      waitsFor (-> didFocus), "focus() should have been called on the input", 1000

      runs ->
          expect($('#calculator_wrapper #calculator_input').focus).toHaveBeenCalled()

    it 'toggle the close button on the calculator button', ->
      @calculator.toggle(jQuery.Event("click"))
      expect($('.calc')).toHaveClass('closed')

      @calculator.toggle(jQuery.Event("click"))
      expect($('.calc')).not.toHaveClass('closed')

  describe 'showHint', ->
    it 'show the help overlay', ->
      @calculator.showHint()
      expect($('.help')).toHaveClass('shown')
      expect($('.help')).toHaveAttr('aria-hidden', 'false')


  describe 'hideHint', ->
    it 'show the help overlay', ->
      @calculator.hideHint()
      expect($('.help')).not.toHaveClass('shown')
      expect($('.help')).toHaveAttr('aria-hidden', 'true')

  describe 'handleClickOnDocument', ->
    it 'on click out of the hint popup it becomes hidden', ->
      @calculator.showHint()
      e = jQuery.Event('click');
      $(document).trigger(e);
      expect($('.help')).not.toHaveClass 'shown'

  describe 'selectHint', ->
    it 'select correct hint item', ->
      element = $('.hint-item').eq(1)
      @calculator.selectHint(element)

      expect(element).toBeFocused()
      expect(@calculator.activeHint).toEqual(element)
      expect(@calculator.hintPopup).toHaveAttr('aria-activedescendant', element.attr('id'))

    it 'select the first hint if argument element is not passed', ->
          @calculator.selectHint()
          expect(@calculator.activeHint.attr('id')).toEqual($('.hint-item').first().attr('id'))

    it 'select the first hint if argument element is empty', ->
          @calculator.selectHint([])
          expect(@calculator.activeHint.attr('id')).toBe($('.hint-item').first().attr('id'))

  describe 'prevHint', ->

    it 'Prev hint item is selected', ->
      @calculator.activeHint = $('.hint-item').eq(1)
      @calculator.prevHint()

      expect(@calculator.activeHint.attr('id')).toBe($('.hint-item').eq(0).attr('id'))

    it 'Prev hint item is selected', ->
      @calculator.activeHint = $('.hint-item').eq(1)
      @calculator.prevHint()

      expect(@calculator.activeHint.attr('id')).toBe($('.hint-item').eq(0).attr('id'))

    it 'if this was the first item, select the last one', ->
      @calculator.activeHint = $('.hint-item').eq(0)
      @calculator.prevHint()

      expect(@calculator.activeHint.attr('id')).toBe($('.hint-item').eq(1).attr('id'))

  describe 'nextHint', ->

    it 'Next hint item is selected', ->
      @calculator.activeHint = $('.hint-item').eq(0)
      @calculator.nextHint()

      expect(@calculator.activeHint.attr('id')).toBe($('.hint-item').eq(1).attr('id'))

    it 'If this was the last item, select the first one', ->
      @calculator.activeHint = $('.hint-item').eq(1)
      @calculator.nextHint()

      expect(@calculator.activeHint.attr('id')).toBe($('.hint-item').eq(0).attr('id'))

  describe 'handleKeyDown', ->
    assertHintIsHidden = (calc, key) ->
      spyOn(calc, 'hideHint')
      calc.showHint()
      e = jQuery.Event('keydown', { keyCode: key });
      value = calc.handleKeyDown(e)

      expect(calc.hideHint).toHaveBeenCalled
      expect(value).toBeFalsy()
      expect(e.isDefaultPrevented()).toBeTruthy()

    assertHintIsVisible = (calc, key) ->
      spyOn(calc, 'showHint')
      e = jQuery.Event('keydown', { keyCode: key });
      value = calc.handleKeyDown(e)

      expect(calc.showHint).toHaveBeenCalled
      expect(value).toBeFalsy()
      expect(e.isDefaultPrevented()).toBeTruthy()
      expect(calc.activeHint).toBeFocused()

    assertNothingHappens = (calc, key) ->
      spyOn(calc, 'showHint')
      e = jQuery.Event('keydown', { keyCode: key });
      value = calc.handleKeyDown(e)

      expect(calc.showHint).not.toHaveBeenCalled
      expect(value).toBeTruthy()
      expect(e.isDefaultPrevented()).toBeFalsy()

    it 'hint popup becomes hidden on press ENTER', ->
      assertHintIsHidden(@calculator, KEY.ENTER)

    it 'hint popup becomes visible on press ENTER', ->
      assertHintIsVisible(@calculator, KEY.ENTER)

    it 'hint popup becomes hidden on press SPACE', ->
      assertHintIsHidden(@calculator, KEY.SPACE)

    it 'hint popup becomes visible on press SPACE', ->
      assertHintIsVisible(@calculator, KEY.SPACE)

    it 'Nothing happens on press ALT', ->
      assertNothingHappens(@calculator, KEY.ALT)

    it 'Nothing happens on press any other button', ->
      assertNothingHappens(@calculator, KEY.DOWN)

  describe 'handleKeyDownOnHint', ->
    it 'Navigation works in proper way', ->
      calc = @calculator

      eventToShowHint = jQuery.Event('keydown', { keyCode: KEY.ENTER } );
      $('#calculator_hint').trigger(eventToShowHint);

      spyOn(calc, 'hideHint')
      spyOn(calc, 'prevHint')
      spyOn(calc, 'nextHint')

      cases =
        left:
          event:
            keyCode: KEY.LEFT
            shiftKey: false
          returnedValue: false
          called: ['prevHint']
          isPropagated: true

        leftWithShift:
          returnedValue: true
          event:
            keyCode: KEY.LEFT
            shiftKey: true
          not_called: ['prevHint']

        up:
          event:
            keyCode: KEY.UP
            shiftKey: false
          returnedValue: false
          called: ['prevHint']
          isPropagated: true

        upWithShift:
          returnedValue: true
          event:
            keyCode: KEY.UP
            shiftKey: true
          not_called: ['prevHint']

        right:
          event:
            keyCode: KEY.RIGHT
            shiftKey: false
          returnedValue: false
          called: ['nextHint']
          isPropagated: true

        rightWithShift:
          returnedValue: true
          event:
            keyCode: KEY.RIGHT
            shiftKey: true
          not_called: ['nextHint']

        down:
          event:
            keyCode: KEY.DOWN
            shiftKey: false
          returnedValue: false
          called: ['nextHint']
          isPropagated: true

        downWithShift:
          returnedValue: true
          event:
            keyCode: KEY.DOWN
            shiftKey: true
          not_called: ['nextHint']

        tab:
          returnedValue: true
          event:
            keyCode: KEY.TAB
            shiftKey: false
          called: ['hideHint']

        alt:
          returnedValue: true
          event:
            which: KEY.ALT
          not_called: ['nextHint', 'prevHint', 'hideHint']

      $.each(cases, (key, data) ->
        calc.hideHint.reset()
        calc.prevHint.reset()
        calc.nextHint.reset()

        e = jQuery.Event('keydown', data.event or {});
        value = calc.handleKeyDownOnHint(e)

        if data.called
          $.each(data.called, (index, spy) ->
            expect(calc[spy]).toHaveBeenCalled()
          )

        if data.not_called
          $.each(data.not_called, (index, spy) ->
            expect(calc[spy]).not.toHaveBeenCalled()
          )

        if data.isPropagated
          expect(e.isPropagationStopped()).toBeTruthy()
        else
          expect(e.isPropagationStopped()).toBeFalsy()

        expect(value).toBe(data.returnedValue)
      )

  describe 'calculate', ->
    beforeEach ->
      $('#calculator_input').val '1+2'
      spyOn($, 'getWithPrefix').andCallFake (url, data, callback) ->
        callback({ result: 3 })
      @calculator.calculate()

    it 'send data to /calculate', ->
      expect($.getWithPrefix).toHaveBeenCalledWith '/calculate',
        equation: '1+2'
      , jasmine.any(Function)

    it 'update the calculator output', ->
      expect($('#calculator_output').val()).toEqual('3')
