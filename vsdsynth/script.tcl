package require csv
package require struct::matrix

set file [lindex $argv 0]
set f [open $file]
struct::matrix m
csv::read2matrix $f m , auto
close $f
set cols [m columns]
set rows [m rows]

m link arr
puts  "Column: $cols, Rows: $rows are the size of the CSV"

set i 0
while {$i < $rows} {
	puts "Setting value for $arr(0,$i) as '$arr(1,$i)'"
	if {$i == 0} {
		set [string map {" " ""} $arr(0,$i)] $arr(1,$i)
	} else {
		set [string map {" " ""} $arr(0,$i)] [file normalize $arr(1,$i)]
	}
	set i [expr {$i+1}]
}


puts "INFO: Validating if all files are present..."
puts "INFO: Design name: $DesignName"

if {! [file isdirectory $OutputDirectory]} {
        puts "File $OutputDirectory does not exist! Creating file $OutputDirectory"
	file mkdir $OutputDirectory
} else {
        puts "Found file $OutputDirectory"
}

if {! [file isdirectory $NetlistDirectory]} {
        puts "File $NetlistDirectory does not exist!"
} else {
        puts "Found file $NetlistDirectory"
}

if {! [file exists $EarlyLibraryPath]} {
        puts "File $EarlyLibraryPath does not exist!"
	exit
} else {
        puts "Found file $EarlyLibraryPath"
}

if {! [file exists $LateLibraryPath]} {
        puts "File $LateLibraryPath does not exist!"
	exit
} else {
        puts "Found file $LateLibraryPath"
}

if {! [file exists $ConstraintsFile]} {
        puts "File $ConstraintsFile does not exist!"
        exit
} else {
        puts "Found file $ConstraintsFile"
}

puts "Reading the Constraints file..."

struct::matrix const
set chan [open $ConstraintsFile]
csv::read2matrix $chan const , auto
close $chan

set c_row [const rows]
set c_col [const columns]


set clocks_row [lindex [lindex [const search all CLOCKS] 0] 1]
set inputs_row [lindex [lindex [const search all INPUTS] 0] 1]
set outputs_row [lindex [lindex [const search all OUTPUTS] 0] 1]
set clocks_col 0
set inputs_col 0
set outputs_col 0

set clock_early_rise_delay [lindex [lindex [const search rect $clocks_col $clocks_row [expr {$c_col-1}] [expr {$c_row-1}] early_rise_delay] 0] 0]

set clock_early_fall_delay [lindex [lindex [const search rect $clocks_col $clocks_row [expr {$c_col-1}] [expr {$c_row-1}] early_fall_delay] 0] 0]

set clock_late_rise_delay [lindex [lindex [const search rect $clocks_col $clocks_row [expr {$c_col-1}] [expr {$c_row-1}] late_rise_delay] 0] 0]

set clock_late_fall_delay [lindex [lindex [const search rect $clocks_col $clocks_row [expr {$c_col-1}] [expr {$c_row-1}] late_fall_delay] 0] 0]

set clock_early_rise_slew [lindex [lindex [const search rect $clocks_col $clocks_row [expr {$c_col-1}] [expr {$c_row-1}] early_rise_slew] 0] 0]

set clock_early_fall_slew [lindex [lindex [const search rect $clocks_col $clocks_row [expr {$c_col-1}] [expr {$c_row-1}] early_fall_slew] 0] 0]

set clock_late_rise_slew [lindex [lindex [const search rect $clocks_col $clocks_row [expr {$c_col-1}] [expr {$c_row-1}] late_rise_slew] 0] 0]

set clock_late_fall_slew [lindex [lindex [const search rect $clocks_col $clocks_row [expr {$c_col-1}] [expr {$c_row-1}] late_fall_slew] 0] 0]

puts "Position of early_rise_delay $clock_early_rise_delay"

set sdc_file [open $OutputDirectory/$DesignName.sdc "w"]
set i [expr $clocks_row+1]
set port [expr $inputs_row-1]

while {$i < $port} {
	puts -nonewline $sdc_file "\ncreate_clock -name [const get cell 0 $i] -period [const get cell 1 $i] -waveform \{0 [expr {[const get cell 1 $i]*[const get cell 2 $i]/100}]\} \[get_ports [const get cell 0 $i]\]"
	puts -nonewline $sdc_file "\nset_clock_latency -source -early -rise [const get cell $clock_early_rise_delay $i] \[get_clocks [const get cell 0 $i]\]"
	puts -nonewline $sdc_file "\nset_clock_latency -source -early -rise [const get cell $clock_early_fall_delay $i] \[get_clocks [const get cell 0 $i]\]"
	puts -nonewline $sdc_file "\nset_clock_latency -source -early -rise [const get cell $clock_late_rise_delay $i] \[get_clocks [const get cell 0 $i]\]"
	puts -nonewline $sdc_file "\nset_clock_latency -source -early -rise [const get cell $clock_late_fall_delay $i] \[get_clocks [const get cell 0 $i]\]"

	puts -nonewline $sdc_file "\nset_clock_transition -rise -min [const get cell $clock_early_rise_slew $i] \[get_clocks [const get cell 0 $i]\]"
	puts -nonewline $sdc_file "\nset_clock_transition -fall -min [const get cell $clock_early_fall_slew $i] \[get_clocks [const get cell 0 $i]\]"
	puts -nonewline $sdc_file "\nset_clock_transition -rise -max [const get cell $clock_late_rise_slew $i] \[get_clocks [const get cell 0 $i]\]"
	puts -nonewline $sdc_file "\nset_clock_transition -fall -max [const get cell $clock_late_fall_slew $i] \[get_clocks [const get cell 0 $i]\]"
	
	set i [expr $i+1]
}



