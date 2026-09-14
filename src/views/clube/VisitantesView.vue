<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { useAuth } from '@/composables/useAuth'
import { useRole } from '@/composables/useRole'
import { useToast } from '@/composables/useToast'
import { useVisitantes, type StatusVisitante } from '@/composables/useVisitantes'
import VisitaTracker from '@/components/folha/VisitaTracker.vue'
import ProvaIngressoCard from '@/components/folha/ProvaIngressoCard.vue'
import type { Database } from '@/types/database.types'

type VisitanteRow = Database['public']['Tables']['visitantes']['Row']

const toast = useToast()
const { user, profile } = useAuth()
const { isDiretorGeral, isDiretorClube } = useRole()
const {
  visitantes, oansistas, turmas, carregando,
  visitasPorVisitante, licoesPorVisitante,
  carregar, salvarVisitante, salvarVisita, salvarLicao, matricular,
} = useVisitantes()

const clubeId = computed(() => profile.value?.clube_id ?? null)
const podeMatricular = computed(() => isDiretorGeral.value || isDiretorClube.value)

const STATUS_LABEL: Record<StatusVisitante, string> = {
  em_visitas: 'Em visitas',
  prova_ingresso: 'Prova de ingresso',
  matriculado: 'Matriculado',
  desistente: 'Desistente',
}

const STATUS_SEVERITY: Record<StatusVisitante, string> = {
  em_visitas: 'info',
  prova_ingresso: 'warn',
  matriculado: 'success',
  desistente: 'secondary',
}

const statusOpcoes = (Object.keys(STATUS_LABEL) as StatusVisitante[]).map(s => ({
  label: STATUS_LABEL[s],
  value: s,
}))

function mensagem(e: unknown): string {
  return (e as { message?: string })?.message ?? 'Tente novamente'
}

const idade = (nasc: string) => {
  const anos = Math.floor((Date.now() - new Date(nasc).getTime()) / (365.25 * 24 * 3600 * 1000))
  return `${anos}a`
}

function visitasFeitas(id: string): number {
  return visitasPorVisitante.value.get(id)?.filter(v => v.data_visita).length ?? 0
}

function nomeIndicado(indicadoPor: string | null): string {
  if (!indicadoPor) return '—'
  return oansistas.value.find(o => o.id === indicadoPor)?.nome ?? '—'
}

// ---- Cadastro / edição ----
const formModal = ref(false)
const editandoId = ref<string | null>(null)
const salvando = ref(false)
const form = reactive({
  nome: '',
  data_nascimento: '',
  responsavel: '',
  contato: '',
  indicado_por: null as string | null,
  status: 'em_visitas' as StatusVisitante,
})

function abrirCriar() {
  editandoId.value = null
  Object.assign(form, { nome: '', data_nascimento: '', responsavel: '', contato: '', indicado_por: null, status: 'em_visitas' })
  formModal.value = true
}

function abrirEdicao(v: VisitanteRow) {
  editandoId.value = v.id
  Object.assign(form, {
    nome: v.nome,
    data_nascimento: v.data_nascimento,
    responsavel: v.responsavel ?? '',
    contato: v.contato ?? '',
    indicado_por: v.indicado_por,
    status: v.status,
  })
  formModal.value = true
}

async function salvar() {
  if (!form.nome.trim() || !form.data_nascimento || !clubeId.value) {
    toast.add({ title: 'Nome e data de nascimento são obrigatórios', color: 'error' })
    return
  }
  salvando.value = true
  try {
    await salvarVisitante({
      nome: form.nome.trim(),
      data_nascimento: form.data_nascimento,
      responsavel: form.responsavel.trim() || null,
      contato: form.contato.trim() || null,
      indicado_por: form.indicado_por,
      status: form.status,
    }, clubeId.value, editandoId.value ?? undefined)
    toast.add({ title: editandoId.value ? 'Visitante atualizado' : 'Visitante cadastrado', color: 'success' })
    formModal.value = false
    if (editandoId.value && visitanteSel.value?.id === editandoId.value) {
      visitanteSel.value = visitantes.value.find(v => v.id === editandoId.value) ?? null
    }
  }
  catch (e) {
    toast.add({ title: 'Erro ao salvar visitante', description: mensagem(e), color: 'error' })
  }
  finally {
    salvando.value = false
  }
}

// ---- Detalhe ----
const detalheModal = ref(false)
const visitanteSel = ref<VisitanteRow | null>(null)
const abaAtiva = ref('visitas')

const visitasDoVisitante = computed(() => visitanteSel.value ? (visitasPorVisitante.value.get(visitanteSel.value.id) ?? []) : [])
const licoesDoVisitante = computed(() => visitanteSel.value ? (licoesPorVisitante.value.get(visitanteSel.value.id) ?? []) : [])

