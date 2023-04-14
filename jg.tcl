clear -all
set_proofgrid_manager on

set top_file fifo_wrap.v

analyze \
    -incdir . \
    -y . \
    -sv12 fifo_wrap.v \
    +libext+.vs +libext+.sv +libext+.vlib +libext+.v +libext+.vh +libext+.v \

elaborate -top fifo_wrap -disable_auto_bbox

clock clk
reset -expression rst

# ---------------------------------------------------------------------------
# Proof structure

# Utility function to filter property lists
proc lfilter {pattern l} {
     set res [list]
     foreach i $l {
         if [string match $pattern $i] {lappend res $i}
     }
     return $res
}


proof_structure -init Root -from <embedded> -copy_all

set goals [get_property_list -no_task_prefix -include {type {assert}}]

set helpers [lfilter "*hlp*" $goals]

set DataIntegrity [lfilter "*integrity*" $goals]

set CriticalLemma [lfilter "*lemma*" $goals]

proof_structure -create assume_guarantee \
    -from Root \
    -op_name AG \
    -property [list $helpers \
		   $CriticalLemma \
		   $DataIntegrity] \
    -imp_name [list "Helpers" "Critical Lemma" "Data Integrity"]
	       


# ---------------------------------------------------------------------------




# Run Proofs

set_engine_mode {Hp Ht Hps B K I N D Tri}
# set_engine_mode {Hps }

# set_engine_mode {Mp N}
# prove -all
