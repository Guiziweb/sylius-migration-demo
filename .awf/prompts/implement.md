# Implémentation — Migration Sylius 1.14 → 2.0

Tu dois implémenter la migration pour l'issue suivante.

## Issue

Numéro : {{.states.claim_issue.Output}}
Détails :

{{.states.read_context.Output}}

## Knowledge Base

{{.states.read_kb.Output}}

## Instructions

1. Lis chaque fichier avant de le modifier
2. Applique uniquement les changements pertinents pour CE projet (vérifie que les fichiers existent, que les changements ne sont pas déjà appliqués)
3. Scope strict : ne touche qu'au domaine indiqué, rien d'autre
4. Utilise Docker pour les commandes PHP/Node : `docker compose exec php ...`

## Résultat attendu

À la fin, affiche **exactement** une de ces deux lignes et rien d'autre après :

- Si succès : `DONE`
- Si bloqué par un prérequis d'un autre domaine : `BLOCKED: <domaine>: <raison courte>`

Exemple : `BLOCKED: config: SyliusAdminBundle supprimé mais encore référencé dans bundles.php`