import { createRouter, createWebHistory, type RouteRecordRaw } from 'vue-router'
import BlankLayout from '@/layouts/BlankLayout.vue'
import AppLayout from '@/layouts/AppLayout.vue'

const rotas: RouteRecordRaw[] = [
  {
    path: '/login',
    component: BlankLayout,
    children: [
      { path: '', name: 'login', component: () => import('@/views/LoginView.vue') },
    ],
  },
  {
    path: '/',
    component: AppLayout,
    children: [
      { path: '', name: 'inicio', component: () => import('@/views/DashboardView.vue') },
      { path: 'chamada', name: 'chamada', component: () => import('@/views/ChamadaView.vue'), meta: { roles: ['lider'] } },
      { path: 'folha-semanal', name: 'folha-semanal', component: () => import('@/views/FolhaSemanalView.vue'), meta: { roles: ['lider'] } },
      { path: 'admin/usuarios', name: 'admin-usuarios', component: () => import('@/views/admin/UsuariosView.vue'), meta: { roles: ['diretor_geral'] } },
      { path: 'admin/clubes', name: 'admin-clubes', component: () => import('@/views/admin/ClubesView.vue'), meta: { roles: ['diretor_geral'] } },
      { path: 'admin/configuracoes', name: 'admin-configuracoes', component: () => import('@/views/admin/ConfiguracoesView.vue'), meta: { roles: ['diretor_geral'] } },
      { path: 'admin/calendario', name: 'admin-calendario', component: () => import('@/views/admin/CalendarioView.vue'), meta: { roles: ['diretor_geral'] } },
      { path: 'clube/turmas', name: 'clube-turmas', component: () => import('@/views/clube/TurmasView.vue'), meta: { roles: ['diretor_geral', 'diretor_clube'] } },
      { path: 'clube/lideres', name: 'clube-lideres', component: () => import('@/views/clube/LideresView.vue'), meta: { roles: ['diretor_geral', 'diretor_clube'] } },
      { path: 'clube/oansistas', name: 'clube-oansistas', component: () => import('@/views/clube/OansistasView.vue'), meta: { roles: ['diretor_geral', 'diretor_clube'] } },
      { path: 'clube/remanejamentos', name: 'clube-remanejamentos', component: () => import('@/views/clube/RemanejamentosView.vue'), meta: { roles: ['diretor_clube'] } },
      { path: 'clube/transferencias', name: 'clube-transferencias', component: () => import('@/views/clube/TransferenciasView.vue'), meta: { roles: ['diretor_clube'] } },
      { path: 'clube/jogos', name: 'clube-jogos', component: () => import('@/views/clube/JogosView.vue'), meta: { roles: ['diretor_geral', 'lider_jogos'] } },
      { path: 'clube/jogos-catalogo', name: 'clube-jogos-catalogo', component: () => import('@/views/clube/JogosCatalogoView.vue'), meta: { roles: ['diretor_geral', 'lider_jogos', 'diretor_clube'] } },
      { path: 'clube/ranking', name: 'clube-ranking', component: () => import('@/views/clube/RankingView.vue'), meta: { roles: ['diretor_geral', 'diretor_clube'] } },
    ],
  },
  { path: '/:pathMatch(.*)*', redirect: '/' },
]

export default createRouter({
  history: createWebHistory(),
  routes: rotas,
})
