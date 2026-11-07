export type Niveau = 'léger' | 'standard' | 'approfondi'

export type Mission = {
  isActive: boolean
  isRunning: boolean
  prompt: string
  startedAt: number
  level: Niveau | null
  budget: number
  isWarned80: boolean
  isWarned100: boolean
}

export type AgentUsage = {
  type: string
  fresh: number
  cached: number
  isDone: boolean
}

export type Usage = {
  mainFresh: number
  mainCached: number
  agents: Record<string, AgentUsage>
}

export type Pending = { number: string; label: string }

declare module 'claude-code' {
  interface PluginState {
    orkyn: {
      mission: Shaped<Mission>
      usage: Shaped<Usage>
      pending: Shaped<Pending[]>
      customBudget: number | null
    }
  }
}
