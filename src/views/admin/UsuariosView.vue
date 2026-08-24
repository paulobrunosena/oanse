<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import Button from 'primevue/button'
import Column from 'primevue/column'
import DataTable from 'primevue/datatable'
import Dialog from 'primevue/dialog'
import InputSwitch from 'primevue/inputswitch'
import InputText from 'primevue/inputtext'
import Select from 'primevue/select'
import Tag from 'primevue/tag'
import { supabase } from '@/lib/supabase'
import { apiFetch } from '@/lib/api'
import { useToast } from '@/composables/useToast'
import type { UserRole } from '@/composables/useAuth'

type Usuario = {
  id: string
  email: string
  nome: string
  telefone: string | null
  role: UserRole
  clube_id: string | null
  ativo: boolean
}

const toast = useToast()

const usuarios = ref<Usuario[]>([])
const clubes = ref<{ id: string, nome: string, cor: string | null }[]>([])
const carregando = ref(true)

const opcoesRole: { label: string, value: UserRole }[] = [
  { label: 'Diretor Geral', value: 'diretor_geral' },
  { label: 'Secretaria', value: 'secretaria' },
  { label: 'Diretor de Clube', value: 'diretor_clube' },
  { label: 'Líder', value: 'lider' },
]

async function carregar() {
  carregando.value = true
  const [lista, clubesData] = await Promise.all([
    apiFetch<Usuario[]>('/api/usuarios'),
    supabase.from('clubes').select('id, nome, cor').order('ordem'),
  ])
  usuarios.value = lista
  clubes.value = clubesData.data ?? []
  carregando.value = false
}

onMounted(carregar)

const nomeClube = (id: string | null) => clubes.value.find(c => c.id === id)?.nome ?? '—'
const nomeRole = (role: UserRole) => opcoesRole.find(r => r.value === role)?.label ?? role

// ---- Criação ----
const modalCriar = ref(false)
const salvando = ref(false)
const formCriar = reactive({
  nome: '',
  email: '',
  senha: '',
  telefone: '',
  role: 'lider' as UserRole,
  clube_id: null as string | null,
})

async function criar() {
  salvando.value = true
  try {
    await apiFetch('/api/usuarios', {
      method: 'POST',
      body: {
        nome: formCriar.nome,
        email: formCriar.email,
        senha: formCriar.senha,
        telefone: formCriar.telefone || null,
        role: formCriar.role,
        clube_id: formCriar.clube_id || null,
      },
    })
    toast.add({ title: 'Usuário criado', color: 'success' })
    modalCriar.value = false
    Object.assign(formCriar, { nome: '', email: '', senha: '', telefone: '', role: 'lider', clube_id: null })
    await carregar()
  }
  catch (e) {
    const erro = e as Partial<{ statusMessage?: string, message?: string }>
    toast.add({ title: 'Erro ao criar', description: erro.statusMessage ?? erro.message, color: 'error' })
  }
  finally {
    salvando.value = false
  }
}

// ---- Edição ----
const editando = ref<Usuario | null>(null)
const formEditar = reactive({ nome: '', telefone: '', role: 'lider' as UserRole, clube_id: null as string | null, ativo: true })

function abrirEdicao(u: Usuario) {
  editando.value = u
  Object.assign(formEditar, {
    nome: u.nome,
    telefone: u.telefone ?? '',
    role: u.role,
    clube_id: u.clube_id,
    ativo: u.ativo,
  })
}

async function salvarEdicao() {
  if (!editando.value) return
  salvando.value = true
  const { error } = await supabase
    .from('profiles')
    .update({
      nome: formEditar.nome,
      telefone: formEditar.telefone || null,
      role: formEditar.role,
      clube_id: formEditar.clube_id || null,
      ativo: formEditar.ativo,
    })
    .eq('id', editando.value.id)
  salvando.value = false

  if (error) {
    toast.add({ title: 'Erro ao salvar', description: error.message, color: 'error' })
    return
  }
  toast.add({ title: 'Usuário atualizado', color: 'success' })
  editando.value = null
  await carregar()
}

// ---- Exclusão ----
const excluindo = ref<Usuario | null>(null)

async function confirmarExclusao() {
  if (!excluindo.value) return
  try {
    await apiFetch(`/api/usuarios/${excluindo.value.id}`, { method: 'DELETE' })
    toast.add({ title: 'Usuário excluído', color: 'success' })
    excluindo.value = null
    await carregar()
  }
  catch (e) {
    const erro = e as Partial<{ statusMessage?: string, message?: string }>
    toast.add({ title: 'Erro ao excluir', description: erro.statusMessage ?? erro.message, color: 'error' })
    excluindo.value = null
  }
}
</script>

