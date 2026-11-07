// ORKYN : tableau de bord et budget de tokens par mission (mod Claude Code).
// Ne coûte aucun token au modèle, sauf les deux rappels de budget (80 % et 100 %).
import { atom, read, update } from 'claude-code'
import type { Register } from 'claude-code'

import type { AgentUsage, Mission, Niveau, Pending, Usage } from '../types'

const PANE = 'orkyn'
const TITLE = 'ORKYN'

// Budget en tokens nouveaux (entrée hors cache, écriture de cache, sortie) par niveau.
// Les lectures de cache sont affichées à part : elles coûtent environ dix fois moins.
const BUDGETS: Record<Niveau, number> = {
  léger: 60_000,
  standard: 300_000,
  approfondi: 1_000_000,
}
const DEFAULT_BUDGET = BUDGETS.standard

const IDLE: Mission = {
  isActive: false,
  isRunning: false,
  prompt: '',
  startedAt: 0,
  level: null,
  budget: DEFAULT_BUDGET,
  isWarned80: false,
  isWarned100: false,
}
const EMPTY: Usage = { mainFresh: 0, mainCached: 0, agents: {} }

const mission = atom({ plugin: 'orkyn', key: 'mission' } as const, IDLE, {
  shape: 'mission-1',
})
const usage = atom({ plugin: 'orkyn', key: 'usage' } as const, EMPTY, {
  shape: 'usage-1',
})
const pending = atom({ plugin: 'orkyn', key: 'pending' } as const, [] as Pending[], {
  shape: 'pending-1',
})
const customBudget = atom(
  { plugin: 'orkyn', key: 'customBudget' } as const,
  null as number | null,
)

export const isOrkynPrompt = (text: string): boolean =>
  /^\s*\/orkyn(:orkyn)?(\s|$)/.test(text)

export const detectLevel = (text: string): Niveau | null => {
  const m = /niveau\s+\**\s*(léger|standard|approfondi)/i.exec(text)
  return m && m[1] ? (m[1].toLowerCase() as Niveau) : null
}

