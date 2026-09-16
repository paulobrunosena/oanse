<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { useConfirm } from 'primevue/useconfirm'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/composables/useAuth'
import { useRole } from '@/composables/useRole'
import { useToast } from '@/composables/useToast'
import { useTransferenciaClube } from '@/composables/useTransferenciaClube'
import { avaliarIdadeClube, clubeParaProgredir, idadeEmAnos, type ClubeFaixa } from '@/utils/idade'
import type { Database } from '@/types/database.types'

type Oansista = Database['public']['Tables']['oansistas']['Row']

const { profile } = useAuth()
const { isDiretorGeral, isDiretorClube } = useRole()
const toast = useToast()
const confirm = useConfirm()
const { transferir: transferirRpc, cancelar: cancelarRpc } = useTransferenciaClube()

const oansistas = ref<(Oansista & { turma_nome: string | null })[]>([])
const turmas = ref<{ id: string, nome: string }[]>([])
const clubes = ref<{ id: string, nome: string, idade_min: number, idade_max: number }[]>([])
const carregando = ref(true)
const salvando = ref(false)

const podeTransferir = computed(() => isDiretorGeral.value || isDiretorClube.value)

const mostrarInativos = ref(false)
const oansistasVisiveis = computed(() =>
  mostrarInativos.value
    ? oansistas.value
    : oansistas.value.filter(o => o.status === 'ativo'),
)

async function carregar() {
  carregando.value = true
  try {
    const { data, error } = await supabase
      .from('oansistas')
      .select('*, turma:turmas(nome)')
      .eq('clube_id', profile.value!.clube_id!)
      .order('nome')
    if (error) throw error
    oansistas.value = (data ?? []).map(o => ({
      ...o,
      turma_nome: (o.turma as unknown as { nome: string } | null)?.nome ?? null,
    }))
  }
  catch (e) {
    toast.add({ title: 'Erro ao carregar os oansistas', description: (e as { message?: string })?.message ?? 'Tente novamente', color: 'error' })
  }
  finally {
    carregando.value = false
  }
}

async function carregarTurmas() {
  const { data, error } = await supabase
    .from('turmas')
    .select('id, nome')
    .eq('clube_id', profile.value!.clube_id!)
    .eq('ativo', true)
    .order('nome')
  if (error) throw error
  turmas.value = data ?? []
}

async function carregarClubes() {
  const { data } = await supabase
    .from('clubes')
    .select('id, nome, idade_min, idade_max')
    .order('ordem')
  clubes.value = data ?? []
}

