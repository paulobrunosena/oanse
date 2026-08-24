<script setup lang="ts">
import { onBeforeUnmount, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import { useLayout } from './composables/layout'
import { useAuth } from '@/composables/useAuth'
import { useRole } from '@/composables/useRole'
import AppMenu from './AppMenu.vue'
import Avatar from 'primevue/avatar'
import Button from 'primevue/button'

const { layoutState, isDesktop, hasOpenOverlay } = useLayout()
const { profile, logout } = useAuth()
const { roleLabel } = useRole()
const route = useRoute()
const sidebarRef = ref<HTMLElement | null>(null)
let outsideClickListener: ((event: MouseEvent) => void) | null = null

watch(
  () => route.path,
  (newPath) => {
    if (isDesktop()) layoutState.activePath = null
    else layoutState.activePath = newPath

    layoutState.overlayMenuActive = false
    layoutState.mobileMenuActive = false
    layoutState.menuHoverActive = false
  },
  { immediate: true },
)

watch(hasOpenOverlay, (newVal) => {
  if (isDesktop()) {
    if (newVal) bindOutsideClickListener()
    else unbindOutsideClickListener()
  }
})

const bindOutsideClickListener = () => {
  if (!outsideClickListener) {
    outsideClickListener = (event: MouseEvent) => {
      if (isOutsideClicked(event)) {
        layoutState.overlayMenuActive = false
      }
    }
    document.addEventListener('click', outsideClickListener)
  }
}

const unbindOutsideClickListener = () => {
  if (outsideClickListener) {
    document.removeEventListener('click', outsideClickListener)
    outsideClickListener = null
  }
}

const isOutsideClicked = (event: MouseEvent) => {
  const topbarButtonEl = document.querySelector('.layout-menu-button')
  const target = event.target as Node

  return !(
    sidebarRef.value?.isSameNode(target) ||
    sidebarRef.value?.contains(target) ||
    topbarButtonEl?.isSameNode(target) ||
    topbarButtonEl?.contains(target)
  )
}

onBeforeUnmount(() => {
  unbindOutsideClickListener()
})
</script>

<template>
  <div
    ref="sidebarRef"
    class="layout-sidebar"
  >
    <AppMenu />

    <div class="layout-sidebar-profile lg:hidden">
      <div class="flex items-center gap-3 px-1 pb-1">
        <Avatar
          :label="(profile?.nome ?? '?').charAt(0).toUpperCase()"
          shape="circle"
        />
        <div class="flex min-w-0 flex-col leading-tight">
          <span class="truncate text-sm font-semibold text-surface-900 dark:text-surface-0">{{ profile?.nome }}</span>
          <span class="text-xs text-surface-500 dark:text-surface-400">{{ roleLabel }}</span>
        </div>
        <Button
          icon="pi pi-sign-out"
          text
          rounded
          size="small"
          class="ml-auto"
          aria-label="Sair"
          @click="logout"
        />
      </div>
    </div>
  </div>
</template>
