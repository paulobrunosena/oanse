<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import Button from 'primevue/button'
import Textarea from 'primevue/textarea'

const props = defineProps<{
  texto: string
  salvando?: boolean
}>()

const emit = defineEmits<{ salvar: [texto: string] }>()

const valor = ref(props.texto)

watch(() => props.texto, (novo) => {
  valor.value = novo
})

const alterado = computed(() => valor.value !== props.texto)

function salvar() {
  emit('salvar', valor.value)
}
</script>

<template>
  <div class="rounded-lg border border-dashed bg-[var(--surface-card)] p-3">
    <Textarea
      v-model="valor"
      rows="3"
      auto-resize
      placeholder="Anotações do manual (versículos a decorar, pendências, etc.)"
      class="w-full"
    />
    <div class="mt-2 flex justify-end">
      <Button
        icon="pi pi-save"
        label="Salvar observações"
        size="small"
        :disabled="!alterado"
        :loading="salvando"
        @click="salvar"
      />
    </div>
  </div>
</template>
