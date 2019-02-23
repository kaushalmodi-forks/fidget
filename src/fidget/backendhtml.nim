import uibase, dom2, chroma, strutils, math, tables


var
  divCache*: seq[Group]
  rootDomNode: Element

proc draw*(group: Group) =

  while divCache.len <= numGroups:
    rootDomNode.appendChild(document.createElement("div"))
    inc perf.numLowLevelCalls
    divCache.add(Group())
  var
    dom = rootDomNode.childNodes[numGroups]
    cacheGroup = divCache[numGroups]

  if cacheGroup.id != current.id:
    inc perf.numLowLevelCalls
    cacheGroup.id = current.id
    dom.id = current.id

  if cacheGroup.screenBox != current.screenBox:
    inc perf.numLowLevelCalls
    cacheGroup.screenBox = current.screenBox
    dom.style.position = "absolute"
    dom.style.left = $current.screenBox.x & "px"
    dom.style.top = $current.screenBox.y & "px"
    dom.style.width = $current.screenBox.w & "px"
    dom.style.height = $current.screenBox.h & "px"

  if cacheGroup.fill != current.fill or cacheGroup.kind != current.kind:
    inc perf.numLowLevelCalls
    cacheGroup.fill = current.fill
    cacheGroup.kind = current.kind
    if current.kind == "text":
      dom.style.color = $current.fill.toHtmlRgba()
      dom.style.backgroundColor = "rgba(0,0,0,0)"
    else:
      dom.style.backgroundColor = $current.fill.toHtmlRgba()
      dom.style.color = "rgba(0,0,0,0)"

  if cacheGroup.stroke != current.stroke:
    inc perf.numLowLevelCalls
    cacheGroup.stroke = current.stroke
    if current.strokeWeight > 0:
      dom.style.borderStyle = "solid"
      dom.style.boxSizing = "border-box"
      dom.style.borderColor = $current.stroke.toHtmlRgba()
      dom.style.borderWidth = $current.strokeWeight
    else:
      dom.style.borderStyle = "none"

  if cacheGroup.transparency != current.transparency:
    inc perf.numLowLevelCalls
    cacheGroup.transparency = current.transparency
    dom.style.opacity = $current.transparency

  if cacheGroup.textStyle != current.textStyle:
    inc perf.numLowLevelCalls
    cacheGroup.textStyle = current.textStyle
    dom.style.fontFamily = current.textStyle.fontFamily
    dom.style.fontSize = $current.textStyle.fontSize & "px"
    dom.style.fontWeight = $current.textStyle.fontWeight

    #dom.style.lineHeight = $current.textStyle.lineHeight & "px"

  if cacheGroup.editableText != current.editableText:
    cacheGroup.editableText = current.editableText
    while dom.firstChild != nil:
      dom.removeChild(dom.firstChild)
    var inputDiv = document.createElement("input")
    dom.appendChild(inputDiv)
    cacheGroup.text = current.text
    inputDiv.setAttribute("placeholder", current.text)
    inputDiv.setAttribute("type", "text")
    inputDiv.style.border = "none"
    inputDiv.style.outline = "none"
    inputDiv.style.width = $current.screenBox.w & "px"
    inputDiv.style.backgroundColor = "transparent"
    inputDiv.style.fontFamily = current.textStyle.fontFamily
    inputDiv.style.fontSize = $current.textStyle.fontSize & "px"
    inputDiv.style.fontWeight = $current.textStyle.fontWeight
    # inputDiv.style.lineHeight = $max(
    #   current.textStyle.lineHeight,
    #   current.textStyle.fontSize + 2) & "px"

  if cacheGroup.text != current.text:
    inc perf.numLowLevelCalls
    cacheGroup.text = current.text
    # remove old text
    while dom.firstChild != nil:
      dom.removeChild(dom.firstChild)

    var textDiv = document.createElement("span")
    dom.appendChild(textDiv)

    if current.text != "":
      # group has text, add text
      var textDom = document.createTextNode(current.text)
      textDiv.appendChild(textDom)

    #   if current.editableText:
    #     textDiv.setAttribute("contenteditable", $current.editableText)
    #     # css-hax "outline: none" does not work because it does not show cursor when
    #     # there are no characters
    #     textDiv.style.outline = "1px solid transparent"
    #   dom.style.overflow = "hidden"

    textDiv.style.whiteSpace = "pre"
    textDiv.style.position = "absolute"

    case current.textStyle.textAlignHorizontal:
      of -1:
        textDiv.style.left = "0px"
      of 1:
        textDiv.style.right = "0px"
      else:
        textDiv.style.left = "50%"

    case current.textStyle.textAlignVertical:
      of -1:
        textDiv.style.top = "0px"
      of 1:
        textDiv.style.bottom = "0px"
      else:
        textDiv.style.bottom = "50%"

    if current.textStyle.textAlignVertical == 0:
      if current.textStyle.textAlignHorizontal == 0:
        textDiv.style.transform = "translate(-50%,-50%)"
        textDiv.style.top = "50%"
        textDiv.style.bottom = ""
      else:
        textDiv.style.transform = "translate(0, -50%)"
        textDiv.style.top = "50%"
        textDiv.style.bottom = ""
    else:
      if current.textStyle.textAlignHorizontal == 0:
        textDiv.style.transform = "translate(-50%, 0)"

  if cacheGroup.imageName != current.imageName:
    cacheGroup.imageName = current.imageName
    if current.imageName != "":
      dom.style.backgroundImage = "url(" & current.imageName & ".png)"
      dom.style.backgroundSize = "100% 100%"
    else:
      dom.style.backgroundImage = ""

  if cacheGroup.cornerRadius != current.cornerRadius:
    cacheGroup.cornerRadius = current.cornerRadius
    dom.style.borderRadius = (
      $current.cornerRadius[0] & "px " &
      $current.cornerRadius[1] & "px " &
      $current.cornerRadius[2] & "px " &
      $current.cornerRadius[3] & "px"
    )
  inc numGroups

