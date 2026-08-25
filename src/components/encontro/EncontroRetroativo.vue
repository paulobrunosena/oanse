<script setup lang="ts">
import { computed, ref } from 'vue'
import Button from 'primevue/button'
import Dialog from 'primevue/dialog'
import Select from 'primevue/select'
import { useEncontro } from '@/composables/useEncontro'
import { useToast } from '@/composables/useToast'
import { formatarDataCurta } from '@/utils/data'

const emit = defineEmits<{ criado: [id: string] }>()

const { sabadosFaltantes, criarRetroativo } = useEncontro()
const toast = useToast()

const aberto = ref(false)
const selecionado = ref<string | null>(null)
const criando = ref(false)

const opcoes = computed(() =>
  sabadosFaltantes.value.map(d => ({ label: formatarDataCurta(d), value: d })),
)

async function confirmar() {
  if (!selecionado.value || criando.value) return
  criando.value = true
  try {
    const { encontro } = await criarRetroativo(selecionado.value)
    aberto.value = false
    selecionado.value = null
    emit('criado', encontro.id)
  }
  catch (e) {
    toast.add({
      title: 'Erro ao criar o sábado',
      description: (e as { message?: string })?.message ?? 'Tente novamente',
      color: 'error',
    })
  }
  finally {
    criando.value = false
  }
}
</script>

<template>
  <div>
    <Button
      :disabled="opcoes.length === 0"
      size="small"
      outlined
      icon="pi pi-calendar-plus"
      label="Sábado perdido"
      class="w-full sm:w-auto"
      @click="aberto = true"
    />

    <Dialog
      v-model:visible="aberto"
      header="Lançar sábado perdido"
      :modal="true"
      class="w-full max-w-md"
    >
      <div class="flex flex-col gap-4">
        <p class="text-sm text-surface-500">
          Selecione o sábado em que não foi possível lançar (ex.: sistema fora
          do ar). O encontro será criado para você preencher a chamada e a folha.
        </p>

        <p
          v-if="opcoes.length === 0"
          class="text-sm text-surface-500"
        >
          Nenhum sábado recente em aberto. Todos já foram lançados ou estão
          marcados como sem Oanse.
        </p>

        <Select
          v-else
          v-model="selecionado"
          :options="opcoes"
          option-label="label"
          option-value="value"
          placeholder="Escolha o sábado"
          class="w-full"
        />

        <div class="flex justify-end gap-2">
          <Button
            label="Cancelar"
            text
            @click="aberto = false"
          />
          <Button
            label="Criar sábado"
            :loading="criando"
            :disabled="!selecionado"
            @click="confirmar"
          />
        </div>
      </div>
    </Dialog>
  </div>
</template>