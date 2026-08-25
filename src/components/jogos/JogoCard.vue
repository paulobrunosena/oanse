<script setup lang="ts">
import { computed, ref } from 'vue'
import Avatar from 'primevue/avatar'
import Button from 'primevue/button'
import InputText from 'primevue/inputtext'
import Select from 'primevue/select'
import Tag from 'primevue/tag'
import type { Jogo, JogoTime } from '@/composables/useJogos'
import { podeAdicionarTime, pontosDoResultado, type PontosJogosConfig } from '@/utils/jogos'

export interface OansistaOpcao {
  id: string
  nome: string
}

export type ResultadoPlacar = {
  colocacao: number | null
  desclassificado: boolean
}

const props = withDefaults(defineProps<{
  jogo: Jogo
  oansistas?: OansistaOpcao[]
  pontosConfig?: PontosJogosConfig[]
}>(), {
  oansistas: () => [],
  pontosConfig: () => [],
})

const emit = defineEmits<{
  'criar-time': [jogoId: string, nome: string, cor: string | null]
  'excluir-jogo': [jogoId: string]
  'excluir-time': [jogoId: string, timeId: string]
  'adicionar-integrante': [jogoId: string, timeId: string, oansistaId: string]
  'remover-integrante': [jogoId: string, timeId: string, oansistaId: string]
  'lancar-resultado': [jogoId: string, timeId: string, resultado: ResultadoPlacar]
  'remover-resultado': [jogoId: string, timeId: string]
}>()

const novoTimeNome = ref('')
const novoTimeCor = ref('')
const integrantePorTime = ref<Record<string, string>>({})

const podeAdicionar = computed(() => podeAdicionarTime(props.jogo.times.length))

const disponiveis = computed<OansistaOpcao[]>(() => {
  const usados = new Set(props.jogo.times.flatMap(t => t.integrantes.map(i => i.oansista_id)))
  return props.oansistas.filter(o => !usados.has(o.id))
})

const placarOpcoes = computed(() => [
  { label: 'Sem resultado', value: 'sem' },
  ...props.pontosConfig
    .slice()
    .sort((a, b) => a.colocacao - b.colocacao)
    .map(c => ({ label: `${c.colocacao}º lugar (${c.pontos} pts)`, value: String(c.colocacao) })),
  { label: 'Desclassificado (0 pts)', value: 'desc' },
])

function valorDoPlacar(time: JogoTime): string {
  const r = time.resultado
  if (!r) return 'sem'
  if (r.desclassificado) return 'desc'
  if (r.colocacao == null) return 'sem'
  return String(r.colocacao)
}

function aoDefinirPlacar(time: JogoTime, valor: string) {
  if (valor === 'sem') {
    emit('remover-resultado', props.jogo.id, time.id)
    return
  }
  if (valor === 'desc') {
    emit('lancar-resultado', props.jogo.id, time.id, { colocacao: null, desclassificado: true })
    return
  }
  emit('lancar-resultado', props.jogo.id, time.id, { colocacao: Number(valor), desclassificado: false })
}

function pontosDoTime(time: JogoTime): number {
  return time.resultado ? pontosDoResultado(time.resultado, props.pontosConfig) : 0
}

function adicionarTime() {
  const nome = novoTimeNome.value.trim()
  if (!nome) return
  emit('criar-time', props.jogo.id, nome, novoTimeCor.value.trim() || null)
  novoTimeNome.value = ''
  novoTimeCor.value = ''
}

function aoSelecionarIntegrante(timeId: string) {
  const oansistaId = integrantePorTime.value[timeId]
  if (!oansistaId) return
  emit('adicionar-integrante', props.jogo.id, timeId, oansistaId)
  integrantePorTime.value[timeId] = ''
}
</script>

