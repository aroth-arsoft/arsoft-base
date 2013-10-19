<?php
// 'temp_c'=12.8;;;; 'temp_f'=55.0;;;; 'wind_degrees'=209.0;;;; 'wind_mph'=4.0;;;; 'wind_gust_mph'=6.0;;;; 'pressure_mb'=1003.6;;;; 'dewpoint_c'=8.9;;;; 'dewpoint_f'=48.0;;;; 'precip_1hr'=0.0;;;; 'precip_today'=0;;;;

$ds_name[1] = "temp_c";
$opt[1]  = "--vertical-label \"Degree Celsius\"  --title \"Temperature in Celsius\" ";
$def[1]  =  rrd::def("temp_c", $RRDFILE[1], $DS[1], "AVERAGE") ;
$def[1] .=  rrd::gprint("temp_c", array("LAST", "MAX", "AVERAGE"), "%2.1lf $UNIT[1]") ;
$def[1] .=  rrd::line2("temp_c", "#E80C3E", "Temperature") ;

$ds_name[2] = "temp_f";
$opt[2]  = "--vertical-label \"Degree Fahrenheit\"  --title \"Temperature in Fahrenheit\" ";
$def[2]  =  rrd::def("temp_f", $RRDFILE[1], $DS[2], "AVERAGE") ;
$def[2] .=  rrd::gprint("temp_f", array("LAST", "MAX", "AVERAGE"), "%2.1lf $UNIT[2]") ;
$def[2] .=  rrd::line2("temp_f", "#E80C3E", "Temperature") ;

$ds_name[3] = "wind_degrees";
$opt[3]  = "--vertical-label \"degree\" -u 360 -l 0 --title \"Wind direction\" ";
$def[3]  =  rrd::def("var1", $RRDFILE[1], $DS[3], "AVERAGE") ;
$def[3] .=  rrd::gprint("var1", array("LAST", "MAX", "AVERAGE"), "%2.1lf $UNIT[3]") ;
$def[3] .=  rrd::line2("var1", "#E80C3E", "Wind direction") ;

$ds_name[4] = "wind_mph and wind_gust_mph";
$opt[4]  = "--vertical-label \"mph\"  --title \"Wind and wind gust speed\" ";
$def[4]  =  rrd::def("wind_mph", $RRDFILE[1], $DS[4], "AVERAGE") ;
$def[4] .=  rrd::def("wind_gust_mph", $RRDFILE[1], $DS[5], "AVERAGE") ;
$def[4] .=  rrd::gprint("wind_mph", array("LAST", "MAX", "AVERAGE"), "%2.1lf $UNIT[4]") ;
$def[4] .=  rrd::gprint("wind_gust_mph", array("LAST", "MAX", "AVERAGE"), "%2.1lf $UNIT[5]") ;
$def[4] .=  rrd::line2("wind_mph", "#E80C3E", "Wind speed") ;
$def[4] .=  rrd::line2("wind_gust_mph", "#008000", "Wind gust speed") ;

$ds_name[5] = "pressure_mb";
$opt[5]  = "--vertical-label \"mbar\" -u 1150 -l 960 --title \"Air pressure\" ";
$def[5]  =  rrd::def("pressure_mb", $RRDFILE[1], $DS[6], "AVERAGE") ;
$def[5] .=  rrd::gprint("pressure_mb", array("LAST", "MAX", "AVERAGE"), "%2.1lf $UNIT[6]") ;
$def[5] .=  rrd::line2("pressure_mb", "#E80C3E") ;

$ds_name[6] = "dewpoint_c";
$opt[6]  = "--vertical-label \"Degree Celsius\"  --title \"Dewpoint in Celsius\" ";
$def[6]  =  rrd::def("dewpoint_c", $RRDFILE[1], $DS[7], "AVERAGE") ;
$def[6] .=  rrd::gprint("dewpoint_c", array("LAST", "MAX", "AVERAGE"), "%2.1lf $UNIT[7]") ;
$def[6] .=  rrd::line2("dewpoint_c", "#E80C3E", "Dewpoint") ;

$ds_name[7] = "dewpoint_f";
$opt[7]  = "--vertical-label \"Degree Fahrenheit\"  --title \"Dewpoint in Fahrenheit\" ";
$def[7]  =  rrd::def("dewpoint_f", $RRDFILE[1], $DS[8], "AVERAGE") ;
$def[7] .=  rrd::gprint("dewpoint_f", array("LAST", "MAX", "AVERAGE"), "%2.1lf $UNIT[8]") ;
$def[7] .=  rrd::line2("dewpoint_f", "#E80C3E", "Dewpoint") ;

$ds_name[8] = "precip_1hr and precip_today";
$opt[8]  = "--vertical-label \"cm\"  --title \"Precipitation\" ";
$def[8]  =  rrd::def("precip_1hr", $RRDFILE[1], $DS[9], "AVERAGE") ;
$def[8] .=  rrd::def("precip_today", $RRDFILE[1], $DS[10], "AVERAGE") ;
$def[8] .=  rrd::gprint("precip_1hr", array("LAST", "MAX", "AVERAGE"), "%2.1lf $UNIT[9]") ;
$def[8] .=  rrd::gprint("precip_today", array("LAST", "MAX", "AVERAGE"), "%2.1lf $UNIT[10]") ;
//$def[8] .=  rrd::line2("precip_1hr", "#E80C3E", "Last hour") ;
//$def[8] .=  rrd::line2("precip_today", "#008000", "Today") ;
$def[8] .=  rrd::gradient("precip_1hr", "#000080", "#0000FF", "Last hour") ;
$def[8] .=  rrd::gradient("precip_today", "#008080", "#00FFFF", "Today") ;

?>

