<script setup lang="ts">
import { storeToRefs } from 'pinia'
import { useLayout } from './composables/layout'
import { useAuth } from '@/composables/useAuth'
import { useRole } from '@/composables/useRole'
import { usePreferenciasStore } from '@/stores/preferencias'
import ActionButton from '@/components/ActionButton.vue'

const { toggleMenu, toggleDarkMode, isDarkTheme } = useLayout()
const { profile, logout } = useAuth()
const { roleLabel } = useRole()

const preferencias = usePreferenciasStore()
const { rotulosAcoes } = storeToRefs(preferencias)
</script>

<template>
  <div class="layout-topbar">
    <div class="layout-topbar-logo-container">
      <button
        class="layout-menu-button layout-topbar-action"
        aria-label="Alternar menu"
        v-tooltip="'Alternar menu'"
        @click="toggleMenu"
      >
        <i class="pi pi-bars" />
      </button>
      <router-link
        to="/"
        class="layout-topbar-logo"
      >
        <img
          src="/logos/oanse.png"
          alt="Oanse"
          class="h-9 w-auto object-contain"
        >
      </router-link>
    </div>

    <div class="layout-topbar-actions">
      <div class="layout-config-menu">
        <button
          type="button"
          class="layout-topbar-action"
          :class="{ 'layout-topbar-action-highlight': rotulosAcoes }"
          :aria-label="rotulosAcoes ? 'Ocultar texto nas ações' : 'Mostrar texto nas ações'"
          v-tooltip="rotulosAcoes ? 'Ocultar texto nas ações' : 'Mostrar texto nas ações'"
          @click="preferencias.alternarRotulosAcoes()"
        >
          <i class="pi pi-tag" />
        </button>

        <button
          type="button"
          class="layout-topbar-action"
          :aria-label="isDarkTheme ? 'Modo claro' : 'Modo escuro'"
          v-tooltip="isDarkTheme ? 'Modo claro' : 'Modo escuro'"
          @click="toggleDarkMode"
        >
          <i :class="['pi', isDarkTheme ? 'pi-sun' : 'pi-moon']" />
        </button>
      </div>

      <div class="layout-topbar-menu hidden lg:block">
        <div class="layout-topbar-menu-content">
          <div class="flex items-center gap-3 px-4">
            <Avatar
              :label="(profile?.nome ?? '?').charAt(0).toUpperCase()"
              shape="circle"
            />
            <div class="flex flex-col leading-tight">
              <span class="text-sm font-semibold text-surface-900 dark:text-surface-0">{{ profile?.nome }}</span>
              <span class="text-xs text-surface-500 dark:text-surface-400">{{ roleLabel }}</span>
            </div>
            <ActionButton
              icon="pi pi-sign-out"
              label="Sair"
              @click="logout"
            />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