<template>
  <div class="rounded-lg border bg-[var(--surface-card)] p-4">
    <div class="flex items-start justify-between gap-3">
      <div class="min-w-0">
        <div class="flex items-center gap-2 flex-wrap">
          <span class="font-semibold">{{ jogo.nome }}</span>
          <Tag
            v-for="clube in jogo.clubes"
            :key="clube.clube_id"
            :value="clube.nome"
            :style="{ background: `${clube.cor ?? '#64748b'}20`, color: clube.cor ?? '#64748b' }"
          />
        </div>
        <p class="text-xs text-surface-500 mt-1">
          {{ jogo.times.length }} time(s) · placar lançado
          {{ jogo.times.some(t => t.resultado) ? 'em parte' : 'ainda não' }}
        </p>
      </div>
      <Button
        icon="pi pi-trash"
        severity="danger"
        text
        size="small"
        title="Excluir jogo"
        @click="$emit('excluir-jogo', jogo.id)"
      />
    </div>

    <div class="mt-4 flex flex-col gap-3">
      <div
        v-for="time in jogo.times"
        :key="time.id"
        class="rounded-md border p-3"
      >
        <div class="flex items-center justify-between gap-2">
          <div class="flex items-center gap-2 min-w-0">
            <span
              v-if="time.cor"
              class="inline-block h-4 w-4 shrink-0 rounded-full border border-surface-300"
              :style="{ backgroundColor: time.cor }"
            />
            <span class="truncate font-medium text-sm">{{ time.nome }}</span>
            <Tag
              severity="success"
              class="shrink-0"
            >
              {{ pontosDoTime(time) }} pts
            </Tag>
          </div>
          <div class="flex items-center gap-2 shrink-0">
            <Select
              :model-value="valorDoPlacar(time)"
              :options="placarOpcoes"
              option-label="label"
              option-value="value"
              size="small"
              class="w-44"
              @update:model-value="valor => aoDefinirPlacar(time, valor as string)"
            />
            <Button
              icon="pi pi-times"
              severity="danger"
              text
              size="small"
              title="Remover time"
              @click="$emit('excluir-time', jogo.id, time.id)"
            />
          </div>
        </div>

        <div class="mt-3 flex flex-col gap-2">
          <div class="flex items-center gap-2">
            <span class="text-xs text-surface-500 w-16 shrink-0">Integrantes</span>
            <div class="flex flex-wrap gap-2">
              <Tag
                v-for="i in time.integrantes"
                :key="i.oansista_id"
                :value="i.nome"
                rounded
                removable
                @remove="$emit('remover-integrante', jogo.id, time.id, i.oansista_id)"
              />
              <span
                v-if="time.integrantes.length === 0"
                class="text-xs text-surface-500"
              >
                Nenhuma criança no time ainda.
              </span>
            </div>
          </div>
          <div class="flex items-center gap-2">
            <span class="text-xs text-surface-500 w-16 shrink-0">Adicionar</span>
            <Select
              v-model="integrantePorTime[time.id]"
              :options="disponiveis"
              option-label="nome"
              option-value="id"
              filter
              show-clear
              placeholder="Buscar criança"
              size="small"
              class="w-full max-w-xs"
              @update:model-value="aoSelecionarIntegrante(time.id)"
            />
          </div>
        </div>
      </div>

      <div
        v-if="jogo.times.length === 0"
        class="text-center py-6 text-surface-500 text-sm rounded-md border border-dashed"
      >
        Nenhum time ainda. Crie ao menos 2 times para lançar o placar.
      </div>

      <div
        v-if="podeAdicionar"
        class="flex flex-col sm:flex-row items-stretch gap-2"
      >
        <InputText
          v-model="novoTimeNome"
          placeholder="Nome do time"
          class="sm:flex-1"
        />
        <InputText
          v-model="novoTimeCor"
          placeholder="Cor (ex.: azul)"
          class="sm:flex-1"
        />
        <Button
          icon="pi pi-plus"
          label="Adicionar time"
          :disabled="!novoTimeNome.trim()"
          size="small"
          @click="adicionarTime"
        />
      </div>
      <p
        v-else
        class="text-xs text-surface-500"
      >
        Máximo de 4 times por jogo.
      </p>
    </div>

    <div class="mt-3 flex items-center gap-2 text-xs text-surface-500">
      <Avatar
        icon="pi pi-info-circle"
        size="xsmall"
        shape="circle"
      />
      <span>
        O placar atualiza automaticamente os pontos das folhas das crianças dos
        times (e a cor do time no sábado).
      </span>
    </div>
  </div>
</template>