set input_early_rise_delay [lindex [lindex [const search rect 0 $inputs_row [expr $c_col-1] [expr $outputs_row-1] early_rise_delay] 0] 0]
set input_early_fall_delay [lindex [lindex [const search rect 0 $inputs_row [expr $c_col-1] [expr $outputs_row-1] early_fall_delay] 0] 0]
set input_late_rise_delay [lindex [lindex [const search rect 0 $inputs_row [expr $c_col-1] [expr $outputs_row-1] late_rise_delay] 0] 0]
set input_late_fall_delay [lindex [lindex [const search rect 0 $inputs_row [expr $c_col-1] [expr $outputs_row-1] late_fall_delay] 0] 0]

set input_early_rise_slew [lindex [lindex [const search rect 0 $inputs_row [expr $c_col-1] [expr $outputs_row-1] early_rise_slew] 0] 0]
set input_early_fall_slew [lindex [lindex [const search rect 0 $inputs_row [expr $c_col-1] [expr $outputs_row-1] early_fall_slew] 0] 0]
set input_late_rise_slew [lindex [lindex [const search rect 0 $inputs_row [expr $c_col-1] [expr $outputs_row-1] late_rise_slew] 0] 0]
set input_late_fall_slew [lindex [lindex [const search rect 0 $inputs_row [expr $c_col-1] [expr $outputs_row-1] late_fall_slew] 0] 0]

puts "$input_early_rise_delay $input_late_rise_delay $input_early_rise_slew $input_late_rise_slew"

set i [expr $inputs_row+1]
set end_of_loop [expr $outputs_row-1]

puts "INFO: WORKING ON IO PORTS"
puts "\nINFO: CATEGORISING BITS AND BUSSES FROM INPUT PORTS"

while {$i < $end_of_loop} {
set netlist [glob -dir $NetlistDirectory *.v]
set temp_f [open /tmp/1 w]

foreach f $netlist {
	set fd [open $f]
	puts "Reading file : $f"
	while {[gets $fd line] != -1} {
		set pattern1 " [const get cell 0 $i];"
		#puts "Reading Pattern : $pattern1"
		if {[regexp -all -- $pattern1 $line]} {
			set pattern2 [lindex [split $line ";"] 0]
			puts "Pattern extracter after neglecting ; is $pattern2"
			if {[regexp -all {input} [lindex [split $pattern2 "\S+"] 0]]} {
				set s1 "[lindex [split $pattern2 "\S+"] 0] [lindex [split $pattern2 "\S+"] 1] [lindex [split $pattern2 "\S+"] 2]"
	puts "removing multiple spaces for the string \"[regsub -all {\s+} $s1 " "]\""
				puts -nonewline $temp_f "\n[regsub -all {\s+} $s1 " "]"
}
		}
	}
	close $fd
}
close $temp_f

set temp_f [open /tmp/1]
set temp2_f [open /tmp/2 w]

puts -nonewline $temp2_f "[join [lsort -unique [split [read $temp_f] \n]] \n]"

close $temp_f
close $temp2_f

set temp2_f [open /tmp/2]
set count [llength [read $temp2_f]]
if {$count > 2} {
	set inp_ports [concat [const get cell 0 $i]*]
} else {
	set inp_ports [const get cell 0 $i]
}

puts -nonewline $sdc_file "\nset_input_delay -clock \[get_clocks [const get cell [expr $input_late_fall_slew+1] $i]\] -min -rise -source_latency_included [const get cell $input_early_rise_delay $i] \[get_ports $inp_ports\]"
puts -nonewline $sdc_file "\nset_input_delay -clock \[get_clocks [const get cell [expr $input_late_fall_slew+1] $i]\] -min -fall -source_latency_included [const get cell $input_early_fall_delay $i] \[get_ports $inp_ports\]"
puts -nonewline $sdc_file "\nset_input_delay -clock \[get_clocks [const get cell [expr $input_late_fall_slew+1] $i]\] -max -rise -source_latency_included [const get cell $input_late_rise_delay $i] \[get_ports $inp_ports\]"
puts -nonewline $sdc_file "\nset_input_delay -clock \[get_clocks [const get cell [expr $input_late_fall_slew+1] $i]\] -max -fall -source_latency_included [const get cell $input_late_fall_delay $i] \[get_ports $inp_ports\]"

puts -nonewline $sdc_file "\nset_input_transition -clock \[get_clocks [const get cell [expr $input_late_fall_slew+1] $i]\] -min -rise -source_latency_included [const get cell $input_early_rise_slew $i] \[get_ports $inp_ports\]"
puts -nonewline $sdc_file "\nset_input_transition -clock \[get_clocks [const get cell [expr $input_late_fall_slew+1] $i]\] -min -fall -source_latency_included [const get cell $input_early_fall_slew $i] \[get_ports $inp_ports\]"
puts -nonewline $sdc_file "\nset_input_transition -clock \[get_clocks [const get cell [expr $input_late_fall_slew+1] $i]\] -max -rise -source_latency_included [const get cell $input_late_rise_slew $i] \[get_ports $inp_ports\]"
puts -nonewline $sdc_file "\nset_input_delay -clock \[get_clocks [const get cell [expr $input_late_fall_slew+1] $i]\] -max -fall -source_latency_included [const get cell $input_late_fall_slew $i] \[get_ports $inp_ports\]"

set i [expr $i+1]
}

