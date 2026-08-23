[
  parallel: true,
  skipped: true,
  tools: [
    # GHSA-rhv4-8758-jx7v — decimal < 3.0.0, unbounded exponent in Decimal.new
    # enables unauthenticated DoS. Accepted risk, not exploitable here:
    #
    #   * decimal is a transitive dev-only dependency (doctor ~> 0.22.0, which
    #     pins decimal ~> 2.0). Every dep in mix.exs is only: [:dev, :test],
    #     runtime: false, so it never reaches a release and never sees
    #     untrusted input.
    #   * It cannot be patched. The first fixed version is 3.0.0, but jason
    #     caps decimal at "~> 1.0 or ~> 2.0" in every published release
    #     including 1.5.0-alpha.2, and jason is required by both credo and
    #     mix_audit. doctor 0.23.0 wants decimal ~> 3.1 and so is unresolvable.
    #
    # Revisit when jason ships decimal ~> 3.0 support; then bump doctor to
    # ~> 0.23.0 and drop this override.
    {:mix_audit, "mix deps.audit --ignore-advisory-ids GHSA-rhv4-8758-jx7v"}
  ]
]
