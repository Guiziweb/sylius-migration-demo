#!/bin/bash
# Crée une sous-issue et désassigne l'issue courante
# Usage: create_subissue.sh <repo> <current_issue> <blocked_output>
# blocked_output format: "BLOCKED: <domain>: <reason>"

REPO=$1
CURRENT_ISSUE=$2
BLOCKED_OUTPUT=$3

# Parser le domaine et la raison depuis "BLOCKED: domain: reason"
DOMAIN=$(echo "$BLOCKED_OUTPUT" | sed 's/BLOCKED: \([^:]*\):.*/\1/' | xargs)
REASON=$(echo "$BLOCKED_OUTPUT" | sed 's/BLOCKED: [^:]*: //' | xargs)

# Créer la sous-issue
gh issue create --repo "$REPO" \
  --title "Migrer prérequis: $REASON" \
  --body "$(printf "Prérequis de #%s\n\n## Contexte\n%s\n\n## KB\n\`.claude/knowledge/kb-%s.md\`" "$CURRENT_ISSUE" "$REASON" "$DOMAIN")" \
  --label "$DOMAIN"

# Désassigner l'issue courante
gh issue edit "$CURRENT_ISSUE" --repo "$REPO" --remove-assignee @me
gh issue comment "$CURRENT_ISSUE" --repo "$REPO" \
  --body "[worker] Bloqué — sous-issue créée. Reprise après résolution du prérequis."