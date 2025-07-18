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


# Hierarchy check


set data "read liberty -lib -ignore miss dir -setattr blackbox ${LateLibraryPath}"

set filename "$DesignName.hier.ys"
set fileID [open $OutputDirectory/$filename "w"]

puts -nonewline $fileID $data
set netlist [glob -dir $NetlistDirectory *.v]

foreach f $netlist {
	set data $f
	puts -nonewline $fileID "\nread verilog file $f"
}

puts -nonewline $fileID "\nhierarchy -check" 
close $fileID


if { [catch {exec yosys -s $OutputDirectory/$DesignName.hier.ys >& $OutputDirectory/$DesignName.hierarchy_check.log} ]} {
	set filename "$OutputDirectory/$DesignName.hierarchy_check.log"
	set pattern "referenced in module"
	set fid [open $filename]
	while {[gets $fid line] != -1} {
		if {[regexp -all -- $pattern $line]} {
			puts "\nERROR: Module [lindex $line 2] is not part of design"
			puts "\nHiearchy check FAIL"
		}
	}
	close $fid
} else {
	puts "\nINFO: Hieararchy check PASS"
}

puts "\nINFO: Please find the hierarchy check file in [file normalize $OutputDirectory/$DesignName.hierarchy_check.log] for more deets"

#---------------------------#
#---Main Synthesis Script---#
#---------------------------#

puts "\nINFO: Creating main synthesis script to be used by Yosys"
set data "read_liberty -lib -ignore_miss_dir -setattr blackbox ${LateLibraryPath}"
set files "$DesignName.ys"
set fid [open $OutputDirectory/$files "w"]
puts -nonewline $fid $data

set netlist [glob -dir $NetlistDirectory *.v]
foreach f $netlist {
	set data $f
	puts -nonewline $fid "\nread_verilog $f"
}

puts -nonewline $fid "\nhierarchy -top $DesignName"
puts -nonewline $fid "\nsynth -top $DesignName"
puts -nonewline $fid "\nsplitnets -ports -format ___\ndfflibmap -liberty ${LateLibraryPath}\nopt"
puts -nonewline $fid "\nabc -liberty ${LateLibraryPath}"
puts -nonewline $fid "\nflatten"
puts -nonewline $fid "\nclean -purge\niopadmap -outpad BUFX2 A:Y -bits\nopt\nclean"
puts -nonewline $fid "\nwrite_verilog $OutputDirectory/$DesignName.synth.v"
close $fid

puts "\nINFO: Running synthesis..."


if {[catch {exec yosys -s $OutputDirectory/$DesignName.ys >& $OutputDirectory/$DesignName.synthesis.log} msg]} {
	puts "\nERROR: Synthesis failed. Please refer to log $OutputDirectory/$DesignName.synthesis.log for errors"
	exit
} else {
	puts "\nINFO: Synthesis successful"
}
puts "Please find logs $OutputDirectory/$DesignName.synthesis.log"


set fid [open /tmp/1 "w"]
puts -nonewline $fid [exec grep -v -w "*" $OutputDirectory/$DesignName.synth.v]
close $fid

set output [open $OutputDirectory/$DesignName.final.synth.v "w"]

set files "/tmp/1"
set fil [open $files r]
	while {[gets $fil line] != -1} {
		puts -nonewline $output [string map {"\\" ""} $line]
		puts -nonewline $output "\n"
	}
	close $fil
	close $output

	puts "\nInfo: Please find the synthesized netlist for $DesignName at below path. You can use this netlist for STA or PNR"
puts "\n$OutputDirectory/$DesignName.final.synth.v"

source ./procs/reopenStdout.proc
source ./procs/set_num_threads.proc

#STA
#Analysis

reopenStdout $OutputDirectory/$DesignName.conf
set_multi_cpu_usage -localCpu 2

source ./procs/read_lib.proc
read_lib -early /home/vsduser/vsdsynth/osu018_stdcells.lib

read_lib -late /home/vsduser/vsdsynth/osu018_stdcells.lib

source ./procs/read_verilog.proc
read_verilog $OutputDirectory/$DesignName.final.synth.v

source ./procs/read_sdc.proc
read_sdc $OutputDirectory/$DesignName.sdc
reopenStdout /dev/tty
set enable_prelayout_timing 1
if {$enable_prelayout_timing == 1} {
	puts "\nInfo: enable_prelayout_timing is $enable_prelayout_timing. Enabling zero-wire load parasitics"
	set spef_file [open $OutputDirectory/$DesignName.spef w]
puts $spef_file "*SPEF \"IEEE 1481-1998\" "
puts $spef_file "*DESIGN \"$DesignName\" "
puts $spef_file "*DATE \"Sun May 11 20:51:50 2025\" "
puts $spef_file "*VENDOR \"PS 2025 Hackathon\" "
puts $spef_file "*PROGRAM \"Benchmark Parasitic Generator\" "
puts $spef_file "*VERSION \"0.0\" "
puts $spef_file "*DESIGN_FLOW \"NETLIST_TYPE_VERILOG\" "
puts $spef_file "*DIVIDER / "
puts $spef_file "*DELIMITER : "
puts $spef_file "*BUS_DELIMITER [ ] "
puts $spef_file "*T_UNIT 1 PS "
puts $spef_file "*C_UNIT 1 FF "
puts $spef_file "*R_UNIT 1 KOHM "
puts $spef_file "*L_UNIT 1 UH "
}

