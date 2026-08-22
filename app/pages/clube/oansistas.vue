<script setup lang="ts">
import type { TableColumn } from '@nuxt/ui'
import type { Database } from '~/types/database.types'

type Oansista = Database['public']['Tables']['oansistas']['Row']

definePageMeta({ middleware: ['role'], roles: ['diretor_geral', 'diretor_clube'] })
useSeoMeta({ title: 'Oansistas — Oanse' })

const { profile } = useAuth()
const supabase = useSupabaseClient()
const toast = useToast()

const oansistas = ref<(Oansista & { turma_nome: string | null })[]>([])
const turmas = ref<{ id: string, nome: string }[]>([])
const carregando = ref(true)
const salvando = ref(false)

async function carregar() {
  carregando.value = true
  const { data } = await supabase
    .from('oansistas')
    .select('*, turma:turmas(nome)')
    .eq('clube_id', profile.value!.clube_id!)
    .order('nome')
  oansistas.value = (data ?? []).map(o => ({
    ...o,
    turma_nome: (o.turma as unknown as { nome: string } | null)?.nome ?? null,
  }))
  carregando.value = false
}

async function carregarTurmas() {
  const { data } = await supabase
    .from('turmas')
    .select('id, nome')
    .eq('clube_id', profile.value!.clube_id!)
    .eq('ativo', true)
    .order('nome')
  turmas.value = data ?? []
}

onMounted(() => {
  carregar()
  carregarTurmas()
})

const idade = (nasc: string) => {
  const anos = Math.floor((Date.now() - new Date(nasc).getTime()) / (365.25 * 24 * 3600 * 1000))
  return `${anos}a`
}

const colunas: TableColumn<Oansista & { turma_nome: string | null }>[] = [
  { accessorKey: 'nome', header: 'Nome' },
  { accessorKey: 'idade', header: 'Idade', cell: ({ row }) => idade(row.original.data_nascimento) },
  { accessorKey: 'turma_nome', header: 'Turma', cell: ({ row }) => row.original.turma_nome ?? '—' },
  { accessorKey: 'status', header: 'Situação' },
  { id: 'acoes' },
]

// ---- Criação/edição compartilham o form ----
const modal = ref(false)
const editando = ref<string | null>(null)
const form = reactive({
  nome: '',
  data_nascimento: '',
  turma_id: '',
  responsavel: '',
  contato: '',
  status: 'ativo' as Oansista['status'],
  observacoes: '',
})

function abrirCriar() {
  editando.value = null
  Object.assign(form, {
    nome: '', data_nascimento: '', turma_id: '',
    responsavel: '', contato: '', status: 'ativo', observacoes: '',
  })
  modal.value = true
}

function abrirEdicao(o: Oansista & { turma_nome: string | null }) {
  editando.value = o.id
  Object.assign(form, {
    nome: o.nome,
    data_nascimento: o.data_nascimento,
    turma_id: o.turma_id ?? '',
    responsavel: o.responsavel ?? '',
    contato: o.contato ?? '',
    status: o.status,
    observacoes: o.observacoes ?? '',
  })
  modal.value = true
}

async function salvar() {
  if (!form.nome.trim() || !form.data_nascimento) {
    toast.add({ title: 'Nome e data de nascimento são obrigatórios', color: 'error' })
    return
  }
  salvando.value = true
  const payload = {
    nome: form.nome.trim(),
    data_nascimento: form.data_nascimento,
    turma_id: form.turma_id || null,
    responsavel: form.responsavel.trim() || null,
    contato: form.contato.trim() || null,
    status: form.status,
    observacoes: form.observacoes.trim() || null,
  }
  const { error } = editando.value
    ? await supabase.from('oansistas').update(payload).eq('id', editando.value)
    : await supabase.from('oansistas').insert({ ...payload, clube_id: profile.value!.clube_id! })
  salvando.value = false

  if (error) {
    toast.add({ title: 'Erro ao salvar', description: error.message, color: 'error' })
    return
  }
  toast.add({ title: editando.value ? 'Oansista atualizado' : 'Oansista cadastrado', color: 'success' })
  modal.value = false
  await carregar()
}

// ---- Importação CSV ----
const modalCsv = ref(false)
const csvTexto = ref('')
const csvResultado = ref<{ ok: number, erros: string[] } | null>(null)
const importando = ref(false)

const EXEMPLO_CSV = 'Nome;Nascimento(AAAA-MM-DD);Responsavel;Contato\nMaria Silva;2018-05-10;Ana Silva;81988880201'

