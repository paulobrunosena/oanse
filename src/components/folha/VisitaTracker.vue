<script setup lang="ts">
import type { Database } from '@/types/database.types'

type VisitaRow = Database['public']['Tables']['visitas']['Row']

const props = defineProps<{
  visitas: VisitaRow[]
  salvando?: number | null
}>()

const emit = defineEmits<{
  'salvar-visita': [numero: number, dados: { data_visita: string, presente: boolean }]
}>()

const NUMEROS = [1, 2, 3]

function visitaDe(numero: number): VisitaRow | undefined {
  return props.visitas.find(v => v.numero === numero)
}

function rotulo(numero: number): string {
  return `${numero}ª visita`
}

function aoMudarData(numero: number, valor: string) {
  const atual = visitaDe(numero)
  emit('salvar-visita', numero, { data_visita: valor, presente: atual?.presente ?? true })
}

function aoMudarPresente(numero: number, valor: boolean) {
  const atual = visitaDe(numero)
  emit('salvar-visita', numero, { data_visita: atual?.data_visita ?? '', presente: valor })
}
</script>

<template>
  <ul class="flex flex-col gap-3">
    <li
      v-for="numero in NUMEROS"
      :key="numero"
      class="flex flex-wrap items-center gap-3"
    >
      <span class="w-20 shrink-0 text-sm font-medium">{{ rotulo(numero) }}</span>
      <InputText
        type="date"
        size="small"
        class="w-40 shrink-0"
        :aria-label="`Data da ${rotulo(numero)}`"
        :model-value="visitaDe(numero)?.data_visita ?? ''"
        :disabled="salvando === numero"
        @update:model-value="valor => aoMudarData(numero, valor as string)"
      />
      <div class="flex items-center gap-2">
        <Checkbox
          :model-value="visitaDe(numero)?.presente ?? true"
          :binary="true"
          :disabled="!visitaDe(numero) || salvando === numero"
          :input-id="`presente-visita-${numero}`"
          @update:model-value="valor => aoMudarPresente(numero, Boolean(valor))"
        />
        <label
          class="text-sm"
          :for="`presente-visita-${numero}`"
        >Presente</label>
      </div>
    </li>
  </ul>
</template>