function abrirDetalhe(v: VisitanteRow) {
  visitanteSel.value = v
  abaAtiva.value = 'visitas'
  detalheModal.value = true
}

const salvandoVisita = ref<number | null>(null)
const salvandoLicao = ref<number | null>(null)

async function onSalvarVisita(numero: number, dados: { data_visita: string, presente: boolean }) {
  if (!visitanteSel.value) return
  salvandoVisita.value = numero
  try {
    await salvarVisita(visitanteSel.value.id, numero, dados)
  }
  catch (e) {
    toast.add({ title: 'Erro ao salvar a visita', description: mensagem(e), color: 'error' })
  }
  finally {
    salvandoVisita.value = null
  }
}

async function onSalvarLicao(licao: number, dataConclusao: string | null) {
  if (!visitanteSel.value) return
  salvandoLicao.value = licao
  try {
    await salvarLicao(visitanteSel.value.id, licao, dataConclusao, user.value?.sub ?? null)
  }
  catch (e) {
    toast.add({ title: 'Erro ao salvar a lição', description: mensagem(e), color: 'error' })
  }
  finally {
    salvandoLicao.value = null
  }
}

// ---- Matricular ----
const matricularModal = ref(false)
const matricularTurmaId = ref<string | null>(null)
const matriculando = ref(false)

function abrirMatricular() {
  matricularTurmaId.value = null
  matricularModal.value = true
}

async function confirmarMatricular() {
  if (!visitanteSel.value) return
  matriculando.value = true
  try {
    await matricular(visitanteSel.value.id, matricularTurmaId.value)
    toast.add({ title: 'Visitante matriculado', color: 'success' })
    matricularModal.value = false
    detalheModal.value = false
  }
  catch (e) {
    toast.add({ title: 'Erro ao matricular', description: mensagem(e), color: 'error' })
  }
  finally {
    matriculando.value = false
  }
}

onMounted(() => {
  if (clubeId.value) carregar(clubeId.value)
})
</script>

