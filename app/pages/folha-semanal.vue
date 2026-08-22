<script setup lang="ts">
import type { Database } from '~/types/database.types'
import type { FormFolha } from '~/composables/useFolhaSemanal'

type Oansista = Database['public']['Tables']['oansistas']['Row']
type Presenca = Database['public']['Tables']['presencas']['Row']

definePageMeta({ middleware: ['role'], roles: ['lider'] })
useSeoMeta({ title: 'Folha Semanal — Oanse' })

const supabase = useSupabaseClient()
const toast = useToast()
const { user } = useAuth()
const { encontro, carregando: carregandoEncontro, carregar: carregarEncontro } = useEncontro()
const { pontos, carregando: carregandoFolhas, carregar: carregarFolhas, folhaDe, salvar } = useFolhaSemanal()

const turma = ref<{ id: string, nome: string } | null>(null)
const oansistas = ref<Oansista[]>([])
const presencas = ref<Presenca[]>([])
const carregando = ref(true)
const salvandoId = ref<string | null>(null)

function presencaDe(o: Oansista): Presenca | undefined {
  return presencas.value.find(p => p.oansista_id === o.id)
}

function presente(o: Oansista): boolean {
  return presencaDe(o)?.presente ?? false
}

const presentes = computed(() => oansistas.value.filter(presente))

const dataFormatada = computed(() => {
  if (!encontro.value) return ''
  return new Date(`${encontro.value.data}T00:00:00`).toLocaleDateString('pt-BR', {
    weekday: 'long', day: 'numeric', month: 'long',
  })
})

async function carregarTurma() {
  if (!user.value?.sub) return
  const { data } = await supabase
    .from('turmas')
    .select('id, nome')
    .eq('lider_id', user.value.sub)
    .eq('ativo', true)
    .maybeSingle()
  turma.value = data ?? null
}

async function carregarOansistas() {
  if (!turma.value) {
    oansistas.value = []
    return
  }
  const { data } = await supabase
    .from('oansistas')
    .select('*')
    .eq('turma_id', turma.value.id)
    .eq('status', 'ativo')
    .order('nome')
  oansistas.value = data ?? []
}

async function carregarPresencas() {
  if (!encontro.value || oansistas.value.length === 0) {
    presencas.value = []
    return
  }
  const ids = oansistas.value.map(o => o.id)
  const { data } = await supabase
    .from('presencas')
    .select('*')
    .eq('encontro_id', encontro.value.id)
    .in('oansista_id', ids)
  presencas.value = data ?? []
}

async function carregarTudo() {
  carregando.value = true
  await Promise.all([carregarEncontro(), carregarTurma()])
  await carregarOansistas()
  await carregarPresencas()
  if (encontro.value) {
    await carregarFolhas(encontro.value.id, oansistas.value.map(o => o.id))
  }
  carregando.value = false
}

async function onSalvar(o: Oansista, form: FormFolha) {
  if (!encontro.value || !user.value?.sub) return
  const presenca = presencaDe(o)
  if (!presenca) return
  salvandoId.value = o.id
  try {
    await salvar(encontro.value.id, o.id, presenca.id, user.value.sub, form)
  }
  catch (e) {
    toast.add({
      title: 'Erro ao salvar folha',
      description: (e as { message?: string })?.message ?? 'Tente novamente',
      color: 'error',
    })
  }
  finally {
    salvandoId.value = null
  }
}

onMounted(carregarTudo)
</script>

<template>
  <div class="p-4 sm:p-6 max-w-3xl mx-auto w-full">
    <div class="flex items-center justify-between mb-4">
      <div>
        <h1 class="text-2xl font-bold">
          Folha Semanal
        </h1>
        <p
          v-if="dataFormatada"
          class="text-sm text-muted capitalize"
        >
          {{ dataFormatada }}
        </p>
      </div>
      <div
        v-if="turma && oansistas.length"
        class="text-sm text-muted"
      >
        {{ presentes.length }} / {{ oansistas.length }} presentes
      </div>
    </div>

    <div
      v-if="carregando || carregandoEncontro || carregandoFolhas"
      class="flex justify-center py-10"
    >
      <UIcon
        name="i-lucide-loader-circle"
        class="size-6 animate-spin text-muted"
      />
    </div>

    <UCard
      v-else-if="!turma"
      class="text-center py-6"
    >
      <p class="text-muted">
        Você ainda não tem uma turma atribuída. Procure o Diretor do seu clube.
      </p>
    </UCard>

    <template v-else-if="turma">
      <p class="text-sm text-muted mb-3">
        Turma: <strong>{{ turma.nome }}</strong>
      </p>

      <div
        v-if="oansistas.length === 0"
        class="text-center py-8 text-muted"
      >
        Nenhuma criança ativa nesta turma.
      </div>

      <div
        v-else
        class="flex flex-col gap-3"
      >
        <template
          v-for="o in oansistas"
          :key="o.id"
        >
          <FolhaSemanalRow
            v-if="presente(o)"
            :nome="o.nome"
            :folha="folhaDe(o.id) ?? null"
            :presente="true"
            :pontos="pontos"
            :salvando="salvandoId === o.id"
            @salvar="form => onSalvar(o, form)"
          />
          <div
            v-else
            class="flex items-center justify-between gap-3 rounded-lg border border-dashed border-default p-3 opacity-70"
          >
            <div class="flex items-center gap-3 min-w-0">
              <UAvatar
                :alt="o.nome"
                size="sm"
              />
              <span class="font-medium truncate">{{ o.nome }}</span>
            </div>
            <div class="flex items-center gap-2 shrink-0">
              <UBadge
                variant="subtle"
                color="neutral"
              >
                Ausente — 0 pts
              </UBadge>
            </div>
          </div>
        </template>
      </div>

      <p class="text-xs text-muted mt-4">
        Ausentes ficam com o total zerado (regra automática). O total é calculado
        pela configuração de pontuação definida pelo Diretor Geral.
      </p>
    </template>
  </div>
</template>
