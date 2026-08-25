<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import Button from 'primevue/button'
import Card from 'primevue/card'
import Dialog from 'primevue/dialog'
import InputText from 'primevue/inputtext'
import MultiSelect from 'primevue/multiselect'
import Select from 'primevue/select'
import Tag from 'primevue/tag'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/composables/useAuth'
import { useEncontro } from '@/composables/useEncontro'
import { useJogos, type OansistaOpcao } from '@/composables/useJogos'
import { useToast } from '@/composables/useToast'
import EncontroSeletor from '@/components/encontro/EncontroSeletor.vue'
import EventoJogosCard from '@/components/jogos/EventoJogosCard.vue'
import RodadasJogosCard, { type RodadaRegistro } from '@/components/jogos/RodadasJogosCard.vue'
import RankingCoresCard from '@/components/jogos/RankingCoresCard.vue'
import { CORES_PREDEFINIDAS, gerarNomeEvento, jogosDisponiveis, type PontosJogosConfig } from '@/utils/jogos'
import type { Database } from '@/types/database.types'

type Clube = Database['public']['Tables']['clubes']['Row']

const toast = useToast()
const { user } = useAuth()
const { encontro, encontros, carregando: carregandoEncontro, carregar: carregarEncontro, selecionar } = useEncontro()
const {
  eventos, evento, rodadas, catalogo, ranking, carregarEventos, carregarCatalogo, selecionarEvento,
  criarEvento, excluirEvento, adicionarCor, removerCor,
  adicionarOansista, removerOansista,
  adicionarRodada, excluirRodada, lancarResultado, removerResultado,
  finalizarEvento, reabrirEvento,
} = useJogos()

const clubes = ref<Clube[]>([])
const oansistas = ref<OansistaOpcao[]>([])
const pontosConfig = ref<PontosJogosConfig[]>([])
const carregandoInicial = ref(true)

const dialogAberto = ref(false)
const novoNome = ref('')
const novosClubes = ref<string[]>([])
const novasCores = ref<string[]>([])
const salvando = ref(false)

const dataFormatada = computed(() => {
  if (!encontro.value) return ''
  return new Date(`${encontro.value.data}T00:00:00`).toLocaleDateString('pt-BR', {
    weekday: 'long', day: 'numeric', month: 'long',
  })
})

/** Clubes que já participaram de algum evento no sábado — não podem repetir. */
const clubesUsados = computed(() => {
  const usados = new Set<string>()
  for (const ev of eventos.value) {
    for (const c of ev.clubes) usados.add(c.clube_id)
  }
  return usados
})

const clubesDisponiveis = computed(() =>
  clubes.value.filter(c => !clubesUsados.value.has(c.id)),
)

const opcoesClubes = computed(() => clubesDisponiveis.value.map(c => ({ label: c.nome, value: c.id })))

const opcoesEventos = computed(() =>
  eventos.value.map(ev => ({
    label: ev.status === 'finalizado' ? `${ev.nome} (finalizado)` : ev.nome,
    value: ev.id,
  })),
)

const opcoesNomes = computed(() =>
  jogosDisponiveis(catalogo.value, evento.value?.clubes.map(c => c.clube_id) ?? []),
)
const ultimoNome = computed(() => rodadas.value[rodadas.value.length - 1]?.nome ?? '')

/** Só oferece para adicionar as crianças dos clubes que participam do evento. */
const oansistasDoEvento = computed(() => {
  if (!evento.value) return []
  const ids = new Set(evento.value.clubes.map(c => c.clube_id))
  return oansistas.value.filter(o => ids.has(o.clube_id))
})

watch(novosClubes, (ids) => {
  const nomes = clubes.value.filter(c => ids.includes(c.id)).map(c => c.nome)
  novoNome.value = gerarNomeEvento(nomes)
})

async function carregarClubesEConfig() {
  const [rClubes, rConfig] = await Promise.all([
    supabase.from('clubes').select('*').order('ordem'),
    supabase.from('jogos_pontos_config').select('*'),
  ])
  clubes.value = rClubes.data ?? []
  pontosConfig.value = (rConfig.data ?? []) as PontosJogosConfig[]
}

type LinhaOansista = {
  id: string
  nome: string
  clube_id: string
  clubes: { nome: string, cor: string | null } | null
}

async function carregarOansistas() {
  const { data } = await supabase
    .from('oansistas')
    .select('id, nome, clube_id, clubes(nome, cor)')
    .eq('status', 'ativo')
    .order('nome')
  oansistas.value = ((data ?? []) as unknown as LinhaOansista[]).map(o => ({
    id: o.id,
    nome: o.nome,
    clube_id: o.clube_id,
    clube: o.clubes ? { nome: o.clubes.nome, cor: o.clubes.cor } : null,
  }))
}

