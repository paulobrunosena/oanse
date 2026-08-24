<script setup lang="ts">
import { onMounted, ref } from 'vue'
import Column from 'primevue/column'
import DataTable from 'primevue/datatable'
import Tag from 'primevue/tag'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/composables/useAuth'
import type { Database } from '@/types/database.types'

type Profile = Database['public']['Tables']['profiles']['Row']

const { profile } = useAuth()

const lideres = ref<(Profile & { turma_nome: string | null })[]>([])
const carregando = ref(true)

async function carregar() {
  carregando.value = true
  const { data } = await supabase
    .from('profiles')
    .select('*, turma:turmas!turmas_lider_id_fkey(nome)')
    .eq('clube_id', profile.value!.clube_id!)
    .eq('role', 'lider')
    .eq('ativo', true)
    .order('nome')
  lideres.value = (data ?? []).map(l => ({
    ...l,
    turma_nome: (l.turma as unknown as { nome: string } | null)?.nome ?? null,
  }))
  carregando.value = false
}

onMounted(carregar)
</script>

<template>
  <div class="p-4 sm:p-6 max-w-4xl mx-auto w-full">
    <div class="mb-4">
      <h1 class="text-2xl font-bold">
        Líderes
      </h1>
      <p class="text-sm text-surface-500">
        Equipe de líderes do clube
      </p>
    </div>

    <DataTable
      :value="lideres"
      :loading="carregando"
      data-key="id"
      class="w-full"
    >
      <Column field="nome" header="Nome" />
      <Column header="Turma">
        <template #body="{ data }">
          <Tag
            v-if="data.turma_nome"
            :value="data.turma_nome"
            severity="info"
          />
          <span
            v-else
            class="text-surface-500"
          >Sem turma</span>
        </template>
      </Column>
      <Column header="Contato">
        <template #body="{ data }">
          {{ data.telefone ?? '—' }}
        </template>
      </Column>
    </DataTable>
  </div>
</template>