<template>
  <div class="p-4 sm:p-6 max-w-5xl mx-auto w-full">
    <div class="flex items-center justify-between mb-4">
      <div>
        <h1 class="text-2xl font-bold">
          Usuários
        </h1>
        <p class="text-sm text-surface-500">
          Gerenciar acessos, perfis e vínculos com clubes
        </p>
      </div>
      <Button
        icon="pi pi-plus"
        label="Novo usuário"
        @click="modalCriar = true"
      />
    </div>

    <DataTable
      :value="usuarios"
      :loading="carregando"
      data-key="id"
      class="w-full"
    >
      <Column field="nome" header="Nome" />
      <Column field="email" header="E-mail" />
      <Column field="role" header="Perfil">
        <template #body="{ data }">
          <Tag :value="nomeRole(data.role)" />
        </template>
      </Column>
      <Column header="Clube">
        <template #body="{ data }">
          {{ nomeClube(data.clube_id) }}
        </template>
      </Column>
      <Column field="ativo" header="Situação">
        <template #body="{ data }">
          <Tag
            :severity="data.ativo ? 'success' : 'secondary'"
            :value="data.ativo ? 'Ativo' : 'Inativo'"
          />
        </template>
      </Column>
      <Column header="" style="width: 90px">
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
              icon="pi pi-trash"
              text
              rounded
              severity="danger"
              size="small"
              aria-label="Excluir"
              @click="excluindo = data"
            />
          </div>
        </template>
      </Column>
    </DataTable>

    <!-- Modal criação -->
    <Dialog
      v-model:visible="modalCriar"
      header="Novo usuário"
      :modal="true"
      class="w-full max-w-md"
    >
      <form
        class="flex flex-col gap-4"
        @submit.prevent="criar"
      >
        <div class="flex flex-col gap-1">
          <label
            for="nu-nome"
            class="text-sm font-medium"
          >Nome *</label>
          <InputText
            id="nu-nome"
            v-model="formCriar.nome"
            class="w-full"
          />
        </div>
        <div class="flex flex-col gap-1">
          <label
            for="nu-email"
            class="text-sm font-medium"
          >E-mail *</label>
          <InputText
            id="nu-email"
            v-model="formCriar.email"
            type="email"
            class="w-full"
          />
        </div>
        <div class="flex flex-col gap-1">
          <label
            for="nu-senha"
            class="text-sm font-medium"
          >Senha inicial *</label>
          <InputText
            id="nu-senha"
            v-model="formCriar.senha"
            type="password"
            class="w-full"
          />
          <small class="text-surface-400">Mínimo 6 caracteres</small>
        </div>
        <div class="flex flex-col gap-1">
          <label
            for="nu-telefone"
            class="text-sm font-medium"
          >Telefone</label>
          <InputText
            id="nu-telefone"
            v-model="formCriar.telefone"
            class="w-full"
            placeholder="(81) 9..."
          />
        </div>
        <div class="flex flex-col gap-1">
          <label
            for="nu-role"
            class="text-sm font-medium"
          >Perfil *</label>
          <Select
            id="nu-role"
            v-model="formCriar.role"
            :options="opcoesRole"
            option-label="label"
            option-value="value"
            class="w-full"
          />
        </div>
        <div class="flex flex-col gap-1">
          <label
            for="nu-clube"
            class="text-sm font-medium"
          >Clube</label>
          <Select
            id="nu-clube"
            v-model="formCriar.clube_id"
            :options="[{ label: '—', value: null }, ...clubes.map(c => ({ label: c.nome, value: c.id }))]"
            option-label="label"
            option-value="value"
            class="w-full"
          />
          <small class="text-surface-400">Vazio para Diretor Geral e Secretaria</small>
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
      header="Editar usuário"
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
          <label class="text-sm font-medium">Telefone</label>
          <InputText
            v-model="formEditar.telefone"
            class="w-full"
          />
        </div>
        <div class="flex flex-col gap-1">
          <label class="text-sm font-medium">Perfil *</label>
          <Select
            v-model="formEditar.role"
            :options="opcoesRole"
            option-label="label"
            option-value="value"
            class="w-full"
          />
        </div>
        <div class="flex flex-col gap-1">
          <label class="text-sm font-medium">Clube</label>
          <Select
            v-model="formEditar.clube_id"
            :options="[{ label: '—', value: null }, ...clubes.map(c => ({ label: c.nome, value: c.id }))]"
            option-label="label"
            option-value="value"
            class="w-full"
          />
          <small class="text-surface-400">Vazio para Diretor Geral e Secretaria</small>
        </div>
        <div class="flex items-center gap-2">
          <InputSwitch v-model="formEditar.ativo" />
          <label class="text-sm font-medium">Usuário ativo</label>
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

    <!-- Confirmação exclusão -->
    <Dialog
      :visible="excluindo !== null"
      header="Excluir usuário"
      :modal="true"
      class="w-full max-w-md"
      @update:visible="excluindo = null"
    >
      <p>
        Excluir <strong>{{ excluindo?.nome }}</strong> ({{ excluindo?.email }})?
        Esta ação não pode ser desfeita e remove também o perfil vinculado.
      </p>
      <div class="flex justify-end gap-2 mt-4">
        <Button
          label="Cancelar"
          text
          @click="excluindo = null"
        />
        <Button
          label="Excluir"
          severity="danger"
          @click="confirmarExclusao"
        />
      </div>
    </Dialog>
  </div>
</template>
