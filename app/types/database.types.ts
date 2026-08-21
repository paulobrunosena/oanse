export type Json
  = | string
    | number
    | boolean
    | null
    | { [key: string]: Json | undefined }
    | Json[]

export type Database = {
  graphql_public: {
    Tables: {
      [_ in never]: never
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      graphql: {
        Args: {
          extensions?: Json
          operationName?: string
          query?: string
          variables?: Json
        }
        Returns: Json
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
  public: {
    Tables: {
      clubes: {
        Row: {
          cor: string | null
          created_at: string
          id: string
          idade_max: number
          idade_min: number
          nome: string
          ordem: number
          slug: string
        }
        Insert: {
          cor?: string | null
          created_at?: string
          id?: string
          idade_max: number
          idade_min: number
          nome: string
          ordem: number
          slug: string
        }
        Update: {
          cor?: string | null
          created_at?: string
          id?: string
          idade_max?: number
          idade_min?: number
          nome?: string
          ordem?: number
          slug?: string
        }
        Relationships: []
      }
      encontros: {
        Row: {
          ativo: boolean
          created_at: string
          data: string
          id: string
          tema: string | null
        }
        Insert: {
          ativo?: boolean
          created_at?: string
          data: string
          id?: string
          tema?: string | null
        }
        Update: {
          ativo?: boolean
          created_at?: string
          data?: string
          id?: string
          tema?: string | null
        }
        Relationships: []
      }
      folhas_semanais: {
        Row: {
          atividade_extra: number
          biblia: boolean
          conduta: boolean
          created_at: string
          ebd: boolean
          encontro_id: string
          id: string
          manual: boolean
          oansista_id: string
          pontos_jogos: number
          presenca_id: string
          registrado_por: string
          secoes_dia: number
          total: number
          uniforme: boolean
          updated_at: string
        }
        Insert: {
          atividade_extra?: number
          biblia?: boolean
          conduta?: boolean
          created_at?: string
          ebd?: boolean
          encontro_id: string
          id?: string
          manual?: boolean
          oansista_id: string
          pontos_jogos?: number
          presenca_id: string
          registrado_por: string
          secoes_dia?: number
          total?: number
          uniforme?: boolean
          updated_at?: string
        }
        Update: {
          atividade_extra?: number
          biblia?: boolean
          conduta?: boolean
          created_at?: string
          ebd?: boolean
          encontro_id?: string
          id?: string
          manual?: boolean
          oansista_id?: string
          pontos_jogos?: number
          presenca_id?: string
          registrado_por?: string
          secoes_dia?: number
          total?: number
          uniforme?: boolean
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: 'folhas_semanais_encontro_id_fkey'
            columns: ['encontro_id']
            isOneToOne: false
            referencedRelation: 'encontros'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'folhas_semanais_encontro_id_fkey'
            columns: ['encontro_id']
            isOneToOne: false
            referencedRelation: 'v_ranking_semanal'
            referencedColumns: ['encontro_id']
          },
          {
            foreignKeyName: 'folhas_semanais_oansista_id_fkey'
            columns: ['oansista_id']
            isOneToOne: false
            referencedRelation: 'oansistas'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'folhas_semanais_presenca_id_fkey'
            columns: ['presenca_id']
            isOneToOne: false
            referencedRelation: 'presencas'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'folhas_semanais_registrado_por_fkey'
            columns: ['registrado_por']
            isOneToOne: false
            referencedRelation: 'profiles'
            referencedColumns: ['id']
          },
        ]
      }
      itens_pontuacao: {
        Row: {
          ativo: boolean
          chave: string
          descricao: string
          pontos: number
        }
        Insert: {
          ativo?: boolean
          chave: string
          descricao: string
          pontos?: number
        }
        Update: {
          ativo?: boolean
          chave?: string
          descricao?: string
          pontos?: number
        }
        Relationships: []
      }
      jogo_resultados: {
        Row: {
          colocacao: number | null
          created_at: string
          desclassificado: boolean
          id: string
          jogo_id: string
          pontos: number
          time_id: string
        }
        Insert: {
          colocacao?: number | null
          created_at?: string
          desclassificado?: boolean
          id?: string
          jogo_id: string
          pontos?: number
          time_id: string
        }
        Update: {
          colocacao?: number | null
          created_at?: string
          desclassificado?: boolean
          id?: string
          jogo_id?: string
          pontos?: number
          time_id?: string
        }
        Relationships: [
          {
            foreignKeyName: 'jogo_resultados_jogo_id_fkey'
            columns: ['jogo_id']
            isOneToOne: false
            referencedRelation: 'jogos'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'jogo_resultados_time_id_fkey'
            columns: ['time_id']
            isOneToOne: false
            referencedRelation: 'jogo_times'
            referencedColumns: ['id']
          },
        ]
      }
      jogo_time_integrantes: {
        Row: {
          id: string
          oansista_id: string
          time_id: string
        }
        Insert: {
          id?: string
          oansista_id: string
          time_id: string
        }
        Update: {
          id?: string
          oansista_id?: string
          time_id?: string
        }
        Relationships: [
          {
            foreignKeyName: 'jogo_time_integrantes_oansista_id_fkey'
            columns: ['oansista_id']
            isOneToOne: false
            referencedRelation: 'oansistas'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'jogo_time_integrantes_time_id_fkey'
            columns: ['time_id']
            isOneToOne: false
            referencedRelation: 'jogo_times'
            referencedColumns: ['id']
          },
        ]
      }
      jogo_times: {
        Row: {
          cor: string | null
          id: string
          jogo_id: string
          lider_id: string | null
          nome: string
        }
        Insert: {
          cor?: string | null
          id?: string
          jogo_id: string
          lider_id?: string | null
          nome: string
        }
        Update: {
          cor?: string | null
          id?: string
          jogo_id?: string
          lider_id?: string | null
          nome?: string
        }
        Relationships: [
          {
            foreignKeyName: 'jogo_times_jogo_id_fkey'
            columns: ['jogo_id']
            isOneToOne: false
            referencedRelation: 'jogos'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'jogo_times_lider_id_fkey'
            columns: ['lider_id']
            isOneToOne: false
            referencedRelation: 'profiles'
            referencedColumns: ['id']
          },
        ]
      }
      jogos: {
        Row: {
          categoria: Database['public']['Enums']['jogo_categoria']
          created_at: string
          criado_por: string | null
          encontro_id: string
          id: string
          nome: string
        }
        Insert: {
          categoria: Database['public']['Enums']['jogo_categoria']
          created_at?: string
          criado_por?: string | null
          encontro_id: string
          id?: string
          nome: string
        }
        Update: {
          categoria?: Database['public']['Enums']['jogo_categoria']
          created_at?: string
          criado_por?: string | null
          encontro_id?: string
          id?: string
          nome?: string
        }
        Relationships: [
          {
            foreignKeyName: 'jogos_criado_por_fkey'
            columns: ['criado_por']
            isOneToOne: false
            referencedRelation: 'profiles'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'jogos_encontro_id_fkey'
            columns: ['encontro_id']
            isOneToOne: false
            referencedRelation: 'encontros'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'jogos_encontro_id_fkey'
            columns: ['encontro_id']
            isOneToOne: false
            referencedRelation: 'v_ranking_semanal'
            referencedColumns: ['encontro_id']
          },
        ]
      }
      jogos_pontos_config: {
        Row: {
          colocacao: number
          desclassificado: boolean
          pontos: number
        }
        Insert: {
          colocacao: number
          desclassificado?: boolean
          pontos: number
        }
        Update: {
          colocacao?: number
          desclassificado?: boolean
          pontos?: number
        }
        Relationships: []
      }
      oansistas: {
        Row: {
          clube_id: string
          contato: string | null
          created_at: string
          data_matricula: string
          data_nascimento: string
          id: string
          nome: string
          observacoes: string | null
          responsavel: string | null
          status: Database['public']['Enums']['status_oansista']
          turma_id: string | null
          updated_at: string
        }
        Insert: {
          clube_id: string
          contato?: string | null
          created_at?: string
          data_matricula?: string
          data_nascimento: string
          id?: string
          nome: string
          observacoes?: string | null
          responsavel?: string | null
          status?: Database['public']['Enums']['status_oansista']
          turma_id?: string | null
          updated_at?: string
        }
        Update: {
          clube_id?: string
          contato?: string | null
          created_at?: string
          data_matricula?: string
          data_nascimento?: string
          id?: string
          nome?: string
          observacoes?: string | null
          responsavel?: string | null
          status?: Database['public']['Enums']['status_oansista']
          turma_id?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: 'oansistas_clube_id_fkey'
            columns: ['clube_id']
            isOneToOne: false
            referencedRelation: 'clubes'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'oansistas_turma_id_fkey'
            columns: ['turma_id']
            isOneToOne: false
            referencedRelation: 'turmas'
            referencedColumns: ['id']
          },
        ]
      }
      premios: {
        Row: {
          ativo: boolean
          created_at: string
          descricao: string | null
          estoque: number
          estoque_min: number
          id: string
          nivel: number | null
          nome: string
          secao: number | null
          tipo: Database['public']['Enums']['premio_tipo']
        }
        Insert: {
          ativo?: boolean
          created_at?: string
          descricao?: string | null
          estoque?: number
          estoque_min?: number
          id?: string
          nivel?: number | null
          nome: string
          secao?: number | null
          tipo: Database['public']['Enums']['premio_tipo']
        }
        Update: {
          ativo?: boolean
          created_at?: string
          descricao?: string | null
          estoque?: number
          estoque_min?: number
          id?: string
          nivel?: number | null
          nome?: string
          secao?: number | null
          tipo?: Database['public']['Enums']['premio_tipo']
        }
        Relationships: []
      }
      premios_movimentacoes: {
        Row: {
          created_at: string
          feito_por: string
          id: string
          observacao: string | null
          premio_id: string
          quantidade: number
          tipo: string
        }
        Insert: {
          created_at?: string
          feito_por: string
          id?: string
          observacao?: string | null
          premio_id: string
          quantidade: number
          tipo: string
        }
        Update: {
          created_at?: string
          feito_por?: string
          id?: string
          observacao?: string | null
          premio_id?: string
          quantidade?: number
          tipo?: string
        }
        Relationships: [
          {
            foreignKeyName: 'premios_movimentacoes_premio_id_fkey'
            columns: ['premio_id']
            isOneToOne: false
            referencedRelation: 'premios'
            referencedColumns: ['id']
          },
        ]
      }
      premios_pendentes: {
        Row: {
          clube_id: string
          data_entrega: string | null
          data_geracao: string
          entregue_por: string | null
          id: string
          oansista_id: string
          observacao: string | null
          premio_id: string
          progresso_id: string | null
          status: Database['public']['Enums']['pendencia_status']
        }
        Insert: {
          clube_id: string
          data_entrega?: string | null
          data_geracao?: string
          entregue_por?: string | null
          id?: string
          oansista_id: string
          observacao?: string | null
          premio_id: string
          progresso_id?: string | null
          status?: Database['public']['Enums']['pendencia_status']
        }
        Update: {
          clube_id?: string
          data_entrega?: string | null
          data_geracao?: string
          entregue_por?: string | null
          id?: string
          oansista_id?: string
          observacao?: string | null
          premio_id?: string
          progresso_id?: string | null
          status?: Database['public']['Enums']['pendencia_status']
        }
        Relationships: [
          {
            foreignKeyName: 'premios_pendentes_clube_id_fkey'
            columns: ['clube_id']
            isOneToOne: false
            referencedRelation: 'clubes'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'premios_pendentes_entregue_por_fkey'
            columns: ['entregue_por']
            isOneToOne: false
            referencedRelation: 'profiles'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'premios_pendentes_oansista_id_fkey'
            columns: ['oansista_id']
            isOneToOne: false
            referencedRelation: 'oansistas'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'premios_pendentes_premio_id_fkey'
            columns: ['premio_id']
            isOneToOne: false
            referencedRelation: 'premios'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'premios_pendentes_progresso_id_fkey'
            columns: ['progresso_id']
            isOneToOne: false
            referencedRelation: 'progresso_manual'
            referencedColumns: ['id']
          },
        ]
      }
      presencas: {
        Row: {
          created_at: string
          encontro_id: string
          id: string
          lider_registrante_id: string
          oansista_id: string
          observacao: string | null
          presente: boolean
        }
        Insert: {
          created_at?: string
          encontro_id: string
          id?: string
          lider_registrante_id: string
          oansista_id: string
          observacao?: string | null
          presente?: boolean
        }
        Update: {
          created_at?: string
          encontro_id?: string
          id?: string
          lider_registrante_id?: string
          oansista_id?: string
          observacao?: string | null
          presente?: boolean
        }
        Relationships: [
          {
            foreignKeyName: 'presencas_encontro_id_fkey'
            columns: ['encontro_id']
            isOneToOne: false
            referencedRelation: 'encontros'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'presencas_encontro_id_fkey'
            columns: ['encontro_id']
            isOneToOne: false
            referencedRelation: 'v_ranking_semanal'
            referencedColumns: ['encontro_id']
          },
          {
            foreignKeyName: 'presencas_lider_registrante_id_fkey'
            columns: ['lider_registrante_id']
            isOneToOne: false
            referencedRelation: 'profiles'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'presencas_oansista_id_fkey'
            columns: ['oansista_id']
            isOneToOne: false
            referencedRelation: 'oansistas'
            referencedColumns: ['id']
          },
        ]
      }
      profiles: {
        Row: {
          ativo: boolean
          clube_id: string | null
          created_at: string
          id: string
          nome: string
          role: Database['public']['Enums']['user_role']
          telefone: string | null
          updated_at: string
        }
        Insert: {
          ativo?: boolean
          clube_id?: string | null
          created_at?: string
          id: string
          nome: string
          role?: Database['public']['Enums']['user_role']
          telefone?: string | null
          updated_at?: string
        }
        Update: {
          ativo?: boolean
          clube_id?: string | null
          created_at?: string
          id?: string
          nome?: string
          role?: Database['public']['Enums']['user_role']
          telefone?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: 'profiles_clube_id_fkey'
            columns: ['clube_id']
            isOneToOne: false
            referencedRelation: 'clubes'
            referencedColumns: ['id']
          },
        ]
      }
      progresso_manual: {
        Row: {
          concluida: boolean
          created_at: string
          data_conclusao: string
          id: string
          nivel: number
          oansista_id: string
          registrado_por: string
          secao: number
        }
        Insert: {
          concluida?: boolean
          created_at?: string
          data_conclusao?: string
          id?: string
          nivel: number
          oansista_id: string
          registrado_por: string
          secao: number
        }
        Update: {
          concluida?: boolean
          created_at?: string
          data_conclusao?: string
          id?: string
          nivel?: number
          oansista_id?: string
          registrado_por?: string
          secao?: number
        }
        Relationships: [
          {
            foreignKeyName: 'progresso_manual_oansista_id_fkey'
            columns: ['oansista_id']
            isOneToOne: false
            referencedRelation: 'oansistas'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'progresso_manual_registrado_por_fkey'
            columns: ['registrado_por']
            isOneToOne: false
            referencedRelation: 'profiles'
            referencedColumns: ['id']
          },
        ]
      }
      prova_ingresso_licoes: {
        Row: {
          concluida: boolean
          data_conclusao: string | null
          id: string
          licao: number
          registrado_por: string | null
          visitante_id: string
        }
        Insert: {
          concluida?: boolean
          data_conclusao?: string | null
          id?: string
          licao: number
          registrado_por?: string | null
          visitante_id: string
        }
        Update: {
          concluida?: boolean
          data_conclusao?: string | null
          id?: string
          licao?: number
          registrado_por?: string | null
          visitante_id?: string
        }
        Relationships: [
          {
            foreignKeyName: 'prova_ingresso_licoes_registrado_por_fkey'
            columns: ['registrado_por']
            isOneToOne: false
            referencedRelation: 'profiles'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'prova_ingresso_licoes_visitante_id_fkey'
            columns: ['visitante_id']
            isOneToOne: false
            referencedRelation: 'visitantes'
            referencedColumns: ['id']
          },
        ]
      }
      remanejamentos_temporarios: {
        Row: {
          created_at: string
          criado_por: string
          encontro_id: string
          id: string
          lider_substituto_id: string
          lider_titular_id: string
          turma_id: string
        }
        Insert: {
          created_at?: string
          criado_por: string
          encontro_id: string
          id?: string
          lider_substituto_id: string
          lider_titular_id: string
          turma_id: string
        }
        Update: {
          created_at?: string
          criado_por?: string
          encontro_id?: string
          id?: string
          lider_substituto_id?: string
          lider_titular_id?: string
          turma_id?: string
        }
        Relationships: [
          {
            foreignKeyName: 'remanejamentos_temporarios_criado_por_fkey'
            columns: ['criado_por']
            isOneToOne: false
            referencedRelation: 'profiles'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'remanejamentos_temporarios_encontro_id_fkey'
            columns: ['encontro_id']
            isOneToOne: false
            referencedRelation: 'encontros'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'remanejamentos_temporarios_encontro_id_fkey'
            columns: ['encontro_id']
            isOneToOne: false
            referencedRelation: 'v_ranking_semanal'
            referencedColumns: ['encontro_id']
          },
          {
            foreignKeyName: 'remanejamentos_temporarios_lider_substituto_id_fkey'
            columns: ['lider_substituto_id']
            isOneToOne: false
            referencedRelation: 'profiles'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'remanejamentos_temporarios_lider_titular_id_fkey'
            columns: ['lider_titular_id']
            isOneToOne: false
            referencedRelation: 'profiles'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'remanejamentos_temporarios_turma_id_fkey'
            columns: ['turma_id']
            isOneToOne: false
            referencedRelation: 'turmas'
            referencedColumns: ['id']
          },
        ]
      }
      transferencias: {
        Row: {
          autorizado_por: string
          created_at: string
          data: string
          id: string
          lider_destino_id: string | null
          lider_origem_id: string | null
          motivo: string | null
          oansista_id: string
          tipo: Database['public']['Enums']['transferencia_tipo']
          turma_destino_id: string | null
          turma_origem_id: string | null
        }
        Insert: {
          autorizado_por: string
          created_at?: string
          data?: string
          id?: string
          lider_destino_id?: string | null
          lider_origem_id?: string | null
          motivo?: string | null
          oansista_id: string
          tipo: Database['public']['Enums']['transferencia_tipo']
          turma_destino_id?: string | null
          turma_origem_id?: string | null
        }
        Update: {
          autorizado_por?: string
          created_at?: string
          data?: string
          id?: string
          lider_destino_id?: string | null
          lider_origem_id?: string | null
          motivo?: string | null
          oansista_id?: string
          tipo?: Database['public']['Enums']['transferencia_tipo']
          turma_destino_id?: string | null
          turma_origem_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: 'transferencias_autorizado_por_fkey'
            columns: ['autorizado_por']
            isOneToOne: false
            referencedRelation: 'profiles'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'transferencias_lider_destino_id_fkey'
            columns: ['lider_destino_id']
            isOneToOne: false
            referencedRelation: 'profiles'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'transferencias_lider_origem_id_fkey'
            columns: ['lider_origem_id']
            isOneToOne: false
            referencedRelation: 'profiles'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'transferencias_oansista_id_fkey'
            columns: ['oansista_id']
            isOneToOne: false
            referencedRelation: 'oansistas'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'transferencias_turma_destino_id_fkey'
            columns: ['turma_destino_id']
            isOneToOne: false
            referencedRelation: 'turmas'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'transferencias_turma_origem_id_fkey'
            columns: ['turma_origem_id']
            isOneToOne: false
            referencedRelation: 'turmas'
            referencedColumns: ['id']
          },
        ]
      }
      turmas: {
        Row: {
          ativo: boolean
          clube_id: string
          created_at: string
          id: string
          lider_id: string
          nome: string
        }
        Insert: {
          ativo?: boolean
          clube_id: string
          created_at?: string
          id?: string
          lider_id: string
          nome: string
        }
        Update: {
          ativo?: boolean
          clube_id?: string
          created_at?: string
          id?: string
          lider_id?: string
          nome?: string
        }
        Relationships: [
          {
            foreignKeyName: 'turmas_clube_id_fkey'
            columns: ['clube_id']
            isOneToOne: false
            referencedRelation: 'clubes'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'turmas_lider_id_fkey'
            columns: ['lider_id']
            isOneToOne: true
            referencedRelation: 'profiles'
            referencedColumns: ['id']
          },
        ]
      }
      visitantes: {
        Row: {
          clube_id: string
          contato: string | null
          created_at: string
          data_cadastro: string
          data_nascimento: string
          id: string
          indicado_por: string | null
          nome: string
          responsavel: string | null
          status: Database['public']['Enums']['status_visitante']
          updated_at: string
        }
        Insert: {
          clube_id: string
          contato?: string | null
          created_at?: string
          data_cadastro?: string
          data_nascimento: string
          id?: string
          indicado_por?: string | null
          nome: string
          responsavel?: string | null
          status?: Database['public']['Enums']['status_visitante']
          updated_at?: string
        }
        Update: {
          clube_id?: string
          contato?: string | null
          created_at?: string
          data_cadastro?: string
          data_nascimento?: string
          id?: string
          indicado_por?: string | null
          nome?: string
          responsavel?: string | null
          status?: Database['public']['Enums']['status_visitante']
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: 'visitantes_clube_id_fkey'
            columns: ['clube_id']
            isOneToOne: false
            referencedRelation: 'clubes'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'visitantes_indicado_por_fkey'
            columns: ['indicado_por']
            isOneToOne: false
            referencedRelation: 'oansistas'
            referencedColumns: ['id']
          },
        ]
      }
      visitas: {
        Row: {
          data_visita: string
          id: string
          numero: number
          observacao: string | null
          presente: boolean
          visitante_id: string
        }
        Insert: {
          data_visita?: string
          id?: string
          numero: number
          observacao?: string | null
          presente?: boolean
          visitante_id: string
        }
        Update: {
          data_visita?: string
          id?: string
          numero?: number
          observacao?: string | null
          presente?: boolean
          visitante_id?: string
        }
        Relationships: [
          {
            foreignKeyName: 'visitas_visitante_id_fkey'
            columns: ['visitante_id']
            isOneToOne: false
            referencedRelation: 'visitantes'
            referencedColumns: ['id']
          },
        ]
      }
    }
    Views: {
      v_premios_pendentes: {
        Row: {
          clube_nome: string | null
          data_entrega: string | null
          data_geracao: string | null
          estoque: number | null
          id: string | null
          oansista_nome: string | null
          premio_nome: string | null
          premio_tipo: Database['public']['Enums']['premio_tipo'] | null
          status: Database['public']['Enums']['pendencia_status'] | null
        }
        Relationships: []
      }
      v_ranking_semanal: {
        Row: {
          clube_id: string | null
          clube_nome: string | null
          encontro_data: string | null
          encontro_id: string | null
          oansista_id: string | null
          oansista_nome: string | null
          posicao: number | null
          total: number | null
        }
        Relationships: [
          {
            foreignKeyName: 'folhas_semanais_oansista_id_fkey'
            columns: ['oansista_id']
            isOneToOne: false
            referencedRelation: 'oansistas'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'oansistas_clube_id_fkey'
            columns: ['clube_id']
            isOneToOne: false
            referencedRelation: 'clubes'
            referencedColumns: ['id']
          },
        ]
      }
    }
    Functions: {
      fn_clube_da_categoria: {
        Args: { p_cat: Database['public']['Enums']['jogo_categoria'] }
        Returns: string[]
      }
      fn_clube_id: { Args: never, Returns: string }
      fn_diretor_do_clube: { Args: { p_clube_id: string }, Returns: boolean }
      fn_lider_da_turma: { Args: { p_turma_id: string }, Returns: boolean }
      fn_perfil: {
        Args: never
        Returns: {
          ativo: boolean
          clube_id: string | null
          created_at: string
          id: string
          nome: string
          role: Database['public']['Enums']['user_role']
          telefone: string | null
          updated_at: string
        }
        SetofOptions: {
          from: '*'
          to: 'profiles'
          isOneToOne: true
          isSetofReturn: false
        }
      }
      fn_ranking_do_encontro: {
        Args: { p_encontro_id: string }
        Returns: {
          clube_nome: string
          oansista_id: string
          oansista_nome: string
          posicao: number
          total: number
        }[]
      }
      fn_responsavel_pela_turma: {
        Args: { p_encontro_id: string, p_turma_id: string }
        Returns: boolean
      }
      fn_responsavel_pelo_oansista: {
        Args: { p_encontro_id: string, p_oansista_id: string }
        Returns: boolean
      }
      fn_role: {
        Args: never
        Returns: Database['public']['Enums']['user_role']
      }
    }
    Enums: {
      jogo_categoria: 'faiscas' | 'flamas_tochas'
      pendencia_status: 'pendente' | 'entregue' | 'cancelada'
      premio_tipo: 'manual' | 'botom' | 'premio'
      status_oansista: 'ativo' | 'inativo' | 'transferido'
      status_visitante:
        | 'em_visitas'
        | 'prova_ingresso'
        | 'matriculado'
        | 'desistente'
      transferencia_tipo: 'temporaria' | 'permanente'
      user_role: 'diretor_geral' | 'secretaria' | 'diretor_clube' | 'lider'
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, '__InternalSupabase'>

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, 'public'>]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
  | keyof (DefaultSchema['Tables'] & DefaultSchema['Views'])
  | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions['schema']]['Tables']
      & DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions['schema']]['Views'])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions['schema']]['Tables']
    & DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions['schema']]['Views'])[TableName] extends {
      Row: infer R
    }
      ? R
      : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema['Tables']
    & DefaultSchema['Views'])
    ? (DefaultSchema['Tables']
      & DefaultSchema['Views'])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
        ? R
        : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
  | keyof DefaultSchema['Tables']
  | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions['schema']]['Tables']
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions['schema']]['Tables'][TableName] extends {
    Insert: infer I
  }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema['Tables']
    ? DefaultSchema['Tables'][DefaultSchemaTableNameOrOptions] extends {
      Insert: infer I
    }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
  | keyof DefaultSchema['Tables']
  | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions['schema']]['Tables']
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions['schema']]['Tables'][TableName] extends {
    Update: infer U
  }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema['Tables']
    ? DefaultSchema['Tables'][DefaultSchemaTableNameOrOptions] extends {
      Update: infer U
    }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
  | keyof DefaultSchema['Enums']
  | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions['schema']]['Enums']
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions['schema']]['Enums'][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema['Enums']
    ? DefaultSchema['Enums'][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
  | keyof DefaultSchema['CompositeTypes']
  | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions['schema']]['CompositeTypes']
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions['schema']]['CompositeTypes'][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema['CompositeTypes']
    ? DefaultSchema['CompositeTypes'][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  graphql_public: {
    Enums: {},
  },
  public: {
    Enums: {
      jogo_categoria: ['faiscas', 'flamas_tochas'],
      pendencia_status: ['pendente', 'entregue', 'cancelada'],
      premio_tipo: ['manual', 'botom', 'premio'],
      status_oansista: ['ativo', 'inativo', 'transferido'],
      status_visitante: [
        'em_visitas',
        'prova_ingresso',
        'matriculado',
        'desistente',
      ],
      transferencia_tipo: ['temporaria', 'permanente'],
      user_role: ['diretor_geral', 'secretaria', 'diretor_clube', 'lider'],
    },
  },
} as const