async function carregarJogosDoEncontro() {
  if (!encontro.value) return
  await carregarEventos(encontro.value.id)
}

async function carregarTudo() {
  carregandoInicial.value = true
  await Promise.all([carregarClubesEConfig(), carregarCatalogo(), carregarOansistas()])
  await carregarEncontro()
  await carregarJogosDoEncontro()
  carregandoInicial.value = false
}

async function aoSelecionarEncontro(id: string) {
  selecionar(id)
  await carregarJogosDoEncontro()
}

function abrirNovoEvento() {
  novoNome.value = ''
  novosClubes.value = []
  novasCores.value = []
  dialogAberto.value = true
}

async function confirmarCriarEvento() {
  if (!novoNome.value.trim() || novosClubes.value.length === 0 || novasCores.value.length < 2 || !user.value?.sub) return
  salvando.value = true
  try {
    await criarEvento(novoNome.value.trim(), novosClubes.value, novasCores.value, user.value.sub)
    toast.add({ title: 'Evento de jogos criado', description: novoNome.value.trim(), color: 'success' })
    dialogAberto.value = false
  }
  catch (e) {
    toast.add({
      title: 'Erro ao criar evento',
      description: (e as { message?: string })?.message ?? 'Tente novamente',
      color: 'error',
    })
  }
  finally {
    salvando.value = false
  }
}

async function excluirEventoConfirmado() {
  if (!evento.value) return
  if (!window.confirm(`Excluir o evento "${evento.value.nome}"? Rodadas, pontos e cores serão removidos.`)) return
  try {
    await excluirEvento(evento.value.id)
    toast.add({ title: 'Evento excluído', color: 'info' })
    await carregarJogosDoEncontro()
  }
  catch (e) {
    toast.add({
      title: 'Erro ao excluir evento',
      description: (e as { message?: string })?.message ?? 'Tente novamente',
      color: 'error',
    })
  }
}

