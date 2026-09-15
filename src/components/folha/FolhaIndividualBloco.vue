<script setup lang="ts">
import { computed } from 'vue'
import { formatarDataCurta } from '@/utils/data'
import {
  blocoConcluido,
  itensConcluidos,
  premioHabilitado,
  rotuloItem,
  type BlocoFolha,
} from '@/utils/folhaIndividual'

const props = defineProps<{
  bloco: BlocoFolha
  salvandoItem?: number | null
}>()

const emit = defineEmits<{
  'salvar-item': [itemNum: number, data: string | null]
}>()

const concluido = computed(() => blocoConcluido(props.bloco))
const habilitadoPremio = computed(() => premioHabilitado(props.bloco))

/** Status do prêmio: incompleto → aguardando → entregue (data via secretaria). */
const statusPremio = computed<'incompleto' | 'aguardando' | 'entregue'>(() => {
  if (!habilitadoPremio.value) return 'incompleto'
  return props.bloco.premioData ? 'entregue' : 'aguardando'
})

function aoMudarItem(itemNum: number, valor: string) {
  emit('salvar-item', itemNum, valor || null)
}
</script>

<template>
  <div class="rounded-lg border bg-[var(--surface-card)] p-3">
    <div class="mb-2 flex items-center justify-between gap-2">
      <span class="font-medium">{{ bloco.nome }}</span>
      <Tag
        :severity="concluido ? 'success' : 'secondary'"
        :value="`${itensConcluidos(bloco)} / ${bloco.quantidade}`"
      />
    </div>

    <ul class="flex flex-col gap-2">
      <li
        v-for="item in bloco.itens"
        :key="item.item_num"
        class="flex items-center justify-between gap-2"
      >
        <span class="flex min-w-0 items-center gap-2">
          <span
            class="flex h-6 w-6 shrink-0 items-center justify-center rounded-full border text-xs font-semibold"
            :class="item.data_conclusao
              ? 'border-primary bg-primary text-primary-contrast'
              : 'border-surface-300 text-surface-500'"
          >
            {{ item.item_num }}
          </span>
          <span class="truncate text-sm">{{ rotuloItem(bloco.nome, item.item_num) }}</span>
        </span>
        <InputText
          type="date"
          size="small"
          class="w-40 shrink-0"
          :aria-label="`Data de conclusão de ${rotuloItem(bloco.nome, item.item_num)}`"
          :model-value="item.data_conclusao ?? ''"
          :disabled="salvandoItem === item.item_num"
          @update:model-value="valor => aoMudarItem(item.item_num, valor as string)"
        />
      </li>
    </ul>

    <div class="mt-3 flex flex-wrap items-center justify-between gap-2 border-t pt-3">
      <span class="flex min-w-0 items-center gap-2">
        <i :class="statusPremio === 'entregue'
          ? 'pi pi-check-circle text-green-500'
          : statusPremio === 'aguardando'
            ? 'pi pi-gift text-amber-500'
            : 'pi pi-lock text-surface-400'" />
        <span class="truncate text-sm">{{ bloco.premio_nome }}</span>
      </span>
      <span
        v-if="statusPremio === 'aguardando'"
        class="text-xs font-medium text-amber-600"
      >
        Aguardando entrega
      </span>
      <span
        v-else-if="statusPremio === 'entregue'"
        class="text-xs font-medium text-green-600"
      >
        Entregue em {{ bloco.premioData ? formatarDataCurta(bloco.premioData) : '' }}
      </span>
    </div>

    <p
      v-if="statusPremio === 'incompleto'"
      class="mt-1 text-xs text-surface-500"
    >
      Conclua todos os itens para liberar o prêmio.
    </p>
  </div>
</template>
