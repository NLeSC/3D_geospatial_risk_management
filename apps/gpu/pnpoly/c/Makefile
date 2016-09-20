CC=gcc

debug:
	$(CC) -Wall -g pnpoly.c -o pnpoly

release:
	$(CC) -Wall -O3 pnpoly.c -o pnpoly

multi_debug:
	$(CC) -Wall -g pnpoly_multi.c -fopenmp -o pnpoly_multi

multi_release:
	$(CC) -Wall -O3 pnpoly_multi.c -fopenmp -o pnpoly_multi

clean:
	rm pnpoly
	rm pnpoly_multi
