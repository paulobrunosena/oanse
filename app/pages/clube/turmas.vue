<script setup lang="ts">
import type { TableColumn } from '@nuxt/ui'
import type { Database } from '~/types/database.types'

type Turma = Database['public']['Tables']['turmas']['Row']
type Profile = Database['public']['Tables']['profiles']['Row']

definePageMeta({ middleware: ['role'], roles: ['diretor_geral', 'diretor_clube'] })
useSeoMeta({ title: 'Turmas — Oanse' })

const { profile } = useAuth()
const supabase = useSupabaseClient()
const toast = useToast()

const turmas = ref<(Turma & { lider_nome: string | null, qtd_oansistas: number })[]>([])
const lideres = ref<Profile[]>([])
const carregando = ref(true)
const salvando = ref(false)

async function carregar() {
  carregando.value = true
  const { data } = await supabase
    .from('turmas')
    .select('*, lider:profiles!turmas_lider_id_fkey(nome), oansistas(count)')
    .eq('clube_id', profile.value!.clube_id!)
    .order('nome')
  turmas.value = (data ?? []).map(t => ({
    ...t,
    lider_nome: (t.lider as unknown as { nome: string } | null)?.nome ?? null,
    qtd_oansistas: (t.oansistas as unknown as { count: number }[] | null)?.[0]?.count ?? 0,
  }))
  carregando.value = false
}

async function carregarLideres() {
  const { data } = await supabase
    .from('profiles')
    .select('*')
    .eq('clube_id', profile.value!.clube_id!)
    .eq('role', 'lider')
    .eq('ativo', true)
    .order('nome')
  lideres.value = data ?? []
}

onMounted(() => {
  carregar()
  carregarLideres()
})

const colunas: TableColumn<Turma & { lider_nome: string | null, qtd_oansistas: number }>[] = [
  { accessorKey: 'nome', header: 'Turma' },
  { accessorKey: 'lider_nome', header: 'Líder' },
  { accessorKey: 'qtd_oansistas', header: 'Oansistas' },
  { accessorKey: 'ativo', header: 'Situação' },
  { id: 'acoes' },
]

// ---- Criação ----
const modalCriar = ref(false)
const form = reactive({ nome: '', lider_id: '' })

const lideresDisponiveis = computed(() => {
  const usados = new Set(turmas.value.filter(t => t.ativo).map(t => t.lider_id))
  return lideres.value
    .filter(l => !usados.has(l.id))
    .map(l => ({ label: l.nome, value: l.id }))
})

async function criar() {
  if (!form.nome.trim() || !form.lider_id) {
    toast.add({ title: 'Preencha o nome e o líder da turma', color: 'error' })
    return
  }
  salvando.value = true
  const { error } = await supabase.from('turmas').insert({
    nome: form.nome.trim(),
    lider_id: form.lider_id,
    clube_id: profile.value!.clube_id!,
  })
  salvando.value = false

  if (error) {
    toast.add({ title: 'Erro ao criar turma', description: error.message, color: 'error' })
    return
  }
  toast.add({ title: 'Turma criada', color: 'success' })
  modalCriar.value = false
  Object.assign(form, { nome: '', lider_id: '' })
  await carregar()
}

// ---- Edição ----
const editando = ref<(Turma & { lider_nome: string | null }) | null>(null)
const formEditar = reactive({ nome: '', lider_id: '' })

function abrirEdicao(t: Turma & { lider_nome: string | null }) {
  editando.value = t
  Object.assign(formEditar, { nome: t.nome, lider_id: t.lider_id })
}

const lideresEdicao = computed(() => {
  const usados = new Set(turmas.value.filter(t => t.ativo && t.id !== editando.value?.id).map(t => t.lider_id))
  return lideres.value
    .filter(l => !usados.has(l.id) || l.id === formEditar.lider_id)
    .map(l => ({ label: l.nome, value: l.id }))
})

