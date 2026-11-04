# Code Signing Policy

This document defines the code signing policy for the **AngelaMihomo** project, specifically utilizing the free open-source code signing service provided by the [SignPath Foundation](https://signpath.org/).

## 1. Scope

This policy applies to all Windows executable artifacts distributed by the AngelaMihomo project, including but not limited to:
- The main executable binary (`AngelaMihomo.exe`)
- The Helper Service executable
- The Windows Installer (`AngelaMihomo-*-setup.exe`)

## 2. Roles and Responsibilities

- **Project Maintainers**: Only authorized maintainers have the permission to merge into the default branch (`release/v1.19.6-chain.1`), create release tags, and manage repository settings.
- **SignPath Service**: Provides the code signing certificate and handles the cryptographic signing process securely in the cloud.

## 3. Security and Branch Protection

To ensure that only trusted and reviewed code gets signed, the project enforces the following repository rules:
- **Protected Branches**: The `main` branch and the default branch (`release/v1.19.6-chain.1`) are protected by the repository ruleset `protect-main-and-release`. Under this ruleset, changes can only land through a Pull Request, the required status checks (`Flutter and editor regressions` and `Go core regressions`) must pass on an up-to-date branch, force pushes are blocked, and the protected branches cannot be deleted.
- **Code Review**: All code changes must be submitted via Pull Requests (PRs). Merging into a protected branch is gated by the required status checks above; direct pushes to protected branches are not possible.
- **Two-Factor Authentication (2FA)**: All maintainers with write access to the repository are highly encouraged (or required by GitHub policy) to enable 2FA.

## 4. Build and Signing Process

The signing process is strictly automated to prevent tampering. Manual code signing by individual developers is not permitted for official releases.

- **Current Status**: SignPath signing is temporarily disabled in the build workflow (see the signing steps in `.github/workflows/build.yaml`) while the project's SignPath account is under review. Windows artifacts of current releases are therefore distributed unsigned. Once signing is re-enabled, the automated process described below applies unchanged.
- **CI/CD Automation**: All signing operations are fully automated via GitHub Actions (e.g., `.github/workflows/build.yaml`).
- **Trigger Conditions**: Signing is only triggered during the official release process, specifically when pushing a new version tag (e.g., `v1.*.*`).
- **Ephemeral Environments**: All builds are compiled on ephemeral, isolated GitHub-hosted runners.
- **SignPath Integration**: Once the unsigned artifacts are compiled, the GitHub Action submits them to SignPath via their official API/Action. SignPath verifies the origin (GitHub Actions OIDC or API Token) and signs the artifacts.
- **Distribution**: The artifacts are automatically downloaded back to the runner and uploaded to the GitHub Releases page (signed, when signing is enabled per the current status above).

## 5. Incident Response and Revocation

If a security breach, unauthorized commit, or private key compromise (related to the repository or CI tokens) is suspected:
1. Maintainers will immediately revoke any exposed tokens.
2. If malicious code was signed, maintainers will immediately contact the SignPath Foundation to request the revocation of the code signing certificate.
3. An advisory will be published on the GitHub repository to notify users.
