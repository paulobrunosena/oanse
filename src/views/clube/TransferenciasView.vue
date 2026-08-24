<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import Button from 'primevue/button'
import Card from 'primevue/card'
import InputText from 'primevue/inputtext'
import Select from 'primevue/select'
import Tag from 'primevue/tag'
import { useAuth } from '@/composables/useAuth'
import { useTransferencias, type OansistaTransferencia } from '@/composables/useTransferencias'
import { useToast } from '@/composables/useToast'

const { profile } = useAuth()
const { user } = useAuth()
const toast = useToast()
const { oansistas, turmas, historico, carregar, transferir } = useTransferencias()

const carregandoInicial = ref(true)
const transferindo = ref(false)

const selecionadoId = ref<string>('')
const destinoId = ref<string>('')
const motivo = ref('')

const selecionado = computed<OansistaTransferencia | undefined>(
  () => oansistas.value.find(o => o.id === selecionadoId.value),
)

const opcoesOansistas = computed(() => oansistas.value.map(o => ({
  label: o.turma_nome ? `${o.nome} — ${o.turma_nome}` : o.nome,
  value: o.id,
})))

const opcoesDestino = computed(() => turmas.value
  .filter(t => t.id !== selecionado.value?.turma_id)
  .map(t => ({ label: t.nome, value: t.id })))

async function carregarTudo() {
  carregandoInicial.value = true
  if (profile.value?.clube_id) {
    await carregar(profile.value.clube_id)
  }
  carregandoInicial.value = false
}

function aoTrocarOansista() {
  destinoId.value = ''
  motivo.value = ''
}

async function transferirOansista() {
  if (!selecionado.value || !destinoId.value || !user.value?.sub) return
  transferindo.value = true
  try {
    await transferir(selecionado.value.id, destinoId.value, motivo.value.trim() || null)
    const nome = selecionado.value.nome
    toast.add({ title: 'Criança transferida', description: nome, color: 'success' })
    selecionadoId.value = ''
    destinoId.value = ''
    motivo.value = ''
    await carregar(profile.value?.clube_id ?? '')
  }
  catch (e) {
    toast.add({
      title: 'Erro na transferência',
      description: (e as { message?: string })?.message ?? 'Tente novamente',
      color: 'error',
    })
  }
  finally {
    transferindo.value = false
  }
}

onMounted(carregarTudo)
</script>

<template>
  <div class="p-4 sm:p-6 max-w-5xl mx-auto w-full">
    <div class="flex items-center justify-between mb-4">
      <div>
        <h1 class="text-2xl font-bold">
          Transferências
        </h1>
        <p class="text-sm text-surface-500">
          Move a criança para outra turma do clube e registra o histórico.
        </p>
      </div>
    </div>

    <div
      v-if="carregandoInicial"
      class="flex justify-center py-10"
    >
      <i class="pi pi-spin pi-spinner text-2xl text-surface-400" />
    </div>

    <Card
      v-else-if="!profile?.clube_id"
      class="text-center py-6"
    >
      <template #content>
        <p class="text-surface-500">
          Você não está vinculado a um clube. Fale com o Diretor Geral.
        </p>
      </template>
    </Card>

    <div
      v-else
      class="grid grid-cols-1 lg:grid-cols-2 gap-4 items-start"
    >
      <Card>
        <template #title>
          <h2 class="font-semibold">
            Transferir criança
          </h2>
        </template>
        <template #content>
          <div class="flex flex-col gap-4">
            <div class="flex flex-col gap-1">
              <label class="text-sm font-medium">Criança</label>
              <Select
                v-model="selecionadoId"
                :options="opcoesOansistas"
                option-label="label"
                option-value="value"
                placeholder="Selecionar criança"
                filter
                class="w-full"
                @update:model-value="aoTrocarOansista"
              />
              <p
                v-if="selecionado"
                class="text-xs text-surface-500 mt-1"
              >
                Turma atual:
                <Tag
                  :value="selecionado.turma_nome ?? 'Sem turma'"
                  severity="secondary"
                />
              </p>
            </div>

            <div class="flex flex-col gap-1">
              <label class="text-sm font-medium">Turma de destino</label>
              <Select
                v-model="destinoId"
                :options="opcoesDestino"
                option-label="label"
                option-value="value"
                :disabled="!selecionado"
                placeholder="Selecionar turma"
                class="w-full"
              />
            </div>

            <div class="flex flex-col gap-1">
              <label class="text-sm font-medium">Motivo (opcional)</label>
              <InputText
                v-model="motivo"
                placeholder="Ex.: nova faixa etária, pedido da família"
                class="w-full"
              />
            </div>

            <Button
              icon="pi pi-arrow-right-arrow-left"
              label="Transferir"
              :loading="transferindo"
              :disabled="!selecionado || !destinoId"
              @click="transferirOansista"
            />
          </div>
        </template>
      </Card>

      <Card>
        <template #title>
          <div class="flex items-center justify-between">
            <h2 class="font-semibold">
              Histórico
            </h2>
            <Tag :value="String(historico.length)" />
          </div>
        </template>
        <template #content>
          <div
            v-if="historico.length === 0"
            class="text-center py-8 text-surface-500"
          >
            Nenhuma transferência registrada.
          </div>

          <ul
            v-else
            class="flex flex-col gap-3 max-h-[480px] overflow-y-auto"
          >
            <li
              v-for="t in historico"
              :key="t.id"
              class="rounded-lg border p-3"
            >
              <div class="flex items-center justify-between gap-2">
                <p class="font-medium text-sm truncate">
                  {{ t.oansista_nome ?? '—' }}
                </p>
                <span class="text-xs text-surface-500 shrink-0">
                  {{ new Date(`${t.data}T00:00:00`).toLocaleDateString('pt-BR') }}
                </span>
              </div>
              <p class="text-xs text-surface-500 mt-1 flex items-center gap-1">
                <span class="truncate">{{ t.origem_nome ?? 'Sem turma' }}</span>
                <i class="pi pi-arrow-right text-xs shrink-0" />
                <span class="truncate">{{ t.destino_nome ?? '—' }}</span>
              </p>
              <p
                v-if="t.motivo"
                class="text-xs text-surface-500 mt-1 italic truncate"
              >
                {{ t.motivo }}
              </p>
            </li>
          </ul>
        </template>
      </Card>
    </div>
  </div>
</template>
