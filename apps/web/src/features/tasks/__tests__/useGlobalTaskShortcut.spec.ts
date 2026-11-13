import { createPinia, setActivePinia } from 'pinia'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { useRoute } from 'vue-router'

import { useTasksStore } from '../store'
import { useGlobalTaskShortcut } from '../composables/useGlobalTaskShortcut'

vi.mock('vue-router', () => ({
  useRoute: vi.fn(),
}))

describe('useGlobalTaskShortcut', () => {
  let listeners: Record<string, (e: unknown) => void> = {}

  class MockHTMLElement {
    tagName = 'BODY'
    isContentEditable = false
    closest() {
      return null
    }
  }

  beforeEach(() => {
    setActivePinia(createPinia())
    listeners = {}

    vi.stubGlobal('HTMLElement', MockHTMLElement)

    // Mock window event listeners
    vi.stubGlobal('window', {
      addEventListener: vi.fn((event: string, handler: (e: unknown) => void) => {
        listeners[event] = handler
      }),
      removeEventListener: vi.fn(),
    })
  })

  afterEach(() => {
    vi.restoreAllMocks()
    vi.unstubAllGlobals()
  })

  it('focuses inline Quick Capture on Today route without opening dialog (AC-007)', () => {
    vi.mocked(useRoute).mockReturnValue({
      name: 'today',
      path: '/today',
      fullPath: '/today',
      query: {},
      params: {},
      hash: '',
      matched: [],
      meta: {},
      redirectedFrom: undefined,
    })

    const focusMock = vi.fn()
    vi.stubGlobal('document', {
      querySelector: vi.fn((selector: string) => {
        if (selector === '[data-quick-capture-input]') {
          return { focus: focusMock }
        }
        return null
      }),
    })

    const tasksStore = useTasksStore()
    const openDialogSpy = vi.spyOn(tasksStore, 'openCreateDialog')

    useGlobalTaskShortcut()

    const onKeydown = listeners['keydown']
    expect(onKeydown).toBeDefined()

    // When user presses 'c' with no modifiers
    const target = new MockHTMLElement()
    const event = {
      key: 'c',
      metaKey: false,
      ctrlKey: false,
      altKey: false,
      shiftKey: false,
      target,
      preventDefault: vi.fn(),
    }
    onKeydown(event)

    expect(event.preventDefault).toHaveBeenCalled()
    expect(focusMock).toHaveBeenCalledTimes(1)
    expect(openDialogSpy).not.toHaveBeenCalled()
    expect(tasksStore.isCreateDialogOpen).toBe(false)
  })

  it('opens task creation dialog when pressing c on non-Today route (AC-007)', () => {
    vi.mocked(useRoute).mockReturnValue({
      name: 'tasks',
      path: '/tasks',
      fullPath: '/tasks',
      query: {},
      params: {},
      hash: '',
      matched: [],
      meta: {},
      redirectedFrom: undefined,
    })

    const tasksStore = useTasksStore()
    const openDialogSpy = vi.spyOn(tasksStore, 'openCreateDialog')

    useGlobalTaskShortcut()

    const onKeydown = listeners['keydown']
    const target = new MockHTMLElement()
    const event = {
      key: 'c',
      metaKey: false,
      ctrlKey: false,
      altKey: false,
      shiftKey: false,
      target,
      preventDefault: vi.fn(),
    }
    onKeydown(event)

    expect(event.preventDefault).toHaveBeenCalled()
    expect(openDialogSpy).toHaveBeenCalledTimes(1)
    expect(tasksStore.isCreateDialogOpen).toBe(true)
  })

  it('ignores c keydown when user is typing in an input element', () => {
    vi.mocked(useRoute).mockReturnValue({
      name: 'today',
      path: '/today',
      fullPath: '/today',
      query: {},
      params: {},
      hash: '',
      matched: [],
      meta: {},
      redirectedFrom: undefined,
    })

    const tasksStore = useTasksStore()
    const openDialogSpy = vi.spyOn(tasksStore, 'openCreateDialog')

    useGlobalTaskShortcut()

    const onKeydown = listeners['keydown']
    const target = new MockHTMLElement()
    target.tagName = 'INPUT'
    const event = {
      key: 'c',
      metaKey: false,
      ctrlKey: false,
      altKey: false,
      shiftKey: false,
      target,
      preventDefault: vi.fn(),
    }
    onKeydown(event)

    expect(event.preventDefault).not.toHaveBeenCalled()
    expect(openDialogSpy).not.toHaveBeenCalled()
  })
})
