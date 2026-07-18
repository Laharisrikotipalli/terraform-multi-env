# Multi-Environment Cloud Infrastructure (Terraform + GitHub Actions)

A single Terraform codebase that provisions `dev`, `staging`, and `production`
environments on AWS using Terraform workspaces, with a containerized local
toolchain and a CI/CD pipeline that validates, cost-estimates, and deploys
changes.

## Architecture

![Multi-environment Terraform architecture diagram](docs/architecture.svg)

The diagram above shows the full flow: a developer works inside the
containerized `iac-workspace`, pushes to GitHub, which triggers the CI/CD
pipeline. The PR workflow plans against `staging` and posts an Infracost cost
comment; the deploy workflow applies to `staging` automatically and to
`production` only after a manual approval gate. Both workflows read and write
state through the locked S3/DynamoDB backend, and the root module composes
the `network` and `compute` modules to provision environment-scoped
infrastructure.

- **State**: S3 backend with versioning + KMS encryption, DynamoDB table for locking.
- **Modules**: `modules/network` (VPC, subnets, IGW, NAT, route tables) and
  `modules/compute` (ALB, security groups, EC2 instances).
- **Environments**: managed via `terraform workspace` (`dev`, `staging`, `production`),
  each with its own `.tfvars` file and isolated state.
- **CI**: `.github/workflows/pr-validation.yml` — format check, init, validate,
  plan against staging, Infracost cost comment on the PR.
- **CD**: `.github/workflows/deploy.yml` — a `resolve-targets` job computes
  which environment(s) to deploy from trigger context (push to `main` runs
  staging then production; a manual `workflow_dispatch` can target either
  environment directly). Production is additionally held behind a required
  reviewer on the GitHub `production` Environment (see *Repository Setup*
  below).

## How to Execute Each Tool

Step-by-step commands for every tool in this stack, in the order you'd normally run them.

### 1. Docker / Docker Compose — local toolchain

```bash
cp .env.example .env              # fill in AWS creds + INFRACOST_API_KEY
docker-compose up -d --build      # builds the image, starts iac-workspace
docker-compose exec iac-workspace bash   # shell into the container
docker-compose down               # stop the container when done
```

### 2. Terraform — bootstrap the backend (one-time, before first `init`)

```bash
cd bootstrap
terraform init
terraform apply -var="state_bucket_name=my-company-tf-state"
cd ..
# copy the output bucket/table names into backend.hcl
```

### 3. Terraform — everyday workspace commands (run inside the container)

```bash
terraform init -backend-config=backend.hcl     # connect to remote state

terraform workspace new dev                    # one-time, create workspaces
terraform workspace new staging
terraform workspace new production
terraform workspace list                       # confirm all 4 exist

terraform workspace select dev                  # switch to an environment
terraform plan  -var-file=environments/dev.tfvars
terraform apply -var-file=environments/dev.tfvars

terraform workspace select production
terraform plan  -var-file=environments/production.tfvars
```

### 4. Terraform — fmt & validate (what CI runs, runnable locally too)

```bash
terraform fmt -check -recursive
terraform validate
```

### 5. Infracost — cost estimate from a plan

```bash
terraform plan -var-file=environments/staging.tfvars -out=tfplan
terraform show -json tfplan > tfplan.json
infracost breakdown --path tfplan.json
```

### 6. GitHub Actions — how the pipelines actually trigger

| Workflow | Trigger | How to run it |
|---|---|---|
| `pr-validation.yml` | Opening/updating a PR against `main` | `git checkout -b my-change`, commit, `git push`, open a PR on GitHub |
| `deploy.yml` (staging) | Merge/push to `main` | Merge the PR — staging applies automatically |
| `deploy.yml` (production) | After the staging job succeeds | Approve the pending run in **Actions → workflow run → Review deployments** |

You can also watch a run from the CLI with the GitHub CLI:
```bash
gh pr create --base main --title "my change" --body "..."
gh run watch
```

### 7. Force-unlock a stuck state lock

```bash
terraform force-unlock <LOCK_ID>
```
Only do this when you're certain no other run is actively applying changes.

## Prerequisites

- Docker and Docker Compose
- An AWS account with permission to create IAM roles, S3, DynamoDB, VPC, EC2, ELB
- An [Infracost](https://www.infracost.io/) API key (free tier)

## Repository Setup (one-time, before first deploy)

The `deploy-production` job in `deploy.yml` targets the GitHub **`production`
Environment**, but GitHub Environments do not enforce manual approval unless
you configure a protection rule — the workflow file alone cannot turn this
on. Before the first deploy:

1. Go to **Settings → Environments** in this repository.
2. Create (or edit) an environment named `production`.
3. Under **Deployment protection rules**, enable **Required reviewers** and
   add at least one reviewer/team.
4. (Recommended) Also create a `staging` environment — even without required
   reviewers, this lets you scope `AWS_DEPLOY_ROLE_ARN` and other secrets
   per environment instead of repository-wide.

Without step 3, `deploy-production` will apply automatically the same way
`deploy-staging` does — the `environment:` key alone only labels the job,
it doesn't gate it.

### Triggering a deploy

| Trigger | Behavior |
|---|---|
| Push/merge to `main` | Runs `deploy-staging` automatically, then `deploy-production` (held for review) |
| Manual run via **Actions → Deploy → Run workflow**, `environment: staging` | Applies only to staging |
| Manual run via **Actions → Deploy → Run workflow**, `environment: production` | Applies only to production (still held for the same required-reviewer gate) |

## Secrets Required in the Repository

| Secret | Purpose |
|---|---|
| `AWS_PLAN_ROLE_ARN` | Read-only role assumed via OIDC for PR plans |
| `AWS_DEPLOY_ROLE_ARN` | Deploy role assumed via OIDC for staging/production applies |
| `INFRACOST_API_KEY` | Infracost cost estimation |

Credentials are never stored as long-lived access keys in this repo; the
workflows assume an IAM role via GitHub's OIDC provider
(`aws-actions/configure-aws-credentials`). If your organization prefers static
keys, replace the `role-to-assume` step with `aws-access-key-id` /
`aws-secret-access-key` secrets, but OIDC is strongly preferred.

## Notes on Production Hardening

- `production.tfvars` disables direct SSH ingress (`allowed_ssh_cidrs = []`);
  use AWS Systems Manager Session Manager for administrative access instead.
- The ALB listens on HTTP (port 80) in this reference implementation; attach
  an ACM certificate and add an HTTPS listener before using this for real
  production traffic.
- Root and app S3 buckets block all public access and use SSE-KMS encryption
  by default.# verified Sat, Jul 18, 2026  9:10:50 AM
