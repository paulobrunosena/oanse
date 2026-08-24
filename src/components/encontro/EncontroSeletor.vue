<script setup lang="ts">
import { computed } from 'vue'
import Select from 'primevue/select'
import type { Encontro } from '@/composables/useEncontro'
import { formatarDataCurta } from '@/utils/data'

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
  <Select
    :model-value="encontro?.id"
    :options="itens"
    option-label="label"
    option-value="value"
    placeholder="Selecionar sábado"
    class="w-40"
    size="small"
    @update:model-value="$emit('selecionar', $event as string)"
  />
</template>
