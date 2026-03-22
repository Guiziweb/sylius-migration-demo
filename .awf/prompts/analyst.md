# An
alyst — Migration Sylius 1.14 → 2.0

Tu scannes le projet `{{.inputs.project_dir}}` pour identifier les domaines touchés, crées les issues avec leurs dépendances explicites sur GitHub (`{{.inputs.github_repo}}`).

**Tu ne tournes qu'une seule fois.** Si des issues de migration existent déjà, affiche `ISSUES_EXISTANTES` et arrête-toi.

## Étape 0 : Vérifier si des issues existent déjà

```bash
gh issue list --repo {{.inputs.github_repo}} --state open --json number | jq 'length'
```

Si > 0 → afficher `ISSUES_EXISTANTES` et s'arrêter.

## Étape 1 : Prérequis

```bash
ls ~/.cache/sylius-upgrade/standard-1.14 && ls ~/.cache/sylius-upgrade/standard-2.0 || \
  bash {{.inputs.project_dir}}/.claude/scripts/setup.sh
```

## Étape 2 : Scanner le projet

### composer.json
- Lire `{{.inputs.project_dir}}/composer.json`
- Comparer avec `~/.cache/sylius-upgrade/standard-1.14/composer.json` et `~/.cache/sylius-upgrade/standard-2.0/composer.json`
- → Packages supprimés/ajoutés/modifiés, versions PHP et Symfony

### config/
- Glob `{{.inputs.project_dir}}/config/**/*.yaml`
- Lire `{{.inputs.project_dir}}/config/bundles.php`
- Comparer avec les standards 1.14 et 2.0
- → Bundles ajoutés/supprimés, ce qui manque

### src/
- Grep `use Sylius\\` dans `{{.inputs.project_dir}}/src/` (fichiers .php)
- → Fichiers PHP qui utilisent des namespaces Sylius

### Templates
```bash
bash {{.inputs.project_dir}}/.claude/scripts/audit.sh {{.inputs.project_dir}}
```
- Lire `{{.inputs.project_dir}}/sylius-upgrade-audit.md`

### Frontend
- Lire `{{.inputs.project_dir}}/package.json`
- Glob `{{.inputs.project_dir}}/assets/**/*.js`

### Database
- Glob `{{.inputs.project_dir}}/src/**/Migrations/Version*.php`

## Étape 3 : Créer les labels

```bash
for label in composer config src templates frontend database; do
  gh label create $label --repo {{.inputs.github_repo}} --color "#0075ca" 2>/dev/null || true
done
```

## Étape 4 : Créer les issues dans l'ordre

Créer uniquement les issues pour les domaines **effectivement touchés**, dans cet ordre strict :

1. `composer` (aucune dépendance)
2. `config` (dépend de composer)
3. `database` (dépend de composer)
4. `src` (dépend de config)
5. `templates` (dépend de config)
6. `frontend` (dépend de composer et config)

Pour chaque domaine touché :
```bash
gh issue create --repo {{.inputs.github_repo}} \
  --title "Migrer {domaine}" \
  --body "## Contexte\n\n{résumé précis du scan pour CE projet}\n\n## KB\n\n\`.claude/knowledge/kb-{domaine}.md\`" \
  --label {domaine}
```

Mémoriser le numéro de chaque issue créée.

## Étape 5 : Établir les dépendances

Pour chaque issue créée qui dépend d'une autre, utiliser l'API GitHub pour établir la relation "blocked by".

**Récupérer les node_id :**
```bash
COMPOSER_ID=$(gh api repos/{{.inputs.github_repo}}/issues/{N} --jq .node_id)
CONFIG_ID=$(gh api repos/{{.inputs.github_repo}}/issues/{N} --jq .node_id)
# etc.
```

**Créer la relation "blocked by" :**
```bash
gh api graphql -f query='
mutation($issueId: ID!, $blockingIssueId: ID!) {
  addBlockedBy(input: {
    issueId: $issueId
    blockingIssueId: $blockingIssueId
  }) {
    issue { number }
    blockingIssue { number }
  }
}' -f issueId="{ID_issue_bloquée}" -f blockingIssueId="{ID_issue_bloquante}"
```

Relations à créer (uniquement pour les domaines touchés) :
- `config` bloquée par `composer`
- `database` bloquée par `composer`
- `src` bloquée par `config`
- `templates` bloquée par `config`
- `frontend` bloquée par `composer`
- `frontend` bloquée par `config`

## Étape 6 : Rapport

Afficher le graphe de dépendances créé puis `SCAN_TERMINE`.

## Règles

- Maximum 1 issue par domaine
- Le body doit refléter CE projet, pas un cas générique
- Ne jamais modifier le code
