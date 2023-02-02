#!/usr/bin/env -S awk -f

{switch ($0) {
  case /M106/: # fan on with percent
    match($0,/M106 S([0-9]+)/,a);
    print "M42 P14 S" int(511 * a[1] / 100)
  break
  case /M107/: # fan off
    print "M42 P14 S0"
  break
  case /G1/: # extrusion stuff
    if (match($0,/[^E]E(-?[0-9]+(\.[0-9]+)?)/, a)) {
      sub("E" a[1], "E" a[1] * 26.384, $0); print
    }else{
      print $0
    }
  break
  default:
    print $0;
  break
}}

