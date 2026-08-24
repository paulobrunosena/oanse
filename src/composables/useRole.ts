import { storeToRefs } from 'pinia'
import { useRoleStore } from '@/stores/role'
import type { UserRole } from '@/stores/auth'

/**
 * Helpers de RBAC (UX apenas — a segurança real é RLS no banco).
 */
export function useRole() {
  const store = useRoleStore()
  return { ...storeToRefs(store), hasAny: store.hasAny }
}

export type { UserRole }
