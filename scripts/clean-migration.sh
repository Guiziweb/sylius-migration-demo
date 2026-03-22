#!/usr/bin/env bash
# clean-migration.sh — Remet à zéro l'état de la migration
# Usage: bash scripts/clean-migration.sh

set -euo pipefail

GITHUB_REPO="Guiziweb/sylius-migration-demo"
GITHUB_OWNER="Guiziweb"
INITIAL_COMMIT="97d8f7e"

echo "=== 0. Retour sur main ==="
git checkout main

echo "=== 0b. Arrêt des containers Docker ==="
docker compose down 2>/dev/null && echo "  containers arrêtés" || true

echo "=== 1. Fermeture des PRs ouvertes ==="
gh pr list --repo $GITHUB_REPO --state open --json number --jq '.[].number' | while read pr; do
  gh pr close $pr --repo $GITHUB_REPO && echo "  closed PR #$pr"
done || true

echo "=== 2. Suppression de toutes les issues (ouvertes + fermées) ==="
gh issue list --repo $GITHUB_REPO --state all --limit 100 --json number,id --jq '.[] | .id' | while read node_id; do
  gh api graphql -f query='mutation($id: ID!) { deleteIssue(input: { issueId: $id }) { repository { id } } }' \
    -f id="$node_id" > /dev/null && echo "  deleted issue $node_id"
done || true

echo "=== 2b. Suppression des labels de domaine ==="
for label in composer config src templates frontend database; do
  gh api repos/$GITHUB_REPO/labels/$label --method DELETE 2>/dev/null && echo "  deleted label $label" || true
done

echo "=== 3. Suppression des branches locales migration/* ==="
git branch | grep "migration/" | while read branch; do
  git branch -D "$branch" && echo "  deleted local branch $branch"
done || true

echo "=== 4. Suppression des branches distantes migration/* ==="
git branch -r | grep "origin/migration/" | sed 's|origin/||' | while read branch; do
  git push origin --delete "$branch" && echo "  deleted remote branch $branch"
done || true

echo "=== 5. Suppression du projet GitHub v2 ==="
PROJECT_NUM=$(gh project list --owner $GITHUB_OWNER --format json | jq -r '.projects[] | select(.title == "Migration Sylius 1.14 → 2.0") | .number' 2>/dev/null || true)
if [ -n "$PROJECT_NUM" ]; then
  PROJECT_ID=$(gh project view $PROJECT_NUM --owner $GITHUB_OWNER --format json | jq -r '.id')
  gh api graphql -f query='mutation($id: ID!) { deleteProjectV2(input: { projectId: $id }) { clientMutationId } }' \
    -f id="$PROJECT_ID" > /dev/null && echo "  deleted project $PROJECT_NUM"
fi

echo "=== 6. Reset au commit initial ==="
git reset --hard $INITIAL_COMMIT
git push origin main --force
echo "  reset to $INITIAL_COMMIT"

echo "=== 7. Nettoyage des fichiers non trackés (hors .claude et scripts) ==="
git clean -fd --exclude='.claude/' --exclude='scripts/' --exclude='sylius-upgrade-audit.md' --exclude='.mcp.json' --exclude='.awf/'

echo ""
echo "✓ Nettoyage terminé — prêt pour une nouvelle itération"