async function importarCsv() {
  const linhas = csvTexto.value.trim().split(/\r?\n/).filter(Boolean)
  const erros: string[] = []
  const registros: Database['public']['Tables']['oansistas']['Insert'][] = []

  linhas.forEach((linha, i) => {
    const [nome = '', nasc = '', responsavel = '', contato = ''] = linha.split(';').map(c => c.trim())
    if (!nome || !/^\d{4}-\d{2}-\d{2}$/.test(nasc)) {
      erros.push(`Linha ${i + 1}: formato inválido (use "${EXEMPLO_CSV}")`)
      return
    }
    registros.push({
      nome,
      data_nascimento: nasc,
      responsavel: responsavel || null,
      contato: contato || null,
      clube_id: profile.value!.clube_id!,
      turma_id: null,
    })
  })

  if (erros.length > 0 || registros.length === 0) {
    csvResultado.value = { ok: 0, erros: erros.length > 0 ? erros : ['Nenhuma linha válida para importar'] }
    return
  }

  importando.value = true
  const { error } = await supabase.from('oansistas').insert(registros)
  importando.value = false

  if (error) {
    csvResultado.value = { ok: 0, erros: [error.message] }
    return
  }
  csvResultado.value = { ok: registros.length, erros: [] }
  toast.add({ title: `${registros.length} oansistas importados`, color: 'success' })
  await carregar()
}
</script>

<template>
  <div class="p-4 sm:p-6 max-w-4xl mx-auto w-full">
    <div class="flex items-center justify-between mb-4">
      <div>
        <h1 class="text-2xl font-bold">
          Oansistas
        </h1>
        <p class="text-sm text-muted">
          Crianças matriculadas no clube
        </p>
      </div>
      <div class="flex gap-2">
        <UButton
          icon="i-lucide-upload"
          color="neutral"
          variant="outline"
          @click="modalCsv = true"
        >
          Importar CSV
        </UButton>
        <UButton
          icon="i-lucide-plus"
          @click="abrirCriar"
        >
          Novo
        </UButton>
      </div>
    </div>

    <UTable
      :data="oansistas"
      :columns="colunas"
      :loading="carregando"
    >
      <template #status-cell="{ row }">
        <UBadge
          :color="row.original.status === 'ativo' ? 'success' : 'neutral'"
          variant="subtle"
        >
          {{ row.original.status === 'ativo' ? 'Ativo' : 'Inativo' }}
        </UBadge>
      </template>
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

    <!-- Modal criar/editar -->
    <UModal
      v-model:open="modal"
      :title="editando ? 'Editar oansista' : 'Novo oansista'"
    >
      <template #body>
        <UForm
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
              label="Data de nascimento"
              name="data_nascimento"
              required
            >
              <UInput
                v-model="form.data_nascimento"
                type="date"
                class="w-full"
              />
            </UFormField>
            <UFormField
              label="Turma"
              name="turma_id"
            >
              <USelect
                v-model="form.turma_id"
                :items="[{ label: 'Sem turma', value: '' }, ...turmas.map(t => ({ label: t.nome, value: t.id }))]"
                class="w-full"
              />
            </UFormField>
          </div>
          <div class="grid grid-cols-2 gap-4">
            <UFormField
              label="Responsável"
              name="responsavel"
            >
              <UInput
                v-model="form.responsavel"
                class="w-full"
              />
            </UFormField>
            <UFormField
              label="Contato"
              name="contato"
            >
              <UInput
                v-model="form.contato"
                class="w-full"
              />
            </UFormField>
          </div>
          <UFormField
            label="Situação"
            name="status"
          >
            <USelect
              v-model="form.status"
              :items="[{ label: 'Ativo', value: 'ativo' }, { label: 'Inativo', value: 'inativo' }]"
              class="w-full"
            />
          </UFormField>
          <UFormField
            label="Observações"
            name="observacoes"
          >
            <UTextarea
              v-model="form.observacoes"
              class="w-full"
              :rows="2"
            />
          </UFormField>
          <div class="flex justify-end gap-2">
            <UButton
              variant="ghost"
              @click="modal = false"
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

    <!-- Modal importar CSV -->
    <UModal
      v-model:open="modalCsv"
      title="Importar oansistas (CSV)"
    >
      <template #body>
        <div class="flex flex-col gap-4">
          <p class="text-sm text-muted">
            Cole as linhas no formato <code>{{ EXEMPLO_CSV }}</code>.
            As crianças entram sem turma — atribua depois editando cada uma.
          </p>
          <UTextarea
            v-model="csvTexto"
            :rows="8"
            placeholder="Nome;AAAA-MM-DD;Responsavel;Contato"
          />
          <div v-if="csvResultado">
            <p
              v-if="csvResultado.ok > 0"
              class="text-sm text-success"
            >
              {{ csvResultado.ok }} oansistas importados com sucesso.
            </p>
            <ul
              v-if="csvResultado.erros.length"
              class="text-sm text-error list-disc pl-4"
            >
              <li
                v-for="(e, i) in csvResultado.erros"
                :key="i"
              >
                {{ e }}
              </li>
            </ul>
          </div>
          <div class="flex justify-end gap-2">
            <UButton
              variant="ghost"
              @click="modalCsv = false; csvResultado = null"
            >
              Fechar
            </UButton>
            <UButton
              :loading="importando"
              :disabled="!csvTexto.trim()"
              @click="importarCsv"
            >
              Importar
            </UButton>
          </div>
        </div>
      </template>
    </UModal>
  </div>
</template>
