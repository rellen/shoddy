[
  parallel: true,
  skipped: true,
  tools: [
    # This project accepts the risk from advisory GHSA-rhv4-8758-jx7v.
    #
    # The advisory reports that decimal, in each version before 3.0.0, does
    # not limit the exponent in Decimal.new. An attacker can use this defect
    # to cause a denial of service, and the attacker needs no authentication.
    #
    # The risk is not applicable to this project, for two reasons:
    #
    #   * decimal is an indirect dependency of the dev environment only. The
    #     doctor package, version ~> 0.22.0, requires decimal ~> 2.0. Every
    #     dependency in mix.exs has runtime: false. Each dependency is limited
    #     to the dev environment, or to the dev environment and the test
    #     environment. Thus decimal is never part of a release, and it never
    #     receives data from a user.
    #   * A patch is not possible. The first corrected version is 3.0.0. But
    #     jason limits decimal to "~> 1.0 or ~> 2.0" in all of its releases,
    #     and this includes version 1.5.0-alpha.2. Both credo and mix_audit
    #     require jason. The doctor package, version 0.23.0, requires decimal
    #     ~> 3.1. Thus the dependencies cannot resolve.
    #
    # Examine this decision again when jason gives support for decimal
    # ~> 3.0. Then change doctor to ~> 0.23.0 and remove this override.
    {:mix_audit, "mix deps.audit --ignore-advisory-ids GHSA-rhv4-8758-jx7v"}
  ]
]
