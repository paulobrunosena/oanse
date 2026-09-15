<script setup lang="ts">
import { onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { useConfirm } from 'primevue/useconfirm'
import { supabase } from '@/lib/supabase'
import { apiFetch } from '@/lib/api'
import { useToast } from '@/composables/useToast'
import { usePendencias, type Pendencia, type PendenciaStatus } from '@/composables/usePendencias'
import { tocarSomAlerta } from '@/utils/alerta'

const toast = useToast()
const confirm = useConfirm()
const { pendencias, carregando, carregar, inscrever } = usePendencias()

const filtroStatus = ref<PendenciaStatus | ''>('pendente')
const filtroClube = ref<string | ''>('')
const entregando = ref<string | null>(null)

const clubes = ref<{ id: string, nome: string }[]>([])

const opcoesStatus: { label: string, value: PendenciaStatus | '' }[] = [
  { label: 'Pendentes', value: 'pendente' },
  { label: 'Entregues', value: 'entregue' },
  { label: 'Canceladas', value: 'cancelada' },
  { label: 'Todas', value: '' },
]

const rotuloStatus: Record<PendenciaStatus, string> = {
  pendente: 'Pendente',
  entregue: 'Entregue',
  cancelada: 'Cancelada',
}

const severidadeStatus: Record<PendenciaStatus, 'info' | 'success' | 'warn'> = {
  pendente: 'info',
  entregue: 'success',
  cancelada: 'warn',
}

async function carregarClubes() {
  const { data, error } = await supabase.from('clubes').select('id, nome').order('nome')
  if (error) return
  clubes.value = (data ?? []) as { id: string, nome: string }[]
}

async function atualizar() {
  try {
    await carregar(filtroStatus.value || undefined, filtroClube.value || undefined)
  }
  catch (e) {
    toast.add({
      title: 'Erro ao carregar pendências',
      description: (e as { message?: string })?.message ?? 'Tente novamente',
      color: 'error',
    })
  }
}

watch(filtroStatus, atualizar)
watch(filtroClube, atualizar)

function notificarNovaPendencia() {
  tocarSomAlerta()
  toast.add({
    title: 'Nova pendência de premiação',
    description: 'Um prêmio acabou de entrar na fila de entrega.',
    color: 'info',
  })
}

function pedirEntrega(p: Pendencia) {
  confirm.require({
    header: 'Entregar prêmio',
    message: `Confirmar entrega de "${p.premio_nome}" para ${p.oansista_nome}? O estoque será baixado automaticamente.`,
    icon: 'pi pi-check-circle',
    acceptLabel: 'Entregar',
    rejectLabel: 'Cancelar',
    acceptProps: { severity: 'success' },
    rejectProps: { severity: 'secondary', text: true },
    accept: async () => {
      entregando.value = p.id
      try {
        await apiFetch(`/api/premios/${p.id}/entregar`, { method: 'POST' })
        toast.add({ title: 'Prêmio entregue', color: 'success' })
        await atualizar()
      }
      catch (e) {
        toast.add({
          title: 'Erro ao entregar',
          description: (e as { message?: string })?.message ?? 'Tente novamente',
          color: 'error',
        })
      }
      finally {
        entregando.value = null
      }
    },
  })
}

let cancelarRealtime: (() => Promise<unknown>) | null = null

onMounted(async () => {
  await carregarClubes()
  await atualizar()
  cancelarRealtime = inscrever((payload) => {
    if (payload.eventType === 'INSERT' && payload.new?.status === 'pendente') {
      notificarNovaPendencia()
    }
  })
})

onBeforeUnmount(() => {
  cancelarRealtime?.()
})
</script>

<template>
  <div class="p-4 sm:p-6 max-w-4xl mx-auto w-full">
    <div class="mb-4 flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
      <div>
        <h1 class="text-2xl font-bold">
          Pendências de premiação
        </h1>
        <p class="text-sm text-surface-500 mt-1">
          Prêmios a entregar, gerados automaticamente ao concluir um bloco da Folha Individual
        </p>
      </div>
      <div class="flex flex-wrap gap-2">
        <Select
          v-model="filtroClube"
          :options="[{ label: 'Todos os clubes', value: '' }, ...clubes.map(c => ({ label: c.nome, value: c.id }))]"
          option-label="label"
          option-value="value"
          class="w-44"
        />
        <Select
          v-model="filtroStatus"
          :options="opcoesStatus"
          option-label="label"
          option-value="value"
          class="w-44"
        />
      </div>
    </div>

    <div class="overflow-x-auto">
      <DataTable
        :value="pendencias"
        :loading="carregando"
        data-key="id"
        class="w-full"
      >
        <Column header="Oansista">
          <template #body="{ data }">
            <span class="font-medium">{{ data.oansista_nome }}</span>
          </template>
        </Column>
        <Column header="Prêmio">
          <template #body="{ data }">
            {{ data.premio_nome }}
          </template>
        </Column>
        <Column header="Clube">
          <template #body="{ data }">
            {{ data.clube_nome }}
          </template>
        </Column>
        <Column header="Status">
          <template #body="{ data }">
            <Tag
              :value="rotuloStatus[data.status as PendenciaStatus]"
              :severity="severidadeStatus[data.status as PendenciaStatus]"
              rounded
            />
          </template>
        </Column>
        <Column header="" style="width: 120px">
          <template #body="{ data }">
            <div class="flex justify-end">
              <Button
                v-if="data.status === 'pendente'"
                icon="pi pi-check"
                label="Entregar"
                size="small"
                severity="success"
                :loading="entregando === data.id"
                @click="pedirEntrega(data)"
              />
            </div>
          </template>
        </Column>
      </DataTable>
    </div>

    <div
      v-if="!carregando && pendencias.length === 0"
      class="py-10 text-center text-surface-500 text-sm"
    >
      Nenhuma pendência nesta lista.
    </div>
  </div>
</template>
