<script setup lang="ts">
import type { OansistaTransferencia } from '~/composables/useTransferencias'

definePageMeta({ middleware: ['role'], roles: ['diretor_clube'] })
useSeoMeta({ title: 'Transferências — Oanse' })

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

const opcoesOansistas = computed(() => {
  const porTurma = new Map<string, string>()
  for (const o of oansistas.value) {
    const chave = `${o.nome}|${o.turma_id ?? ''}`
    if (!porTurma.has(o.id)) porTurma.set(o.id, chave)
  }
  return oansistas.value.map(o => ({
    label: o.turma_nome ? `${o.nome} — ${o.turma_nome}` : o.nome,
    value: o.id,
  }))
})

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
        <p class="text-sm text-muted">
          Move a criança para outra turma do clube e registra o histórico.
        </p>
      </div>
    </div>

    <div
      v-if="carregandoInicial"
      class="flex justify-center py-10"
    >
      <UIcon
        name="i-lucide-loader-circle"
        class="size-6 animate-spin text-muted"
      />
    </div>

    <UCard
      v-else-if="!profile?.clube_id"
      class="text-center py-6"
    >
      <p class="text-muted">
        Você não está vinculado a um clube. Fale com o Diretor Geral.
      </p>
    </UCard>

    <div
      v-else
      class="grid grid-cols-1 lg:grid-cols-2 gap-4 items-start"
    >
      <UCard>
        <template #header>
          <h2 class="font-semibold">
            Transferir criança
          </h2>
        </template>

        <div class="flex flex-col gap-4">
          <div>
            <label class="text-sm font-medium">Criança</label>
            <USelect
              v-model="selecionadoId"
              :items="opcoesOansistas"
              placeholder="Selecionar criança"
              searchable
              class="mt-1 w-full"
              @update:model-value="aoTrocarOansista"
            />
            <p
              v-if="selecionado"
              class="text-xs text-muted mt-1"
            >
              Turma atual:
              <UBadge
                variant="soft"
                color="neutral"
              >
                {{ selecionado.turma_nome ?? 'Sem turma' }}
              </UBadge>
            </p>
          </div>

          <div>
            <label class="text-sm font-medium">Turma de destino</label>
            <USelect
              v-model="destinoId"
              :items="opcoesDestino"
              :disabled="!selecionado"
              placeholder="Selecionar turma"
              class="mt-1 w-full"
            />
          </div>

          <div>
            <label class="text-sm font-medium">Motivo (opcional)</label>
            <UInput
              v-model="motivo"
              placeholder="Ex.: nova faixa etária, pedido da família"
              class="mt-1 w-full"
            />
          </div>

          <UButton
            icon="i-lucide-arrow-right-left"
            color="primary"
            :loading="transferindo"
            :disabled="!selecionado || !destinoId"
            @click="transferirOansista"
          >
            Transferir
          </UButton>
        </div>
      </UCard>

      <UCard>
        <template #header>
          <div class="flex items-center justify-between">
            <h2 class="font-semibold">
              Histórico
            </h2>
            <UBadge variant="soft">
              {{ historico.length }}
            </UBadge>
          </div>
        </template>

        <div
          v-if="historico.length === 0"
          class="text-center py-8 text-muted"
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
            class="rounded-lg border border-default p-3"
          >
            <div class="flex items-center justify-between gap-2">
              <p class="font-medium text-sm truncate">
                {{ t.oansista_nome ?? '—' }}
              </p>
              <span class="text-xs text-muted shrink-0">
                {{ new Date(`${t.data}T00:00:00`).toLocaleDateString('pt-BR') }}
              </span>
            </div>
            <p class="text-xs text-muted mt-1 flex items-center gap-1">
              <span class="truncate">{{ t.origem_nome ?? 'Sem turma' }}</span>
              <UIcon
                name="i-lucide-arrow-right"
                class="size-3 shrink-0"
              />
              <span class="truncate">{{ t.destino_nome ?? '—' }}</span>
            </p>
            <p
              v-if="t.motivo"
              class="text-xs text-muted mt-1 italic truncate"
            >
              {{ t.motivo }}
            </p>
          </li>
        </ul>
      </UCard>
    </div>
  </div>
</template>
