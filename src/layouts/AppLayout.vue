<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRoute } from 'vue-router'
import { useAuth } from '@/composables/useAuth'
import { useRole } from '@/composables/useRole'
import { supabase } from '@/lib/supabase'
import { logoClube } from '@/utils/data'

const route = useRoute()
const { profile, logout } = useAuth()
const { roleLabel, isDiretorGeral, isDiretorClube, isLider } = useRole()

const collapsed = ref(false)
const clube = ref<{ nome: string, slug: string | null, cor: string | null } | null>(null)

onMounted(async () => {
  if (!profile.value?.clube_id) return
  const { data } = await supabase
    .from('clubes')
    .select('id, nome, slug, cor')
    .eq('id', profile.value.clube_id)
    .single()
  clube.value = data ?? null
})

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

const menu = computed(() => {
  const itens: { label: string, icon: string, to: string }[] = [
    { label: 'Início', icon: 'pi pi-home', to: '/' },
  ]

  if (isDiretorGeral.value) {
    itens.push(
      { label: 'Usuários', icon: 'pi pi-users', to: '/admin/usuarios' },
      { label: 'Clubes', icon: 'pi pi-shield', to: '/admin/clubes' },
      { label: 'Configurações', icon: 'pi pi-cog', to: '/admin/configuracoes' },
      { label: 'Calendário', icon: 'pi pi-calendar', to: '/admin/calendario' },
    )
  }

  if (isDiretorClube.value) {
    itens.push(
      { label: 'Turmas', icon: 'pi pi-users', to: '/clube/turmas' },
      { label: 'Líderes', icon: 'pi pi-user-check', to: '/clube/lideres' },
      { label: 'Oansistas', icon: 'pi pi-heart', to: '/clube/oansistas' },
      { label: 'Remanejamentos', icon: 'pi pi-shuffle', to: '/clube/remanejamentos' },
      { label: 'Transferências', icon: 'pi pi-arrow-right-arrow-left', to: '/clube/transferencias' },
    )
  }

  if (isLider.value) {
    itens.push(
      { label: 'Chamada', icon: 'pi pi-check-square', to: '/chamada' },
      { label: 'Folha Semanal', icon: 'pi pi-book', to: '/folha-semanal' },
    )
  }

  return itens
})
</script>

<template>
  <div class="flex min-h-screen">
    <aside
      class="bg-white border-r flex flex-col shrink-0 transition-all"
      :class="collapsed ? 'w-16' : 'w-64'"
    >
      <div class="flex items-center gap-2 h-16 px-4 border-b min-w-0">
        <img
          src="/logos/oanse.png"
          alt="Oanse"
          class="size-8 shrink-0 object-contain"
        >
        <span
          v-if="!collapsed"
          class="text-lg font-bold truncate"
        >Oanse</span>
      </div>

      <nav class="flex-1 overflow-y-auto p-2 flex flex-col gap-1">
        <RouterLink
          v-for="item in menu"
          :key="item.to"
          :to="item.to"
          class="flex items-center gap-3 px-3 py-2 rounded-lg text-sm transition-colors"
          :class="route.path === item.to ? 'bg-primary-50 text-primary-700 font-medium' : 'text-surface-700 hover:bg-surface-100'"
          :title="item.label"
        >
          <i
            :class="item.icon"
            class="shrink-0"
          />
          <span
            v-if="!collapsed"
            class="truncate"
          >{{ item.label }}</span>
        </RouterLink>
      </nav>

      <div class="border-t p-3 flex flex-col gap-3">
        <div
          v-if="clube"
          class="flex items-center gap-2 min-w-0"
        >
          <img
            :src="logoClube(clube.slug) ?? undefined"
            :alt="clube.nome"
            class="size-6 shrink-0 object-contain"
          >
          <span
            v-if="!collapsed"
            class="text-sm font-medium truncate"
            :style="{ color: clube.cor ?? undefined }"
          >{{ clube.nome }}</span>
        </div>
        <div class="flex items-center gap-2 min-w-0">
          <Avatar
            :label="(profile?.nome ?? '?').charAt(0).toUpperCase()"
            size="small"
          />
          <div
            v-if="!collapsed"
            class="flex flex-col min-w-0 flex-1"
          >
            <span class="text-sm font-medium truncate">{{ profile?.nome }}</span>
            <span class="text-xs text-surface-500 truncate">{{ roleLabel }}</span>
          </div>
          <Button
            v-if="!collapsed"
            icon="pi pi-sign-out"
            text
            rounded
            size="small"
            aria-label="Sair"
            @click="logout"
          />
        </div>
      </div>
    </aside>

    <div class="flex-1 flex flex-col min-w-0">
      <header class="h-16 border-b bg-white flex items-center px-6">
        <Button
          icon="pi pi-bars"
          text
          rounded
          size="small"
          aria-label="Alternar menu"
          @click="collapsed = !collapsed"
        />
        <h1 class="text-lg font-semibold ml-3">
          {{ tituloPagina }}
        </h1>
      </header>
      <main class="flex-1 overflow-y-auto">
        <router-view />
      </main>
    </div>
  </div>
</template>
