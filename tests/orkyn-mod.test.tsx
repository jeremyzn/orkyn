import { expect, test } from 'claude-code/testing'
import type { TurnStepResult } from 'claude-code'

import { detectLevel, fmt, isOrkynPrompt, parsePending } from '../hooks/orkyn-mod'

const PANE = {
  plugin: 'orkyn',
  component: 'Pane',
  requestId: 'orkyn',
  props: {
    title: 'ORKYN',
    isFocused: false,
    bodyColumns: 40,
    placement: 'dock',
    scroll: { offset: 0, bodyRows: 30 },
    view: {},
  },
} as const

const step = (answer: string, fresh: number, agentId?: string) => ({
  turnId: 't1',
  index: 0,
  model: 'claude-sonnet-5-5',
  messageCount: 1,
  ...(agentId ? { agentId } : {}),
})

const result = (answer: string, fresh: number): TurnStepResult => ({
  turnId: 't1',
  index: 0,
  answer,
  toolUses: [],
  stopReason: 'end_turn' as const,
  usage: {
    model: 'claude-sonnet-5-5',
    input_tokens: fresh,
    output_tokens: 0,
    cache_read_input_tokens: 1000,
    cache_creation_input_tokens: 0,
  },
})

test('fonctions pures : commande, niveau, actions à valider, format', async () => {
  expect(isOrkynPrompt('/orkyn ajoute un bouton')).toBe(true)
  expect(isOrkynPrompt('/orkyn:orkyn aide')).toBe(true)
  expect(isOrkynPrompt('/orkynx')).toBe(false)
  expect(isOrkynPrompt('ajoute /orkyn')).toBe(false)
  expect(detectLevel('Niveau léger : question simple.')).toBe('léger')
  expect(detectLevel('## Rapport ORKYN (niveau approfondi)')).toBe('approfondi')
  expect(detectLevel('rien')).toBe(null)
  const items = parsePending(
    '### À valider par vous\n1. Pousser sur GitHub : livraison → `git push`\n2. Publier la version : store\nRépondez « ok 1 »',
  )
  expect(items.length).toBe(2)
  expect(items[0]?.label).toBe('Pousser sur GitHub')
  expect(parsePending('Pas de bloc').length).toBe(0)
  expect(fmt(950)).toBe('950')
  expect(fmt(12_400)).toBe('12 k')
  expect(fmt(1_250_000)).toBe('1.3 M')
})

test('panneau vide hors mission, sur chaque surface', async $ => {
  for (const surface of ['terminal', 'desktop', 'vscode', 'mobile'] as const) {
    const ui = await $.ui.mount({ ...PANE, surface })
    expect((await ui.find({ type: 'Text', text: /Aucune mission/ }))?.text).toBe(
      'Aucune mission ORKYN dans cette session.',
    )
    await ui.unmount()
  }
})

test('une mission /orkyn compte les tokens, détecte le niveau et alerte à 80 %', async ($, on) => {
  on('ui.open', () => ({ value: { isPlaced: true } }))
  on('clock.now', () => ({ value: 1_700_000_000_000 }))
  on('prompt.submit', (_, e) => ({ text: e.text }))
  const appended: string[] = []
  on('ui.toast', () => ({ value: undefined }))
  on('session.append', (_, e, next) => {
    const block = (e.message.content as readonly { text?: string }[])[0]
    appended.push(block?.text ?? '')
    return next(e)
  })
  let next = result('Niveau léger : question simple.', 10_000)
  on('turn.step', async function* () {
    return next
  })

  await $.prompt.submit({ text: '/orkyn explique guard.sh', wait: false, origin: { kind: 'composer' } })
  for await (const _ of $.turn.step(step('', 0))) void _

  let ui = await $.ui.mount({ ...PANE, surface: 'terminal' })
  expect((await ui.find({ type: 'Text', text: /explique guard/ }))?.text).toBe('explique guard.sh')
  expect(await ui.find({ type: 'Text', text: /niveau léger/ })).toBeDefined()
  expect(await ui.find({ type: 'Text', text: /10 k sur 60 k/ })).toBeDefined()
  await ui.unmount()

  next = result('', 40_000)
  for await (const _ of $.turn.step(step('', 0))) void _
  expect(appended.length).toBe(1)
  expect(appended[0]).toContain('80 %')

  ui = await $.ui.mount({ ...PANE, surface: 'terminal' })
  expect(await ui.find({ type: 'Text', text: /50 k sur 60 k/ })).toBeDefined()
  await ui.unmount()
})
