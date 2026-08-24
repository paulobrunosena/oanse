<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import Button from 'primevue/button'
import Column from 'primevue/column'
import DataTable from 'primevue/datatable'
import Dialog from 'primevue/dialog'
import InputText from 'primevue/inputtext'
import Select from 'primevue/select'
import Tag from 'primevue/tag'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/composables/useAuth'
import { useToast } from '@/composables/useToast'
import type { Database } from '@/types/database.types'

type Turma = Database['public']['Tables']['turmas']['Row']
type Profile = Database['public']['Tables']['profiles']['Row']

const { profile } = useAuth()
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
        <p class="text-sm text-surface-500">
          Cada turma tem um líder responsável (1 líder = 1 turma)
        </p>
      </div>
      <Button
        icon="pi pi-plus"
        label="Nova turma"
        :disabled="lideresDisponiveis.length === 0"
        @click="modalCriar = true"
      />
    </div>

    <p
      v-if="lideresDisponiveis.length === 0"
      class="text-sm text-surface-500 mb-4"
    >
      Sem líderes disponíveis. Cadastre líderes em Usuários (perfil Líder, vinculado ao seu clube).
    </p>

    <DataTable
      :value="turmas"
      :loading="carregando"
      data-key="id"
      class="w-full"
    >
      <Column field="nome" header="Turma" />
      <Column field="lider_nome" header="Líder">
        <template #body="{ data }">
          {{ data.lider_nome ?? '—' }}
        </template>
      </Column>
      <Column field="qtd_oansistas" header="Oansistas" />
      <Column header="Situação">
        <template #body="{ data }">
          <Tag
            :severity="data.ativo ? 'success' : 'secondary'"
            :value="data.ativo ? 'Ativa' : 'Inativa'"
          />
        </template>
      </Column>
      <Column header="" style="width: 100px">
        <template #body="{ data }">
          <div class="flex gap-1 justify-end">
            <Button
              icon="pi pi-pencil"
              text
              rounded
              size="small"
              aria-label="Editar"
              @click="abrirEdicao(data)"
            />
            <Button
              :icon="data.ativo ? 'pi pi-circle-off' : 'pi pi-check-circle'"
              text
              rounded
              size="small"
              :aria-label="data.ativo ? 'Desativar' : 'Ativar'"
              @click="alternarAtivo(data)"
            />
          </div>
        </template>
      </Column>
    </DataTable>

    <!-- Modal criação -->
    <Dialog
      v-model:visible="modalCriar"
      header="Nova turma"
      :modal="true"
      class="w-full max-w-md"
    >
      <form
        class="flex flex-col gap-4"
        @submit.prevent="criar"
      >
        <div class="flex flex-col gap-1">
          <label class="text-sm font-medium">Nome *</label>
          <InputText
            v-model="form.nome"
            class="w-full"
            placeholder="Ex.: Turma 2 - Tio Beto"
          />
        </div>
        <div class="flex flex-col gap-1">
          <label class="text-sm font-medium">Líder responsável *</label>
          <Select
            v-model="form.lider_id"
            :options="lideresDisponiveis"
            option-label="label"
            option-value="value"
            placeholder="Selecione"
            class="w-full"
          />
        </div>
        <div class="flex justify-end gap-2">
          <Button
            label="Cancelar"
            text
            @click="modalCriar = false"
          />
          <Button
            type="submit"
            label="Criar"
            :loading="salvando"
          />
        </div>
      </form>
    </Dialog>

    <!-- Modal edição -->
    <Dialog
      :visible="editando !== null"
      header="Editar turma"
      :modal="true"
      class="w-full max-w-md"
      @update:visible="editando = null"
    >
      <form
        v-if="editando"
        class="flex flex-col gap-4"
        @submit.prevent="salvarEdicao"
      >
        <div class="flex flex-col gap-1">
          <label class="text-sm font-medium">Nome *</label>
          <InputText
            v-model="formEditar.nome"
            class="w-full"
          />
        </div>
        <div class="flex flex-col gap-1">
          <label class="text-sm font-medium">Líder responsável *</label>
          <Select
            v-model="formEditar.lider_id"
            :options="lideresEdicao"
            option-label="label"
            option-value="value"
            class="w-full"
          />
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
