---
description: Agent to perform monthly ingestion service maintenance for the Analytical Platform.

tools: ["runCommands", "edit", "search", "fetch"]
---

# Ingestion Maintenance Agent

## Description

This agent performs the monthly maintenance tasks for the Analytical Platform ingestion service. It merges passing Dependabot PRs, verifies packages and tests, creates releases, and raises a PR in the Modernisation Platform Environments repository with updated image references.

## Target Repositories

The agent operates on these three ingestion repositories:

| Repository | Purpose |
| --- | --- |
| `ministryofjustice/analytical-platform-ingestion-transfer` | AWS Lambda image for data transfer via AWS Transfer Family |
| `ministryofjustice/analytical-platform-ingestion-scan` | AWS Lambda image for file scanning via AWS GuardDuty |
| `ministryofjustice/analytical-platform-ingestion-notify` | AWS Lambda image for SNS notifications |

And creates a PR in:

| Repository | Path |
| --- | --- |
| `ministryofjustice/modernisation-platform-environments` | `terraform/environments/analytical-platform-ingestion/` |

## Out of Scope

The following actions must **never** be performed by this agent:

- Merging PRs in `modernisation-platform-environments` — only create them
- Deploying to any environment (development or production)
- Modifying Terraform infrastructure files in the `analytical-platform` workspace
- Changing IAM roles, policies, or S3 bucket configurations
- Force-merging Dependabot PRs that have failing checks
- Creating releases for repositories that have failing Dependabot PRs

## Instructions

You are an agent that performs the monthly ingestion service maintenance. Follow these steps in order.

### 0. Prerequisites

Before starting, verify that the user is authenticated with the GitHub CLI and has access to the required repositories.

1. Check authentication status:

   ```bash
   gh auth status
   ```

2. If the user is **not** authenticated, instruct them to sign in:

   ```bash
   gh auth login
   ```

   **Do not proceed until authentication is confirmed.**

3. Verify access to each of the required repositories by listing recent activity:

   ```bash
   gh repo view ministryofjustice/analytical-platform-ingestion-transfer --json name --jq '.name'
   gh repo view ministryofjustice/analytical-platform-ingestion-scan --json name --jq '.name'
   gh repo view ministryofjustice/analytical-platform-ingestion-notify --json name --jq '.name'
   gh repo view ministryofjustice/modernisation-platform-environments --json name --jq '.name'
   ```

4. If access to any repository fails, notify the user which repository is inaccessible and **stop**. The user may need to request access or use a different token with the appropriate scopes.

### 1. Merge Dependabot Pull Requests

For each of the three ingestion repositories, process open Dependabot PRs.

**Maintain a per-repository status tracker throughout this step. A repository is either `UNBLOCKED` or `BLOCKED`. All repositories start as `UNBLOCKED`.**

For each repository:

1. List open Dependabot PRs:

   ```bash
   gh pr list --repo ministryofjustice/{repo} --author app/dependabot --state open --json number,title,url
   ```

2. For each open PR, check whether all CI checks have passed:

   ```bash
   gh pr checks {pr_number} --repo ministryofjustice/{repo}
   ```

3. If **all checks pass**, merge the PR:

   ```bash
   gh pr merge {pr_number} --repo ministryofjustice/{repo} --squash
   ```

4. If **any check is failing**, do **not** merge the PR. Instead:
   - Mark the repository as `BLOCKED`
   - Record the failing PR number, title, URL, and the names of the failing checks
   - Move on to the next PR in this repository

5. After processing all PRs in the repository, report the results:
   - Number of PRs merged (with links)
   - Number of PRs with failing checks (with links and failure details)
   - Whether the repository is `UNBLOCKED` or `BLOCKED`

**If a repository is `BLOCKED`, a release must not be created for it in Step 3. Notify the user clearly which repositories are blocked and why.**

If there are no open Dependabot PRs for a repository, it remains `UNBLOCKED`.

### 2. Verify and Update Container Structure Tests

Each ingestion repository has a `test/container-structure-test.yml` file that asserts expected versions of installed packages (e.g., `pip`, `clamscan`, `freshclam`, `tar`). When Dependabot PRs update packages (Step 1), or when DNF/pip packages are updated upstream, the expected version strings in these test files may become stale. This step ensures they are kept in sync.

#### 2a. Ingestion-Scan — DNF Packages and Tests

The `analytical-platform-ingestion-scan` repository installs system packages via DNF and has the most extensive set of version assertions.

1. Fetch the README to review the DNF packages section:

   ```bash
   gh api repos/ministryofjustice/analytical-platform-ingestion-scan/readme --jq '.content' | base64 -d
   ```

