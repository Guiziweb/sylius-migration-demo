#!/bin/bash
# Trouve la première issue de migration disponible :
# - non assignée
# - sans sous-issue ouverte (Mikado)
# - dont toutes les issues bloquantes sont fermées (dépendances)
# Output: JSON {number, label} ou "AUCUNE_ISSUE"

REPO=$1

ISSUES=$(gh issue list --repo "$REPO" --state open \
  --json number,labels,assignees \
  --jq '[.[] | select(
    (.assignees | length == 0) and
    (.labels | map(.name) | any(. == "composer" or . == "config" or . == "src" or . == "templates" or . == "frontend" or . == "database"))
  )] | sort_by(.number)')

if [ -z "$ISSUES" ] || [ "$ISSUES" = "[]" ]; then
  echo "AUCUNE_ISSUE"
  exit 0
fi

for row in $(echo "$ISSUES" | jq -r '.[] | @base64'); do
  ISSUE=$(echo "$row" | base64 --decode)
  NUM=$(echo "$ISSUE" | jq -r '.number')
  LABEL=$(echo "$ISSUE" | jq -r '.labels | map(.name) | map(select(. == "composer" or . == "config" or . == "src" or . == "templates" or . == "frontend" or . == "database")) | first')

  # Vérifier sous-issues ouvertes (Mikado)
  SUB=$(gh issue list --repo "$REPO" --state open \
    --json number,body \
    --jq "[.[] | select(.body | contains(\"Prérequis de #$NUM\"))] | length")
  if [ "$SUB" != "0" ]; then
    continue
  fi

  # Vérifier que les issues bloquantes sont toutes fermées
  NODE_ID=$(gh api "repos/$REPO/issues/$NUM" --jq '.node_id')
  BLOCKERS=$(gh api graphql -f query='
    query($id: ID!) {
      node(id: $id) {
        ... on Issue {
          blockedBy(first: 20) {
            nodes { number state }
          }
        }
      }
    }' -f id="$NODE_ID" \
    --jq '[.data.node.blockedBy.nodes[] | select(.state == "OPEN")] | length' 2>/dev/null || echo "0")

  if [ "$BLOCKERS" != "0" ]; then
    continue
  fi

  echo "{\"number\": $NUM, \"label\": \"$LABEL\"}"
  exit 0
done

echo "AUCUNE_ISSUE"