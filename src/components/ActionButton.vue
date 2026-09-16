<script setup lang="ts">
import { computed } from 'vue'
import { storeToRefs } from 'pinia'
import { usePreferenciasStore } from '@/stores/preferencias'

const props = withDefaults(
  defineProps<{
    icon: string
    label: string
    tooltip?: string
    severity?: string
    loading?: boolean
    disabled?: boolean
    rounded?: boolean
    size?: 'small' | 'large'
  }>(),
  {
    tooltip: undefined,
    severity: undefined,
    loading: false,
    disabled: false,
    rounded: true,
    size: 'small',
  },
)

const emit = defineEmits<{ click: [event: Event] }>()

const { rotulosAcoes } = storeToRefs(usePreferenciasStore())

const labelVisivel = computed(() => (rotulosAcoes.value ? props.label : undefined))
const tooltipTexto = computed(() => (rotulosAcoes.value ? undefined : (props.tooltip ?? props.label)))
</script>

<template>
  <Button
    :icon="icon"
    :label="labelVisivel"
    :aria-label="label"
    :severity="severity"
    :loading="loading"
    :disabled="disabled"
    :rounded="rounded"
    :size="size"
    text
    v-tooltip="tooltipTexto"
    @click="emit('click', $event)"
  />
</template>
