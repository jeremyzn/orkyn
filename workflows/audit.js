export const meta = {
  name: 'audit',
  description: 'ORKYN à fond : audit de sécurité en 3 angles parallèles, chaque faille vérifiée par un contradicteur',
  whenToUse: "Audit de sécurité complet d'un projet, seulement sur demande explicite (coûteux : 3 auditeurs puis 1 vérificateur par faille).",
  phases: [
    { title: 'Audit', detail: '3 auditeurs orkyn-security en lecture seule' },
    { title: 'Vérification', detail: 'un contradicteur orkyn-qa par faille P0 à P2' },
  ],
}

const FINDINGS = {
  type: 'object',
  required: ['findings'],
  properties: {
    findings: {
      type: 'array',
      items: {
        type: 'object',
        required: ['priority', 'title', 'file', 'line', 'evidence', 'fix'],
        properties: {
          priority: { type: 'string', enum: ['P0', 'P1', 'P2', 'P3'] },
          title: { type: 'string' },
          file: { type: 'string' },
          line: { type: 'integer' },
          evidence: { type: 'string' },
          fix: { type: 'string' },
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

const scope = typeof args === 'string' && args.trim() ? args.trim() : 'le projet entier (dossier courant)'
const COMMON = `Mission ORKYN : audit de sécurité, lecture seule, aucune modification, aucune installation.
Périmètre : ${scope}.
Suis le skill orkyn-security. Ne lis jamais la valeur d'un secret.
Rends uniquement des constats vérifiés dans le code (fichier et ligne ouverts), avec priorité réelle P0 à P3 et correction prête à appliquer. Aucun constat vaut mieux qu'un faux positif.`

const ANGLES = [
  { key: 'secrets-deps', focus: 'Couches 1 et 2 : secrets (fichiers et historique git) puis dépendances et chaîne d’approvisionnement.' },
  { key: 'code', focus: 'Couche 3 : failles du code (OWASP 2025, contrôle d’accès, injections, authentification), et couche 4 mobile si détectée.' },
  { key: 'config-ia', focus: 'Couches 5 et 6 : IA et agents si le projet appelle un modèle, puis configuration, Docker, IaC et CI.' },
]

const MAX_VERIF = 12

const results = await pipeline(
  ANGLES,
  a => agent(`${COMMON}\nAngle : ${a.focus}`, {
    label: `audit:${a.key}`, phase: 'Audit', schema: FINDINGS, agentType: 'orkyn:orkyn-security',
  }),
  (found, a) => {
    const list = (found?.findings ?? []).filter(f => f.priority !== 'P3')
    if (list.length > MAX_VERIF) log(`${a.key} : ${list.length - MAX_VERIF} constats au-delà de ${MAX_VERIF} non vérifiés (rapportés tels quels).`)
    const low = (found?.findings ?? []).filter(f => f.priority === 'P3')
    return parallel(list.slice(0, MAX_VERIF).map(f => () =>
      agent(`Mission ORKYN : contradicteur, lecture seule. Essaie de RÉFUTER ce constat de sécurité en ouvrant le code. Par défaut, s'il n'est pas exploitable ou mal localisé : isReal=false.
Constat : [${f.priority}] ${f.title} dans ${f.file}:${f.line}. Preuve avancée : ${f.evidence}`, {
        label: `verif:${f.file}:${f.line}`, phase: 'Vérification', schema: VERDICT, agentType: 'orkyn:orkyn-qa', effort: 'medium',
      }).then(v => ({ ...f, verdict: v }))
    )).then(checked => [...checked, ...list.slice(MAX_VERIF).map(f => ({ ...f, verdict: null })), ...low.map(f => ({ ...f, verdict: null }))])
  },
)

const all = results.flat().filter(Boolean)
const order = { P0: 0, P1: 1, P2: 2, P3: 3 }
const confirmed = all.filter(f => f.verdict?.isReal).sort((a, b) => order[a.priority] - order[b.priority])
const rejected = all.filter(f => f.verdict && !f.verdict.isReal).map(f => ({ title: f.title, file: f.file, reason: f.verdict.reason }))
const unverified = all.filter(f => !f.verdict)
return { confirmed, unverified, rejected }
