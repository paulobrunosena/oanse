<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import Button from 'primevue/button'
import Card from 'primevue/card'
import InputText from 'primevue/inputtext'
import Password from 'primevue/password'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/composables/useAuth'

const router = useRouter()
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
  await router.push('/')
}

onMounted(() => {
  if (user.value) router.replace('/')
})
</script>

<template>
  <div class="w-full max-w-sm flex flex-col gap-6">
    <div class="flex flex-col items-center gap-2">
      <img
        src="/logos/oanse.png"
        alt="Oanse"
        class="h-14 w-auto object-contain"
      >
      <h1 class="text-2xl font-bold">
        Oanse
      </h1>
      <p class="text-sm text-surface-500">
        Ministério Infantil — Acesso ao sistema
      </p>
    </div>

    <Card>
      <template #content>
        <form
          class="flex flex-col gap-4"
          @submit.prevent="entrar"
        >
          <div class="flex flex-col gap-1">
            <label
              for="email"
              class="text-sm font-medium"
            >E-mail</label>
            <InputText
              id="email"
              v-model="state.email"
              type="email"
              placeholder="voce@exemplo.com"
              autocomplete="email"
              class="w-full"
            />
          </div>

          <div class="flex flex-col gap-1">
            <label
              for="password"
              class="text-sm font-medium"
            >Senha</label>
            <Password
              id="password"
              v-model="state.password"
              placeholder="••••••••"
              :feedback="false"
              toggle-mask
              autocomplete="current-password"
              class="w-full"
            />
          </div>

          <p
            v-if="erro"
            class="text-sm text-red-600"
          >
            {{ erro }}
          </p>

          <Button
            type="submit"
            :loading="carregando"
            label="Entrar"
            class="w-full"
          />
        </form>
      </template>
    </Card>

    <Card>
      <template #content>
        <p class="text-xs font-semibold text-surface-500 mb-2">
          Contas de teste (senha: oanse123)
        </p>
        <ul class="text-xs text-surface-500 flex flex-col gap-1">
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
      </template>
    </Card>
  </div>
</template>
