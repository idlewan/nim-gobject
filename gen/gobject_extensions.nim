# manual extensions for gobject.nim
#
#template gSignalConnect*(instance, detailedSignal, cHandler, data: expr): expr =
#  gSignalConnectData(instance, detailedSignal, cHandler, data,
#                        nil, cast[GConnectFlags](0))
#

