# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

The Terraform root configuration that sets up MTA-STS (RFC 8461) and TLS-RPT for `westphalia-kn.de`. All of the logic lives in the reusable module [`ThorstenSauter/mta-sts-cloudflare-azure-static-web-app`](https://github.com/ThorstenSauter/mta-sts-cloudflare-azure-static-web-app). It renders the policy, creates the Cloudflare DNS records and the Azure Static Web App, and deploys the content. This repo only pins the module version and supplies the domain-specific inputs. The single environment is `infra/production/`.

## Commands

No tests exist. To run the same static checks as CI from `infra/production/`:

```sh
terraform init -backend=false
terraform fmt -check -recursive
tflint --init --config ../.tflint.hcl && tflint --config ../.tflint.hcl
terraform validate
```

A real `plan`/`apply` needs the azurerm backend (configured through CI variables, since `backend.tf` is empty), Azure credentials, `CLOUDFLARE_API_TOKEN` and Node.js (the module deploys with `npx`). In practice it only runs in CI.

## CI/CD

- `terraform-plan.yml` (PRs to `main`): validates, then plans in the `plan-production` environment and posts the result to the PR. That environment holds read-only credentials (a Reader managed identity and a Zone:Read/DNS:Read Cloudflare token); `production`, with write access, is restricted to `main` and used only by the deploy. It uses `ThorstenSauter/terraform-actions`.
- `deploy-production.yml` (push to `main`): runs `terraform apply`. **Merging to `main` changes the live policy and DNS.**
  Deploys run one at a time in the `terraform-state-production` concurrency group and are never cancelled. Keep PR plan jobs out of that group: they wait on the state lock (`lock-timeout`) instead, because a third queued job in a group cancels the pending one.
- `mta-sts-check.yml` runs weekly (Mondays 06:00 UTC) and validates the live MTA-STS setup with `ThorstenSauter/mta-sts-check-action`. It opens, updates or closes a tracking issue labeled `mta-sts-check`.
- Azure auth uses OIDC. Backend settings and the working directory come from repository/environment variables (`TF_*`, `INFRA_DIRECTORY`). Nothing is hard-coded.
- The Terraform version is read from `.terraform-version`.

## Changing the policy

Edit the `module` block in `infra/production/main.tf`: `mx_hosts` (must match the domain's MX records exactly), `mta_sts_mode` (`testing`/`enforce`/`none`) and `rua` (the TLS-RPT report address). The module computes the policy ID from the rendered policy, so the `_mta-sts` TXT record and the redeploy follow automatically. When the mail provider's MX host changes, `mx_hosts` must be updated *before* the old host disappears. Otherwise senders in `enforce` mode will refuse delivery.
## Conventions

- Dependency updates (actions, the module `?ref=`, tflint plugin) come from Renovate using the shared `local>ThorstenSauter/renovate-config` preset. Major module bumps can change inputs, so check the module's release notes.
- GitHub Actions are pinned to commit SHAs with a `# vX.Y.Z` comment.
- `.terraform.lock.hcl` is committed (this is a root module).
- Commit messages follow Conventional Commits (`feat:`, `ci:`, `chore(deps):`), and changes land through PRs.
- `.editorconfig`: LF line endings, 2-space indent, UTF-8.
- This repo is one of several near-identical `mta-sts-<domain>` repos. Structural changes (workflows, tooling) are usually applied to all of them.