close $temp2_f

set output_early_rise_delay [lindex [lindex [const search rect 0 $outputs_row [expr $c_col-1] [expr $c_row-1] early_rise_delay] 0] 0]
set output_early_fall_delay [lindex [lindex [const search rect 0 $outputs_row [expr $c_col-1] [expr $c_row-1] early_fall_delay] 0] 0]
set output_late_rise_delay [lindex [lindex [const search rect 0 $outputs_row [expr $c_col-1] [expr $c_row-1] late_rise_delay] 0] 0]
set output_late_fall_delay [lindex [lindex [const search rect 0 $outputs_row [expr $c_col-1] [expr $c_row-1] late_fall_delay] 0] 0]
set output_load [lindex [lindex [const search rect 0 $outputs_row [expr $c_col-1] [expr $c_row-1] load] 0] 0]
set output_related_clock [lindex [lindex [const search rect 0 $outputs_row [expr $c_col-1] [expr $c_row-1] clocks] 0] 0]

set i [expr $outputs_row+1]
set end_loop $c_row


while {$i < $end_loop} {
set netlist [glob -dir $NetlistDirectory *.v]
set temp_f [open /tmp/1 w]

foreach f $netlist {
        set fd [open $f]
        puts "Reading file : $f"
        while {[gets $fd line] != -1} {
                set pattern1 " [const get cell 0 $i];"
                #puts "Reading Pattern : $pattern1"
                if {[regexp -all -- $pattern1 $line]} {
                        set pattern2 [lindex [split $line ";"] 0]
                        puts "Pattern extracter after neglecting ; is $pattern2"
                        if {[regexp -all {output} [lindex [split $pattern2 "\S+"] 0]]} {
                                set s1 "[lindex [split $pattern2 "\S+"] 0] [lindex [split $pattern2 "\S+"] 1] [lindex [split $pattern2 "\S+"] 2]"
        puts "removing multiple spaces for the string \"[regsub -all {\s+} $s1 " "]\""
                                puts -nonewline $temp_f "\n[regsub -all {\s+} $s1 " "]"
}
                }
        }
        close $fd
}
close $temp_f

set temp_f [open /tmp/1]
set temp2_f [open /tmp/2 w]

puts -nonewline $temp2_f "[join [lsort -unique [split [read $temp_f] \n]] \n]"

close $temp_f
close $temp2_f

set temp2_f [open /tmp/2]
set count [llength [read $temp2_f]]
if {$count > 2} {
        set op_ports [concat [const get cell 0 $i]*]
} else {
        set op_ports [const get cell 0 $i]
}

puts -nonewline $sdc_file "\nset_output_delay -clock \[get_clocks [const get cell $output_related_clock $i]\] -min -rise -source_latency_included [const get cell $output_early_rise_delay $i] \[get_ports $op_ports\]"
puts -nonewline $sdc_file "\nset_output_delay -clock \[get_clocks [const get cell $output_related_clock $i]\] -min -fall -source_latency_included [const get cell $output_early_fall_delay $i] \[get_ports $op_ports\]"
puts -nonewline $sdc_file "\nset_output_delay -clock \[get_clocks [const get cell $output_related_clock $i]\] -max -rise -source_latency_included [const get cell $output_late_rise_delay $i] \[get_ports $op_ports\]"
puts -nonewline $sdc_file "\nset_output_delay -clock \[get_clocks [const get cell $output_related_clock $i]\] -max -fall -source_latency_included [const get cell $output_late_fall_delay $i] \[get_ports $op_ports\]"
puts -nonewline $sdc_file "\nset_load [const get cell $output_load $i] \[get_ports $op_ports\]"
set i [expr $i+1]
}

close $temp2_f
close $sdc_file

puts "INFO: PROCESSING IS COMPLETE..."
puts "INFO: SDC FILE is created under the OUTPUT DIRECTORY"

