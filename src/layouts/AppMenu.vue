<script setup lang="ts">
import { computed } from 'vue'
import { useRole } from '@/composables/useRole'
import AppMenuItem, { type MenuItem } from './AppMenuItem.vue'

const { isDiretorGeral, isDiretorClube, isLider } = useRole()

const model = computed<MenuItem[]>(() => {
  const itens: MenuItem[] = [
    {
      label: 'Início',
      items: [{ label: 'Dashboard', icon: 'pi pi-fw pi-home', to: '/' }],
    },
  ]

  if (isDiretorGeral.value) {
    itens.push({
      label: 'Administração',
      items: [
        { label: 'Usuários', icon: 'pi pi-fw pi-users', to: '/admin/usuarios' },
        { label: 'Clubes', icon: 'pi pi-fw pi-shield', to: '/admin/clubes' },
        { label: 'Configurações', icon: 'pi pi-fw pi-cog', to: '/admin/configuracoes' },
        { label: 'Calendário', icon: 'pi pi-fw pi-calendar', to: '/admin/calendario' },
      ],
    })
  }

  if (isDiretorClube.value) {
    itens.push({
      label: 'Clube',
      items: [
        { label: 'Turmas', icon: 'pi pi-fw pi-users', to: '/clube/turmas' },
        { label: 'Líderes', icon: 'pi pi-fw pi-id-card', to: '/clube/lideres' },
        { label: 'Oansistas', icon: 'pi pi-fw pi-heart', to: '/clube/oansistas' },
        { label: 'Remanejamentos', icon: 'pi pi-fw pi-arrows-h', to: '/clube/remanejamentos' },
        { label: 'Transferências', icon: 'pi pi-fw pi-arrow-right-arrow-left', to: '/clube/transferencias' },
      ],
    })
  }

  if (isLider.value) {
    itens.push({
      label: 'Líder',
      items: [
        { label: 'Chamada', icon: 'pi pi-fw pi-check-square', to: '/chamada' },
        { label: 'Folha Semanal', icon: 'pi pi-fw pi-book', to: '/folha-semanal' },
      ],
    })
  }

  return itens
})
</script>

<template>
  <ul class="layout-menu">
    <template
      v-for="(item, i) in model"
      :key="item.label + i"
    >
      <app-menu-item
        v-if="!item.separator"
        :item="item"
        :index="i"
      />
      <li
        v-if="item.separator"
        class="menu-separator"
      />
    </template>
  </ul>
</template>