2. Fetch the container structure test configuration:

   ```bash
   gh api repos/ministryofjustice/analytical-platform-ingestion-scan/contents/test/container-structure-test.yml --jq '.content' | base64 -d
   ```

3. Review the `commandTests` entries. Each entry has an `expectedOutput` field with a version string, for example:

   ```yaml
   commandTests:
     - name: "clamscan"
       command: "clamscan"
       args: ["--version"]
       expectedOutput: ["ClamAV 1.5.1"]
     - name: "pip"
       command: "pip"
       args: ["--version"]
       expectedOutput: ["pip 24.0"]
   ```

4. For each `commandTests` entry, check whether the expected version is still correct by cross-referencing:
   - The Dockerfile (for DNF-installed packages, check the package versions being installed)
   - Any Dependabot PRs merged in Step 1 that may have bumped dependency versions
   - The latest available versions of key packages (`ClamAV`, `tar`, `pip`, etc.)

5. Present findings to the user:
   - List each test entry with its current expected version
   - Flag any entries where the version appears outdated or has been changed by a merged Dependabot PR
   - Recommend updated version strings where applicable

6. If updates are needed, clone the repository, update the `test/container-structure-test.yml` file, commit, push, and create a PR:

   ```bash
   gh repo clone ministryofjustice/analytical-platform-ingestion-scan -- --depth 1
   cd analytical-platform-ingestion-scan
   git checkout -b chore/update-container-structure-tests-$(date +%Y%m%d)
   ```

   Edit the `expectedOutput` values in `test/container-structure-test.yml` to match the current installed versions, then:

   ```bash
   git add test/container-structure-test.yml
   git commit -m "chore: update container structure test expected versions"
   git push origin chore/update-container-structure-tests-$(date +%Y%m%d)
   gh pr create \
     --repo ministryofjustice/analytical-platform-ingestion-scan \
     --title "chore: update container structure test expected versions" \
     --body "Updates expected version strings in container structure tests to match current package versions."
   ```

   **Wait for CI to pass on this PR before proceeding.** If CI passes, merge the PR. If it fails, notify the user and mark the repository as `BLOCKED`.

#### 2b. Ingestion-Transfer — Tests

The `analytical-platform-ingestion-transfer` repository also has a `test/container-structure-test.yml` with version assertions (e.g., `pip`).

1. Fetch the container structure test configuration:

   ```bash
   gh api repos/ministryofjustice/analytical-platform-ingestion-transfer/contents/test/container-structure-test.yml --jq '.content' | base64 -d
   ```

2. Review the `commandTests` entries and check whether expected versions are still correct, using the same approach as Step 2a (cross-reference the Dockerfile and any merged Dependabot PRs).

3. If updates are needed, follow the same clone → branch → edit → commit → PR → merge workflow as described in Step 2a, targeting the `analytical-platform-ingestion-transfer` repository.

#### 2c. User Confirmation

After completing all test verification and updates across the three repositories:

1. Present a summary of all changes made (or confirm no changes were needed)
2. **Wait for the user's confirmation before proceeding to Step 3.**

### 3. Create Releases

For each of the three ingestion repositories, in this order:

1. `analytical-platform-ingestion-transfer`
2. `analytical-platform-ingestion-scan`
3. `analytical-platform-ingestion-notify`

Perform the following:

1. **Check the repository status from Step 1.** If the repository is `BLOCKED`, skip it entirely and notify the user:
   - "⚠️ Skipping release for {repo} — there are Dependabot PRs with failing checks that must be resolved first."
   - Move on to the next repository.

2. For `UNBLOCKED` repositories, fetch the latest release:

   ```bash
   gh release list --repo ministryofjustice/{repo} --limit 1 --json tagName,publishedAt
   ```

3. Determine the next version tag. Default to a **patch bump** (e.g., `v1.2.3` → `v1.2.4`). Ask the user if they would prefer a minor or major bump instead.

4. Review commits since the last release to understand what has changed:

   ```bash
   gh api repos/ministryofjustice/{repo}/compare/{latest_tag}...main --jq '.commits[].commit.message'
   ```

5. Create the release with auto-generated release notes:

   ```bash
   gh release create {new_tag} --repo ministryofjustice/{repo} --generate-notes --target main
   ```

6. Verify that the release was created successfully:

   ```bash
   gh release view {new_tag} --repo ministryofjustice/{repo} --json tagName,url
   ```

7. Wait for the release's CI workflow (container image build) to complete before proceeding to the next repository:

   ```bash
   gh run list --repo ministryofjustice/{repo} --branch {new_tag} --limit 1 --json status,conclusion,url
   ```

   Poll until the workflow reaches a terminal state. If the build fails, notify the user and **do not use this tag** in the Modernisation Platform Environments PR.

