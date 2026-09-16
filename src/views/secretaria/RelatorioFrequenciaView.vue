<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useToast } from '@/composables/useToast'
import { percentualFrequencia, useRelatorioFrequencia } from '@/composables/useRelatorioFrequencia'

const toast = useToast()
const { linhas, carregando, carregar } = useRelatorioFrequencia()

function iso(d: Date): string {
  return d.toISOString().slice(0, 10)
}

function primeiroDiaDoMes(): string {
  const d = new Date()
  d.setDate(1)
  return iso(d)
}

const de = ref(primeiroDiaDoMes())
const ate = ref(iso(new Date()))

async function atualizar() {
  if (!de.value || !ate.value) return
  try {
    await carregar(de.value, ate.value)
  }
  catch (e) {
    toast.add({
      title: 'Erro ao carregar o relatório',
      description: (e as { message?: string })?.message ?? 'Tente novamente',
      color: 'error',
    })
  }
}

onMounted(atualizar)
</script>

<template>
  <div class="p-4 sm:p-6 max-w-4xl mx-auto w-full">
    <div class="mb-4">
      <h1 class="text-2xl font-bold">
        Relatório de frequência
      </h1>
      <p class="text-sm text-surface-500 mt-1">
        Presenças e faltas acumuladas por oansista no período
      </p>
    </div>

    <div class="mb-4 flex flex-wrap items-end gap-3">
      <div class="flex flex-col gap-1">
        <label class="text-sm font-medium">De</label>
        <InputText
          v-model="de"
          type="date"
          class="w-40"
        />
      </div>
      <div class="flex flex-col gap-1">
        <label class="text-sm font-medium">Até</label>
        <InputText
          v-model="ate"
          type="date"
          class="w-40"
        />
      </div>
      <Button
        icon="pi pi-search"
        label="Filtrar"
        @click="atualizar"
      />
    </div>

    <div class="overflow-x-auto">
      <DataTable
        :value="linhas"
        :loading="carregando"
        data-key="oansista_id"
        class="w-full"
      >
        <Column header="Oansista">
          <template #body="{ data }">
            <span class="font-medium">{{ data.oansista_nome }}</span>
          </template>
        </Column>
        <Column header="Clube">
          <template #body="{ data }">
            {{ data.clube_nome }}
          </template>
        </Column>
        <Column header="Turma">
          <template #body="{ data }">
            {{ data.turma_nome }}
          </template>
        </Column>
        <Column header="Presenças">
          <template #body="{ data }">
            {{ data.presencas }}
          </template>
        </Column>
        <Column header="Faltas">
          <template #body="{ data }">
            {{ data.faltas }}
          </template>
        </Column>
        <Column header="Frequência">
          <template #body="{ data }">
            {{ percentualFrequencia(data) }}%
          </template>
        </Column>
      </DataTable>
    </div>

    <div
      v-if="!carregando && linhas.length === 0"
      class="py-10 text-center text-surface-500 text-sm"
    >
      Nenhuma presença registrada neste período.
    </div>
  </div>
</template>
