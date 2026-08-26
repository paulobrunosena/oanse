<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import Button from 'primevue/button'
import Column from 'primevue/column'
import DataTable from 'primevue/datatable'
import Dialog from 'primevue/dialog'
import InputNumber from 'primevue/inputnumber'
import InputText from 'primevue/inputtext'
import { supabase } from '@/lib/supabase'
import { useToast } from '@/composables/useToast'
import { logoClube } from '@/utils/data'
import type { Database } from '@/types/database.types'

type Clube = Database['public']['Tables']['clubes']['Row']

const toast = useToast()

const clubes = ref<Clube[]>([])
const carregando = ref(true)

async function carregar() {
  carregando.value = true
  const { data } = await supabase.from('clubes').select('*').order('ordem')
  clubes.value = data ?? []
  carregando.value = false
}

onMounted(carregar)

const editando = ref<Clube | null>(null)
const salvando = ref(false)
const form = reactive({ nome: '', idade_min: 4, idade_max: 5, cor: '#8B5CF6', ordem: 1 })

function abrirEdicao(c: Clube) {
  editando.value = c
  Object.assign(form, {
    nome: c.nome,
    idade_min: c.idade_min,
    idade_max: c.idade_max,
    cor: c.cor,
    ordem: c.ordem,
  })
}

async function salvar() {
  if (!editando.value) return
  if (form.idade_min > form.idade_max) {
    toast.add({ title: 'Idade mínima não pode ser maior que a máxima', color: 'error' })
    return
  }
  salvando.value = true
  const { error } = await supabase
    .from('clubes')
    .update({
      nome: form.nome,
      idade_min: form.idade_min,
      idade_max: form.idade_max,
      cor: form.cor,
      ordem: form.ordem,
    })
    .eq('id', editando.value.id)
  salvando.value = false

  if (error) {
    toast.add({ title: 'Erro ao salvar', description: error.message, color: 'error' })
    return
  }
  toast.add({ title: 'Clube atualizado', color: 'success' })
  editando.value = null
  await carregar()
}
</script>

<template>
  <div class="p-4 sm:p-6 max-w-3xl mx-auto w-full">
    <h1 class="text-2xl font-bold">
      Clubes
    </h1>
    <p class="text-sm text-surface-500 mb-4">
      Faixas de idade e identidade visual de cada clube
    </p>

    <div class="overflow-x-auto">
      <DataTable
        :value="clubes"
        :loading="carregando"
        data-key="id"
        class="w-full"
      >
      <Column field="nome" header="Clube">
        <template #body="{ data }">
          <span class="font-semibold flex items-center gap-2">
            <img
              :src="logoClube(data.slug) ?? undefined"
              :alt="data.nome"
              class="size-6 object-contain"
            >
            <span
              class="size-3 rounded-full inline-block"
              :style="{ backgroundColor: data.cor }"
            />
            {{ data.nome }}
          </span>
        </template>
      </Column>
      <Column field="idade" header="Idade">
        <template #body="{ data }">
          {{ data.idade_min }} a {{ data.idade_max }} anos
        </template>
      </Column>
      <Column field="slug" header="Slug" />
      <Column header="" style="width: 70px">
        <template #body="{ data }">
          <div class="flex justify-end">
            <Button
              icon="pi pi-pencil"
              text
              rounded
              size="small"
              aria-label="Editar"
              @click="abrirEdicao(data)"
            />
          </div>
        </template>
      </Column>
      </DataTable>
    </div>

    <Dialog
      :visible="editando !== null"
      header="Editar clube"
      :modal="true"
      class="w-full max-w-md"
      @update:visible="editando = null"
    >
      <form
        v-if="editando"
        class="flex flex-col gap-4"
        @submit.prevent="salvar"
      >
        <div class="flex flex-col gap-1">
          <label class="text-sm font-medium">Nome *</label>
          <InputText
            v-model="form.nome"
            class="w-full"
          />
        </div>
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div class="flex flex-col gap-1">
            <label class="text-sm font-medium">Idade mínima *</label>
            <InputNumber
              v-model="form.idade_min"
              :min="2"
              :max="17"
              class="w-full"
            />
          </div>
          <div class="flex flex-col gap-1">
            <label class="text-sm font-medium">Idade máxima *</label>
            <InputNumber
              v-model="form.idade_max"
              :min="2"
              :max="17"
              class="w-full"
            />
          </div>
        </div>
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div class="flex flex-col gap-1">
            <label class="text-sm font-medium">Cor</label>
            <InputText
              v-model="form.cor"
              type="color"
              class="w-full"
            />
          </div>
          <div class="flex flex-col gap-1">
            <label class="text-sm font-medium">Ordem de exibição</label>
            <InputNumber
              v-model="form.ordem"
              :min="1"
              :max="10"
              class="w-full"
            />
          </div>
        </div>
        <div class="flex justify-end gap-2">
          <Button
            label="Cancelar"
            text
            @click="editando = null"
          />
          <Button
            type="submit"
            label="Salvar"
            :loading="salvando"
          />
        </div>
      </form>
    </Dialog>
  </div>
</template>
