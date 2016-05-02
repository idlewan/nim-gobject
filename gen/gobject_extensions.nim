# manual extensions for gobject.nim
#

template gCallback*(f: expr): expr =
  cast[GCallback](f)

# typeIface: The GType of the interface to add
# ifaceInit: The interface init function
proc implementInterfaceStr*(typeIface, ifaceInit: string): string {.cdecl.} =
  """
var gImplementInterfaceInfo = GInterfaceInfoObj(interfaceInit: cast[GInterfaceInitFunc](\$2),
                                                     interfaceFinalize: nil,
                                                     interfaceData: nil)
addInterfaceStatic(gDefineTypeId, \$1, addr(gImplementInterfaceInfo))

""" % [typeIface, ifaceInit]

# Below is the original C description -- but we use nep1 style 
# tn: The name of the new type, in Camel case.
# t: The name of the new type, in lowercase, with words separated by _.
# tp: The GType of the parent type.
# f: GTypeFlags to pass to gTypeRegisterStatic()
# c: Custom code that gets inserted in the *GetType() function.
macro gDefineTypeExtended*(tn, t, tp, f, c: static[string]): stmt =
  var
    cc = indent("\n" & c, 4)
    s = """

proc $2Init(self: $1) {.cdecl.}
proc $2ClassInit(klass: $1Class) {.cdecl.}
var $2ParentClass: Gpointer = nil
var $1PrivateOffset: cint
proc $2ClassInternInit(klass: Gpointer) {.cdecl.} =
  $2ParentClass = typeClassPeekParent(klass)
  if $1PrivateOffset != 0:
    typeClassAdjustPrivateOffset(klass, $1PrivateOffset)

  $2ClassInit(cast[$1Class](klass))
  
proc $2GetInstancePrivate(self: $1): $1Private {.cdecl.} =
  return cast[$1Private](gStructMemberP(self, $1PrivateOffset))

proc $2GetType*(): GType {.cdecl.} =
  var gDefineTypeIdVolatile {.global.}: Gsize = 0
  if onceInitEnter(addr(gDefineTypeIdVolatile)):
    var gDefineTypeId: GType = registerStaticSimple($3,
                                      internStaticString("$1"),
                                      sizeof($1ClassObj).cuint,
                                      cast[GClassInitFunc]($2ClassInternInit),
                                      sizeof($1Obj).cuint,
                                      cast[GInstanceInitFunc]($2Init),
                                      cast[GTypeFlags]($4))
    $5
    onceInitLeave(addr(gDefineTypeIdVolatile), gDefineTypeId)
  return gDefineTypeIdVolatile

""" % [tn, t, tp, f, cc]
  #echo s
  result = parseStmt(s)

template gDefineTypeExtended*(tn, tp, f: expr; c: string) =
  const tnn = astToStr(tn)
  const t = toLower(tnn[0]) & substr(tnn, 1)
  gDefineTypeExtended(tnn, t, astToStr(tp), astToStr(f), c)

template offsetof*(typ, field): expr = (var dummy: typ; cast[system.int](addr(dummy.field)) - cast[system.int](addr(dummy)))

template gStructOffset*(typ, field): expr = (var dummy: typ; clong(cast[system.int](addr(dummy.field)) - cast[system.int](addr(dummy))))

template gPrivateOffset*(TypeName, field): expr =
  `TypeName privateOffset` + gStructOffset(`TypeName PrivateObj`, field)

template gStructMemberP*(structP, structOffset): expr =
  (cast[Gpointer]((cast[system.int](structP) + (clong) (structOffset))))

template gDefineTypeExtendedClassInit*(TypeName, typeName): string =
  """
  proc $2ClassInternInit(klass: Gpointer) {.cdecl.} =
    $2ParentClass = gTypeClassPeekParent (klass)
    if $1PrivateOffset != 0:
      gTypeClassAdjustPrivateIffset(klass, addr $1PrivateOffset)
    $2ClassInit(cast[ptr $1Class](klass))

""" % [TypeName, typeName]

template gAddPrivate*(TypeName): expr =
  `TypeName privateOffset` = addInstancePrivate(gDefineTypeId, sizeof(`TypeName PrivateObj`))

template gDefineType*(TN, TP): expr =
  gDefineTypeExtended (TN, TP, 0, "")

template gDefineTypeWithPrivate*(TN, TP): expr =
  gDefineTypeExtended(TN, TP, 0, "gAddPrivate(" & astToStr(TN) & ")")