async function salvarEdicao() {
  if (!editando.value) return
  salvando.value = true
  const { error } = await supabase
    .from('turmas')
    .update({ nome: formEditar.nome.trim(), lider_id: formEditar.lider_id })
    .eq('id', editando.value.id)
  salvando.value = false

  if (error) {
    toast.add({ title: 'Erro ao salvar', description: error.message, color: 'error' })
    return
  }
  toast.add({ title: 'Turma atualizada', color: 'success' })
  editando.value = null
  await carregar()
}

// ---- Ativar/desativar ----
async function alternarAtivo(t: Turma & { lider_nome: string | null }) {
  const { error } = await supabase.from('turmas').update({ ativo: !t.ativo }).eq('id', t.id)
  if (error) {
    toast.add({ title: 'Erro', description: error.message, color: 'error' })
    return
  }
  await carregar()
}
</script>

<template>
  <div class="p-4 sm:p-6 max-w-3xl mx-auto w-full">
    <div class="flex items-center justify-between mb-4">
      <div>
        <h1 class="text-2xl font-bold">
          Turmas
        </h1>
        <p class="text-sm text-muted">
          Cada turma tem um líder responsável (1 líder = 1 turma)
        </p>
      </div>
      <UButton
        icon="i-lucide-plus"
        :disabled="lideresDisponiveis.length === 0"
        @click="modalCriar = true"
      >
        Nova turma
      </UButton>
    </div>

    <p
      v-if="lideresDisponiveis.length === 0"
      class="text-sm text-muted mb-4"
    >
      Sem líderes disponíveis. Cadastre líderes em Usuários (perfil Líder, vinculado ao seu clube).
    </p>

    <UTable
      :data="turmas"
      :columns="colunas"
      :loading="carregando"
    >
      <template #ativo-cell="{ row }">
        <UBadge
          :color="row.original.ativo ? 'success' : 'neutral'"
          variant="subtle"
        >
          {{ row.original.ativo ? 'Ativa' : 'Inativa' }}
        </UBadge>
      </template>
      <template #acoes-cell="{ row }">
        <div class="flex gap-1 justify-end">
          <UButton
            icon="i-lucide-pencil"
            color="neutral"
            variant="ghost"
            size="sm"
            aria-label="Editar"
            @click="abrirEdicao(row.original)"
          />
          <UButton
            :icon="row.original.ativo ? 'i-lucide-circle-off' : 'i-lucide-circle-check'"
            color="neutral"
            variant="ghost"
            size="sm"
            :aria-label="row.original.ativo ? 'Desativar' : 'Ativar'"
            @click="alternarAtivo(row.original)"
          />
        </div>
      </template>
    </UTable>

    <!-- Modal criação -->
    <UModal
      v-model:open="modalCriar"
      title="Nova turma"
    >
      <template #body>
        <UForm
          :state="form"
          class="flex flex-col gap-4"
          @submit="criar"
        >
          <UFormField
            label="Nome"
            name="nome"
            required
          >
            <UInput
              v-model="form.nome"
              class="w-full"
              placeholder="Ex.: Turma 2 - Tio Beto"
            />
          </UFormField>
          <UFormField
            label="Líder responsável"
            name="lider_id"
            required
          >
            <USelect
              v-model="form.lider_id"
              :items="lideresDisponiveis"
              class="w-full"
              placeholder="Selecione"
            />
          </UFormField>
          <div class="flex justify-end gap-2">
            <UButton
              variant="ghost"
              @click="modalCriar = false"
            >
              Cancelar
            </UButton>
            <UButton
              type="submit"
              :loading="salvando"
            >
              Criar
            </UButton>
          </div>
        </UForm>
      </template>
    </UModal>

    <!-- Modal edição -->
    <UModal
      :open="!!editando"
      title="Editar turma"
      @update:open="editando = null"
    >
      <template #body>
        <UForm
          v-if="editando"
          :state="formEditar"
          class="flex flex-col gap-4"
          @submit="salvarEdicao"
        >
          <UFormField
            label="Nome"
            name="nome"
            required
          >
            <UInput
              v-model="formEditar.nome"
              class="w-full"
            />
          </UFormField>
          <UFormField
            label="Líder responsável"
            name="lider_id"
            required
          >
            <USelect
              v-model="formEditar.lider_id"
              :items="lideresEdicao"
              class="w-full"
            />
          </UFormField>
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
