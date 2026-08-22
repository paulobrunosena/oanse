<script setup lang="ts">
import type { TableColumn } from '@nuxt/ui'
import type { Database } from '~/types/database.types'
import { formatarDataCurta } from '~/utils/data'

type DiaSemOanse = Database['public']['Tables']['dias_sem_oanse']['Row']

definePageMeta({ middleware: ['role'], roles: ['diretor_geral'] })
useSeoMeta({ title: 'Calendário — Oanse' })

const supabase = useSupabaseClient()
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

const colunas: TableColumn<DiaSemOanse>[] = [
  {
    accessorKey: 'data',
    header: 'Sábado',
    cell: ({ row }) => formatarDataCurta(row.original.data),
  },
  {
    accessorKey: 'motivo',
    header: 'Motivo',
    cell: ({ row }) => row.original.motivo ?? '—',
  },
  { id: 'acoes' },
]

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

  // Caso de borda: se já existia encontro ativo nesse sábado, desativa-o para
  // impedir novos lançamentos (RN 7). O histórico dos lançamentos antigos é mantido.
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
    <p class="text-sm text-muted mb-4">
      Sábados sem Oanse (férias, feriados, eventos). Nestes dias o sistema bloqueia chamada e folha.
    </p>

    <UCard class="mb-6">
      <UForm
        :state="form"
        class="flex flex-col gap-4"
        @submit="salvar"
      >
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <UFormField
            label="Sábado sem Oanse"
            name="data"
            required
          >
            <UInput
              v-model="form.data"
              type="date"
              class="w-full"
            />
          </UFormField>
          <UFormField
            label="Motivo"
            name="motivo"
          >
            <UInput
              v-model="form.motivo"
              class="w-full"
              placeholder="Ex.: Férias, feriado, evento"
            />
          </UFormField>
        </div>
        <div class="flex justify-end">
          <UButton
            type="submit"
            :loading="salvando"
          >
            Registrar sábado sem Oanse
          </UButton>
        </div>
      </UForm>
    </UCard>

    <UTable
      :data="dias"
      :columns="colunas"
      :loading="carregando"
    >
      <template #acoes-cell="{ row }">
        <div class="flex justify-end">
          <UButton
            icon="i-lucide-trash-2"
            color="error"
            variant="ghost"
            size="sm"
            aria-label="Excluir"
            @click="excluir(row.original)"
          />
        </div>
      </template>
      <template #empty>
        <div class="text-center py-8 text-muted">
          Nenhum sábado sem Oanse registrado.
        </div>
      </template>
    </UTable>
  </div>
</template>
