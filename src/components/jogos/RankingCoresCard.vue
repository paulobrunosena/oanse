<script setup lang="ts">
import { computed } from 'vue'
import Tag from 'primevue/tag'
import type { RankingCor } from '@/composables/useJogos'
import { corHex } from '@/utils/jogos'

const props = defineProps<{
  ranking: RankingCor[]
}>()

const medalhas = ['🥇', '🥈', '🥉', '4º']
const ordenado = computed(() =>
  [...props.ranking].sort((a, b) => a.posicao - b.posicao),
)
</script>

<template>
  <div class="rounded-lg border bg-[var(--surface-card)] p-4">
    <div class="flex items-center gap-2">
      <i class="pi pi-trophy text-primary" />
      <span class="font-semibold">Ranking das cores — placar final do sábado</span>
    </div>

    <div
      v-if="ordenado.length === 0"
      class="mt-4 text-sm text-surface-500"
    >
      Nenhuma cor participando neste evento.
    </div>

    <div
      v-else
      class="mt-4 flex flex-col gap-2"
    >
      <div
        v-for="(linha, i) in ordenado"
        :key="linha.cor"
        class="flex items-center justify-between gap-3 rounded-md border p-3"
      >
        <div class="flex items-center gap-3 min-w-0">
          <span class="text-xl w-8 shrink-0 text-center">
            {{ medalhas[i] ?? `${linha.posicao}º` }}
          </span>
          <span
            class="inline-block h-4 w-4 shrink-0 rounded-full border border-surface-300"
            :style="{ backgroundColor: corHex(linha.cor) }"
          />
          <span class="capitalize font-medium">{{ linha.cor }}</span>
        </div>
        <Tag severity="success">
          {{ linha.pontos }} pts
        </Tag>
      </div>
    </div>

    <p class="mt-3 text-xs text-surface-500">
      Somatória dos pontos de todas as rodadas lançadas. Anuncie o placar no
      final da programação.
    </p>
  </div>
</template>