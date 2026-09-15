<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { useConfirm } from 'primevue/useconfirm'
import { useToast } from '@/composables/useToast'
import { usePremios, type Premio, type PremioForm, type PremioTipo } from '@/composables/usePremios'
import { useEstoque, type TipoMovimentacao } from '@/composables/useEstoque'
import { formatarDataHora } from '@/utils/data'

const toast = useToast()
const confirm = useConfirm()
const { premios, carregando, carregar, criar, atualizar, excluir } = usePremios()
const { movimentacoes, carregar: carregarMovimentacoes, registrar } = useEstoque()

const opcoesTipo: { label: string, value: PremioTipo }[] = [
  { label: 'Botom', value: 'botom' },
  { label: 'Prêmio', value: 'premio' },
  { label: 'Manual', value: 'manual' },
]

const rotuloTipo: Record<PremioTipo, string> = {
  botom: 'Botom',
  premio: 'Prêmio',
  manual: 'Manual',
}

const opcoesMovimento: { label: string, value: TipoMovimentacao }[] = [
  { label: 'Entrada', value: 'entrada' },
  { label: 'Saída', value: 'saida' },
]

const dialogAberto = ref(false)
const editandoId = ref<string | null>(null)
const salvando = ref(false)
const form = reactive<PremioForm>({
  nome: '',
  tipo: 'botom',
  descricao: null,
  estoque: 0,
  estoque_min: 0,
  ativo: true,
})

const estoqueBaixo = computed(() => premios.value.filter(p => p.estoque <= p.estoque_min))

function abaixoDoMinimo(p: Premio) {
  return p.estoque <= p.estoque_min
}

function abrirNovo() {
  editandoId.value = null
  Object.assign(form, {
    nome: '',
    tipo: 'botom' as PremioTipo,
    descricao: null,
    estoque: 0,
    estoque_min: 0,
    ativo: true,
  })
  dialogAberto.value = true
}

function abrirEdicao(p: Premio) {
  editandoId.value = p.id
  Object.assign(form, {
    nome: p.nome,
    tipo: p.tipo,
    descricao: p.descricao,
    estoque: p.estoque,
    estoque_min: p.estoque_min,
    ativo: p.ativo,
  })
  dialogAberto.value = true
}

async function salvar() {
  const nome = form.nome.trim()
  if (!nome) return
  salvando.value = true
  try {
    const dados: PremioForm = {
      nome,
      tipo: form.tipo,
      descricao: form.descricao,
      estoque: form.estoque,
      estoque_min: form.estoque_min,
      ativo: form.ativo,
    }
    if (editandoId.value) {
      await atualizar(editandoId.value, dados)
      toast.add({ title: 'Prêmio atualizado', color: 'success' })
    }
    else {
      await criar(dados)
      toast.add({ title: 'Prêmio criado', color: 'success' })
    }
    dialogAberto.value = false
    await carregar()
  }
  catch (e) {
    toast.add({
      title: 'Erro ao salvar',
      description: (e as { message?: string })?.message ?? 'Tente novamente',
      color: 'error',
    })
  }
  finally {
    salvando.value = false
  }
}

function pedirExclusao(p: Premio) {
  confirm.require({
    header: 'Excluir prêmio',
    message: `Excluir "${p.nome}" do catálogo?`,
    icon: 'pi pi-exclamation-triangle',
    acceptLabel: 'Excluir',
    rejectLabel: 'Cancelar',
    acceptProps: { severity: 'danger' },
    rejectProps: { severity: 'secondary', text: true },
    accept: async () => {
      try {
        await excluir(p.id)
        await carregar()
        toast.add({ title: 'Prêmio excluído', color: 'info' })
      }
      catch (e) {
        toast.add({
          title: 'Erro ao excluir',
          description: (e as { message?: string })?.message ?? 'Tente novamente',
          color: 'error',
        })
      }
    },
  })
}

const movimentoAberto = ref(false)
const movimentoPremio = ref<Premio | null>(null)
const movimentoSalvando = ref(false)
const movimentoForm = reactive({
  tipo: 'entrada' as TipoMovimentacao,
  quantidade: 1,
  observacao: '',
})

function abrirMovimentacoes(p: Premio) {
  movimentoPremio.value = p
  Object.assign(movimentoForm, { tipo: 'entrada', quantidade: 1, observacao: '' })
  movimentoAberto.value = true
  carregarMovimentacoes(p.id).catch(() => {})
}

