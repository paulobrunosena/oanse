<script setup lang="ts">
import type { FormError } from '@nuxt/ui'

definePageMeta({ layout: 'blank' })
useSeoMeta({ title: 'Entrar — Oanse' })

const supabase = useSupabaseClient()
const { user } = useAuth()

const state = reactive({ email: '', password: '' })
const carregando = ref(false)
const erro = ref<string | null>(null)

const contasTeste = [
  { email: 'diretor@oanse.local', perfil: 'Diretor Geral' },
  { email: 'secretaria@oanse.local', perfil: 'Secretaria' },
  { email: 'diretor.ursinhos@oanse.local', perfil: 'Diretor de Clube' },
  { email: 'tia.ana@oanse.local', perfil: 'Líder' },
]

const validar = (s: typeof state): FormError[] => {
  const erros: FormError[] = []
  if (!s.email.trim()) erros.push({ name: 'email', message: 'Informe o e-mail' })
  if (!s.password) erros.push({ name: 'password', message: 'Informe a senha' })
  return erros
}

async function entrar() {
  carregando.value = true
  erro.value = null
  const { error } = await supabase.auth.signInWithPassword({
    email: state.email.trim(),
    password: state.password,
  })
  carregando.value = false
  if (error) {
    erro.value = 'E-mail ou senha inválidos.'
    return
  }
  await navigateTo('/')
}

onMounted(() => {
  if (user.value) navigateTo('/', { replace: true })
})
</script>

<template>
  <div class="w-full max-w-sm flex flex-col gap-6">
    <div class="flex flex-col items-center gap-2">
      <UIcon
        name="i-lucide-flame"
        class="size-12 text-primary"
      />
      <h1 class="text-2xl font-bold">
        Oanse
      </h1>
      <p class="text-sm text-muted">
        Ministério Infantil — Acesso ao sistema
      </p>
    </div>

    <UCard>
      <UForm
        :state="state"
        :validate="validar"
        class="flex flex-col gap-4"
        @submit="entrar"
      >
        <UFormField
          label="E-mail"
          name="email"
        >
          <UInput
            v-model="state.email"
            type="email"
            icon="i-lucide-mail"
            placeholder="voce@exemplo.com"
            class="w-full"
            autocomplete="email"
          />
        </UFormField>

        <UFormField
          label="Senha"
          name="password"
        >
          <UInput
            v-model="state.password"
            type="password"
            icon="i-lucide-lock"
            placeholder="••••••••"
            class="w-full"
            autocomplete="current-password"
          />
        </UFormField>

        <p
          v-if="erro"
          class="text-sm text-error"
        >
          {{ erro }}
        </p>

        <UButton
          type="submit"
          block
          :loading="carregando"
          icon="i-lucide-log-in"
        >
          Entrar
        </UButton>
      </UForm>
    </UCard>

    <UCard
      variant="subtle"
      :ui="{ body: 'p-4 sm:p-4' }"
    >
      <p class="text-xs font-semibold text-muted mb-2">
        Contas de teste (senha: oanse123)
      </p>
      <ul class="text-xs text-muted flex flex-col gap-1">
        <li
          v-for="conta in contasTeste"
          :key="conta.email"
        >
          <button
            type="button"
            class="hover:text-primary underline-offset-2 hover:underline"
            @click="state.email = conta.email; state.password = 'oanse123'"
          >
            {{ conta.email }}
          </button>
          — {{ conta.perfil }}
        </li>
      </ul>
    </UCard>
  </div>
</template>
