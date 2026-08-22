<script setup lang="ts">
import type { TableColumn } from '@nuxt/ui'
import type { Database } from '~/types/database.types'

type Profile = Database['public']['Tables']['profiles']['Row']

definePageMeta({ middleware: ['role'], roles: ['diretor_geral', 'diretor_clube'] })
useSeoMeta({ title: 'Líderes — Oanse' })

const { profile } = useAuth()
const supabase = useSupabaseClient()

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

const colunas: TableColumn<Profile & { turma_nome: string | null }>[] = [
  { accessorKey: 'nome', header: 'Nome' },
  {
    accessorKey: 'turma_nome',
    header: 'Turma',
    cell: ({ row }) => row.original.turma_nome ?? 'Sem turma',
  },
  {
    accessorKey: 'telefone',
    header: 'Contato',
    cell: ({ row }) => row.original.telefone ?? '—',
  },
]
</script>

<template>
  <div class="p-4 sm:p-6 max-w-4xl mx-auto w-full">
    <div class="mb-4">
      <h1 class="text-2xl font-bold">
        Líderes
      </h1>
      <p class="text-sm text-muted">
        Equipe de líderes do clube
      </p>
    </div>

    <UTable
      :data="lideres"
      :columns="colunas"
      :loading="carregando"
    >
      <template #turma_nome-cell="{ row }">
        <UBadge
          v-if="row.original.turma_nome"
          color="primary"
          variant="subtle"
        >
          {{ row.original.turma_nome }}
        </UBadge>
        <span
          v-else
          class="text-muted"
        >Sem turma</span>
      </template>
    </UTable>
  </div>
</template>
