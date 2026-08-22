<script setup lang="ts">
import type { NavigationMenuItem } from '@nuxt/ui'

const { profile } = useAuth()
const { roleLabel, isDiretorGeral, isDiretorClube, isLider } = useRole()
const { logout } = useAuth()

const route = useRoute()

const tituloPagina = computed(() => {
  const mapa: Record<string, string> = {
    '/': 'Início',
    '/admin/usuarios': 'Usuários',
    '/admin/clubes': 'Clubes',
    '/admin/configuracoes': 'Configurações',
    '/admin/calendario': 'Calendário',
    '/clube/turmas': 'Turmas',
    '/clube/lideres': 'Líderes',
    '/clube/oansistas': 'Oansistas',
    '/clube/remanejamentos': 'Remanejamentos',
    '/clube/transferencias': 'Transferências',
    '/chamada': 'Chamada',
    '/folha-semanal': 'Folha Semanal',
  }
  return mapa[route.path] ?? 'Oanse'
})

const menuItens = computed<NavigationMenuItem[]>(() => {
  const itens: NavigationMenuItem[] = [
    { label: 'Início', icon: 'i-lucide-home', to: '/' },
  ]

  if (isDiretorGeral.value) {
    itens.push(
      { label: 'Usuários', icon: 'i-lucide-users', to: '/admin/usuarios' },
      { label: 'Clubes', icon: 'i-lucide-shield', to: '/admin/clubes' },
      { label: 'Configurações', icon: 'i-lucide-settings', to: '/admin/configuracoes' },
      { label: 'Calendário', icon: 'i-lucide-calendar-off', to: '/admin/calendario' },
    )
  }

  if (isDiretorClube.value) {
    itens.push(
      { label: 'Turmas', icon: 'i-lucide-users-round', to: '/clube/turmas' },
      { label: 'Líderes', icon: 'i-lucide-user-check', to: '/clube/lideres' },
      { label: 'Oansistas', icon: 'i-lucide-baby', to: '/clube/oansistas' },
      { label: 'Remanejamentos', icon: 'i-lucide-shuffle', to: '/clube/remanejamentos' },
      { label: 'Transferências', icon: 'i-lucide-arrow-right-left', to: '/clube/transferencias' },
    )
  }

  if (isLider.value) {
    itens.push(
      { label: 'Chamada', icon: 'i-lucide-clipboard-check', to: '/chamada' },
      { label: 'Folha Semanal', icon: 'i-lucide-book-open-check', to: '/folha-semanal' },
    )
  }

  return itens
})
</script>

<template>
  <UDashboardGroup unit="rem">
    <UDashboardSidebar
      id="main-sidebar"
      collapsible
      resizable
      :ui="{ footer: 'border-t border-default' }"
    >
      <template #header="{ collapsed }">
        <div class="flex items-center gap-2 min-w-0">
          <UIcon
            name="i-lucide-flame"
            class="size-8 shrink-0 text-primary"
          />
          <span
            v-if="!collapsed"
            class="text-lg font-bold truncate"
          >Oanse</span>
        </div>
      </template>

      <template #default="{ collapsed }">
        <UNavigationMenu
          :collapsed="collapsed"
          :items="menuItens"
          orientation="vertical"
          class="w-full"
        />
      </template>

      <template #footer="{ collapsed }">
        <div class="flex items-center gap-2 w-full min-w-0">
          <UAvatar
            :alt="profile?.nome ?? '?'"
            size="sm"
          />
          <div
            v-if="!collapsed"
            class="flex flex-col min-w-0 flex-1"
          >
            <span class="text-sm font-medium truncate">{{ profile?.nome }}</span>
            <span class="text-xs text-muted truncate">{{ roleLabel }}</span>
          </div>
          <UButton
            v-if="!collapsed"
            icon="i-lucide-log-out"
            color="neutral"
            variant="ghost"
            size="sm"
            aria-label="Sair"
            @click="logout"
          />
        </div>
      </template>
    </UDashboardSidebar>

    <UDashboardPanel :ui="{ body: 'h-full' }">
      <template #header>
        <UDashboardNavbar :title="tituloPagina" />
      </template>
      <template #body>
        <slot />
      </template>
    </UDashboardPanel>
  </UDashboardGroup>
</template>
