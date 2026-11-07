export const meta = {
  name: 'revue',
  description: 'ORKYN à fond : revue des changements sous 3 angles (bugs, conception, sécurité), chaque problème vérifié par un contradicteur',
  whenToUse: 'Revue approfondie d’un diff ou d’une branche, seulement sur demande explicite (coûteux).',
  phases: [
    { title: 'Revue', detail: 'qa, reviewer et security en parallèle, lecture seule' },
    { title: 'Vérification', detail: 'un contradicteur par problème' },
  ],
}

const ISSUES = {
  type: 'object',
  required: ['issues'],
  properties: {
    issues: {
      type: 'array',
      items: {
        type: 'object',
        required: ['severity', 'title', 'file', 'line', 'evidence', 'suggestion'],
        properties: {
          severity: { type: 'string', enum: ['bloquant', 'majeur', 'mineur'] },
          title: { type: 'string' },
          file: { type: 'string' },
          line: { type: 'integer' },
          evidence: { type: 'string' },
          suggestion: { type: 'string' },
        },
      },
    },
  },
}

const VERDICT = {
  type: 'object',
  required: ['isReal', 'reason'],
  properties: { isReal: { type: 'boolean' }, reason: { type: 'string' } },
}

const target = typeof args === 'string' && args.trim()
  ? args.trim()
  : 'les changements de la branche courante par rapport à la branche principale (git diff de la base de fusion), plus les fichiers modifiés non commités'

const COMMON = `Mission ORKYN : revue, lecture seule, aucune modification.
Cible : ${target}.
Lis le diff d'abord, puis seulement le code nécessaire. Rends uniquement des problèmes étayés (fichier:ligne, scénario concret). Rien vaut mieux qu'un faux positif.`

const LENSES = [
  { key: 'bugs', agentType: 'orkyn:orkyn-qa', focus: 'Ce qui casse : bugs, cas limites, régressions, gestion d’erreurs.' },
  { key: 'conception', agentType: 'orkyn:orkyn-reviewer', focus: 'Conception : suringénierie, duplication, lisibilité, maintenabilité.' },
  { key: 'securite', agentType: 'orkyn:orkyn-security', focus: 'Sécurité du diff : entrées, accès, secrets, dépendances ajoutées.' },
]

const MAX_VERIF = 10

const results = await pipeline(
  LENSES,
  l => agent(`${COMMON}\nAngle : ${l.focus}`, { label: `revue:${l.key}`, phase: 'Revue', schema: ISSUES, agentType: l.agentType }),
  (found, l) => {
    const list = (found?.issues ?? []).filter(i => i.severity !== 'mineur')
    const minor = (found?.issues ?? []).filter(i => i.severity === 'mineur').map(i => ({ ...i, lens: l.key, verdict: null }))
    if (list.length > MAX_VERIF) log(`${l.key} : ${list.length - MAX_VERIF} problèmes au-delà de ${MAX_VERIF} non vérifiés.`)
    return parallel(list.slice(0, MAX_VERIF).map(i => () =>
      agent(`Mission ORKYN : contradicteur, lecture seule. Essaie de RÉFUTER ce problème signalé en revue en lisant le code. S'il est faux, mal localisé ou sans impact réel : isReal=false.
Problème : [${i.severity}] ${i.title} dans ${i.file}:${i.line}. Preuve avancée : ${i.evidence}`, {
        label: `verif:${i.file}:${i.line}`, phase: 'Vérification', schema: VERDICT, agentType: 'orkyn:orkyn-qa', effort: 'medium',
      }).then(v => ({ ...i, lens: l.key, verdict: v }))
    )).then(checked => [...checked, ...minor])
  },
)

const all = results.flat().filter(Boolean)
const confirmed = all.filter(i => i.verdict?.isReal)
const rejected = all.filter(i => i.verdict && !i.verdict.isReal).map(i => ({ title: i.title, file: i.file, reason: i.verdict.reason }))
const minor = all.filter(i => !i.verdict)
return { confirmed, minor, rejected }
