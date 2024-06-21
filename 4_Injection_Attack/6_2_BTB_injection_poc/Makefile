all: attacker victim

attacker:
	@./run_attacker.sh

victim:
	@./run_victim.sh

clean:
	rm -f *.o *.out *.ld x_attacker x_victim
	../../utils/script/kill_attacker_process.sh