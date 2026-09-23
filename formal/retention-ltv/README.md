# Retention/LTV control plane — TLA+ model

This is an executable, bounded model of the proposed analytics ingestion,
app-version policy, update prompts, free core actions, premium usage, and
subscription state. It verifies control-plane safety; it cannot prove that a
feature causes retention or that a pricing hypothesis will succeed.

Run from the docs repository:

```bash
mkdir -p formal/retention-ltv/tools
cp formal/homies/tools/tla2tools.jar formal/retention-ltv/tools/
npm run verify:retention
```

The jar is TLA+ tools v1.7.4, downloaded and checksum-verified by
`formal/homies/tools/fetch-tla2tools.sh`. Java 11+ is required. Generated logs
under `out/` and the jar are ignored by Git.

Bounds: two clients, three ordered versions, four event IDs, one initial token,
and a two-token allowance cap. The four expected-fail reachability checks prove
that required/optional prompts and accepted core/premium events are reachable.
