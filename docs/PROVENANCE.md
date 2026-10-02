# Project Provenance

## Origin

VaultGuard began from an existing ERC-4626 invariant-testing codebase that was available locally during development.

The inherited code provided the initial structure for:

- ERC-4626 interfaces
- invariant testing
- stateful fuzzing handlers
- reference and vulnerable vault mocks
- Foundry test organization

The current project has been substantially modified and extended beyond that starting point.

## Attribution

The original repository history is preserved in Git where available.

Existing source files are not presented as having been originally authored by the current project maintainer.

The project maintainer is responsible for the modifications, security tests, documentation, extensions, and new material added as part of VaultGuard.

## Repository Cleanup

During the initial review, an unrelated `vendor/` directory was identified under:

```text
src/mocks/vaults/reference/vendor/
```

The directory contained editor/bootstrap tooling and encoded executable payloads that were unrelated to the ERC-4626 testing framework.

The contents were **not executed**.

Relevant evidence was preserved before the directory was removed from the working project. The removal was committed separately before further development continued.

The cleanup was performed to keep the project focused on ERC-4626 testing and to prevent unrelated tooling from remaining in the repository.

## Development Approach

VaultGuard is being developed as an educational security-testing framework for ERC-4626 vaults.

The project distinguishes between:

1. inherited starting material,
2. modifications to inherited code,
3. newly authored tests and framework components, and
4. security findings demonstrated by executable tests.

Claims about vulnerabilities are intended to be supported by reproducible tests rather than by naming a potential issue alone.

## Security Testing Philosophy

VaultGuard uses multiple forms of executable testing:

- focused unit tests for individual ERC-4626 behaviors,
- stateful invariant testing across randomized action sequences,
- multi-actor fuzzing,
- adversarial implementations that intentionally violate expected behavior, and
- differential tests comparing the same sequence across implementations.

This approach is intended to make security properties and failure modes observable through reproducible test cases.

## Scope and Limitations

VaultGuard is an educational security-testing project and should not be interpreted as a complete audit framework.

Passing the included tests does not establish that an arbitrary production ERC-4626 implementation is secure.

The current project focuses on accounting consistency, conversion behavior, preview functions, rounding, limits, donations, and inflation-related share allocation.

Additional production risks may arise from protocol-specific features such as fees, strategies, external integrations, upgradeability, access control, oracle dependencies, or asynchronous assets.