async function salvarMovimentacao() {
  const premio = movimentoPremio.value
  if (!premio || movimentoForm.quantidade < 1) return
  movimentoSalvando.value = true
  try {
    await registrar(
      premio.id,
      movimentoForm.tipo,
      movimentoForm.quantidade,
      movimentoForm.observacao.trim() || undefined,
    )
    toast.add({
      title: movimentoForm.tipo === 'entrada' ? 'Entrada registrada' : 'Saída registrada',
      color: 'success',
    })
    Object.assign(movimentoForm, { tipo: 'entrada', quantidade: 1, observacao: '' })
    await Promise.all([carregar(), carregarMovimentacoes(premio.id)])
  }
  catch (e) {
    toast.add({
      title: 'Erro ao registrar movimentação',
      description: (e as { message?: string })?.message ?? 'Tente novamente',
      color: 'error',
    })
  }
  finally {
    movimentoSalvando.value = false
  }
}

onMounted(carregar)
</script>

<template>
  <div class="p-4 sm:p-6 max-w-4xl mx-auto w-full">
    <div class="mb-4 flex items-start justify-between gap-3">
      <div>
        <h1 class="text-2xl font-bold">
          Catálogo de prêmios
        </h1>
        <p class="text-sm text-surface-500 mt-1">
          Prêmios e materiais controlados pela Secretaria (botons, distintivos e manuais)
        </p>
      </div>
      <Button
        icon="pi pi-plus"
        label="Novo prêmio"
        @click="abrirNovo"
      />
    </div>

    <div
      v-if="estoqueBaixo.length"
      class="mb-4 flex items-start gap-2 rounded-lg border border-amber-300 bg-amber-50 p-3 text-sm text-amber-800"
    >
      <i class="pi pi-exclamation-triangle mt-0.5" />
      <div>
        <span class="font-medium">{{ estoqueBaixo.length }} {{ estoqueBaixo.length === 1 ? 'item abaixo' : 'itens abaixo' }} do estoque mínimo:</span>
        <span> {{ estoqueBaixo.map(p => p.nome).join(', ') }}</span>
      </div>
    </div>

    <div class="overflow-x-auto">
      <DataTable
        :value="premios"
        :loading="carregando"
        data-key="id"
        class="w-full"
      >
        <Column field="nome" header="Prêmio">
          <template #body="{ data }">
            <span class="font-medium">{{ data.nome }}</span>
            <div
              v-if="data.descricao"
              class="text-xs text-surface-500"
            >
              {{ data.descricao }}
            </div>
          </template>
        </Column>
        <Column field="tipo" header="Tipo">
          <template #body="{ data }">
            {{ rotuloTipo[data.tipo as PremioTipo] }}
          </template>
        </Column>
        <Column field="estoque" header="Estoque">
          <template #body="{ data }">
            <div class="flex items-center gap-2">
              <span>{{ data.estoque }}</span>
              <Tag
                v-if="abaixoDoMinimo(data)"
                value="mínimo"
                severity="warn"
                rounded
              />
            </div>
          </template>
        </Column>
        <Column field="estoque_min" header="Mín.">
          <template #body="{ data }">
            {{ data.estoque_min }}
          </template>
        </Column>
        <Column header="" style="width: 140px">
          <template #body="{ data }">
            <div class="flex justify-end">
              <Button
                icon="pi pi-box"
                text
                rounded
                size="small"
                aria-label="Movimentações"
                @click="abrirMovimentacoes(data)"
              />
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
                size="small"
                severity="danger"
                aria-label="Excluir"
                @click="pedirExclusao(data)"
              />
            </div>
          </template>
        </Column>
      </DataTable>
    </div>

    <Dialog
      :visible="dialogAberto"
      :header="editandoId ? 'Editar prêmio' : 'Novo prêmio'"
      :modal="true"
      class="w-full max-w-md"
      @update:visible="dialogAberto = $event"
    >
      <form
        class="flex w-full min-w-0 flex-col gap-4"
        @submit.prevent="salvar"
      >
        <div class="flex min-w-0 flex-col gap-1">
          <label class="text-sm font-medium">Nome *</label>
          <InputText
            v-model="form.nome"
            class="w-full"
          />
        </div>
        <div class="grid min-w-0 grid-cols-1 gap-4 sm:grid-cols-2">
          <div class="flex min-w-0 flex-col gap-1">
            <label class="text-sm font-medium">Tipo</label>
            <Select
              v-model="form.tipo"
              :options="opcoesTipo"
              option-label="label"
              option-value="value"
              class="w-full"
            />
          </div>
          <div class="flex min-w-0 flex-col gap-1">
            <label class="text-sm font-medium">Descrição</label>
            <InputText
              v-model="form.descricao"
              class="w-full"
            />
          </div>
        </div>
        <div class="grid min-w-0 grid-cols-1 gap-4 sm:grid-cols-2">
          <div class="flex min-w-0 flex-col gap-1">
            <label class="text-sm font-medium">Estoque</label>
            <InputNumber
              v-model="form.estoque"
              :min="0"
              :input-style="{ minWidth: '0', width: '100%' }"
              class="w-full min-w-0"
            />
          </div>
          <div class="flex min-w-0 flex-col gap-1">
            <label class="text-sm font-medium">Estoque mínimo</label>
            <InputNumber
              v-model="form.estoque_min"
              :min="0"
              :input-style="{ minWidth: '0', width: '100%' }"
              class="w-full min-w-0"
            />
          </div>
        </div>
        <div class="flex items-center gap-2">
          <ToggleSwitch v-model="form.ativo" />
          <label class="text-sm">Ativo</label>
        </div>
        <div class="flex justify-end gap-2">
          <Button
            label="Cancelar"
            text
            @click="dialogAberto = false"
          />
          <Button
            type="submit"
            label="Salvar"
            :loading="salvando"
          />
        </div>
      </form>
    </Dialog>

    <Dialog
      :visible="movimentoAberto"
      :header="movimentoPremio ? `Movimentações — ${movimentoPremio.nome}` : 'Movimentações'"
      :modal="true"
      class="w-full max-w-lg"
      @update:visible="movimentoAberto = $event"
    >
      <form
        class="flex min-w-0 flex-col gap-4"
        @submit.prevent="salvarMovimentacao"
      >
        <div class="grid min-w-0 grid-cols-1 gap-4 sm:grid-cols-3">
          <div class="flex min-w-0 flex-col gap-1">
            <label class="text-sm font-medium">Tipo</label>
            <Select
              v-model="movimentoForm.tipo"
              :options="opcoesMovimento"
              option-label="label"
              option-value="value"
              class="w-full"
            />
          </div>
          <div class="flex min-w-0 flex-col gap-1">
            <label class="text-sm font-medium">Quantidade</label>
            <InputNumber
              v-model="movimentoForm.quantidade"
              :min="1"
              :input-style="{ minWidth: '0', width: '100%' }"
              class="w-full min-w-0"
            />
          </div>
          <div class="flex min-w-0 flex-col gap-1">
            <label class="text-sm font-medium">Observação</label>
            <InputText
              v-model="movimentoForm.observacao"
              class="w-full"
            />
          </div>
        </div>
        <div class="flex justify-end gap-2">
          <Button
            label="Cancelar"
            text
            @click="movimentoAberto = false"
          />
          <Button
            type="submit"
            label="Registrar"
            :loading="movimentoSalvando"
          />
        </div>
      </form>

      <div class="mt-4 border-t pt-4">
        <h3 class="mb-2 text-sm font-semibold">
          Histórico
        </h3>
        <DataTable
          :value="movimentacoes"
          data-key="id"
          size="small"
          class="w-full"
        >
          <Column header="Data">
            <template #body="{ data }">
              {{ formatarDataHora(data.created_at) }}
            </template>
          </Column>
          <Column header="Tipo">
            <template #body="{ data }">
              {{ data.tipo === 'entrada' ? 'Entrada' : 'Saída' }}
            </template>
          </Column>
          <Column header="Qtd.">
            <template #body="{ data }">
              {{ data.quantidade }}
            </template>
          </Column>
          <Column header="Por">
            <template #body="{ data }">
              {{ data.feito_por_nome }}
            </template>
          </Column>
        </DataTable>
        <div
          v-if="movimentacoes.length === 0"
          class="py-4 text-center text-sm text-surface-500"
        >
          Nenhuma movimentação registrada.
        </div>
      </div>
    </Dialog>
  </div>
</template>
