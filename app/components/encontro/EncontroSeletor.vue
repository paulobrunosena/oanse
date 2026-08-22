<script setup lang="ts">
import type { Encontro } from '~/composables/useEncontro'
import { formatarDataCurta } from '~/utils/data'

const props = defineProps<{
  encontros: Encontro[]
  encontro: Encontro | null
}>()

defineEmits<{ selecionar: [id: string] }>()

const itens = computed(() =>
  props.encontros.map(e => ({ label: formatarDataCurta(e.data), value: e.id })),
)
</script>

<template>
  <USelect
    :model-value="encontro?.id"
    :items="itens"
    placeholder="Selecionar sábado"
    class="w-40"
    size="sm"
    @update:model-value="$emit('selecionar', $event as string)"
  />
</template>
