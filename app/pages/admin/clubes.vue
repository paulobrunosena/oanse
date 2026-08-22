<script setup lang="ts">
import type { TableColumn } from '@nuxt/ui'
import type { Database } from '~/types/database.types'

type Clube = Database['public']['Tables']['clubes']['Row']

definePageMeta({ middleware: ['role'], roles: ['diretor_geral'] })
useSeoMeta({ title: 'Clubes — Oanse' })

const supabase = useSupabaseClient()
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

const colunas: TableColumn<Clube>[] = [
  {
    accessorKey: 'nome',
    header: 'Clube',
    cell: ({ row }) => h('span', { class: 'font-semibold flex items-center gap-2' }, [
      h('span', { class: 'size-3 rounded-full', style: { backgroundColor: row.original.cor } }),
      row.original.nome,
    ]),
  },
  { accessorKey: 'idade', header: 'Idade', cell: ({ row }) => `${row.original.idade_min} a ${row.original.idade_max} anos` },
  { accessorKey: 'slug', header: 'Slug' },
  { id: 'acoes' },
]

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
    <p class="text-sm text-muted mb-4">
      Faixas de idade e identidade visual de cada clube
    </p>

    <UTable
      :data="clubes"
      :columns="colunas"
      :loading="carregando"
    >
      <template #acoes-cell="{ row }">
        <div class="flex justify-end">
          <UButton
            icon="i-lucide-pencil"
            color="neutral"
            variant="ghost"
            size="sm"
            aria-label="Editar"
            @click="abrirEdicao(row.original)"
          />
        </div>
      </template>
    </UTable>

    <UModal
      :open="!!editando"
      title="Editar clube"
      @update:open="editando = null"
    >
      <template #body>
        <UForm
          v-if="editando"
          :state="form"
          class="flex flex-col gap-4"
          @submit="salvar"
        >
          <UFormField
            label="Nome"
            name="nome"
            required
          >
            <UInput
              v-model="form.nome"
              class="w-full"
            />
          </UFormField>
          <div class="grid grid-cols-2 gap-4">
            <UFormField
              label="Idade mínima"
              name="idade_min"
              required
            >
              <UInputNumber
                v-model="form.idade_min"
                :min="2"
                :max="17"
                class="w-full"
              />
            </UFormField>
            <UFormField
              label="Idade máxima"
              name="idade_max"
              required
            >
              <UInputNumber
                v-model="form.idade_max"
                :min="2"
                :max="17"
                class="w-full"
              />
            </UFormField>
          </div>
          <div class="grid grid-cols-2 gap-4">
            <UFormField
              label="Cor"
              name="cor"
            >
              <UInput
                v-model="form.cor"
                type="color"
                class="w-full"
              />
            </UFormField>
            <UFormField
              label="Ordem de exibição"
              name="ordem"
            >
              <UInputNumber
                v-model="form.ordem"
                :min="1"
                :max="10"
                class="w-full"
              />
            </UFormField>
          </div>
          <div class="flex justify-end gap-2">
            <UButton
              variant="ghost"
              @click="editando = null"
            >
              Cancelar
            </UButton>
            <UButton
              type="submit"
              :loading="salvando"
            >
              Salvar
            </UButton>
          </div>
        </UForm>
      </template>
    </UModal>
  </div>
</template>
