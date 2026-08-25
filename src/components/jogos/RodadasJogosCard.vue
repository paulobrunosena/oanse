<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import Button from 'primevue/button'
import Select from 'primevue/select'
import Tag from 'primevue/tag'
import type { EventoCor, RodadaJogo } from '@/composables/useJogos'
import { corHex, pontosDaColocacao, type PontosJogosConfig } from '@/utils/jogos'

export interface RodadaResultadoInput {
  cor_id: string
  colocacao: number | null
  desclassificado: boolean
}

export interface RodadaRegistro {
  nome: string
  resultados: RodadaResultadoInput[]
}

const props = withDefaults(defineProps<{
  rodadas: RodadaJogo[]
  cores: EventoCor[]
  opcoesNomes: string[]
  pontosConfig?: PontosJogosConfig[]
  nomeInicial?: string
}>(), {
  pontosConfig: () => [],
  nomeInicial: '',
})

const emit = defineEmits<{
  registrar: [registro: RodadaRegistro]
  'excluir-rodada': [jogoId: string]
  'lancar-resultado': [jogoId: string, corId: string, resultado: { colocacao: number | null, desclassificado: boolean }]
  'remover-resultado': [jogoId: string, corId: string]
}>()

const nomeRodada = ref(props.nomeInicial)
const placarRodada = reactive<Record<string, string>>({})

watch(() => props.nomeInicial, (nome) => {
  nomeRodada.value = nome
  for (const key of Object.keys(placarRodada)) delete placarRodada[key]
})

const placarOpcoes = computed(() => [
  { label: 'Não jogou', value: '' },
  ...Array.from({ length: props.cores.length }, (_, i) => ({
    label: `${i + 1}º lugar (${pontosDaColocacao(i + 1, props.pontosConfig)} pts)`,
    value: String(i + 1),
  })),
  { label: 'Desclassificado (0 pts)', value: 'desc' },
])

function registrar() {
  const resultados: RodadaResultadoInput[] = Object.entries(placarRodada)
    .filter(([, valor]) => valor !== '' && valor != null)
    .map(([corId, valor]) => ({
      cor_id: corId,
      colocacao: valor === 'desc' ? null : Number(valor),
      desclassificado: valor === 'desc',
    }))
  emit('registrar', { nome: nomeRodada.value.trim(), resultados })
  for (const key of Object.keys(placarRodada)) delete placarRodada[key]
}

function resultadoDaCor(rodada: RodadaJogo, corId: string) {
  return rodada.resultados.find(r => r.cor_id === corId)
}

function valorDoPlacar(rodada: RodadaJogo, corId: string): string {
  const r = resultadoDaCor(rodada, corId)
  if (!r) return ''
  if (r.desclassificado) return 'desc'
  if (r.colocacao == null) return ''
  return String(r.colocacao)
}

function aoDefinirPlacar(rodada: RodadaJogo, corId: string, valor: string) {
  if (valor === '' || valor == null) {
    emit('remover-resultado', rodada.id, corId)
    return
  }
  emit('lancar-resultado', rodada.id, corId, {
    colocacao: valor === 'desc' ? null : Number(valor),
    desclassificado: valor === 'desc',
  })
}
</script>

<template>
  <div class="rounded-lg border bg-[var(--surface-card)] p-4">
    <div class="flex items-center justify-between gap-3">
      <span class="font-semibold">Registrar resultado da rodada</span>
      <Tag severity="info">
        {{ rodadas.length }} rodada(s) lançada(s)
      </Tag>
    </div>

    <div class="mt-4 flex flex-col gap-4">
      <div class="flex flex-col gap-1">
        <label class="text-sm font-medium">Jogo / atividade</label>
        <Select
          v-model="nomeRodada"
          :options="opcoesNomes"
          filter
          placeholder="Selecione o jogo"
          class="w-full"
        />
        <p class="text-xs text-surface-500">
          Já vem preenchido com o último jogo lançado — basta confirmar e marcar as colocações.
        </p>
      </div>

      <div class="flex flex-col gap-3">
        <label class="text-sm font-medium">Colocações das cores</label>
        <div
          v-for="cor in cores"
          :key="cor.id"
          class="flex items-center justify-between gap-2 rounded-md border p-3"
        >
          <div class="flex items-center gap-2 min-w-0">
            <span
              class="inline-block h-4 w-4 shrink-0 rounded-full border border-surface-300"
              :style="{ backgroundColor: corHex(cor.cor) }"
            />
            <span class="capitalize text-sm">{{ cor.cor }}</span>
          </div>
          <Select
            v-model="placarRodada[cor.id]"
            :options="placarOpcoes"
            option-label="label"
            option-value="value"
            size="small"
            class="w-44"
          />
        </div>
      </div>

      <Button
        icon="pi pi-check"
        label="Registrar rodada"
        :disabled="!nomeRodada.trim()"
        class="w-full sm:w-auto self-end"
        @click="registrar"
      />
    </div>

    <div
      v-if="rodadas.length"
      class="mt-6 flex flex-col gap-3"
    >
      <span class="text-sm font-semibold">Rodadas lançadas</span>
      <div
        v-for="rodada in rodadas"
        :key="rodada.id"
        class="rounded-md border p-3"
      >
        <div class="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
          <span class="truncate font-medium text-sm">{{ rodada.nome }}</span>
          <div class="flex flex-wrap items-center gap-1.5 shrink-0">
            <div
              v-for="cor in cores"
              :key="cor.id"
              class="flex items-center gap-1"
            >
              <span
                class="inline-block h-3 w-3 shrink-0 rounded-full border border-surface-300"
                :style="{ backgroundColor: corHex(cor.cor) }"
              />
              <Select
                :model-value="valorDoPlacar(rodada, cor.id)"
                :options="placarOpcoes"
                option-label="label"
                option-value="value"
                size="small"
                class="w-28 sm:w-32"
                @update:model-value="valor => aoDefinirPlacar(rodada, cor.id, valor as string)"
              />
            </div>
            <Button
              icon="pi pi-trash"
              severity="danger"
              text
              size="small"
              title="Excluir rodada"
              @click="$emit('excluir-rodada', rodada.id)"
            />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>