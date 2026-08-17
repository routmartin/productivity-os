<script setup lang="ts">
import { RouterView } from 'vue-router'

import PreviewToast from '@/components/shared/PreviewToast.vue'
import FocusDock from '@/features/focus/components/FocusDock.vue'
import SearchOverlay from '@/features/search/components/SearchOverlay.vue'

import ContextPanel from './ContextPanel.vue'
import SideNav from './SideNav.vue'
import TopBar from './TopBar.vue'
</script>

<template>
  <div class="shell">
    <SideNav />
    <main class="workspace">
      <TopBar />
      <div class="scroll">
        <RouterView v-slot="{ Component }">
          <Transition name="page" mode="out-in">
            <component :is="Component" />
          </Transition>
        </RouterView>
      </div>
    </main>
    <ContextPanel />
    <PreviewToast />
    <FocusDock />
    <SearchOverlay />
  </div>
</template>

<style scoped>
.shell {
  display: grid;
  grid-template-columns: auto minmax(0, 1fr) auto;
  height: 100vh;
  overflow: hidden;
}

.workspace {
  display: flex;
  flex-direction: column;
  min-width: 0;
  overflow: hidden;
  /* Pages respond to the real workspace width (sidebar and context panel
     already deducted) via @container queries. */
  container-type: inline-size;
  container-name: workspace;
}

.scroll {
  flex: 1;
  overflow-y: auto;
  overflow-x: hidden;
}
</style>