async function acaoComAtualizacao(acao: () => Promise<unknown>, mensagemSucesso?: string) {
  try {
    await acao()
    await carregarJogosDoEncontro()
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

async function registrarRodada(registro: RodadaRegistro) {
  if (!evento.value || !user.value?.sub) return
  try {
    const jogoId = await adicionarRodada(evento.value.id, registro.nome, user.value.sub)
    for (const r of registro.resultados) {
      await lancarResultado(jogoId, r.cor_id, { colocacao: r.colocacao, desclassificado: r.desclassificado })
    }
    await carregarJogosDoEncontro()
    toast.add({ title: 'Rodada registrada', description: registro.nome, color: 'success' })
  }
  catch (e) {
    toast.add({
      title: 'Erro ao registrar rodada',
      description: (e as { message?: string })?.message ?? 'Tente novamente',
      color: 'error',
    })
  }
}

async function excluirRodadaConfirmada(jogoId: string) {
  if (!window.confirm('Excluir esta rodada? Os pontos dela serão removidos.')) return
  await acaoComAtualizacao(() => excluirRodada(jogoId), 'Rodada excluída')
}

async function finalizar() {
  if (!evento.value) return
  if (!window.confirm('Finalizar os jogos do sábado? O placar das cores será fixado para o anúncio.')) return
  await acaoComAtualizacao(() => finalizarEvento(evento.value!.id), 'Jogos finalizados')
}

async function reabrir() {
  if (!evento.value) return
  await acaoComAtualizacao(() => reabrirEvento(evento.value!.id), 'Jogos reabertos')
}

onMounted(carregarTudo)
</script>

<template>
  <div class="p-4 sm:p-6 max-w-4xl mx-auto w-full">
    <div class="flex flex-col gap-3 mb-4 sm:flex-row sm:items-center sm:justify-between">
      <div>
        <h1 class="text-2xl font-bold">
          Jogos do sábado
        </h1>
        <p
          v-if="dataFormatada"
          class="text-sm text-surface-500 capitalize"
        >
          {{ dataFormatada }}
        </p>
      </div>
      <div class="flex flex-wrap items-center gap-3">
        <EncontroSeletor
          :encontros="encontros"
          :encontro="encontro"
          @selecionar="aoSelecionarEncontro"
        />
        <Button
          v-if="encontro && clubesDisponiveis.length > 0"
          icon="pi pi-plus"
          label="Novo evento"
          @click="abrirNovoEvento"
        />
      </div>
    </div>

    <div
      v-if="carregandoInicial || carregandoEncontro"
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
      v-else
      class="flex flex-col gap-4"
    >
      <Card
        v-if="eventos.length === 0"
        class="text-center py-6"
      >
        <template #content>
          <div class="flex flex-col items-center gap-3">
            <i class="pi pi-flag text-3xl text-surface-300" />
            <p class="text-surface-500">
              Nenhum evento de jogos criado neste sábado ainda.
            </p>
            <p class="text-sm text-surface-500">
              Cadastre uma única vez: clubes que vão jogar, cores participantes e quem fica em cada cor.
              Depois é só registrar o resultado de cada rodada.
            </p>
            <Button
              icon="pi pi-plus"
              label="Criar evento de jogos"
              @click="abrirNovoEvento"
            />
          </div>
        </template>
      </Card>

      <template v-else>
        <div class="flex items-center gap-3">
          <Select
            :model-value="evento?.id"
            :options="opcoesEventos"
            option-label="label"
            option-value="value"
            class="w-full sm:w-80"
            @update:model-value="selecionarEvento($event as string)"
          />
          <Tag
            v-if="evento"
            :severity="evento.status === 'finalizado' ? 'success' : 'info'"
            :value="evento.status === 'finalizado' ? 'Finalizado' : 'Em andamento'"
          />
        </div>
        <p class="text-xs text-surface-500">
          Cada clube participa de apenas um evento por sábado. Ao criar um novo
          evento, só aparecem os clubes que ainda não jogaram.
        </p>

        <div v-if="evento">
          <div class="mb-4">
            <EventoJogosCard
              :evento="evento"
              :oansistas="oansistasDoEvento"
              @adicionar-cor="cor => acaoComAtualizacao(() => adicionarCor(evento!.id, cor), 'Cor adicionada')"
              @remover-cor="corId => acaoComAtualizacao(() => removerCor(corId), 'Cor removida')"
              @adicionar-oansista="(corId, oansistaId) => acaoComAtualizacao(() => adicionarOansista(corId, oansistaId))"
              @remover-oansista="(corId, oansistaId) => acaoComAtualizacao(() => removerOansista(corId, oansistaId))"
              @finalizar="finalizar"
              @reabrir="reabrir"
              @excluir="excluirEventoConfirmado"
            />
          </div>

          <RodadasJogosCard
            v-if="evento.status === 'em_andamento'"
            :rodadas="rodadas"
            :cores="evento.cores"
            :opcoes-nomes="opcoesNomes"
            :pontos-config="pontosConfig"
            :nome-inicial="ultimoNome"
            @registrar="registrarRodada"
            @excluir-rodada="excluirRodadaConfirmada"
            @lancar-resultado="(jogoId, corId, resultado) => acaoComAtualizacao(() => lancarResultado(jogoId, corId, resultado))"
            @remover-resultado="(jogoId, corId) => acaoComAtualizacao(() => removerResultado(jogoId, corId))"
          />

          <RankingCoresCard
            :ranking="ranking"
          />

          <p
            v-if="evento.status === 'finalizado'"
            class="text-xs text-surface-500 text-center"
          >
            Evento finalizado. Para ajustar algo, clique em "Reabrir".
          </p>
        </div>

        <Card
          v-if="clubesDisponiveis.length === 0"
          class="text-center py-4"
        >
          <template #content>
            <p class="text-surface-500 text-sm">
              Todos os clubes já participaram de um evento de jogos neste sábado.
            </p>
          </template>
        </Card>
      </template>
    </div>

    <Dialog
      v-model:visible="dialogAberto"
      modal
      header="Novo evento de jogos"
      :style="{ width: '28rem' }"
    >
      <div class="flex flex-col gap-4 pt-2">
        <div class="flex flex-col gap-1">
          <label class="text-sm font-medium">Clubes que vão jogar</label>
          <MultiSelect
            v-model="novosClubes"
            :options="opcoesClubes"
            option-label="label"
            option-value="value"
            filter
            placeholder="Selecione os clubes"
            class="w-full"
          />
          <p class="text-xs text-surface-500">
            Só aparecem os clubes que ainda não jogaram neste sábado.
          </p>
        </div>
        <div class="flex flex-col gap-1">
          <label class="text-sm font-medium">Cores participantes</label>
          <MultiSelect
            v-model="novasCores"
            :options="CORES_PREDEFINIDAS.map(c => ({ label: c, value: c }))"
            option-label="label"
            option-value="value"
            placeholder="Verde, vermelho, amarelo ou azul"
            class="w-full"
          />
          <p class="text-xs text-surface-500">
            Mínimo 2 cores. As cores já vêm prontas — você só escolhe as que participam.
          </p>
        </div>
        <div class="flex flex-col gap-1">
          <label class="text-sm font-medium">Nome do evento</label>
          <InputText
            v-model="novoNome"
            placeholder="Ex.: Jogos dos Flamas e Tochas"
            class="w-full"
          />
          <p class="text-xs text-surface-500">
            Preenchido automaticamente pelos clubes — edite se quiser.
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
            label="Criar evento"
            :loading="salvando"
            :disabled="!novoNome.trim() || novosClubes.length === 0 || novasCores.length < 2"
            @click="confirmarCriarEvento"
          />
        </div>
      </div>
    </Dialog>
  </div>
</template>