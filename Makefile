TESTED ?= null
VERILOG ?= iverilog
SHELL := /bin/bash
VCD_POS ?= temp.vcd
VVP ?= vvp
ATRUN ?=

ST_IV = $(shell which $(VERILOG) 2>/dev/null)
ST_VVP = $(shell which $(VVP) 2>/dev/null)

TESTEDS ?= tb_clock tb_mem tb_regfile tb_xregfile tb_alu

test: $(TESTEDS)

$(TESTEDS):
	@mkdir -p tb/sim/ tb/vcd/
	$(MAKE) testone TESTED=$@

testone:
	-@mkdir -p tb/sim tb/vcd
	@$(VERILOG) -I. $(ATRUN) tb/$(TESTED).v || exit 80
	@mv a.out tb/sim/$(TESTED).vvp
	@printf "\e[34mTested: %s\e[0m\n" $(TESTED)
	@$(VVP) tb/sim/$(TESTED).vvp
	@mv temp.vcd tb/vcd/$(TESTED).vcd
ifndef UQST
	@printf "\n\e[34mIs it successful? \e[0m"
	@/bin/bash -c 'read -n 1 REPLY; echo; [ "$$REPLY" = "n" ] && exit 100 || exit 0'
endif

self-test:
ifeq ($(ST_IV),)
	@echo -e "\e[31m$(VERILOG) is not in this enviroment. \e[0m"
else ifeq ($(ST_VVP),)
	@echo -e "\e[31m$(VVP) is not in this enviroment. \e[0m"
else
	rm -f tb/sim/.pass tb/sim/.fail
	mkdir -p tb/sim/ tb/vcd/
	for t in $(TESTEDS); do \
		set -o pipefail; if $(MAKE) testone TESTED=$$t ATRUN="-D SELFTEST" \
		UQST=T 2>&1 | tee tb/sim/$$t.log; then \
			echo "$$t" >> tb/sim/.pass; \
		else \
			echo "$$t" >> tb/sim/.fail; \
		fi; \
	done; \
	echo -e "\n\n"; \
	if [ -s tb/sim/.pass ]; then \
		echo ""; \
		echo -e "\e[32mPassed:"; \
		while read p; do echo "  . $$p"; done < tb/sim/.pass; \
	fi; \
	echo; \
	if [ -s tb/sim/.fail ]; then \
		echo ""; \
		echo -e "\e[31mFailed:"; \
		while read f; do \
			printf "  F $$f: "; \
			grep -m1 "Fail" tb/sim/$$f.log | sed 's/^/        /; s/^.*Self-Test Failed: //'; \
		done < tb/sim/.fail; \
	fi; \
	echo -e "\e[0m"; \
	[ ! -s tb/sim/.fail ]
endif
