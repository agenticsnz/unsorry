The seedkit gains five more theorem families — arithmetic series, shifted-square
sums, scaled odd-square sums, alternating geometric series, and consecutive-product
divisibility (`k! ∣ n·(n+1)·…·(n+k−1)`) — each with a one-line `run_batch_<family>.sh`
wrapper. The shared number-word table now spans 1..80. `run_batch_family.sh` also
clears `.lake/build` after each batch (`SEEDKIT_CLEAN_BUILD`, default on) so a long
pool run cannot exhaust the disk with accumulated per-module build output.