close $spef_file

set conf_file [open $OutputDirectory/$DesignName.conf a]
puts $conf_file "set_spef_fpath $OutputDirectory/$DesignName.spef"
puts $conf_file "init_timer "
puts $conf_file "report_timer "
puts $conf_file "report_wns "
puts $conf_file "report_worst_paths -numPaths 10000 "
close $conf_file

set tcl_precision 3

set time_elapsed_in_us [time {exec /home/vsduser/OpenTimer-1.0.5/bin/OpenTimer < $OutputDirectory/$DesignName.conf >& $OutputDirectory/$DesignName.results} 1]
set time_elapsed_in_sec "[expr {[lindex $time_elapsed_in_us 0]/100000}] sec"
puts "\nInfo: STA finished in $time_elapsed_in_sec seconds"
puts "\nInfo: Refer to $OutputDirectory/$DesignName.results for warning and errors"

puts "tcl_precision is $tcl_precision"

set WRAT "-"
set fil [open $OutputDirectory/$DesignName.results r]
set pattern {RAT}
while {[gets $fil line] != -1} {
	if {[regexp $pattern $line]} {
		set WRAT "[expr {[lindex $line 3]/1000}]ns"
		break
	} else {
		continue
	}
}
puts "INFO: Worst RAT Slack is $WRAT"
close $fil

set fil [open $OutputDirectory/$DesignName.results r]
set count 0
while {[gets $fil line] != -1} {
                incr count [regexp -all -- $pattern $line]
}
set count_output_violations $count
puts "Number of output violations $count_output_violations"
close $fil

set w_negative_setup_slack "-"
set fil [open $OutputDirectory/$DesignName.results r]
set pattern {Setup}
while {[gets $fil line] != -1} {
        if {[regexp $pattern $line]} {
                set w_negative_setup_slack "[expr {[lindex $line 3]/1000}]ns"
                break
        } else {
                continue
        }
}
close $fil

set fil [open $OutputDirectory/$DesignName.results r]
set count 0
while {[gets $fil line] != -1} {
                incr count [regexp -all -- $pattern $line]
}
set count_setup_violations $count
close $fil

set w_negative_hold_slack "-"
set fil [open $OutputDirectory/$DesignName.results r]
set pattern {Hold}
while {[gets $fil line] != -1} {
        if {[regexp $pattern $line]} {
                set w_negative_hold_slack "[expr {[lindex $line 3]/1000}]ns"
                break
        } else {
                continue
        }
}
close $fil

set fil [open $OutputDirectory/$DesignName.results r]
set count 0
while {[gets $fil line] != -1} {
                incr count [regexp -all -- $pattern $line]
}
set count_hold_violations $count
close $fil

set pattern {Num of gates}
set fil [open $OutputDirectory/$DesignName.results r]
while {[gets $fil line] != -1} {
        if {[regexp $pattern $line]} {
                set instance_count [lindex [join $line " "] 4 ]
                break
        } else {
                continue
        }
}
close $fil

set Instance_count "$instance_count PS"
set time_elapsed_in_sec "$time_elapsed_in_sec PS"
puts "DesignName is \{$DesignName\}"
puts "time_elapsed_in_sec is \{$time_elapsed_in_sec\}"
puts "Instance_count is \{$instance_count\}"
puts "worst_negative_setup_slack is \{$w_negative_setup_slack\}"
puts "Number_of_setup_violations is \{$count_setup_violations\}"
puts "worst_negative_hold_slack is \{$w_negative_hold_slack\}"
puts "Number_of_hold_violations is \{$count_hold_violations\}"
puts "worst_RAT_slack is \{$WRAT\}"
puts "Number_output_violations is \{$count_output_violations\}"

puts "\n"
puts "                                 **********PRELAYOUT TIMING RESULTS**********                                                      "
set formatStr {%15s%15s%15s%15s%15s%15s%15s%15s%15s}

puts [format $formatStr "-----------" "-------" "--------------" "-----------" "-----------" "----------" "----------" "-------" "-------"]
puts [format $formatStr "Design Name" "Runtime" "Instance Count" " WNS Setup " " FEP Setup " " WNS Hold " " FEP Hold " "WNS RAT" "FEP RAT"]
puts [format $formatStr "-----------" "-------" "--------------" "-----------" "-----------" "----------" "----------" "-------" "-------"]
foreach design_name $DesignName runtime $time_elapsed_in_sec instance_count $instance_count wns_setup $w_negative_setup_slack fep_setup $count_setup_violations wns_hold $w_negative_hold_slack fep_hold $count_hold_violations wns_rat $WRAT fep_rat $count_output_violations {
	puts [format $formatStr $design_name $runtime $instance_count $wns_setup $fep_setup $wns_hold $fep_hold $wns_rat $fep_rat]
}

puts [format $formatStr "-----------" "-------" "--------------" "-----------" "-----------" "----------" "----------" "-------" "-------"]
puts "\n"

