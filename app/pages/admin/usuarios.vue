<script setup lang="ts">
import type { TableColumn } from '@nuxt/ui'
import type { UserRole } from '~/composables/useAuth'

type Usuario = {
  id: string
  email: string
  nome: string
  telefone: string | null
  role: UserRole
  clube_id: string | null
  ativo: boolean
}

definePageMeta({ middleware: ['role'], roles: ['diretor_geral'] })
useSeoMeta({ title: 'Usuários — Oanse' })

const supabase = useSupabaseClient()
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
    $fetch<Usuario[]>('/api/usuarios'),
    supabase.from('clubes').select('id, nome, cor').order('ordem'),
  ])
  usuarios.value = lista
  clubes.value = clubesData.data ?? []
  carregando.value = false
}

onMounted(carregar)

const nomeClube = (id: string | null) => clubes.value.find(c => c.id === id)?.nome ?? '—'
const nomeRole = (role: UserRole) => opcoesRole.find(r => r.value === role)?.label ?? role

const colunas: TableColumn<Usuario>[] = [
  { accessorKey: 'nome', header: 'Nome' },
  { accessorKey: 'email', header: 'E-mail' },
  { accessorKey: 'role', header: 'Perfil' },
  { accessorKey: 'clube', header: 'Clube' },
  { accessorKey: 'ativo', header: 'Situação' },
  { id: 'acoes', header: '' },
]

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
    await $fetch('/api/usuarios', {
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
    await $fetch(`/api/usuarios/${excluindo.value.id}`, { method: 'DELETE' })
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
        <p class="text-sm text-muted">
          Gerenciar acessos, perfis e vínculos com clubes
        </p>
      </div>
      <UButton
        icon="i-lucide-plus"
        @click="modalCriar = true"
      >
        Novo usuário
      </UButton>
    </div>

    <UTable
      :data="usuarios"
      :columns="colunas"
      :loading="carregando"
      class="flex-1"
    >
      <template #role-cell="{ row }">
        <UBadge variant="subtle">
          {{ nomeRole(row.original.role) }}
        </UBadge>
      </template>
      <template #clube-cell="{ row }">
        {{ nomeClube(row.original.clube_id) }}
      </template>
      <template #ativo-cell="{ row }">
        <UBadge
          :color="row.original.ativo ? 'success' : 'neutral'"
          variant="subtle"
        >
          {{ row.original.ativo ? 'Ativo' : 'Inativo' }}
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
            icon="i-lucide-trash-2"
            color="error"
            variant="ghost"
            size="sm"
            aria-label="Excluir"
            @click="excluindo = row.original"
          />
        </div>
      </template>
    </UTable>

    <!-- Modal criação -->
    <UModal
      v-model:open="modalCriar"
      title="Novo usuário"
    >
      <template #body>
        <UForm
          :state="formCriar"
          class="flex flex-col gap-4"
          @submit="criar"
        >
          <UFormField
            label="Nome"
            name="nome"
            required
          >
            <UInput
              v-model="formCriar.nome"
              class="w-full"
            />
          </UFormField>
          <UFormField
            label="E-mail"
            name="email"
            required
          >
            <UInput
              v-model="formCriar.email"
              type="email"
              class="w-full"
            />
          </UFormField>
          <UFormField
            label="Senha inicial"
            name="senha"
            required
            hint="Mínimo 6 caracteres"
          >
            <UInput
              v-model="formCriar.senha"
              type="password"
              class="w-full"
            />
          </UFormField>
          <UFormField
            label="Telefone"
            name="telefone"
          >
            <UInput
              v-model="formCriar.telefone"
              class="w-full"
              placeholder="(81) 9..."
            />
          </UFormField>
          <UFormField
            label="Perfil"
            name="role"
            required
          >
            <USelect
              v-model="formCriar.role"
              :items="opcoesRole"
              class="w-full"
            />
          </UFormField>
          <UFormField
            label="Clube"
            name="clube_id"
            hint="Vazio para Diretor Geral e Secretaria"
          >
            <USelect
              v-model="formCriar.clube_id"
              :items="[{ label: '—', value: null }, ...clubes.map(c => ({ label: c.nome, value: c.id }))]"
              class="w-full"
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
      title="Editar usuário"
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
            label="Telefone"
            name="telefone"
          >
            <UInput
              v-model="formEditar.telefone"
              class="w-full"
            />
          </UFormField>
          <UFormField
            label="Perfil"
            name="role"
            required
          >
            <USelect
              v-model="formEditar.role"
              :items="opcoesRole"
              class="w-full"
            />
          </UFormField>
          <UFormField
            label="Clube"
            name="clube_id"
            hint="Vazio para Diretor Geral e Secretaria"
          >
            <USelect
              v-model="formEditar.clube_id"
              :items="[{ label: '—', value: null }, ...clubes.map(c => ({ label: c.nome, value: c.id }))]"
              class="w-full"
            />
          </UFormField>
          <UFormField
            label="Situação"
            name="ativo"
          >
            <USwitch
              v-model="formEditar.ativo"
              label="Usuário ativo"
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

    <!-- Confirmação exclusão -->
    <UModal
      :open="!!excluindo"
      title="Excluir usuário"
      @update:open="excluindo = null"
    >
      <template #body>
        <p>
          Excluir <strong>{{ excluindo?.nome }}</strong> ({{ excluindo?.email }})?
          Esta ação não pode ser desfeita e remove também o perfil vinculado.
        </p>
        <div class="flex justify-end gap-2 mt-4">
          <UButton
            variant="ghost"
            @click="excluindo = null"
          >
            Cancelar
          </UButton>
          <UButton
            color="error"
            @click="confirmarExclusao"
          >
            Excluir
          </UButton>
        </div>
      </template>
    </UModal>
  </div>
</template>
