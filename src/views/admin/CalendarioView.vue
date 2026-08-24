<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import Button from 'primevue/button'
import Card from 'primevue/card'
import Column from 'primevue/column'
import DataTable from 'primevue/datatable'
import InputText from 'primevue/inputtext'
import { supabase } from '@/lib/supabase'
import { useToast } from '@/composables/useToast'
import { formatarDataCurta } from '@/utils/data'
import type { Database } from '@/types/database.types'

type DiaSemOanse = Database['public']['Tables']['dias_sem_oanse']['Row']

const toast = useToast()

const dias = ref<DiaSemOanse[]>([])
const carregando = ref(true)
const salvando = ref(false)

const form = reactive({ data: '', motivo: '' })

async function carregar() {
  carregando.value = true
  const { data } = await supabase
    .from('dias_sem_oanse')
    .select('*')
    .order('data', { ascending: false })
  dias.value = data ?? []
  carregando.value = false
}

onMounted(carregar)

async function salvar() {
  if (!form.data) {
    toast.add({ title: 'Informe a data', color: 'error' })
    return
  }
  salvando.value = true
  const data = form.data
  const { error } = await supabase
    .from('dias_sem_oanse')
    .insert({ data, motivo: form.motivo.trim() || null })
  if (error) {
    salvando.value = false
    toast.add({ title: 'Erro ao registrar', description: error.message, color: 'error' })
    return
  }

  // RN 7: se já existia encontro ativo nesse sábado, desativa-o para impedir
  // novos lançamentos. O histórico dos lançamentos antigos é mantido.
  await supabase
    .from('encontros')
    .update({ ativo: false })
    .eq('data', data)
    .eq('ativo', true)

  salvando.value = false
  toast.add({ title: 'Sábado registrado como sem Oanse', color: 'success' })
  Object.assign(form, { data: '', motivo: '' })
  await carregar()
}

async function excluir(row: DiaSemOanse) {
  const { error } = await supabase.from('dias_sem_oanse').delete().eq('id', row.id)
  if (error) {
    toast.add({ title: 'Erro ao excluir', description: error.message, color: 'error' })
    return
  }
  toast.add({ title: 'Sábado reativado', color: 'success' })
  await carregar()
}
</script>

<template>
  <div class="p-4 sm:p-6 max-w-3xl mx-auto w-full">
    <h1 class="text-2xl font-bold">
      Calendário
    </h1>
    <p class="text-sm text-surface-500 mb-4">
      Sábados sem Oanse (férias, feriados, eventos). Nestes dias o sistema bloqueia chamada e folha.
    </p>

    <Card class="mb-6">
      <template #content>
        <form
          class="flex flex-col gap-4"
          @submit.prevent="salvar"
        >
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div class="flex flex-col gap-1">
              <label class="text-sm font-medium">Sábado sem Oanse *</label>
              <InputText
                v-model="form.data"
                type="date"
                class="w-full"
              />
            </div>
            <div class="flex flex-col gap-1">
              <label class="text-sm font-medium">Motivo</label>
              <InputText
                v-model="form.motivo"
                class="w-full"
                placeholder="Ex.: Férias, feriado, evento"
              />
            </div>
          </div>
          <div class="flex justify-end">
            <Button
              type="submit"
              label="Registrar sábado sem Oanse"
              :loading="salvando"
            />
          </div>
        </form>
      </template>
    </Card>

    <DataTable
      :value="dias"
      :loading="carregando"
      data-key="id"
      class="w-full"
    >
      <Column header="Sábado">
        <template #body="{ data }">
          {{ formatarDataCurta(data.data) }}
        </template>
      </Column>
      <Column header="Motivo">
        <template #body="{ data }">
          {{ data.motivo ?? '—' }}
        </template>
      </Column>
      <Column header="" style="width: 70px">
        <template #body="{ data }">
          <div class="flex justify-end">
            <Button
              icon="pi pi-trash"
              text
              rounded
              severity="danger"
              size="small"
              aria-label="Excluir"
              @click="excluir(data)"
            />
          </div>
        </template>
      </Column>
      <template #empty>
        <div class="text-center py-8 text-surface-500">
          Nenhum sábado sem Oanse registrado.
        </div>
      </template>
    </DataTable>
  </div>
</template>
