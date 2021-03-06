#
# Copyright (C) 2019 Chris McClelland
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software
# and associated documentation files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright  notice and this permission notice  shall be included in all copies or
# substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
# BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

# Launch ModelSim in GUI mode, with appropriate window layout
proc gui_run {ncw vcw go gp start width cursor} {
  add wave -div ""
  configure wave -namecolwidth $ncw
  configure wave -valuecolwidth $vcw
  configure wave -gridoffset "${go}ns"
  configure wave -gridperiod "${gp}ns"
  onbreak resume
  run -all
  view wave
  set end [expr ${start}+${gp}*${width}]
  bookmark add wave default "${start}ns ${end}ns"
  bookmark goto wave default
  wave activecursor 1
  wave cursortime -time "${cursor}ns"
  wave refresh
}

proc vsim_run {tb {opts ""}} {
  set cov ""
  if {$::env(COVERAGE) == 1} {
    set cov "-coverage"
  }
  if {$::env(VOPT) == "0"} {
    echo "Running without vopt by default: put VOPT := 1 in your Makefile to enable it"
    eval "vsim -novopt -t ps ${cov} ${opts} $::env(DEF_LIST) -L work_lib $::env(LIB_LIST) ${tb}"
  } elseif {[string match "*ModelSim ALTERA*" [vsim -version]]} {
    echo "Running without vopt because ModelSim Altera does not support it"
    eval "vsim -novopt -t ps ${cov} ${opts} $::env(DEF_LIST) -L work_lib $::env(LIB_LIST) ${tb}"
  } else {
    echo "Running with vopt..."
    eval "vopt +acc ${tb} -o ${tb}_opt ${opts} $::env(DEF_LIST) -L work_lib $::env(LIB_LIST)"
    eval "vsim -t ps ${cov} ${tb}_opt"
  }
}

proc cli_run {{opts ""}} {
  foreach tb [split $::env(TESTBENCH) " "] {
    vsim_run ${tb} ${opts}
    run -all
    if {$::env(COVERAGE) == 1} {
      echo
      coverage report -file coverage.txt
      cat coverage.txt
    }
  }
}

proc finish {} {
  set result [coverage attribute -name TESTSTATUS -concise]
  if {$::env(CONTINUE_ON_FAILURE) == 1} {
    if {$result != 0} {
      echo "Tests failed, but CONTINUE_ON_FAILURE was set, therefore creating \$PROJ_HOME/.testfail and continuing"
      close [open "$::env(PROJ_HOME)/.testfail" w]
    }
    exit -force -code 0
  } else {
    exit -force -code $result
  }
}
