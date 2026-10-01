# Project Provenance

## Origin

VaultGuard began from an existing ERC-4626 invariant-testing codebase that was
available locally during development.

The inherited code provided the initial structure for:

- ERC-4626 interfaces
- invariant testing
- stateful fuzzing handlers
- reference and vulnerable vault mocks
- Foundry test organization

The current project is being substantially modified and extended beyond that
starting point.

## Attribution

The original repository history is preserved in Git where available. Existing
source files are not presented as having been originally authored by the
current project maintainer.

The project maintainer is responsible for the modifications, security tests,
documentation, extensions, and new material added as part of VaultGuard.

## Repository Cleanup

During the initial review, an unrelated `vendor/` directory was identified
under:

`src/mocks/vaults/reference/vendor/`

The directory contained editor/bootstrap tooling and encoded executable
payloads that were unrelated to the ERC-4626 testing framework.

The contents were not executed.

The directory was removed from the working project after the relevant evidence
had been preserved, and the removal was committed separately before further
development.

## Development Approach

VaultGuard is being developed as an educational and security-testing framework
for ERC-4626 vaults.

The project distinguishes between:

1. inherited starting material,
2. modifications to inherited code,
3. newly authored tests and framework components, and
4. security findings demonstrated by executable tests.

Claims about vulnerabilities are intended to be supported by reproducible
tests rather than by naming a potential issue alone.