export const parsePending = (text: string): Pending[] => {
  const at = text.search(/À valider par vous/i)
  if (at < 0) return []
  const items: Pending[] = []
  for (const line of text.slice(at).split('\n')) {
    const m = /^\s*(\d+)\.\s+(.+?)\s*(?::|→|$)/.exec(line)
    if (m && m[1] && m[2]) items.push({ number: m[1], label: m[2].replace(/[*`]/g, '').slice(0, 70) })
  }
  return items.slice(0, 9)
}

export const totalFresh = (u: Usage): number =>
  u.mainFresh + Object.values(u.agents).reduce((s, a) => s + a.fresh, 0)

export const fmt = (n: number): string =>
  n >= 1_000_000 ? `${(n / 1_000_000).toFixed(1)} M` : n >= 1000 ? `${Math.round(n / 1000)} k` : `${n}`

const bar = (ratio: number, width: number): string => {
  const full = Math.max(0, Math.min(width, Math.round(ratio * width)))
  return '█'.repeat(full) + '░'.repeat(width - full)
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await $.command.register({
      name: 'orkyn-panneau',
      description: 'ORKYN : ouvre le tableau de bord (mission, tokens, budget)',
    })
    await $.command.register({
      name: 'orkyn-budget',
      description: 'ORKYN : fixe le budget de tokens des missions (nombre, ou auto)',
    })
    return next(e)
  })

  on('command.run', { command: 'orkyn-panneau' }, async $ => {
    await $.ui.open({ id: PANE, title: TITLE })
    return { text: 'Tableau de bord ORKYN ouvert.' }
  })

  on('command.run', { command: 'orkyn-budget' }, async ($, e) => {
    const arg = (e.args ?? '').trim().toLowerCase().replace(/[\s_.]/g, '')
    if (arg === '' || arg === 'auto') {
      await update($, customBudget, () => null)
      return { text: 'Budget ORKYN automatique : léger 60 k, standard 300 k, approfondi 1 M tokens.' }
    }
    const m = /^(\d+)(k|m)?$/.exec(arg)
    if (!m) return { text: 'Usage : /orkyn-budget 200k, /orkyn-budget 1m ou /orkyn-budget auto' }
    const n = Number(m[1]) * (m[2] === 'm' ? 1_000_000 : m[2] === 'k' ? 1000 : 1)
    await update($, customBudget, () => n)
    await update($, mission, ms => ({ ...ms, budget: n }))
    return { text: `Budget ORKYN fixé à ${fmt(n)} tokens par mission.` }
  })

  // Nouvelle mission : chaque /orkyn remet les compteurs à zéro et ouvre le panneau.
  on('prompt.submit', async ($, e, next) => {
    if (isOrkynPrompt(e.text)) {
      const custom = await read($, customBudget)
      const startedAt = await $.clock.now()
      await update($, mission, () => ({
        ...IDLE,
        isActive: true,
        isRunning: true,
        prompt: e.text.replace(/^\s*\/orkyn(:orkyn)?\s*/, '').slice(0, 80),
        startedAt,
        budget: custom ?? DEFAULT_BUDGET,
      }))
      await update($, usage, () => EMPTY)
      await update($, pending, () => [])
      void $.ui.open({ id: PANE, title: TITLE })
    }
    return next(e)
  })

  on('agent.spawn', async ($, e, next) => {
    const ms = await read($, mission)
    if (ms.isActive && ms.isWarned100) {
      return {
        deny: `Budget ORKYN atteint (${fmt(ms.budget)} tokens) : aucun nouvel agent. Conclus avec ce que tu as, ou l'utilisateur relève le budget avec /orkyn-budget.`,
      }
    }
    const r = await next(e)
    if (ms.isActive && r.agentId) {
      const id = r.agentId
      const type = (e.subagentType ?? 'agent').replace(/^orkyn:orkyn-/, '')
      await update($, usage, u => {
        const prev: AgentUsage | undefined = u.agents[id]
        return { ...u, agents: { ...u.agents, [id]: { type, fresh: prev?.fresh ?? 0, cached: prev?.cached ?? 0, isDone: false } } }
      })
    }
    return r
  })

  on('turn.step', async function* ($, e, next) {
    const r = yield* next(e)
    const ms = await read($, mission)
    if (!ms.isActive || !r || !r.usage) return r
    const fresh = r.usage.input_tokens + r.usage.cache_creation_input_tokens + r.usage.output_tokens
    const cached = r.usage.cache_read_input_tokens
    const agentId = e.agentId
    const u = await update($, usage, cur => {
      if (!agentId) return { ...cur, mainFresh: cur.mainFresh + fresh, mainCached: cur.mainCached + cached }
      const a: AgentUsage = cur.agents[agentId] ?? { type: 'agent', fresh: 0, cached: 0, isDone: false }
      return { ...cur, agents: { ...cur.agents, [agentId]: { ...a, fresh: a.fresh + fresh, cached: a.cached + cached } } }
    })

    let budget = ms.budget
    if (!agentId && ms.level === null && r.answer) {
      const level = detectLevel(r.answer)
      if (level) {
        budget = (await read($, customBudget)) ?? BUDGETS[level]
        await update($, mission, cur => ({ ...cur, level, budget }))
      }
    }

    const used = totalFresh(u)
    const now = await read($, mission)
    if (used >= budget && !now.isWarned100) {
      await update($, mission, cur => ({ ...cur, isWarned80: true, isWarned100: true }))
      $.ui.toast(`ORKYN : budget atteint (${fmt(used)} sur ${fmt(budget)} tokens)`)
      await $.session
        .append({
          message: {
            type: 'user',
            content: [{ type: 'text', text: `[Budget ORKYN] Budget de la mission atteint : ${fmt(used)} tokens sur ${fmt(budget)}. Conclus maintenant : termine la modification en cours, lance la vérification ciblée et rends le rapport. Plus aucun nouvel agent (refusé). Mets ce qui reste dans « Actions restantes ».` }],
          },
        })
        .catch(() => undefined)
    } else if (used >= budget * 0.8 && !now.isWarned80) {
      await update($, mission, cur => ({ ...cur, isWarned80: true }))
      $.ui.toast(`ORKYN : 80 % du budget utilisé (${fmt(used)} sur ${fmt(budget)})`)
      await $.session
        .append({
          message: {
            type: 'user',
            content: [{ type: 'text', text: `[Budget ORKYN] 80 % du budget de la mission utilisé : ${fmt(used)} tokens sur ${fmt(budget)}. Finis la tâche en cours sans ouvrir de nouveau chantier, et prépare le rapport.` }],
          },
        })
        .catch(() => undefined)
    }
    return r
  })

  on('turn.complete', async ($, e, next) => {
    const r = await next(e)
    const ms = await read($, mission)
    if (!ms.isActive) return r
    if (e.agentId) {
      const id = e.agentId
      await update($, usage, u => (u.agents[id] ? { ...u, agents: { ...u.agents, [id]: { ...u.agents[id], isDone: true } } } : u))
    } else {
      await update($, mission, cur => ({ ...cur, isRunning: false }))
      await update($, pending, () => parsePending(e.answer ?? ''))
    }
    return r
  })

  on('turn.start', async ($, e, next) => {
    if (!e.agentId) {
      const ms = await read($, mission)
      if (ms.isActive && !ms.isRunning) await update($, mission, cur => ({ ...cur, isRunning: true }))
    }
    return next(e)
  })

  on('ui.render', { component: 'Pane', requestId: PANE }, async ($, e) => {
    const { Box, Text, Button } = $.ui.resolve(e)
    const ms = await read($, mission)
    const u = await read($, usage)
    const todo = await read($, pending)
    const width = Math.max(10, Math.min(30, (e.props.bodyColumns ?? 40) - 12))

    if (!ms.isActive) {
      return (
        <Box flexDirection="column">
          <Text dimColor>Aucune mission ORKYN dans cette session.</Text>
          <Text dimColor>Lancez /orkyn suivi de votre demande.</Text>
        </Box>
      )
    }

    const used = totalFresh(u)
    const ratio = ms.budget > 0 ? used / ms.budget : 0
    const color = ratio >= 1 ? 'red' : ratio >= 0.8 ? 'yellow' : 'green'
    const agents = Object.values(u.agents)
    const cached = u.mainCached + agents.reduce((s, a) => s + a.cached, 0)

    return (
      <Box flexDirection="column">
        <Text bold>{ms.prompt || 'Mission ORKYN'}</Text>
        <Text dimColor>
          {ms.isRunning ? 'en cours' : 'terminée'} · niveau {ms.level ?? 'en attente'}
        </Text>
        <Text> </Text>
        <Text>Budget</Text>
        <Text color={color}>
          {bar(ratio, width)} {Math.round(ratio * 100)} %
        </Text>
        <Text dimColor>
          {fmt(used)} sur {fmt(ms.budget)} tokens · cache relu {fmt(cached)}
        </Text>
        <Text> </Text>
        <Text>Coordinateur : {fmt(u.mainFresh)}</Text>
        {agents.length === 0 && <Text dimColor>Aucun agent lancé</Text>}
        {agents.map(a => (
          <Text dimColor={a.isDone}>
            {a.isDone ? '✓' : '…'} {a.type} : {fmt(a.fresh)}
          </Text>
        ))}
        {todo.length > 0 && (
          <Box flexDirection="column">
            <Text> </Text>
            <Text bold>À valider par vous</Text>
            {todo.map(p => (
              <Box>
                <Button
                  key={`ok-${p.number}`}
                  label={`ok ${p.number}`}
                  onPress={() => {
                    void $.prompt.submit({ text: `ok ${p.number}`, asUser: true })
                    void update($, pending, list => list.filter(x => x.number !== p.number))
                  }}
                />
                <Text> {p.label}</Text>
              </Box>
            ))}
            <Box>
              <Button
                key="ok-tout"
                variant="primary"
                label="ok tout"
                onPress={() => {
                  void $.prompt.submit({ text: 'ok tout', asUser: true })
                  void update($, pending, () => [])
                }}
              />
              <Button
                key="non"
                label="non"
                onPress={() => {
                  void $.prompt.submit({ text: 'non', asUser: true })
                  void update($, pending, () => [])
                }}
              />
            </Box>
          </Box>
        )}
      </Box>
    )
  })
}
