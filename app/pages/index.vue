<script setup lang="ts">
const { profile } = useAuth()
const { roleLabel } = useRole()
const { data: clube } = useAsyncData('clube-atual', async () => {
  if (!profile.value?.clube_id) return null
  const supabase = useSupabaseClient()
  const { data } = await supabase
    .from('clubes')
    .select('nome, cor, slug')
    .eq('id', profile.value!.clube_id!)
    .single()
  return data
})

useSeoMeta({ title: 'Início — Oanse' })
</script>

<template>
  <div class="p-4 sm:p-6 max-w-3xl mx-auto w-full">
    <h1 class="text-2xl font-bold">
      Olá, {{ profile?.nome?.split(' ')[0] }}!
    </h1>
    <p class="text-muted mt-1">
      Você está logado como <strong>{{ roleLabel }}</strong>
      <template v-if="clube">
        do clube
        <span class="inline-flex items-center gap-1 align-middle">
          <img
            :src="logoClube(clube.slug) ?? undefined"
            :alt="clube.nome"
            class="size-4 object-contain inline-block"
          >
          <span
            class="font-semibold"
            :style="{ color: clube.cor ?? undefined }"
          >{{ clube.nome }}</span>
        </span>
      </template>.
    </p>

    <div class="mt-8 grid gap-4 sm:grid-cols-2">
      <UCard>
        <template #header>
          <span class="font-semibold">Fase 1 em construção</span>
        </template>
        <p class="text-sm text-muted">
          As telas de administração (usuários, clubes, configurações), turmas e
          oansistas estão sendo implementadas.
        </p>
      </UCard>
      <UCard>
        <template #header>
          <span class="font-semibold">Próximas fases</span>
        </template>
        <p class="text-sm text-muted">
          Fase 2: Lançamento Semanal (chamada e Folha Semanal).
          Fase 3: Painel da Secretaria. Fase 4: Jogos e Ranking.
        </p>
      </UCard>
    </div>
  </div>
</template>
