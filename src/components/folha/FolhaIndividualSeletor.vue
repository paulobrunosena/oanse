<script setup lang="ts">
import { computed } from 'vue'
import Select from 'primevue/select'

const props = defineProps<{
  oansistas: { id: string, nome: string }[]
  oansistaId: string | null
}>()

defineEmits<{ selecionar: [id: string] }>()

const itens = computed(() => props.oansistas.map(o => ({ label: o.nome, value: o.id })))
</script>

<template>
  <Select
    :model-value="oansistaId"
    :options="itens"
    option-label="label"
    option-value="value"
    :filter="true"
    placeholder="Selecionar oansista"
    class="w-full sm:w-56"
    size="small"
    @update:model-value="$emit('selecionar', $event as string)"
  />
</template>
