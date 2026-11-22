# Code Signing Policy

This document defines the code signing policy for the **AngelaMihomo** project, specifically utilizing the free open-source code signing service provided by the [SignPath Foundation](https://signpath.org/).

> **Current status (2026-11-21):** This policy describes the intended signing
> arrangement. It is **not yet in effect** for this repository: the SignPath
> steps in the release workflow are currently disabled (the upstream project's
> SignPath account was suspended by the provider's risk controls, and this
> fork's own SignPath open-source application has not been submitted yet).
> Until signing is activated, **Windows artifacts are unsigned** and Windows
> will show an "unknown publisher" prompt on install, and **macOS artifacts
> are ad-hoc signed and not notarized**. The README states the same. This
> notice will be removed in the same change that enables signing.

## 1. Scope

This policy applies to all Windows executable artifacts distributed by the AngelaMihomo project, including but not limited to:
- The main executable binary (`AngelaMihomo.exe`)
- The Helper Service executable
- The Windows Installer (`AngelaMihomo-*-setup.exe`)

## 2. Roles and Responsibilities

- **Project Maintainers**: Only authorized maintainers have the permission to push to the default branch (`main`), create release tags, and manage repository settings.
- **SignPath Service**: Provides the code signing certificate and handles the cryptographic signing process securely in the cloud.

## 3. Security and Branch Protection

To ensure that only trusted and reviewed code gets signed, the project enforces the following repository rules:
- **Protected Branches**: The `main` branch is protected.
- **Code Review**: All code changes from contributors must be submitted via Pull Requests (PRs).
- **Two-Factor Authentication (2FA)**: All maintainers with write access to the repository are highly encouraged (or required by GitHub policy) to enable 2FA.

## 4. Build and Signing Process

The signing process is strictly automated to prevent tampering. Manual code signing by individual developers is not permitted for official releases.

- **CI/CD Automation**: All signing operations are fully automated via GitHub Actions (e.g., `.github/workflows/build.yaml`).
- **Trigger Conditions**: Signing is only triggered during the official release process, specifically when pushing a new version tag (e.g., `v1.*.*`).
- **Ephemeral Environments**: All builds are compiled on ephemeral, isolated GitHub-hosted runners.
- **SignPath Integration**: Once the unsigned artifacts are compiled, the GitHub Action submits them to SignPath via their official API/Action. SignPath verifies the origin (GitHub Actions OIDC or API Token) and signs the artifacts.
- **Distribution**: The signed artifacts are automatically downloaded back to the runner and uploaded to the GitHub Releases page.
- **Android Keystore Handling (T251)**: In `build.yaml` the Android release keystore is decoded outside the checked-out workspace (under the runner's temp directory) and removed by an `always()` cleanup step; Gradle locates it through the `storeFile` property in `local.properties`. Pull requests from forks never receive this material — they build with a generated throwaway keystore, so their artifacts carry no release signature. Pull requests from branches in this repository do build with the release key (the project's signed trial packages are produced from PR pipelines); that residual exposure is accepted for this single-maintainer repository and recorded here deliberately.

## 5. Incident Response and Revocation

If a security breach, unauthorized commit, or private key compromise (related to the repository or CI tokens) is suspected:
1. Maintainers will immediately revoke any exposed tokens.
2. If malicious code was signed, maintainers will immediately contact the SignPath Foundation to request the revocation of the code signing certificate.
3. An advisory will be published on the GitHub repository to notify users.
