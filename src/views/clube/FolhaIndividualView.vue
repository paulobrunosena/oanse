<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/composables/useAuth'
import { useFolhaIndividual } from '@/composables/useFolhaIndividual'
import { useToast } from '@/composables/useToast'
import FolhaIndividualManual from '@/components/folha/FolhaIndividualManual.vue'
import FolhaIndividualSeletor from '@/components/folha/FolhaIndividualSeletor.vue'

const toast = useToast()
const { user, profile } = useAuth()
const {
  folha, carregando, carregandoProgresso,
  carregar, carregarProgresso, salvarItem, salvarObservacao,
} = useFolhaIndividual()

const oansistas = ref<{ id: string, nome: string }[]>([])
const oansistaId = ref<string | null>(null)
const abaAtiva = ref<string>('')
const salvandoItem = ref<string | null>(null)
const salvandoObservacao = ref(false)
const carregandoInicial = ref(true)

const clubeId = computed(() => profile.value?.clube_id ?? null)
const isLider = computed(() => profile.value?.role === 'lider')

watch(folha, (manuais) => {
  if (!manuais.length) {
    abaAtiva.value = ''
    return
  }
  if (!manuais.some(m => m.id === abaAtiva.value)) abaAtiva.value = manuais[0]!.id
})

function mensagem(e: unknown): string {
  return (e as { message?: string })?.message ?? 'Tente novamente'
}

async function carregarTurmaDoLider(): Promise<string | null> {
  if (!user.value?.sub) return null
  const { data } = await supabase
    .from('turmas')
    .select('id')
    .eq('lider_id', user.value.sub)
    .eq('ativo', true)
    .maybeSingle()
  return data?.id ?? null
}

async function carregarOansistas() {
  oansistas.value = []
  if (!clubeId.value) return
  if (isLider.value) {
    const turmaId = await carregarTurmaDoLider()
    if (!turmaId) return
    const { data } = await supabase
      .from('oansistas')
      .select('id, nome')
      .eq('turma_id', turmaId)
      .eq('status', 'ativo')
      .order('nome')
    oansistas.value = data ?? []
    return
  }
  const { data } = await supabase
    .from('oansistas')
    .select('id, nome')
    .eq('clube_id', clubeId.value)
    .eq('status', 'ativo')
    .order('nome')
  oansistas.value = data ?? []
}

async function selecionar(id: string) {
  oansistaId.value = id
  await carregarProgresso(id)
}

async function carregarTudo() {
  carregandoInicial.value = true
  if (clubeId.value) {
    await Promise.all([carregar(clubeId.value), carregarOansistas()])
    if (oansistas.value.length > 0) await selecionar(oansistas.value[0]!.id)
  }
  carregandoInicial.value = false
}

async function onSalvarItem(blocoId: string, itemNum: number, data: string | null) {
  if (!oansistaId.value || !user.value?.sub) return
  salvandoItem.value = `${blocoId}:${itemNum}`
  try {
    await salvarItem(oansistaId.value, blocoId, itemNum, data, user.value.sub)
  }
  catch (e) {
    toast.add({ title: 'Erro ao salvar item da folha', description: mensagem(e), color: 'error' })
  }
  finally {
    salvandoItem.value = null
  }
}

async function onSalvarObservacao(manualId: string, texto: string) {
  if (!oansistaId.value) return
  salvandoObservacao.value = true
  try {
    await salvarObservacao(oansistaId.value, manualId, texto)
    toast.add({ title: 'Observações salvas', color: 'success' })
  }
  catch (e) {
    toast.add({ title: 'Erro ao salvar observações', description: mensagem(e), color: 'error' })
  }
  finally {
    salvandoObservacao.value = false
  }
}

onMounted(carregarTudo)
</script>

<template>
  <div class="p-4 sm:p-6 max-w-5xl mx-auto w-full">
    <div class="mb-4 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
      <div>
        <h1 class="text-2xl font-bold">
          Folha Individual
        </h1>
        <p class="text-sm text-surface-500">
          Progresso no manual, itens concluídos e prêmios por criança
        </p>
      </div>
      <FolhaIndividualSeletor
        v-if="oansistas.length > 0"
        :oansistas="oansistas"
        :oansista-id="oansistaId"
        @selecionar="selecionar"
      />
    </div>

    <div
      v-if="carregandoInicial || carregando || carregandoProgresso"
      class="flex justify-center py-10"
    >
      <i class="pi pi-spin pi-spinner text-2xl text-surface-400" />
    </div>

    <Card
      v-else-if="!clubeId"
      class="text-center py-6"
    >
      <template #content>
        <p class="text-surface-500">
          Você não está vinculado a um clube. Fale com o Diretor Geral.
        </p>
      </template>
    </Card>

    <Card
      v-else-if="folha.length === 0"
      class="text-center py-6"
    >
      <template #content>
        <p class="text-surface-500">
          Nenhum manual da Folha Individual cadastrado para este clube.
        </p>
      </template>
    </Card>

    <Card
      v-else-if="oansistas.length === 0"
      class="text-center py-6"
    >
      <template #content>
        <p class="text-surface-500">
          {{ isLider ? 'Nenhuma criança ativa na sua turma.' : 'Nenhuma criança ativa neste clube.' }}
        </p>
      </template>
    </Card>

    <Tabs
      v-else
      v-model:value="abaAtiva"
    >
      <TabList>
        <Tab
          v-for="manual in folha"
          :key="manual.id"
          :value="manual.id"
        >
          {{ manual.nome }}
        </Tab>
      </TabList>
      <TabPanels>
        <TabPanel
          v-for="manual in folha"
          :key="manual.id"
          :value="manual.id"
        >
          <FolhaIndividualManual
            :manual="manual"
            :salvando-item="salvandoItem"
            :salvando-observacao="salvandoObservacao"
            @salvar-item="onSalvarItem"
            @salvar-observacao="onSalvarObservacao"
          />
        </TabPanel>
      </TabPanels>
    </Tabs>
  </div>
</template>
