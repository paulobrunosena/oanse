<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import Button from 'primevue/button'
import Card from 'primevue/card'
import Dialog from 'primevue/dialog'
import InputText from 'primevue/inputtext'
import MultiSelect from 'primevue/multiselect'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/composables/useAuth'
import { useEncontro } from '@/composables/useEncontro'
import { useJogos, type Jogo } from '@/composables/useJogos'
import { useToast } from '@/composables/useToast'
import EncontroSeletor from '@/components/encontro/EncontroSeletor.vue'
import JogoCard, { type OansistaOpcao } from '@/components/jogos/JogoCard.vue'
import type { PontosJogosConfig } from '@/utils/jogos'
import type { Database } from '@/types/database.types'

type Clube = Database['public']['Tables']['clubes']['Row']

const toast = useToast()
const { user } = useAuth()
const { encontro, encontros, carregando: carregandoEncontro, carregar: carregarEncontro, selecionar } = useEncontro()
const {
  jogos, carregando, carregar, criarJogo, excluirJogo, criarTime,
  adicionarIntegrante, removerIntegrante, excluirTime, lancarResultado, removerResultado,
} = useJogos()

const clubes = ref<Clube[]>([])
const oansistas = ref<OansistaOpcao[]>([])
const pontosConfig = ref<PontosJogosConfig[]>([])
const carregandoInicial = ref(true)

const dialogAberto = ref(false)
const novoNome = ref('')
const novosClubes = ref<string[]>([])
const salvando = ref(false)

const dataFormatada = computed(() => {
  if (!encontro.value) return ''
  return new Date(`${encontro.value.data}T00:00:00`).toLocaleDateString('pt-BR', {
    weekday: 'long', day: 'numeric', month: 'long',
  })
})

const opcoesClubes = computed(() => clubes.value.map(c => ({ label: c.nome, value: c.id })))

async function carregarClubesEConfig() {
  const [rClubes, rConfig] = await Promise.all([
    supabase.from('clubes').select('*').order('ordem'),
    supabase.from('jogos_pontos_config').select('*'),
  ])
  clubes.value = rClubes.data ?? []
  pontosConfig.value = (rConfig.data ?? []) as PontosJogosConfig[]
}

async function carregarOansistas() {
  const ids = [...new Set(jogos.value.flatMap(j => j.clubes.map(c => c.clube_id)))]
  if (ids.length === 0) {
    oansistas.value = []
    return
  }
  const { data } = await supabase
    .from('oansistas')
    .select('id, nome')
    .in('clube_id', ids)
    .eq('status', 'ativo')
    .order('nome')
  oansistas.value = (data ?? []).map(o => ({ id: o.id, nome: o.nome }))
}

async function carregarTudo() {
  carregandoInicial.value = true
  await carregarClubesEConfig()
  await carregarEncontro()
  if (encontro.value) await carregar(encontro.value.id)
  await carregarOansistas()
  carregandoInicial.value = false
}

async function aoSelecionarEncontro(id: string) {
  selecionar(id)
  if (encontro.value) await carregar(encontro.value.id)
  await carregarOansistas()
}

function abrirNovoJogo() {
  novoNome.value = ''
  novosClubes.value = []
  dialogAberto.value = true
}

async function confirmarCriarJogo() {
  if (!novoNome.value.trim() || novosClubes.value.length === 0 || !user.value?.sub) return
  salvando.value = true
  try {
    await criarJogo(novoNome.value.trim(), novosClubes.value, user.value.sub)
    await carregarOansistas()
    toast.add({ title: 'Jogo criado', description: novoNome.value.trim(), color: 'success' })
    dialogAberto.value = false
  }
  catch (e) {
    toast.add({
      title: 'Erro ao criar jogo',
      description: (e as { message?: string })?.message ?? 'Tente novamente',
      color: 'error',
    })
  }
  finally {
    salvando.value = false
  }
}

async function excluirJogoConfirmado(jogoId: string) {
  const jogo = jogos.value.find(j => j.id === jogoId)
  if (!jogo) return
  if (!window.confirm(`Excluir o jogo "${jogo.nome}"? Os times e pontos serão removidos.`)) return
  try {
    await excluirJogo(jogo.id)
    await carregarOansistas()
    toast.add({ title: 'Jogo excluído', color: 'info' })
  }
  catch (e) {
    toast.add({
      title: 'Erro ao excluir jogo',
      description: (e as { message?: string })?.message ?? 'Tente novamente',
      color: 'error',
    })
  }
}

