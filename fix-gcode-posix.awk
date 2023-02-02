#!/usr/bin/env -S awk -f

# adjust cooling fan
/M106/ { 
  for(i=1; i<=NF; i++) if ($i ~/S/) fan_percent=substr($i, 2);
  print "M42 P14 S" int(511 * fan_percent / 100) "; set cooling fan to " fan_percent "%"
}

# stop cooling fan
/M107/ {
  print "M42 P14 S0; stop cooling fan"
}

# adjust extrusion ammount
/G1/ {
  extrusion_ammount=0
  for(i=1; i<=NF; i++) if ($i ~/E/) extrusion_ammount=substr($i, 2);
  sub("E" extrusion_ammount, "E" extrusion_ammount * 26.316, $0)
}
