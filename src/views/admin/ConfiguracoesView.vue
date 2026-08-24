<script setup lang="ts">
import { onMounted, ref } from 'vue'
import Button from 'primevue/button'
import Card from 'primevue/card'
import Column from 'primevue/column'
import DataTable from 'primevue/datatable'
import InputNumber from 'primevue/inputnumber'
import { supabase } from '@/lib/supabase'
import { useToast } from '@/composables/useToast'
import type { Database } from '@/types/database.types'

type ItemPontuacao = Database['public']['Tables']['itens_pontuacao']['Row']
type PontosConfig = Database['public']['Tables']['jogos_pontos_config']['Row']

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
        <p class="text-sm text-surface-500">
          Pontuação da Folha Semanal e dos jogos
        </p>
      </div>
      <Button
        icon="pi pi-save"
        label="Salvar"
        :loading="salvando"
        @click="salvarTudo"
      />
    </div>

    <Card class="mb-6">
      <template #title>
        <span class="font-semibold">Itens de pontuação (Folha Semanal)</span>
      </template>
      <template #content>
        <DataTable
          v-if="!carregando"
          :value="itens"
          data-key="chave"
          class="w-full"
        >
          <Column field="descricao" header="Item" />
          <Column field="pontos" header="Pontos">
            <template #body="{ data }">
              <InputNumber
                v-model="(data as any).pontos"
                :min="0"
                :max="100"
                class="w-28"
              />
            </template>
          </Column>
        </DataTable>
      </template>
    </Card>

    <Card>
      <template #title>
        <span class="font-semibold">Pontos dos jogos por colocação</span>
      </template>
      <template #content>
        <DataTable
          v-if="!carregando"
          :value="configJogos"
          data-key="colocacao"
          class="w-full"
        >
          <Column field="colocacao" header="Colocação">
            <template #body="{ data }">
              {{ data.colocacao }}º lugar
            </template>
          </Column>
          <Column field="pontos" header="Pontos">
            <template #body="{ data }">
              <InputNumber
                v-model="(data as any).pontos"
                :min="0"
                :max="500"
                class="w-28"
              />
            </template>
          </Column>
        </DataTable>
        <p class="text-xs text-surface-500 mt-2">
          Times desclassificados recebem 0 pontos.
        </p>
      </template>
    </Card>
  </div>
</template>
