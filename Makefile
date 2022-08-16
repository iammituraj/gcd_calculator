#################################################################################################################################
# File Name        : Makefile
# Description      : Makefile to compile and simulate GCD Calculator in ModelSim/QuestaSim - in Linux.
# Developer        : Mitu Raj, chip@chipmunklogic.com at Chipmunk Logic ™, https://chipmunklogic.com
# Date of Creation : July-23-2022
#################################################################################################################################

# Define shell
.ONESHELL:
SHELL:=/bin/bash

# Define directories
SRC_DIR    = $(shell pwd)/src
SIM_DIR    = $(shell pwd)/sim
SCRIPT_DIR = $(shell pwd)/scripts
DUMP_DIR   = $(shell pwd)/dump_$(DATE)

# Shell variables
DATE = $$(date +'%d_%m_%Y')

# Questasim flags
TOP        = tb_apb_top_gcd
VLOG_FLAGS =
VSIM_FLAGS = -c -voptargs="+acc -O0" -logfile "$(SIM_DIR)/vsim.log"

#--------------------------------------------------------------------------------------------------------------------------------
# Targets and Recipes
#--------------------------------------------------------------------------------------------------------------------------------

# help
help:
	@echo ""
	@echo "HELP"
	@echo "----"
	@echo "1. make compile -- To compile design"
	@echo "2. make sim     -- To simulate design"
	@echo "4. make run_all -- To clean + compile + simulate design"
	@echo "3. make clean   -- To clean sim and dump"
	@echo ""

# build_sim
build_sim:
	@echo "Building sim directory ..."
	@mkdir -pv $(SIM_DIR)

# build_dump
build_dump:
	@echo "Building dump directory ..."
	@mkdir -pv $(DUMP_DIR)

# check_sim
check_sim:
	$(shell test $(SIM_DIR) || echo "sim directory not found - please compile first. OR run make help")

# compile
compile: build_sim
	@echo "Compiling design ..."
	vlog -logfile $(SIM_DIR)/vlog.log $(VLOG_FLAGS) -work $(SIM_DIR)/work -sv $(SRC_DIR)/*.sv

# sim
sim: check_sim build_dump
	@echo "Simulating design ..."
	vsim $(VSIM_FLAGS) $(SIM_DIR)/work.$(TOP) -t ns -do "\
	do "$(SCRIPT_DIR)/run.do""	
	mv -f $(shell pwd)/*.vcd $(DUMP_DIR)/

# run_all
run_all: clean compile sim

# clean
clean:
	@echo "Cleaning all simulation files ..."
	rm -rf $(SIM_DIR)
	rm -rf $(DUMP_DIR)
	rm -rf transcript
	rm -rf *.vstf
	rm -rf *.vcd