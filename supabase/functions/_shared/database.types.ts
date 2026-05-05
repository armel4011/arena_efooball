export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.5"
  }
  public: {
    Tables: {
      admin_audit_log: {
        Row: {
          action: string
          admin_id: string
          after_state: Json | null
          before_state: Json | null
          created_at: string
          id: string
          ip_address: string | null
          target_id: string | null
          target_type: string | null
          user_agent: string | null
        }
        Insert: {
          action: string
          admin_id: string
          after_state?: Json | null
          before_state?: Json | null
          created_at?: string
          id?: string
          ip_address?: string | null
          target_id?: string | null
          target_type?: string | null
          user_agent?: string | null
        }
        Update: {
          action?: string
          admin_id?: string
          after_state?: Json | null
          before_state?: Json | null
          created_at?: string
          id?: string
          ip_address?: string | null
          target_id?: string | null
          target_type?: string | null
          user_agent?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "admin_audit_log_admin_id_fkey"
            columns: ["admin_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      anti_cheat_events: {
        Row: {
          created_at: string
          data: Json
          id: string
          match_id: string | null
          profile_id: string
          recording_url: string | null
          severity: number
          type: string
        }
        Insert: {
          created_at?: string
          data?: Json
          id?: string
          match_id?: string | null
          profile_id: string
          recording_url?: string | null
          severity?: number
          type: string
        }
        Update: {
          created_at?: string
          data?: Json
          id?: string
          match_id?: string | null
          profile_id?: string
          recording_url?: string | null
          severity?: number
          type?: string
        }
        Relationships: [
          {
            foreignKeyName: "anti_cheat_events_match_id_fkey"
            columns: ["match_id"]
            isOneToOne: false
            referencedRelation: "matches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "anti_cheat_events_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      app_config: {
        Row: {
          description: string | null
          id: string
          key: string
          updated_at: string
          value: Json
        }
        Insert: {
          description?: string | null
          id?: string
          key: string
          updated_at?: string
          value: Json
        }
        Update: {
          description?: string | null
          id?: string
          key?: string
          updated_at?: string
          value?: Json
        }
        Relationships: []
      }
      auto_actions_log: {
        Row: {
          action: string
          edge_function: string
          error: string | null
          executed_at: string
          id: string
          payload: Json
          status: string
          target_id: string | null
          target_type: string | null
        }
        Insert: {
          action: string
          edge_function: string
          error?: string | null
          executed_at?: string
          id?: string
          payload?: Json
          status: string
          target_id?: string | null
          target_type?: string | null
        }
        Update: {
          action?: string
          edge_function?: string
          error?: string | null
          executed_at?: string
          id?: string
          payload?: Json
          status?: string
          target_id?: string | null
          target_type?: string | null
        }
        Relationships: []
      }
      banned_words: {
        Row: {
          category: string | null
          created_at: string
          id: string
          language: string
          severity: number
          word: string
        }
        Insert: {
          category?: string | null
          created_at?: string
          id?: string
          language?: string
          severity?: number
          word: string
        }
        Update: {
          category?: string | null
          created_at?: string
          id?: string
          language?: string
          severity?: number
          word?: string
        }
        Relationships: []
      }
      bracket_nodes: {
        Row: {
          bye_player_id: string | null
          competition_id: string
          created_at: string
          id: string
          is_bye: boolean
          is_grand_final: boolean
          is_third_place_match: boolean
          match_id: string | null
          next_node_id: string | null
          next_position: string | null
          parent_node_id: string | null
          phase_id: string
          position_in_round: number
          round_number: number
          total_rounds: number
        }
        Insert: {
          bye_player_id?: string | null
          competition_id: string
          created_at?: string
          id?: string
          is_bye?: boolean
          is_grand_final?: boolean
          is_third_place_match?: boolean
          match_id?: string | null
          next_node_id?: string | null
          next_position?: string | null
          parent_node_id?: string | null
          phase_id: string
          position_in_round: number
          round_number: number
          total_rounds: number
        }
        Update: {
          bye_player_id?: string | null
          competition_id?: string
          created_at?: string
          id?: string
          is_bye?: boolean
          is_grand_final?: boolean
          is_third_place_match?: boolean
          match_id?: string | null
          next_node_id?: string | null
          next_position?: string | null
          parent_node_id?: string | null
          phase_id?: string
          position_in_round?: number
          round_number?: number
          total_rounds?: number
        }
        Relationships: [
          {
            foreignKeyName: "bracket_nodes_bye_player_id_fkey"
            columns: ["bye_player_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "bracket_nodes_competition_id_fkey"
            columns: ["competition_id"]
            isOneToOne: false
            referencedRelation: "competitions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "bracket_nodes_match_id_fkey"
            columns: ["match_id"]
            isOneToOne: false
            referencedRelation: "matches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "bracket_nodes_next_node_id_fkey"
            columns: ["next_node_id"]
            isOneToOne: false
            referencedRelation: "bracket_nodes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "bracket_nodes_parent_node_id_fkey"
            columns: ["parent_node_id"]
            isOneToOne: false
            referencedRelation: "bracket_nodes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "bracket_nodes_phase_id_fkey"
            columns: ["phase_id"]
            isOneToOne: false
            referencedRelation: "phases"
            referencedColumns: ["id"]
          },
        ]
      }
      chat_channels: {
        Row: {
          competition_id: string | null
          created_at: string
          id: string
          is_archived: boolean
          match_id: string | null
          name: string | null
          type: string
        }
        Insert: {
          competition_id?: string | null
          created_at?: string
          id?: string
          is_archived?: boolean
          match_id?: string | null
          name?: string | null
          type: string
        }
        Update: {
          competition_id?: string | null
          created_at?: string
          id?: string
          is_archived?: boolean
          match_id?: string | null
          name?: string | null
          type?: string
        }
        Relationships: [
          {
            foreignKeyName: "chat_channels_competition_id_fkey"
            columns: ["competition_id"]
            isOneToOne: false
            referencedRelation: "competitions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "chat_channels_match_id_fkey"
            columns: ["match_id"]
            isOneToOne: false
            referencedRelation: "matches"
            referencedColumns: ["id"]
          },
        ]
      }
      chat_messages: {
        Row: {
          channel_id: string
          content: string
          created_at: string
          id: string
          is_moderated: boolean
          moderated_at: string | null
          moderated_reason: string | null
          sender_id: string | null
          type: string
        }
        Insert: {
          channel_id: string
          content: string
          created_at?: string
          id?: string
          is_moderated?: boolean
          moderated_at?: string | null
          moderated_reason?: string | null
          sender_id?: string | null
          type?: string
        }
        Update: {
          channel_id?: string
          content?: string
          created_at?: string
          id?: string
          is_moderated?: boolean
          moderated_at?: string | null
          moderated_reason?: string | null
          sender_id?: string | null
          type?: string
        }
        Relationships: [
          {
            foreignKeyName: "chat_messages_channel_id_fkey"
            columns: ["channel_id"]
            isOneToOne: false
            referencedRelation: "chat_channels"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "chat_messages_sender_id_fkey"
            columns: ["sender_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      competition_registrations: {
        Row: {
          competition_id: string
          payment_id: string | null
          player_id: string
          registered_at: string
          status: string
        }
        Insert: {
          competition_id: string
          payment_id?: string | null
          player_id: string
          registered_at?: string
          status?: string
        }
        Update: {
          competition_id?: string
          payment_id?: string | null
          player_id?: string
          registered_at?: string
          status?: string
        }
        Relationships: [
          {
            foreignKeyName: "competition_registrations_competition_id_fkey"
            columns: ["competition_id"]
            isOneToOne: false
            referencedRelation: "competitions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "competition_registrations_payment_id_fkey"
            columns: ["payment_id"]
            isOneToOne: false
            referencedRelation: "payments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "competition_registrations_player_id_fkey"
            columns: ["player_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      competitions: {
        Row: {
          banner_url: string | null
          commission_pct: number
          created_at: string
          created_by: string | null
          current_players: number
          description: string | null
          end_date: string | null
          format: Database["public"]["Enums"]["tournament_format"]
          game: string
          id: string
          max_players: number
          name: string
          prize_pool_currency: string | null
          prize_pool_local: number
          registration_closes_at: string | null
          registration_currency: string
          registration_fee: number
          registration_opens_at: string | null
          sponsor_bonus_local: number
          start_date: string
          status: Database["public"]["Enums"]["competition_status"]
          updated_at: string
        }
        Insert: {
          banner_url?: string | null
          commission_pct?: number
          created_at?: string
          created_by?: string | null
          current_players?: number
          description?: string | null
          end_date?: string | null
          format: Database["public"]["Enums"]["tournament_format"]
          game: string
          id?: string
          max_players: number
          name: string
          prize_pool_currency?: string | null
          prize_pool_local?: number
          registration_closes_at?: string | null
          registration_currency: string
          registration_fee?: number
          registration_opens_at?: string | null
          sponsor_bonus_local?: number
          start_date: string
          status?: Database["public"]["Enums"]["competition_status"]
          updated_at?: string
        }
        Update: {
          banner_url?: string | null
          commission_pct?: number
          created_at?: string
          created_by?: string | null
          current_players?: number
          description?: string | null
          end_date?: string | null
          format?: Database["public"]["Enums"]["tournament_format"]
          game?: string
          id?: string
          max_players?: number
          name?: string
          prize_pool_currency?: string | null
          prize_pool_local?: number
          registration_closes_at?: string | null
          registration_currency?: string
          registration_fee?: number
          registration_opens_at?: string | null
          sponsor_bonus_local?: number
          start_date?: string
          status?: Database["public"]["Enums"]["competition_status"]
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "competitions_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      disputes: {
        Row: {
          bot_attempted_at: string | null
          created_at: string
          escalated_at: string | null
          escalation_level: number
          evidence: Json
          id: string
          match_id: string
          opened_by: string
          reason: string | null
          resolution: string | null
          resolved_at: string | null
          resolved_by: string | null
          status: string
          updated_at: string
        }
        Insert: {
          bot_attempted_at?: string | null
          created_at?: string
          escalated_at?: string | null
          escalation_level?: number
          evidence?: Json
          id?: string
          match_id: string
          opened_by: string
          reason?: string | null
          resolution?: string | null
          resolved_at?: string | null
          resolved_by?: string | null
          status?: string
          updated_at?: string
        }
        Update: {
          bot_attempted_at?: string | null
          created_at?: string
          escalated_at?: string | null
          escalation_level?: number
          evidence?: Json
          id?: string
          match_id?: string
          opened_by?: string
          reason?: string | null
          resolution?: string | null
          resolved_at?: string | null
          resolved_by?: string | null
          status?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "disputes_match_id_fkey"
            columns: ["match_id"]
            isOneToOne: false
            referencedRelation: "matches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "disputes_opened_by_fkey"
            columns: ["opened_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "disputes_resolved_by_fkey"
            columns: ["resolved_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      exchange_rates: {
        Row: {
          base_currency: string
          fetched_at: string
          id: string
          quote_currency: string
          rate: number
          source: string | null
        }
        Insert: {
          base_currency: string
          fetched_at?: string
          id?: string
          quote_currency: string
          rate: number
          source?: string | null
        }
        Update: {
          base_currency?: string
          fetched_at?: string
          id?: string
          quote_currency?: string
          rate?: number
          source?: string | null
        }
        Relationships: []
      }
      group_memberships: {
        Row: {
          created_at: string
          draws: number
          goal_diff: number | null
          goals_against: number
          goals_for: number
          group_id: string
          id: string
          losses: number
          played: number
          points: number
          position: number | null
          profile_id: string
          wins: number
        }
        Insert: {
          created_at?: string
          draws?: number
          goal_diff?: number | null
          goals_against?: number
          goals_for?: number
          group_id: string
          id?: string
          losses?: number
          played?: number
          points?: number
          position?: number | null
          profile_id: string
          wins?: number
        }
        Update: {
          created_at?: string
          draws?: number
          goal_diff?: number | null
          goals_against?: number
          goals_for?: number
          group_id?: string
          id?: string
          losses?: number
          played?: number
          points?: number
          position?: number | null
          profile_id?: string
          wins?: number
        }
        Relationships: [
          {
            foreignKeyName: "group_memberships_group_id_fkey"
            columns: ["group_id"]
            isOneToOne: false
            referencedRelation: "groups"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "group_memberships_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      groups: {
        Row: {
          competition_id: string
          created_at: string
          group_number: number
          id: string
          name: string
          phase_id: string
        }
        Insert: {
          competition_id: string
          created_at?: string
          group_number: number
          id?: string
          name: string
          phase_id: string
        }
        Update: {
          competition_id?: string
          created_at?: string
          group_number?: number
          id?: string
          name?: string
          phase_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "groups_competition_id_fkey"
            columns: ["competition_id"]
            isOneToOne: false
            referencedRelation: "competitions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "groups_phase_id_fkey"
            columns: ["phase_id"]
            isOneToOne: false
            referencedRelation: "phases"
            referencedColumns: ["id"]
          },
        ]
      }
      invitation_codes: {
        Row: {
          code: string
          created_at: string
          expires_at: string
          generated_by: string | null
          id: string
          role: Database["public"]["Enums"]["user_role"]
          used_at: string | null
          used_by: string | null
        }
        Insert: {
          code: string
          created_at?: string
          expires_at: string
          generated_by?: string | null
          id?: string
          role?: Database["public"]["Enums"]["user_role"]
          used_at?: string | null
          used_by?: string | null
        }
        Update: {
          code?: string
          created_at?: string
          expires_at?: string
          generated_by?: string | null
          id?: string
          role?: Database["public"]["Enums"]["user_role"]
          used_at?: string | null
          used_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "invitation_codes_generated_by_fkey"
            columns: ["generated_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "invitation_codes_used_by_fkey"
            columns: ["used_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      match_events: {
        Row: {
          created_at: string
          created_by: string | null
          id: string
          match_id: string
          payload: Json
          type: string
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          id?: string
          match_id: string
          payload?: Json
          type: string
        }
        Update: {
          created_at?: string
          created_by?: string | null
          id?: string
          match_id?: string
          payload?: Json
          type?: string
        }
        Relationships: [
          {
            foreignKeyName: "match_events_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "match_events_match_id_fkey"
            columns: ["match_id"]
            isOneToOne: false
            referencedRelation: "matches"
            referencedColumns: ["id"]
          },
        ]
      }
      matches: {
        Row: {
          agora_stream_channel: string | null
          competition_id: string
          created_at: string
          current_viewers_count: number
          finished_at: string | null
          group_id: string | null
          home_player_id: string | null
          id: string
          is_streamed: boolean
          match_config: Json
          match_number: number | null
          next_match_id: string | null
          peak_viewers_count: number
          phase_id: string | null
          player1_id: string | null
          player2_id: string | null
          room_code: string | null
          round: number | null
          scheduled_at: string | null
          score1: number | null
          score2: number | null
          started_at: string | null
          status: Database["public"]["Enums"]["match_status"]
          stream_ended_at: string | null
          stream_started_at: string | null
          stream_status: string
          streaming_activated_at: string | null
          streaming_activated_by_admin_id: string | null
          streaming_activation_type: string | null
          updated_at: string
          winner_id: string | null
        }
        Insert: {
          agora_stream_channel?: string | null
          competition_id: string
          created_at?: string
          current_viewers_count?: number
          finished_at?: string | null
          group_id?: string | null
          home_player_id?: string | null
          id?: string
          is_streamed?: boolean
          match_config?: Json
          match_number?: number | null
          next_match_id?: string | null
          peak_viewers_count?: number
          phase_id?: string | null
          player1_id?: string | null
          player2_id?: string | null
          room_code?: string | null
          round?: number | null
          scheduled_at?: string | null
          score1?: number | null
          score2?: number | null
          started_at?: string | null
          status?: Database["public"]["Enums"]["match_status"]
          stream_ended_at?: string | null
          stream_started_at?: string | null
          stream_status?: string
          streaming_activated_at?: string | null
          streaming_activated_by_admin_id?: string | null
          streaming_activation_type?: string | null
          updated_at?: string
          winner_id?: string | null
        }
        Update: {
          agora_stream_channel?: string | null
          competition_id?: string
          created_at?: string
          current_viewers_count?: number
          finished_at?: string | null
          group_id?: string | null
          home_player_id?: string | null
          id?: string
          is_streamed?: boolean
          match_config?: Json
          match_number?: number | null
          next_match_id?: string | null
          peak_viewers_count?: number
          phase_id?: string | null
          player1_id?: string | null
          player2_id?: string | null
          room_code?: string | null
          round?: number | null
          scheduled_at?: string | null
          score1?: number | null
          score2?: number | null
          started_at?: string | null
          status?: Database["public"]["Enums"]["match_status"]
          stream_ended_at?: string | null
          stream_started_at?: string | null
          stream_status?: string
          streaming_activated_at?: string | null
          streaming_activated_by_admin_id?: string | null
          streaming_activation_type?: string | null
          updated_at?: string
          winner_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "matches_competition_id_fkey"
            columns: ["competition_id"]
            isOneToOne: false
            referencedRelation: "competitions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "matches_group_id_fkey"
            columns: ["group_id"]
            isOneToOne: false
            referencedRelation: "groups"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "matches_home_player_id_fkey"
            columns: ["home_player_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "matches_next_match_id_fkey"
            columns: ["next_match_id"]
            isOneToOne: false
            referencedRelation: "matches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "matches_phase_id_fkey"
            columns: ["phase_id"]
            isOneToOne: false
            referencedRelation: "phases"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "matches_player1_id_fkey"
            columns: ["player1_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "matches_player2_id_fkey"
            columns: ["player2_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "matches_streaming_activated_by_admin_id_fkey"
            columns: ["streaming_activated_by_admin_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "matches_winner_id_fkey"
            columns: ["winner_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      notifications: {
        Row: {
          body: string | null
          created_at: string
          data: Json
          id: string
          read_at: string | null
          sent_at: string | null
          title: string
          type: string
          user_id: string
        }
        Insert: {
          body?: string | null
          created_at?: string
          data?: Json
          id?: string
          read_at?: string | null
          sent_at?: string | null
          title: string
          type: string
          user_id: string
        }
        Update: {
          body?: string | null
          created_at?: string
          data?: Json
          id?: string
          read_at?: string | null
          sent_at?: string | null
          title?: string
          type?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "notifications_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      payment_webhook_log: {
        Row: {
          created_at: string
          error: string | null
          event_type: string | null
          id: string
          payload: Json
          processed_at: string | null
          provider: string
          related_payment_id: string | null
          related_payout_id: string | null
          signature_valid: boolean | null
        }
        Insert: {
          created_at?: string
          error?: string | null
          event_type?: string | null
          id?: string
          payload: Json
          processed_at?: string | null
          provider: string
          related_payment_id?: string | null
          related_payout_id?: string | null
          signature_valid?: boolean | null
        }
        Update: {
          created_at?: string
          error?: string | null
          event_type?: string | null
          id?: string
          payload?: Json
          processed_at?: string | null
          provider?: string
          related_payment_id?: string | null
          related_payout_id?: string | null
          signature_valid?: boolean | null
        }
        Relationships: [
          {
            foreignKeyName: "payment_webhook_log_related_payment_id_fkey"
            columns: ["related_payment_id"]
            isOneToOne: false
            referencedRelation: "payments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "payment_webhook_log_related_payout_id_fkey"
            columns: ["related_payout_id"]
            isOneToOne: false
            referencedRelation: "payouts"
            referencedColumns: ["id"]
          },
        ]
      }
      payments: {
        Row: {
          amount_local: number
          amount_usd: number | null
          competition_id: string
          created_at: string
          currency: string
          exchange_rate: number | null
          id: string
          idempotency_key: string | null
          provider: string
          provider_method: string | null
          provider_response: Json
          provider_transaction_id: string | null
          status: string
          updated_at: string
          user_id: string
        }
        Insert: {
          amount_local: number
          amount_usd?: number | null
          competition_id: string
          created_at?: string
          currency: string
          exchange_rate?: number | null
          id?: string
          idempotency_key?: string | null
          provider: string
          provider_method?: string | null
          provider_response?: Json
          provider_transaction_id?: string | null
          status?: string
          updated_at?: string
          user_id: string
        }
        Update: {
          amount_local?: number
          amount_usd?: number | null
          competition_id?: string
          created_at?: string
          currency?: string
          exchange_rate?: number | null
          id?: string
          idempotency_key?: string | null
          provider?: string
          provider_method?: string | null
          provider_response?: Json
          provider_transaction_id?: string | null
          status?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "payments_competition_id_fkey"
            columns: ["competition_id"]
            isOneToOne: false
            referencedRelation: "competitions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "payments_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      payouts: {
        Row: {
          amount_local: number
          amount_usd: number
          auto_checks: Json
          competition_id: string
          completed_at: string | null
          created_at: string
          currency: string
          exchange_rate: number | null
          id: string
          payout_destination: Json | null
          payout_method: string | null
          payout_provider: string | null
          prize_id: string
          provider_response: Json
          provider_transaction_id: string | null
          scheduled_for: string | null
          status: string
          updated_at: string
          user_id: string
          validated_at: string | null
          validated_by_admin_id: string | null
          validation_justification: string | null
        }
        Insert: {
          amount_local: number
          amount_usd: number
          auto_checks?: Json
          competition_id: string
          completed_at?: string | null
          created_at?: string
          currency: string
          exchange_rate?: number | null
          id?: string
          payout_destination?: Json | null
          payout_method?: string | null
          payout_provider?: string | null
          prize_id: string
          provider_response?: Json
          provider_transaction_id?: string | null
          scheduled_for?: string | null
          status?: string
          updated_at?: string
          user_id: string
          validated_at?: string | null
          validated_by_admin_id?: string | null
          validation_justification?: string | null
        }
        Update: {
          amount_local?: number
          amount_usd?: number
          auto_checks?: Json
          competition_id?: string
          completed_at?: string | null
          created_at?: string
          currency?: string
          exchange_rate?: number | null
          id?: string
          payout_destination?: Json | null
          payout_method?: string | null
          payout_provider?: string | null
          prize_id?: string
          provider_response?: Json
          provider_transaction_id?: string | null
          scheduled_for?: string | null
          status?: string
          updated_at?: string
          user_id?: string
          validated_at?: string | null
          validated_by_admin_id?: string | null
          validation_justification?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "payouts_competition_id_fkey"
            columns: ["competition_id"]
            isOneToOne: false
            referencedRelation: "competitions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "payouts_prize_id_fkey"
            columns: ["prize_id"]
            isOneToOne: false
            referencedRelation: "prizes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "payouts_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "payouts_validated_by_admin_id_fkey"
            columns: ["validated_by_admin_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      phases: {
        Row: {
          competition_id: string
          config: Json
          created_at: string
          finished_at: string | null
          id: string
          phase_order: number
          started_at: string | null
          status: string
          type: Database["public"]["Enums"]["phase_type"]
        }
        Insert: {
          competition_id: string
          config?: Json
          created_at?: string
          finished_at?: string | null
          id?: string
          phase_order: number
          started_at?: string | null
          status?: string
          type: Database["public"]["Enums"]["phase_type"]
        }
        Update: {
          competition_id?: string
          config?: Json
          created_at?: string
          finished_at?: string | null
          id?: string
          phase_order?: number
          started_at?: string | null
          status?: string
          type?: Database["public"]["Enums"]["phase_type"]
        }
        Relationships: [
          {
            foreignKeyName: "phases_competition_id_fkey"
            columns: ["competition_id"]
            isOneToOne: false
            referencedRelation: "competitions"
            referencedColumns: ["id"]
          },
        ]
      }
      platform_revenue: {
        Row: {
          amount_local: number
          amount_usd: number | null
          competition_id: string | null
          currency: string
          id: string
          kind: string
          payment_id: string | null
          recorded_at: string
        }
        Insert: {
          amount_local: number
          amount_usd?: number | null
          competition_id?: string | null
          currency: string
          id?: string
          kind: string
          payment_id?: string | null
          recorded_at?: string
        }
        Update: {
          amount_local?: number
          amount_usd?: number | null
          competition_id?: string | null
          currency?: string
          id?: string
          kind?: string
          payment_id?: string | null
          recorded_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "platform_revenue_competition_id_fkey"
            columns: ["competition_id"]
            isOneToOne: false
            referencedRelation: "competitions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "platform_revenue_payment_id_fkey"
            columns: ["payment_id"]
            isOneToOne: false
            referencedRelation: "payments"
            referencedColumns: ["id"]
          },
        ]
      }
      prizes: {
        Row: {
          competition_id: string
          display_name: string | null
          final_amount_local: number | null
          final_amount_usd: number | null
          final_currency: string | null
          fixed_amount: number | null
          fixed_currency: string | null
          id: string
          percentage_value: number | null
          position: number
          prize_mode: string
        }
        Insert: {
          competition_id: string
          display_name?: string | null
          final_amount_local?: number | null
          final_amount_usd?: number | null
          final_currency?: string | null
          fixed_amount?: number | null
          fixed_currency?: string | null
          id?: string
          percentage_value?: number | null
          position: number
          prize_mode: string
        }
        Update: {
          competition_id?: string
          display_name?: string | null
          final_amount_local?: number | null
          final_amount_usd?: number | null
          final_currency?: string | null
          fixed_amount?: number | null
          fixed_currency?: string | null
          id?: string
          percentage_value?: number | null
          position?: number
          prize_mode?: string
        }
        Relationships: [
          {
            foreignKeyName: "prizes_competition_id_fkey"
            columns: ["competition_id"]
            isOneToOne: false
            referencedRelation: "competitions"
            referencedColumns: ["id"]
          },
        ]
      }
      profiles: {
        Row: {
          account_deletion_reason: string | null
          account_deletion_requested_at: string | null
          auth_provider: string
          auth_provider_id: string | null
          avatar_color: string
          backup_codes: Json
          cgu_accepted_at: string | null
          cgu_version_accepted: string | null
          country_code: string
          created_at: string
          deleted_at: string | null
          email: string
          fcm_token: string | null
          id: string
          is_active: boolean
          kyc_status: string
          kyc_verified_at: string | null
          marketing_consent: boolean
          onboarding_completed: boolean
          onboarding_completed_at: string | null
          preferred_currency: string
          preferred_language: string
          privacy_policy_accepted_at: string | null
          role: Database["public"]["Enums"]["user_role"]
          stats: Json
          timezone: string
          totp_enabled: boolean
          totp_secret: string | null
          updated_at: string
          username: string
        }
        Insert: {
          account_deletion_reason?: string | null
          account_deletion_requested_at?: string | null
          auth_provider?: string
          auth_provider_id?: string | null
          avatar_color?: string
          backup_codes?: Json
          cgu_accepted_at?: string | null
          cgu_version_accepted?: string | null
          country_code: string
          created_at?: string
          deleted_at?: string | null
          email: string
          fcm_token?: string | null
          id: string
          is_active?: boolean
          kyc_status?: string
          kyc_verified_at?: string | null
          marketing_consent?: boolean
          onboarding_completed?: boolean
          onboarding_completed_at?: string | null
          preferred_currency?: string
          preferred_language?: string
          privacy_policy_accepted_at?: string | null
          role?: Database["public"]["Enums"]["user_role"]
          stats?: Json
          timezone?: string
          totp_enabled?: boolean
          totp_secret?: string | null
          updated_at?: string
          username: string
        }
        Update: {
          account_deletion_reason?: string | null
          account_deletion_requested_at?: string | null
          auth_provider?: string
          auth_provider_id?: string | null
          avatar_color?: string
          backup_codes?: Json
          cgu_accepted_at?: string | null
          cgu_version_accepted?: string | null
          country_code?: string
          created_at?: string
          deleted_at?: string | null
          email?: string
          fcm_token?: string | null
          id?: string
          is_active?: boolean
          kyc_status?: string
          kyc_verified_at?: string | null
          marketing_consent?: boolean
          onboarding_completed?: boolean
          onboarding_completed_at?: string | null
          preferred_currency?: string
          preferred_language?: string
          privacy_policy_accepted_at?: string | null
          role?: Database["public"]["Enums"]["user_role"]
          stats?: Json
          timezone?: string
          totp_enabled?: boolean
          totp_secret?: string | null
          updated_at?: string
          username?: string
        }
        Relationships: []
      }
      streams: {
        Row: {
          ended_at: string | null
          id: string
          is_active: boolean
          is_public: boolean
          match_id: string
          player_id: string
          started_at: string
          url: string | null
        }
        Insert: {
          ended_at?: string | null
          id?: string
          is_active?: boolean
          is_public?: boolean
          match_id: string
          player_id: string
          started_at?: string
          url?: string | null
        }
        Update: {
          ended_at?: string | null
          id?: string
          is_active?: boolean
          is_public?: boolean
          match_id?: string
          player_id?: string
          started_at?: string
          url?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "streams_match_id_fkey"
            columns: ["match_id"]
            isOneToOne: false
            referencedRelation: "matches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "streams_player_id_fkey"
            columns: ["player_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      is_admin: { Args: never; Returns: boolean }
      is_super_admin: { Args: never; Returns: boolean }
    }
    Enums: {
      competition_status:
        | "draft"
        | "registration_open"
        | "registration_closed"
        | "ongoing"
        | "completed"
        | "cancelled"
      match_status:
        | "pending"
        | "scheduled"
        | "ready"
        | "in_progress"
        | "score_pending"
        | "awaiting_validation"
        | "disputed"
        | "completed"
        | "cancelled"
        | "forfeited"
      phase_type: "groups" | "knockout" | "round_robin"
      tournament_format:
        | "single_elimination"
        | "groups_then_knockout"
        | "round_robin"
      user_role: "player" | "admin" | "super_admin"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {
      competition_status: [
        "draft",
        "registration_open",
        "registration_closed",
        "ongoing",
        "completed",
        "cancelled",
      ],
      match_status: [
        "pending",
        "scheduled",
        "ready",
        "in_progress",
        "score_pending",
        "awaiting_validation",
        "disputed",
        "completed",
        "cancelled",
        "forfeited",
      ],
      phase_type: ["groups", "knockout", "round_robin"],
      tournament_format: [
        "single_elimination",
        "groups_then_knockout",
        "round_robin",
      ],
      user_role: ["player", "admin", "super_admin"],
    },
  },
} as const