var startTime: float

proc drawStart() =
  startTime = window.performance.now()
  numGroups = 0
  perf.numLowLevelCalls = 0

  rootUrl = $window.location.search

  # set up root HTML
  root.box.x = 0
  root.box.y = 0
  root.box.w = float document.body.clientWidth
  root.box.h = float document.body.clientHeight

  scrollBox.x = float window.scrollX
  scrollBox.y = float window.scrollY
  scrollBox.w = float document.body.clientWidth
  scrollBox.h = float document.body.clientHeight

  document.body.style.overflowX = "hidden"
  document.body.style.overflowY = "auto"


proc drawFinish() =

  perf.drawMain = window.performance.now() - startTime

  #echo perf.drawMain
  #echo numGroups
  #echo perf.numLowLevelCalls

  # remove left over nodes
  while rootDomNode.childNodes.len > numGroups:
    rootDomNode.removeChild(rootDomNode.lastChild)
    discard divCache.pop()


proc hardRedraw() =
  setupRoot()

  drawStart()
  drawMain()
  drawFinish()


proc requestHardRedraw(time: float = 0.0) =
  requestedFrame = false
  hardRedraw()


proc redraw*() =
  if not requestedFrame:
    requestedFrame = true
    discard window.requestAnimationFrame(requestHardRedraw)

window.addEventListener "load", proc(event: Event) =
  redraw()

  rootDomNode = document.createElement("div")
  document.body.appendChild(rootDomNode)


window.addEventListener "resize", proc(event: Event) =
  redraw()


window.addEventListener "scroll", proc(event: Event) =
  redraw()


window.addEventListener "mousedown", proc(event: Event) =
  mouse.pos.x = float event.pageX
  mouse.pos.y = float event.pageY
  mouse.click = true
  mouse.down = true
  hardRedraw()
  mouse.click = false


window.addEventListener "mouseup", proc(event: Event) =
  redraw()
  mouse.down = false


window.addEventListener "mousemove", proc(event: Event) =
  # don't redraw(), too heavy
  mouse.pos.x = float event.pageX
  mouse.pos.y = float event.pageY
  redraw()


proc set*(keyboard: Keyboard, state: KeyState, event: Event) =
  keyboard.state = state
  keyboard.keyCode = event.keyCode
  var keyString: cstring
  asm """`keyString` = `event`.key"""
  keyboard.keyString = $keyString
  keyboard.altKey = event.altKey
  keyboard.ctrlKey = event.ctrlKey
  keyboard.shiftKey = event.shiftKey

window.addEventListener "keydown", proc(event: Event) =
  keyboard.set(Down, event)
  hardRedraw()
  if keyboard.state != Empty:
    keyboard.use()
  else:
    event.preventDefault()

window.addEventListener "keyup", proc(event: Event) =
  keyboard.set(Up, event)
  hardRedraw()
  if keyboard.state != Empty:
    keyboard.use()
  else:
    event.preventDefault()

window.addEventListener "keypress", proc(event: Event) =
  keyboard.set(Press, event)
  hardRedraw()
  if keyboard.state != Empty:
    keyboard.use()
  else:
    event.preventDefault()

window.addEventListener "input", proc(event: Event) =
  ## When INPUT element has keyboard input this is called
  if document.activeElement.nodeName == "INPUT":
    keyboard.input = $(cast[InputElement](document.activeElement).value)
    keyboard.inputFocusId = $document.activeElement.parentElement.id
    redraw()
    echo "input"

window.addEventListener "focusin", proc(event: Event) =
  ## When INPUT element gets focus this is called, set the keyboard.input and
  ## the keyboard.inputFocusId
  ## Note: "focus" does not bubble, so its not used here.
  if document.activeElement.nodeName == "INPUT":
    keyboard.input = $(cast[InputElement](document.activeElement).value)
    keyboard.inputFocusId = $document.activeElement.parentElement.id
    redraw()

window.addEventListener "focusout", proc(event: Event) =
  ## When INPUT element looses focus this is called, clear keyboard.input and
  ## the keyboard.inputFocusId
  ## Note: "blur" does not bubble, so its not used here.
  keyboard.input = ""
  keyboard.inputFocusId = ""
  redraw()


proc goto*(url: string) =
  ## Goes to a new URL, inserts it into history so that back button works
  type dummy = object
  window.history.pushState(dummy(), "", url)
  redraw()


proc openBrowser*(url: string) =
  ## Opens a URL in a browser
  discard window.open("https://reddit.atlassian.net/wiki/spaces/EX/pages/399114580/Experiment+Analysis+UI", "_blank")

