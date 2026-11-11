import { defineStore } from 'pinia'
import { ref } from 'vue'

const STORAGE_KEY = 'productivity-os:sidebar-collapsed'

function getSavedCollapsed(): boolean {
  if (typeof window === 'undefined') return false
  try {
    return localStorage.getItem(STORAGE_KEY) === 'true'
  } catch {
    return false
  }
}

export const useNavStore = defineStore('nav', () => {
  const isCollapsed = ref(getSavedCollapsed())

  function toggleCollapse(): void {
    isCollapsed.value = !isCollapsed.value
    if (typeof window !== 'undefined') {
      try {
        localStorage.setItem(STORAGE_KEY, String(isCollapsed.value))
      } catch {
        // Ignore storage write errors
      }
    }
  }

  function setCollapsed(value: boolean): void {
    isCollapsed.value = value
    if (typeof window !== 'undefined') {
      try {
        localStorage.setItem(STORAGE_KEY, String(value))
      } catch {
        // Ignore storage write errors
      }
    }
  }

  return {
    isCollapsed,
    toggleCollapse,
    setCollapsed,
  }
})