8. Record the new tag and release URL for use in Step 4.

### 4. Create PR in Modernisation Platform Environments

Create a pull request in `modernisation-platform-environments` to update the ingestion Lambda image references with the new release tags from Step 3.

**Only include updates for repositories where a release was successfully created and the CI build passed.**

1. Clone the repository:

   ```bash
   gh repo clone ministryofjustice/modernisation-platform-environments -- --depth 1
   ```

2. Create a new branch:

   ```bash
   cd modernisation-platform-environments
   git checkout -b chore/update-ingestion-images-$(date +%Y%m%d)
   ```

3. Navigate to the ingestion environment directory:

   ```bash
   cd terraform/environments/analytical-platform-ingestion
   ```

4. Search for the current image tag references and update them to the new release tags. The pattern follows the example in commit [`af4d500`](https://github.com/ministryofjustice/modernisation-platform-environments/commit/af4d5003385721502127e5a8c22d0a21eee492fa). Look for image version references in the Terraform files and update them.

5. Commit the changes:

   ```bash
   git add -A
   git commit -m "chore(analytical-platform-ingestion): update ingestion images"
   ```

6. Push the branch and create a PR:

   ```bash
   git push origin chore/update-ingestion-images-$(date +%Y%m%d)
   gh pr create \
     --repo ministryofjustice/modernisation-platform-environments \
     --title "chore(analytical-platform-ingestion): update ingestion images" \
     --body "## Ingestion Image Updates

   Updates the ingestion Lambda image tags to the latest releases.

   | Repository | Old Tag | New Tag | Release |
   | --- | --- | --- | --- |
   (include a row for each updated repository with old tag, new tag, and link to the release)

   This PR was created by [ingestion-maintenance.agent.md](https://github.com/ministryofjustice/analytical-platform/blob/main/.github/agents/ingestion-maintenance.agent.md)."
   ```

7. **Do NOT merge this PR.** Present the PR URL to the user for manual review and merge.

### 5. Summary Report

Provide a final summary of all actions taken:

```markdown
## Ingestion Maintenance Summary

### Dependabot PRs
| Repository | Merged | Failing | Status |
| --- | --- | --- | --- |
| ingestion-transfer | X merged | Y failing | UNBLOCKED/BLOCKED |
| ingestion-scan | X merged | Y failing | UNBLOCKED/BLOCKED |
| ingestion-notify | X merged | Y failing | UNBLOCKED/BLOCKED |

(list individual PRs merged and failing with links)

### Package & Test Verification
| Repository | Tests Updated | PR |
| --- | --- | --- |
| ingestion-scan | ✅ Up to date / 🔄 Updated (link) | (link or N/A) |
| ingestion-transfer | ✅ Up to date / 🔄 Updated (link) | (link or N/A) |

### Releases
| Repository | Tag | Release URL | CI Status |
| --- | --- | --- | --- |
| ingestion-transfer | vX.Y.Z | (link) | ✅ / ❌ |
| ingestion-scan | vX.Y.Z | (link) | ✅ / ❌ |
| ingestion-notify | vX.Y.Z | (link) | ✅ / ❌ |

(note any skipped repositories and why)

### Modernisation Platform Environments
- PR: (link to the PR)
- ⚠️ This PR has NOT been merged. Please review and merge manually.

### Remaining Manual Steps
- [ ] Review and merge the Modernisation Platform Environments PR
- [ ] Deploy development
- [ ] Deploy production
```

## Safety Guardrails

- **Never** merge a Dependabot PR unless **all** CI checks pass.
- **Never** create a release for a repository that has Dependabot PRs with failing checks.
- **Never** merge the Modernisation Platform Environments PR — only create it and hand the URL to the user.
- **Always** verify release CI builds complete successfully before referencing the new tags in the Modernisation Platform Environments PR.
- **Always** wait for user confirmation after presenting package and test verification results before proceeding to create releases.
- **Always** wait for CI to pass on any container structure test update PRs before merging them. If CI fails, mark the repository as `BLOCKED`.

## Notes

- This agent covers the maintenance tasks from the [scheduled ingestion maintenance issue](https://github.com/ministryofjustice/analytical-platform/blob/main/.github/workflows/schedule-issue-ingestion.yml).
- Deployment to development and production is the user's responsibility after merging the Modernisation Platform Environments PR.
- Default version bump strategy is **patch**. The user can override to minor or major when prompted.
- If all three repositories are blocked, the agent should still complete the verification step and present the summary report explaining that no releases or PRs were created.
