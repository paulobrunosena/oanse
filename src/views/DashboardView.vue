<script setup lang="ts">
import { onMounted, ref } from 'vue'
import Card from 'primevue/card'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/composables/useAuth'
import { useRole } from '@/composables/useRole'
import { logoClube } from '@/utils/data'

const { profile } = useAuth()
const { roleLabel } = useRole()

const clube = ref<{ nome: string, cor: string | null, slug: string | null } | null>(null)

onMounted(async () => {
  if (!profile.value?.clube_id) return
  const { data } = await supabase
    .from('clubes')
    .select('nome, cor, slug')
    .eq('id', profile.value.clube_id)
    .single()
  clube.value = data ?? null
})
</script>

<template>
  <div class="p-4 sm:p-6 max-w-3xl mx-auto w-full">
    <h1 class="text-2xl font-bold">
      Olá, {{ profile?.nome?.split(' ')[0] }}!
    </h1>
    <p class="text-surface-500 mt-1">
      Você está logado como <strong>{{ roleLabel }}</strong>
      <template v-if="clube">
        do clube
        <span class="inline-flex items-center gap-1 align-middle">
          <img
            :src="logoClube(clube.slug) ?? undefined"
            :alt="clube.nome"
            class="size-4 object-contain inline-block"
          >
          <span
            class="font-semibold"
            :style="{ color: clube.cor ?? undefined }"
          >{{ clube.nome }}</span>
        </span>
      </template>.
    </p>

    <div class="mt-8 grid gap-4 sm:grid-cols-2">
      <Card>
        <template #title>
          <span class="font-semibold">Fase 1 em construção</span>
        </template>
        <template #content>
          <p class="text-sm text-surface-500">
            As telas de administração (usuários, clubes, configurações), turmas e
            oansistas estão sendo implementadas.
          </p>
        </template>
      </Card>
      <Card>
        <template #title>
          <span class="font-semibold">Próximas fases</span>
        </template>
        <template #content>
          <p class="text-sm text-surface-500">
            Fase 2: Lançamento Semanal (chamada e Folha Semanal).
            Fase 3: Painel da Secretaria. Fase 4: Jogos e Ranking.
          </p>
        </template>
      </Card>
    </div>
  </div>
</template>
