# Proof runs

This directory is the append-only fact table for terminal coordinated proof
runs (ADR-023 / SPEC-023-A). Each AISP record captures one locally completed
run that reached a durable outcome PR:

- `proved`: the proof passed local verification and its proof PR carries the
  matching library index entry;
- `decomposed`: the proof budget was exhausted and the accepted decomposition
  PR carries the run;
- `failed`: the proof budget was exhausted and the affinity-demotion PR carries
  the run because no decomposition was accepted.

Infrastructure failures and local-only smoke runs are excluded. Records are
advisory analytics inputs, never proof-admission or queue-selection inputs.
