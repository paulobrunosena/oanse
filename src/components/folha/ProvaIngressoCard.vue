<script setup lang="ts">
import type { Database } from '@/types/database.types'

type LicaoRow = Database['public']['Tables']['prova_ingresso_licoes']['Row']

const props = defineProps<{
  licoes: LicaoRow[]
  salvando?: number | null
}>()

const emit = defineEmits<{
  'salvar-licao': [licao: number, dataConclusao: string | null]
}>()

const TOTAL_LICOES = 10
const NUMEROS = Array.from({ length: TOTAL_LICOES }, (_, i) => i + 1)

function licaoDe(numero: number): LicaoRow | undefined {
  return props.licoes.find(l => l.licao === numero)
}

function aoMudar(numero: number, valor: string) {
  emit('salvar-licao', numero, valor || null)
}
</script>

<template>
  <ul class="grid grid-cols-1 gap-2 sm:grid-cols-2">
    <li
      v-for="numero in NUMEROS"
      :key="numero"
      class="flex items-center justify-between gap-2"
    >
      <span class="flex min-w-0 items-center gap-2">
        <span
          class="flex h-6 w-6 shrink-0 items-center justify-center rounded-full border text-xs font-semibold"
          :class="licaoDe(numero)?.data_conclusao
            ? 'border-primary bg-primary text-primary-contrast'
            : 'border-surface-300 text-surface-500'"
        >
          {{ numero }}
        </span>
        <span class="truncate text-sm">Lição {{ numero }}</span>
      </span>
      <InputText
        type="date"
        size="small"
        class="w-40 shrink-0"
        :aria-label="`Data de conclusão da lição ${numero}`"
        :model-value="licaoDe(numero)?.data_conclusao ?? ''"
        :disabled="salvando === numero"
        @update:model-value="valor => aoMudar(numero, valor as string)"
      />
    </li>
  </ul>
</template>
