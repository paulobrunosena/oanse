<script setup lang="ts">
import type { Database } from '~/types/database.types'

type Oansista = Database['public']['Tables']['oansistas']['Row']
type Presenca = Database['public']['Tables']['presencas']['Row']

definePageMeta({ middleware: ['role'], roles: ['lider'] })
useSeoMeta({ title: 'Chamada — Oanse' })

const supabase = useSupabaseClient()
const toast = useToast()
const { user } = useAuth()
const { encontro, carregando: carregandoEncontro, carregar: carregarEncontro } = useEncontro()

const turma = ref<{ id: string, nome: string } | null>(null)
const oansistas = ref<Oansista[]>([])
const presencas = ref<Presenca[]>([])
const carregando = ref(true)
const salvandoId = ref<string | null>(null)

const presencaPorOansista = computed(() => {
  const mapa = new Map<string, Presenca>()
  for (const p of presencas.value) mapa.set(p.oansista_id, p)
  return mapa
})

const presentes = computed(() => presencas.value.filter(p => p.presente).length)

function presente(o: Oansista): boolean {
  return presencaPorOansista.value.get(o.id)?.presente ?? false
}

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

  if (!turma.value && encontro.value) {
    const { data: rem } = await supabase
      .from('remanejamentos_temporarios')
      .select('turma_id')
      .eq('encontro_id', encontro.value.id)
      .eq('lider_substituto_id', user.value.sub)
      .maybeSingle()
    if (rem) {
      const { data: t } = await supabase
        .from('turmas')
        .select('id, nome')
        .eq('id', rem.turma_id)
        .maybeSingle()
      turma.value = t ?? null
    }
  }
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
  await carregarEncontro()
  await carregarTurma()
  await carregarOansistas()
  await carregarPresencas()
  carregando.value = false
}

async function alternar(o: Oansista) {
  if (!encontro.value || !user.value?.sub) return
  salvandoId.value = o.id
  const existente = presencaPorOansista.value.get(o.id)

  try {
    if (existente) {
      const { error } = await supabase
        .from('presencas')
        .update({ presente: !existente.presente })
        .eq('id', existente.id)
      if (error) throw error
      existente.presente = !existente.presente
    }
    else {
      const { data: nova, error } = await supabase
        .from('presencas')
        .insert({
          encontro_id: encontro.value.id,
          oansista_id: o.id,
          presente: true,
          lider_registrante_id: user.value.sub,
        })
        .select()
        .single()
      if (error || !nova) throw error

      const { error: errFolha } = await supabase
        .from('folhas_semanais')
        .insert({
          encontro_id: encontro.value.id,
          oansista_id: o.id,
          presenca_id: nova.id,
          registrado_por: user.value.sub,
        })
      if (errFolha) throw errFolha

      presencas.value.push(nova)
    }
  }
  catch (e) {
    toast.add({
      title: 'Erro ao lançar presença',
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
  <div class="p-4 sm:p-6 max-w-2xl mx-auto w-full">
    <div class="flex items-center justify-between mb-4">
      <div>
        <h1 class="text-2xl font-bold">
          Chamada
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
        {{ presentes }} / {{ oansistas.length }} presentes
      </div>
    </div>

    <div
      v-if="carregando || carregandoEncontro"
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

      <ul
        v-else
        class="flex flex-col gap-2"
      >
        <li
          v-for="o in oansistas"
          :key="o.id"
          class="flex items-center justify-between gap-3 rounded-lg border border-default p-3"
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
              :color="presente(o) ? 'success' : 'neutral'"
              variant="subtle"
            >
              {{ presente(o) ? 'Presente' : 'Falta' }}
            </UBadge>
            <USwitch
              :model-value="presente(o)"
              :loading="salvandoId === o.id"
              @update:model-value="alternar(o)"
            />
          </div>
        </li>
      </ul>
    </template>
  </div>
</template>
