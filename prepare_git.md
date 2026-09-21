# Git Interview Preparation

---

## What is the difference between `git merge` and `git rebase`?

Both commands are used to integrate changes from one branch into another, but they differ in **how they modify the commit history**:

| Aspect | `git merge` | `git rebase` |
|--------|-------------|--------------|
| **History** | Creates a new **merge commit** that preserves the complete branch history | **Replays** commits from one branch onto another, producing a **linear history** |
| **Commit Integrity** | Preserves original commit hashes and timestamps | Rewrites commit hashes (creates new commits) |
| **Visual** | Shows branch divergence and convergence | Appears as if work was done sequentially, without branches |
| **Safety** | Safe for shared/public branches | **Avoid** on shared branches — rewriting public history causes complications for collaborators |
| **Conflicts** | Resolved once at merge time | May need to be resolved for each commit during replay |

**When to use:**
- Use **`git merge`** for integrating feature branches into `main` or `develop` — it preserves the full context of the work.
- Use **`git rebase`** for cleaning up local commits before sharing a branch (e.g., squashing multiple WIP commits into a single clean commit).

---

## How do you resolve merge conflicts?

1. **Identify the conflicting files:**
   ```bash
   git status
   # Files with both "added by us" and "added by them" are in conflict
   ```

2. **Open the conflicting files** and look for conflict markers:
   ```
   <<<<<<< HEAD (your version)
   conflicting code
   =======
   conflicting code (incoming version)
   >>>>>>> feature-branch
   ```

3. **Edit the file** to resolve the conflict — keep the correct code, remove the markers, and ensure the result is functionally correct.

4. **Stage the resolved files:**
   ```bash
   git add <resolved_file>
   ```

5. **Complete the merge/rebase:**
   ```bash
   git commit   # for merge
   git rebase --continue   # for rebase
   ```

6. **Verify** by running tests or building the project to ensure the resolution did not introduce errors.

---

## How do you protect sensitive information from being pushed to GitHub?

- **`.gitignore`:** Add patterns for sensitive files (`.env`, `*.key`, `*.pem`, `secrets.yaml`, `credentials.json`) to `.gitignore` to prevent them from being tracked.
- **Pre-commit hooks:** Use tools like **GitLeaks**, **TruffleHog**, or **pre-commit** framework to scan for secrets before they are committed:
  ```bash
  pip install pre-commit
  pre-commit install  # installs the hook
  ```
- **`.gitattributes` with `filter`:** Configure Git to strip secrets at commit time using Git's clean/smudge filters.
- **If secrets are already committed:**
  - **Never** simply delete the file and commit — the secret remains in Git history.
  - Use **`git filter-repo`** (recommended) or **BFG Repo-Cleaner** to remove the secret from all historical commits.
  - **Rotate the exposed secret immediately** — assume it has been compromised.
  - Force-push the cleaned history (only if no one has pulled the contaminated branch).

---

## How do you implement branching strategies in a project?

I have implemented both **GitFlow** and **Trunk-Based Development**, depending on the team's maturity and release cadence:

**GitFlow (for teams with structured release cycles):**
- **`main`** — Production-ready code, protected, only updated via release merges
- **`develop`** — Integration branch for feature development
- **`feature/*`** — Branches created from `develop` for new features
- **`release/*`** — Branches for release preparation and final testing
- **`hotfix/*`** — Branches from `main` for urgent production fixes

**Trunk-Based Development (for teams with CI/CD and frequent deployments):**
- Developers work on **short-lived feature branches** (lasting hours, not days) merged into `main` frequently.
- **Feature flags** are used to enable/disable incomplete features in production.
- **Main branch is always deployable**, backed by automated tests and CI pipelines.
- Branch protection rules require **pull request reviews** and **CI checks to pass** before merge.

**Branch Protection Rules (enforced on `main`):**
- Require at least 1–2 pull request reviewers
- Require status checks (CI pipeline) to pass before merging
- Disallow force pushes and direct commits to `main`
- Require linear history (squash merge or rebase merge)

---

## Difference between `git revert` and `git reset`?

Both commands undo changes, but they differ in **how they handle Git history**:

| Aspect | `git revert` | `git reset` |
|--------|-------------|-------------|
| **What it does** | Creates a **new commit** that undoes the changes from a specified commit | **Moves the branch pointer** to a different commit, discarding commits in between |
| **History** | **Preserves** commit history — safe for shared branches | **Rewrites** history — dangerous for shared/public branches |
| **Use Case** | Undo a committed change that has already been pushed | Undo local, unpushed changes |

**Example:** Suppose you have commits `A → B → C → D` (D is HEAD).

- **`git revert D`** creates a new commit `E` that undoes D's changes: `A → B → C → D → E` (all commits are preserved)
- **`git reset --hard C`** moves HEAD back to C, losing D: `A → B → C` (D is gone)

**`git reset` has three modes:**
1. **`--soft`** — Moves the branch pointer but keeps all changes staged (in the index). Use when you want to recommit changes.
2. **`--mixed`** (default) — Moves the branch pointer and unstages changes, but keeps them in the working directory. Use when you want to redo commits with different grouping.
3. **`--hard`** — Moves the branch pointer and **discards all changes** in the staging area and working directory. Use with caution — this permanently destroys uncommitted work.
