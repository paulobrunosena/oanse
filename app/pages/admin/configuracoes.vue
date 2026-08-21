<script setup lang="ts">
import type { TableColumn } from '@nuxt/ui'
import type { Database } from '~/types/database.types'

type ItemPontuacao = Database['public']['Tables']['itens_pontuacao']['Row']
type PontosConfig = Database['public']['Tables']['jogos_pontos_config']['Row']

definePageMeta({ middleware: ['role'], roles: ['diretor_geral'] })
useSeoMeta({ title: 'Configurações — Oanse' })

const supabase = useSupabaseClient()
const toast = useToast()

const itens = ref<ItemPontuacao[]>([])
const configJogos = ref<PontosConfig[]>([])
const carregando = ref(true)
const salvando = ref(false)

async function carregar() {
  carregando.value = true
  const [it, cfg] = await Promise.all([
    supabase.from('itens_pontuacao').select('*').order('pontos', { ascending: false }),
    supabase.from('jogos_pontos_config').select('*').order('colocacao'),
  ])
  itens.value = it.data ?? []
  configJogos.value = cfg.data ?? []
  carregando.value = false
}

onMounted(carregar)

const colunasItens: TableColumn<ItemPontuacao>[] = [
  { accessorKey: 'descricao', header: 'Item' },
  { accessorKey: 'pontos', header: 'Pontos' },
]

const colunasJogos: TableColumn<PontosConfig>[] = [
  { accessorKey: 'colocacao', header: 'Colocação', cell: ({ row }) => `${row.original.colocacao}º lugar` },
  { accessorKey: 'pontos', header: 'Pontos' },
]

async function salvarTudo() {
  salvando.value = true
  try {
    for (const item of itens.value) {
      const { error } = await supabase
        .from('itens_pontuacao')
        .update({ pontos: item.pontos, descricao: item.descricao })
        .eq('chave', item.chave)
      if (error) throw error
    }
    for (const cfg of configJogos.value) {
      const { error } = await supabase
        .from('jogos_pontos_config')
        .update({ pontos: cfg.pontos })
        .eq('colocacao', cfg.colocacao)
      if (error) throw error
    }
    toast.add({ title: 'Configurações salvas', color: 'success' })
  }
  catch (e) {
    toast.add({ title: 'Erro ao salvar', description: e instanceof Error ? e.message : undefined, color: 'error' })
  }
  finally {
    salvando.value = false
  }
}
</script>

<template>
  <div class="p-4 sm:p-6 max-w-3xl mx-auto w-full">
    <div class="flex items-center justify-between mb-4">
      <div>
        <h1 class="text-2xl font-bold">
          Configurações
        </h1>
        <p class="text-sm text-muted">
          Pontuação da Folha Semanal e dos jogos
        </p>
      </div>
      <UButton
        icon="i-lucide-save"
        :loading="salvando"
        @click="salvarTudo"
      >
        Salvar
      </UButton>
    </div>

    <UCard class="mb-6">
      <template #header>
        <span class="font-semibold">Itens de pontuação (Folha Semanal)</span>
      </template>
      <UTable
        v-if="!carregando"
        :data="itens"
        :columns="colunasItens"
      >
        <template #pontos-cell="{ row }">
          <UInputNumber
            v-model="(row.original as any).pontos"
            :min="0"
            :max="100"
            class="w-28"
          />
        </template>
      </UTable>
    </UCard>

    <UCard>
      <template #header>
        <span class="font-semibold">Pontos dos jogos por colocação</span>
      </template>
      <UTable
        v-if="!carregando"
        :data="configJogos"
        :columns="colunasJogos"
      >
        <template #pontos-cell="{ row }">
          <UInputNumber
            v-model="(row.original as any).pontos"
            :min="0"
            :max="500"
            class="w-28"
          />
        </template>
      </UTable>
      <p class="text-xs text-muted mt-2">
        Times desclassificados recebem 0 pontos.
      </p>
    </UCard>
  </div>
</template>