<template>
  <div class="p-4 sm:p-6 max-w-5xl mx-auto w-full">
    <div class="mb-4 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
      <div>
        <h1 class="text-2xl font-bold">
          Visitantes
        </h1>
        <p class="text-sm text-surface-500">
          Cadastro, acompanhamento das visitas e prova de ingresso
        </p>
      </div>
      <Button
        icon="pi pi-plus"
        label="Novo visitante"
        :disabled="!clubeId"
        @click="abrirCriar"
      />
    </div>

    <Card v-if="!clubeId" class="text-center py-6">
      <template #content>
        <p class="text-surface-500">
          Você não está vinculado a um clube. Fale com o Diretor Geral.
        </p>
      </template>
    </Card>

    <template v-else>
      <div class="overflow-x-auto">
        <DataTable
          :value="visitantes"
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
          <Column header="Situação">
            <template #body="{ data }">
              <Tag
                :severity="STATUS_SEVERITY[data.status as StatusVisitante]"
                :value="STATUS_LABEL[data.status as StatusVisitante]"
              />
            </template>
          </Column>
          <Column header="Responsável">
            <template #body="{ data }">
              {{ data.responsavel ?? '—' }}
            </template>
          </Column>
          <Column header="Visitas">
            <template #body="{ data }">
              {{ visitasFeitas(data.id) }}/3
            </template>
          </Column>
          <Column header="" style="width: 70px">
            <template #body="{ data }">
              <div class="flex justify-end">
                <Button
                  icon="pi pi-eye"
                  text
                  rounded
                  size="small"
                  aria-label="Ver detalhes"
                  @click="abrirDetalhe(data)"
                />
              </div>
            </template>
          </Column>
        </DataTable>
      </div>
    </template>

    <!-- Modal cadastro/edição -->
    <Dialog
      v-model:visible="formModal"
      :header="editandoId ? 'Editar visitante' : 'Novo visitante'"
      :modal="true"
      class="w-full max-w-lg"
    >
      <form class="flex flex-col gap-4" @submit.prevent="salvar">
        <div class="flex flex-col gap-1">
          <label class="text-sm font-medium">Nome *</label>
          <InputText v-model="form.nome" class="w-full" />
        </div>
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div class="flex flex-col gap-1">
            <label class="text-sm font-medium">Data de nascimento *</label>
            <InputText v-model="form.data_nascimento" type="date" class="w-full" />
          </div>
          <div class="flex flex-col gap-1">
            <label class="text-sm font-medium">Indicado por</label>
            <Select
              v-model="form.indicado_por"
              :options="[{ label: 'Ninguém', value: null }, ...oansistas.map(o => ({ label: o.nome, value: o.id }))]"
              option-label="label"
              option-value="value"
              class="w-full"
            />
          </div>
        </div>
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div class="flex flex-col gap-1">
            <label class="text-sm font-medium">Responsável</label>
            <InputText v-model="form.responsavel" class="w-full" />
          </div>
          <div class="flex flex-col gap-1">
            <label class="text-sm font-medium">Contato</label>
            <InputText v-model="form.contato" class="w-full" />
          </div>
        </div>
        <div class="flex flex-col gap-1">
          <label class="text-sm font-medium">Situação</label>
          <Select
            v-model="form.status"
            :options="statusOpcoes"
            option-label="label"
            option-value="value"
            class="w-full"
          />
        </div>
        <div class="flex justify-end gap-2">
          <Button label="Cancelar" text @click="formModal = false" />
          <Button type="submit" label="Salvar" :loading="salvando" />
        </div>
      </form>
    </Dialog>

    <!-- Modal detalhe -->
    <Dialog
      v-model:visible="detalheModal"
      :header="visitanteSel?.nome ?? 'Visitante'"
      :modal="true"
      class="w-full max-w-2xl"
    >
      <div v-if="visitanteSel" class="flex flex-col gap-4">
        <div class="flex flex-wrap items-center justify-between gap-3">
          <div class="flex flex-wrap items-center gap-x-4 gap-y-1 text-sm">
            <span class="text-surface-500">Idade: <strong class="text-surface-950 dark:text-surface-0">{{ idade(visitanteSel.data_nascimento) }}</strong></span>
            <span class="text-surface-500">Responsável: <strong class="text-surface-950 dark:text-surface-0">{{ visitanteSel.responsavel ?? '—' }}</strong></span>
            <span class="text-surface-500">Contato: <strong class="text-surface-950 dark:text-surface-0">{{ visitanteSel.contato ?? '—' }}</strong></span>
            <span class="text-surface-500">Indicado por: <strong class="text-surface-950 dark:text-surface-0">{{ nomeIndicado(visitanteSel.indicado_por) }}</strong></span>
          </div>
          <div class="flex items-center gap-2">
            <Tag :severity="STATUS_SEVERITY[visitanteSel.status]" :value="STATUS_LABEL[visitanteSel.status]" />
            <Button icon="pi pi-pencil" text rounded size="small" aria-label="Editar" @click="abrirEdicao(visitanteSel)" />
          </div>
        </div>

        <Tabs v-model:value="abaAtiva">
          <TabList>
            <Tab value="visitas">Visitas</Tab>
            <Tab value="prova">Prova de Ingresso</Tab>
          </TabList>
          <TabPanels>
            <TabPanel value="visitas">
              <VisitaTracker
                :visitas="visitasDoVisitante"
                :salvando="salvandoVisita"
                @salvar-visita="onSalvarVisita"
              />
            </TabPanel>
            <TabPanel value="prova">
              <ProvaIngressoCard
                :licoes="licoesDoVisitante"
                :salvando="salvandoLicao"
                @salvar-licao="onSalvarLicao"
              />
            </TabPanel>
          </TabPanels>
        </Tabs>
      </div>

      <template #footer>
        <div class="flex justify-between gap-2">
          <Button
            v-if="podeMatricular"
            label="Matricular"
            icon="pi pi-user-plus"
            :disabled="visitanteSel?.status === 'matriculado'"
            @click="abrirMatricular"
          />
          <span v-else />
          <Button label="Fechar" text @click="detalheModal = false" />
        </div>
      </template>
    </Dialog>

    <!-- Modal matricular -->
    <Dialog
      v-model:visible="matricularModal"
      header="Matricular visitante"
      :modal="true"
      class="w-full max-w-md"
    >
      <div class="flex flex-col gap-4">
        <p class="text-sm text-surface-500">
          {{ visitanteSel?.nome }} será convertido em oansista. Escolha uma turma
          (opcional — pode atribuir depois).
        </p>
        <div class="flex flex-col gap-1">
          <label class="text-sm font-medium">Turma</label>
          <Select
            v-model="matricularTurmaId"
            :options="[{ label: 'Sem turma', value: null }, ...turmas.map(t => ({ label: t.nome, value: t.id }))]"
            option-label="label"
            option-value="value"
            class="w-full"
          />
        </div>
      </div>
      <template #footer>
        <div class="flex justify-end gap-2">
          <Button label="Cancelar" text @click="matricularModal = false" />
          <Button label="Matricular" :loading="matriculando" @click="confirmarMatricular" />
        </div>
      </template>
    </Dialog>
  </div>
</template>