onMounted(() => {
  carregar()
  carregarTurmas()
  carregarClubes()
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

const avaliacaoIdade = computed(() =>
  avaliarIdadeClube(clubes.value, form.data_nascimento, profile.value?.clube_id ?? null),
)

const hintIdade = computed<{ severidade: 'error' | 'warn', texto: string } | null>(() => {
  const a = avaliacaoIdade.value
  if (a.tipo === 'muito_novo') {
    return { severidade: 'error', texto: 'A criança nasceu neste ano e ainda não pode ser cadastrada.' }
  }
  if (a.tipo === 'clube_diferente') {
    return {
      severidade: 'warn',
      texto: `A idade corresponde ao clube ${a.clubeSugerido.nome} (${a.clubeSugerido.idade_min} a ${a.clubeSugerido.idade_max} anos).`,
    }
  }
  if (a.tipo === 'fora_de_todas') {
    return { severidade: 'warn', texto: 'A idade não corresponde a nenhuma faixa de clube.' }
  }
  return null
})

async function persistirSalvar() {
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

async function salvar() {
  if (!form.nome.trim() || !form.data_nascimento) {
    toast.add({ title: 'Nome e data de nascimento são obrigatórios', color: 'error' })
    return
  }

  const avaliacao = avaliarIdadeClube(clubes.value, form.data_nascimento, profile.value?.clube_id ?? null)
  if (avaliacao.tipo === 'muito_novo') {
    toast.add({
      title: 'Data de nascimento inválida',
      description: 'A criança nasceu neste ano e ainda não pode ser cadastrada.',
      color: 'error',
    })
    return
  }
  if (avaliacao.tipo === 'clube_diferente') {
    const alvo = clubes.value.find(c => c.id === profile.value?.clube_id)?.nome ?? 'este clube'
    confirm.require({
      header: 'Idade de outro clube',
      message: `A idade informada corresponde ao clube ${avaliacao.clubeSugerido.nome} (${avaliacao.clubeSugerido.idade_min} a ${avaliacao.clubeSugerido.idade_max} anos), e não a ${alvo}. Deseja cadastrar em ${alvo} mesmo assim?`,
      icon: 'pi pi-exclamation-triangle',
      acceptLabel: 'Sim, cadastrar',
      rejectLabel: 'Cancelar',
      acceptProps: { severity: 'warn' },
      rejectProps: { severity: 'secondary', text: true },
      accept: () => persistirSalvar(),
    })
    return
  }

  await persistirSalvar()
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

// ---- Transferência de clube (mudança de faixa etária) ----
const transferirModal = ref(false)
const transferirSel = ref<Oansista | null>(null)
const transferirDestino = ref<string | null>(null)
const transferirMotivo = ref('')
const transferindo = ref(false)

const clubesDestino = computed(() =>
  clubes.value.filter(c => c.id !== transferirSel.value?.clube_id),
)

const avaliacaoTransferencia = computed(() =>
  avaliarIdadeClube(
    clubes.value,
    transferirSel.value?.data_nascimento ?? '',
    transferirDestino.value,
  ),
)

const hintTransferencia = computed<{ severidade: 'error' | 'warn', texto: string } | null>(() => {
  if (!transferirDestino.value) return null
  const a = avaliacaoTransferencia.value
  if (a.tipo === 'muito_novo') {
    return { severidade: 'error', texto: 'A criança nasceu neste ano.' }
  }
  if (a.tipo === 'clube_diferente') {
    return {
      severidade: 'warn',
      texto: `A idade corresponde ao clube ${a.clubeSugerido.nome} (${a.clubeSugerido.idade_min} a ${a.clubeSugerido.idade_max} anos).`,
    }
  }
  if (a.tipo === 'fora_de_todas') {
    return { severidade: 'warn', texto: 'A idade não corresponde a nenhuma faixa de clube.' }
  }
  return null
})

function abrirTransferir(o: Oansista & { turma_nome: string | null }) {
  transferirSel.value = o
  transferirDestino.value = null
  transferirMotivo.value = ''
  transferirModal.value = true
}

async function persistirTransferir() {
  if (!transferirSel.value || !transferirDestino.value) return
  transferindo.value = true
  try {
    await transferirRpc(
      transferirSel.value.id,
      transferirDestino.value,
      transferirMotivo.value.trim() || null,
    )
    toast.add({ title: 'Criança transferida de clube', color: 'success' })
    transferirModal.value = false
    await carregar()
  }
  catch (e) {
    toast.add({ title: 'Erro ao transferir', description: (e as { message?: string })?.message ?? 'Tente novamente', color: 'error' })
  }
  finally {
    transferindo.value = false
  }
}

function confirmarTransferir() {
  if (!transferirSel.value || !transferirDestino.value) return

  const avaliacao = avaliarIdadeClube(clubes.value, transferirSel.value.data_nascimento, transferirDestino.value)
  if (avaliacao.tipo === 'muito_novo') {
    toast.add({ title: 'Transferência bloqueada', description: 'A criança nasceu neste ano.', color: 'error' })
    return
  }
  if (avaliacao.tipo === 'clube_diferente') {
    const destino = clubes.value.find(c => c.id === transferirDestino.value)?.nome ?? 'este clube'
    confirm.require({
      header: 'Idade de outro clube',
      message: `A idade informada corresponde ao clube ${avaliacao.clubeSugerido.nome} (${avaliacao.clubeSugerido.idade_min} a ${avaliacao.clubeSugerido.idade_max} anos), e não a ${destino}. Deseja transferir para ${destino} mesmo assim?`,
      icon: 'pi pi-exclamation-triangle',
      acceptLabel: 'Sim, transferir',
      rejectLabel: 'Cancelar',
      acceptProps: { severity: 'warn' },
      rejectProps: { severity: 'secondary', text: true },
      accept: () => persistirTransferir(),
    })
    return
  }

  void persistirTransferir()
}

// ---- Progressão de faixa etária (progredir para o próximo clube) ----
const progredindoId = ref<string | null>(null)

function confirmarProgredir(o: Oansista & { turma_nome: string | null }) {
  const alvo = clubeParaProgredir(clubes.value, o.data_nascimento, o.clube_id)
  if (!alvo) return
  const anos = idadeEmAnos(o.data_nascimento)
  confirm.require({
    header: 'Progredir de clube',
    message: `${o.nome} agora tem ${anos ?? '—'} anos e passou para a faixa do clube ${alvo.nome} (${alvo.idade_min} a ${alvo.idade_max} anos). Deseja progredir para ${alvo.nome}?`,
    icon: 'pi pi-angle-double-right',
    acceptLabel: 'Sim, progredir',
    rejectLabel: 'Cancelar',
    acceptProps: { severity: 'primary' },
    rejectProps: { severity: 'secondary', text: true },
    accept: () => progredir(o, alvo),
  })
}

async function progredir(o: Oansista & { turma_nome: string | null }, alvo: ClubeFaixa) {
  progredindoId.value = o.id
  try {
    await transferirRpc(o.id, alvo.id, 'Progressão de faixa etária')
    toast.add({ title: `Criança progrediu para ${alvo.nome}`, color: 'success' })
    await carregar()
  }
  catch (e) {
    toast.add({ title: 'Erro ao progredir de clube', description: (e as { message?: string })?.message ?? 'Tente novamente', color: 'error' })
  }
  finally {
    progredindoId.value = null
  }
}

const cancelandoTransferencia = ref(false)
async function cancelarTransferencia(o: Oansista & { turma_nome: string | null }) {
  cancelandoTransferencia.value = true
  try {
    await cancelarRpc(o.id)
    toast.add({ title: 'Transferência cancelada', color: 'success' })
    await carregar()
  }
  catch (e) {
    toast.add({ title: 'Erro ao cancelar transferência', description: (e as { message?: string })?.message ?? 'Tente novamente', color: 'error' })
  }
  finally {
    cancelandoTransferencia.value = false
  }
}

const STATUS_TAG: Record<Oansista['status'], { label: string, severity: string }> = {
  ativo: { label: 'Ativo', severity: 'success' },
  inativo: { label: 'Inativo', severity: 'secondary' },
  transferido: { label: 'Transferido', severity: 'warn' },
}
</script>

<template>
  <div class="p-4 sm:p-6 max-w-4xl mx-auto w-full">
    <div class="flex flex-wrap items-center justify-between gap-3 mb-4">
      <div>
        <h1 class="text-2xl font-bold">
          Oansistas
        </h1>
        <p class="text-sm text-surface-500">
          Crianças matriculadas no clube
        </p>
      </div>
      <div class="flex items-center gap-2">
        <div class="flex items-center gap-2">
          <Checkbox
            v-model="mostrarInativos"
            :binary="true"
            input-id="mostrar-inativos"
          />
          <label class="text-sm" for="mostrar-inativos">Mostrar inativos/transferidos</label>
        </div>
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

    <div class="overflow-x-auto">
      <DataTable
        :value="oansistasVisiveis"
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
            :severity="STATUS_TAG[data.status as Oansista['status']].severity"
            :value="STATUS_TAG[data.status as Oansista['status']].label"
          />
        </template>
      </Column>
      <Column header="" style="width: 110px">
        <template #body="{ data }">
          <div class="flex justify-end gap-1">
            <Button
              v-if="podeTransferir && data.status === 'ativo' && clubeParaProgredir(clubes, data.data_nascimento, data.clube_id)"
              icon="pi pi-angle-double-right"
              text
              rounded
              size="small"
              :loading="progredindoId === data.id"
              aria-label="Progredir de clube"
              @click="confirmarProgredir(data)"
            />
            <Button
              v-if="podeTransferir && data.status === 'ativo'"
              icon="pi pi-arrow-right"
              text
              rounded
              size="small"
              aria-label="Mudar de clube"
              @click="abrirTransferir(data)"
            />
            <Button
              v-if="podeTransferir && data.status === 'transferido'"
              icon="pi pi-undo"
              text
              rounded
              size="small"
              :loading="cancelandoTransferencia"
              aria-label="Cancelar transferência"
              @click="cancelarTransferencia(data)"
            />
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
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div class="flex flex-col gap-1">
            <label class="text-sm font-medium">Data de nascimento *</label>
            <InputText
              v-model="form.data_nascimento"
              type="date"
              class="w-full"
            />
            <small
              v-if="hintIdade"
              class="text-sm"
              :class="hintIdade.severidade === 'error' ? 'text-red-600' : 'text-amber-600'"
            >
              {{ hintIdade.texto }}
            </small>
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
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
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

    <!-- Modal transferência de clube -->
    <Dialog
      v-model:visible="transferirModal"
      header="Mudar de clube"
      :modal="true"
      class="w-full max-w-md"
    >
      <div
        v-if="transferirSel"
        class="flex flex-col gap-4"
      >
        <p class="text-sm text-surface-500">
          {{ transferirSel.nome }} será transferido para outro clube. A criança
          passa a acompanhar o novo clube como visitante (completando apenas as
          lições da Prova de Ingresso — sem as 3 visitas).
        </p>
        <div class="flex flex-col gap-1">
          <label class="text-sm font-medium">Clube de destino *</label>
          <Select
            v-model="transferirDestino"
            :options="clubesDestino.map(c => ({ label: c.nome, value: c.id }))"
            option-label="label"
            option-value="value"
            placeholder="Selecione o clube"
            class="w-full"
          />
          <small
            v-if="hintTransferencia"
            class="text-xs"
            :class="hintTransferencia.severidade === 'error' ? 'text-red-600' : 'text-amber-600'"
          >
            {{ hintTransferencia.texto }}
          </small>
        </div>
        <div class="flex flex-col gap-1">
          <label class="text-sm font-medium">Motivo</label>
          <Textarea
            v-model="transferirMotivo"
            class="w-full"
            rows="2"
          />
        </div>
      </div>
      <template #footer>
        <div class="flex justify-end gap-2">
          <Button
            label="Cancelar"
            text
            @click="transferirModal = false"
          />
          <Button
            label="Transferir"
            :loading="transferindo"
            :disabled="!transferirDestino"
            @click="confirmarTransferir"
          />
        </div>
      </template>
    </Dialog>
  </div>
</template>