async function acaoComAtualizacao(acao: () => Promise<unknown>, mensagemSucesso?: string) {
  try {
    await acao()
    await carregar(encontro.value?.id ?? '')
    await carregarOansistas()
    if (mensagemSucesso) toast.add({ title: mensagemSucesso, color: 'success' })
  }
  catch (e) {
    toast.add({
      title: 'Erro na operação',
      description: (e as { message?: string })?.message ?? 'Tente novamente',
      color: 'error',
    })
  }
}

onMounted(carregarTudo)
</script>

<template>
  <div class="p-4 sm:p-6 max-w-5xl mx-auto w-full">
    <div class="flex items-center justify-between gap-3 mb-4">
      <div>
        <h1 class="text-2xl font-bold">
          Jogos
        </h1>
        <p
          v-if="dataFormatada"
          class="text-sm text-surface-500 capitalize"
        >
          {{ dataFormatada }}
        </p>
      </div>
      <div class="flex items-center gap-3">
        <EncontroSeletor
          :encontros="encontros"
          :encontro="encontro"
          @selecionar="aoSelecionarEncontro"
        />
        <Button
          icon="pi pi-plus"
          label="Novo jogo"
          :disabled="!encontro"
          @click="abrirNovoJogo"
        />
      </div>
    </div>

    <div
      v-if="carregandoInicial || carregandoEncontro || carregando"
      class="flex justify-center py-10"
    >
      <i class="pi pi-spin pi-spinner text-2xl text-surface-400" />
    </div>

    <Card
      v-else-if="!encontro"
      class="text-center py-6"
    >
      <template #content>
        <p class="text-surface-500">
          Selecione um sábado para gerenciar os jogos.
        </p>
      </template>
    </Card>

    <div
      v-else-if="jogos.length === 0"
      class="text-center py-10 text-surface-500"
    >
      <i class="pi pi-flag text-3xl mb-2 block text-surface-300" />
      <p>Nenhum jogo criado neste sábado ainda.</p>
      <p class="text-sm mt-1">
        Crie um jogo marcando 1 a 4 clubes participantes (qualquer combinação).
      </p>
    </div>

    <div
      v-else
      class="flex flex-col gap-4"
    >
      <div
        v-for="jogo in jogos"
        :key="jogo.id"
      >
        <JogoCard
          :jogo="jogo"
          :oansistas="oansistas"
          :pontos-config="pontosConfig"
          @criar-time="(jogoId, nome, cor) => acaoComAtualizacao(() => criarTime(jogoId, nome, cor))"
          @excluir-jogo="excluirJogoConfirmado"
          @excluir-time="(jogoId, timeId) => acaoComAtualizacao(() => excluirTime(timeId), 'Time removido')"
          @adicionar-integrante="(jogoId, timeId, oansistaId) => acaoComAtualizacao(() => adicionarIntegrante(timeId, oansistaId))"
          @remover-integrante="(jogoId, timeId, oansistaId) => acaoComAtualizacao(() => removerIntegrante(timeId, oansistaId))"
          @lancar-resultado="(jogoId, timeId, resultado) => acaoComAtualizacao(() => lancarResultado(jogoId, timeId, resultado))"
          @remover-resultado="(jogoId, timeId) => acaoComAtualizacao(() => removerResultado(timeId))"
        />
      </div>
    </div>

    <Dialog
      v-model:visible="dialogAberto"
      modal
      header="Novo jogo"
      :style="{ width: '26rem' }"
    >
      <div class="flex flex-col gap-4 pt-2">
        <div class="flex flex-col gap-1">
          <label class="text-sm font-medium">Nome do jogo</label>
          <InputText
            v-model="novoNome"
            placeholder="Ex.: Corrida de obstáculos"
            class="w-full"
          />
        </div>
        <div class="flex flex-col gap-1">
          <label class="text-sm font-medium">Clubes participantes</label>
          <MultiSelect
            v-model="novosClubes"
            :options="opcoesClubes"
            option-label="label"
            option-value="value"
            filter
            placeholder="Selecione 1 a 4 clubes"
            class="w-full"
          />
          <p class="text-xs text-surface-500">
            Mínimo 1, máximo os 4 clubes. Ex.: Flamas + Tochas jogam juntos.
          </p>
        </div>
        <div class="flex justify-end gap-2">
          <Button
            label="Cancelar"
            severity="secondary"
            text
            @click="dialogAberto = false"
          />
          <Button
            label="Criar"
            :loading="salvando"
            :disabled="!novoNome.trim() || novosClubes.length === 0"
            @click="confirmarCriarJogo"
          />
        </div>
      </div>
    </Dialog>
  </div>
</template>