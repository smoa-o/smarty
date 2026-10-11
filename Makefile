TESTED ?= null
VERILOG ?= iverilog
SHELL := /bin/bash
VCD_POS ?= temp.vcd

all: test

test:
	-mkdir -p tb/sim/ tb/vcd/
	$(MAKE) testone TESTED=tb_clock

testone:
	@$(VERILOG) -I. tb/$(TESTED).v
	@mv a.out tb/sim/$(TESTED).vvp
	@printf "\e[34mTested: %s\e[0m\n" $(TESTED)
	@-vvp tb/sim/$(TESTED).vvp
	@mv temp.vcd tb/vcd/$(TESTED).vcd
	@printf "\n\e[34mIs it successful? \e[0m"
	@/bin/bash -c 'read -n 1 REPLY; echo; [ "$$REPLY" = "n" ] && exit 100 || exit 0'
