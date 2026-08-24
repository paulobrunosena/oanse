<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import Button from 'primevue/button'
import Column from 'primevue/column'
import DataTable from 'primevue/datatable'
import Dialog from 'primevue/dialog'
import InputText from 'primevue/inputtext'
import Select from 'primevue/select'
import Tag from 'primevue/tag'
import Textarea from 'primevue/textarea'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/composables/useAuth'
import { useToast } from '@/composables/useToast'
import type { Database } from '@/types/database.types'

type Oansista = Database['public']['Tables']['oansistas']['Row']

const { profile } = useAuth()
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

// ---- Criação/edição compartilham o form ----
const modal = ref(false)
const editando = ref<string | null>(null)
const form = reactive({
  nome: '',
  data_nascimento: '',
  turma_id: null as string | null,
  responsavel: '',
  contato: '',
  status: 'ativo' as Oansista['status'],
  observacoes: '',
})

function abrirCriar() {
  editando.value = null
  Object.assign(form, {
    nome: '', data_nascimento: '', turma_id: null,
    responsavel: '', contato: '', status: 'ativo', observacoes: '',
  })
  modal.value = true
}

function abrirEdicao(o: Oansista & { turma_nome: string | null }) {
  editando.value = o.id
  Object.assign(form, {
    nome: o.nome,
    data_nascimento: o.data_nascimento,
    turma_id: o.turma_id,
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
        <p class="text-sm text-surface-500">
          Crianças matriculadas no clube
        </p>
      </div>
      <div class="flex gap-2">
        <Button
          icon="pi pi-upload"
          label="Importar CSV"
          text
          @click="modalCsv = true"
        />
        <Button
          icon="pi pi-plus"
          label="Novo"
          @click="abrirCriar"
        />
      </div>
    </div>

    <DataTable
      :value="oansistas"
      :loading="carregando"
      data-key="id"
      class="w-full"
    >
      <Column field="nome" header="Nome" />
      <Column header="Idade">
        <template #body="{ data }">
          {{ idade(data.data_nascimento) }}
        </template>
      </Column>
      <Column header="Turma">
        <template #body="{ data }">
          {{ data.turma_nome ?? '—' }}
        </template>
      </Column>
      <Column header="Situação">
        <template #body="{ data }">
          <Tag
            :severity="data.status === 'ativo' ? 'success' : 'secondary'"
            :value="data.status === 'ativo' ? 'Ativo' : 'Inativo'"
          />
        </template>
      </Column>
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

    <!-- Modal criar/editar -->
    <Dialog
      v-model:visible="modal"
      :header="editando ? 'Editar oansista' : 'Novo oansista'"
      :modal="true"
      class="w-full max-w-lg"
    >
      <form
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
        <div class="grid grid-cols-2 gap-4">
          <div class="flex flex-col gap-1">
            <label class="text-sm font-medium">Data de nascimento *</label>
            <InputText
              v-model="form.data_nascimento"
              type="date"
              class="w-full"
            />
          </div>
          <div class="flex flex-col gap-1">
            <label class="text-sm font-medium">Turma</label>
            <Select
              v-model="form.turma_id"
              :options="[{ label: 'Sem turma', value: null }, ...turmas.map(t => ({ label: t.nome, value: t.id }))]"
              option-label="label"
              option-value="value"
              class="w-full"
            />
          </div>
        </div>
        <div class="grid grid-cols-2 gap-4">
          <div class="flex flex-col gap-1">
            <label class="text-sm font-medium">Responsável</label>
            <InputText
              v-model="form.responsavel"
              class="w-full"
            />
          </div>
          <div class="flex flex-col gap-1">
            <label class="text-sm font-medium">Contato</label>
            <InputText
              v-model="form.contato"
              class="w-full"
            />
          </div>
        </div>
        <div class="flex flex-col gap-1">
          <label class="text-sm font-medium">Situação</label>
          <Select
            v-model="form.status"
            :options="[{ label: 'Ativo', value: 'ativo' }, { label: 'Inativo', value: 'inativo' }]"
            option-label="label"
            option-value="value"
            class="w-full"
          />
        </div>
        <div class="flex flex-col gap-1">
          <label class="text-sm font-medium">Observações</label>
          <Textarea
            v-model="form.observacoes"
            class="w-full"
            rows="2"
          />
        </div>
        <div class="flex justify-end gap-2">
          <Button
            label="Cancelar"
            text
            @click="modal = false"
          />
          <Button
            type="submit"
            label="Salvar"
            :loading="salvando"
          />
        </div>
      </form>
    </Dialog>

    <!-- Modal importar CSV -->
    <Dialog
      v-model:visible="modalCsv"
      header="Importar oansistas (CSV)"
      :modal="true"
      class="w-full max-w-lg"
      @update:visible="modalCsv = $event; if (!$event) csvResultado = null"
    >
      <div class="flex flex-col gap-4">
        <p class="text-sm text-surface-500">
          Cole as linhas no formato <code>{{ EXEMPLO_CSV }}</code>.
          As crianças entram sem turma — atribua depois editando cada uma.
        </p>
        <Textarea
          v-model="csvTexto"
          rows="8"
          placeholder="Nome;AAAA-MM-DD;Responsavel;Contato"
          class="w-full"
        />
        <div v-if="csvResultado">
          <p
            v-if="csvResultado.ok > 0"
            class="text-sm text-green-600"
          >
            {{ csvResultado.ok }} oansistas importados com sucesso.
          </p>
          <ul
            v-if="csvResultado.erros.length"
            class="text-sm text-red-600 list-disc pl-4"
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
          <Button
            label="Fechar"
            text
            @click="modalCsv = false; csvResultado = null"
          />
          <Button
            label="Importar"
            :loading="importando"
            :disabled="!csvTexto.trim()"
            @click="importarCsv"
          />
        </div>
      </div>
    </Dialog>
  </div>
</template>
