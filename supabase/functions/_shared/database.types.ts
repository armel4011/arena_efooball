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
          {
            foreignKeyName: "admin_audit_log_admin_id_fkey"
            columns: ["admin_id"]
            isOneToOne: false
            referencedRelation: "public_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      admin_chat_messages: {
        Row: {
          admin_id: string
          caption: string | null
          id: string
          image_url: string | null
          read_at: string | null
          recipient_id: string
          sent_at: string
          text: string | null
        }
        Insert: {
          admin_id: string
          caption?: string | null
          id?: string
          image_url?: string | null
          read_at?: string | null
          recipient_id: string
          sent_at?: string
          text?: string | null
        }
        Update: {
          admin_id?: string
          caption?: string | null
          id?: string
          image_url?: string | null
          read_at?: string | null
          recipient_id?: string
          sent_at?: string
          text?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "admin_chat_messages_admin_id_fkey"
            columns: ["admin_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "admin_chat_messages_admin_id_fkey"
            columns: ["admin_id"]
            isOneToOne: false
            referencedRelation: "public_profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "admin_chat_messages_recipient_id_fkey"
            columns: ["recipient_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "admin_chat_messages_recipient_id_fkey"
            columns: ["recipient_id"]
            isOneToOne: false
            referencedRelation: "public_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      admin_register_attempts: {
        Row: {
          failed_count: number
          ip: string
          locked_until: string | null
          updated_at: string
          window_started_at: string
        }
        Insert: {
          failed_count?: number
          ip: string
          locked_until?: string | null
          updated_at?: string
          window_started_at?: string
        }
        Update: {
          failed_count?: number
          ip?: string
          locked_until?: string | null
          updated_at?: string
          window_started_at?: string
        }
        Relationships: []
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
          {
            foreignKeyName: "anti_cheat_events_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "public_profiles"
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
          loser_next_node_id: string | null
          loser_next_position: string | null
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
          loser_next_node_id?: string | null
          loser_next_position?: string | null
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
          loser_next_node_id?: string | null
          loser_next_position?: string | null
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
            foreignKeyName: "bracket_nodes_bye_player_id_fkey"
            columns: ["bye_player_id"]
            isOneToOne: false
            referencedRelation: "public_profiles"
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
            foreignKeyName: "bracket_nodes_loser_next_node_id_fkey"
            columns: ["loser_next_node_id"]
            isOneToOne: false
            referencedRelation: "bracket_nodes"
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
      calls: {
        Row: {
          agora_channel: string
          answered_at: string | null
          callee_id: string
          caller_id: string
          created_at: string
          ended_at: string | null
          id: string
          scope: string
          scope_id: string
          status: Database["public"]["Enums"]["call_status"]
        }
        Insert: {
          agora_channel: string
          answered_at?: string | null
          callee_id: string
          caller_id: string
          created_at?: string
          ended_at?: string | null
          id?: string
          scope: string
          scope_id: string
          status?: Database["public"]["Enums"]["call_status"]
        }
        Update: {
          agora_channel?: string
          answered_at?: string | null
          callee_id?: string
          caller_id?: string
          created_at?: string
          ended_at?: string | null
          id?: string
          scope?: string
          scope_id?: string
          status?: Database["public"]["Enums"]["call_status"]
        }
        Relationships: [
          {
            foreignKeyName: "calls_callee_id_fkey"
            columns: ["callee_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "calls_callee_id_fkey"
            columns: ["callee_id"]
            isOneToOne: false
            referencedRelation: "public_profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "calls_caller_id_fkey"
            columns: ["caller_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "calls_caller_id_fkey"
            columns: ["caller_id"]
            isOneToOne: false
            referencedRelation: "public_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      chat_channel_user_state: {
        Row: {
          channel_id: string
          cleared_at: string | null
          hidden: boolean
          last_read_at: string | null
          updated_at: string
          user_id: string
        }
        Insert: {
          channel_id: string
          cleared_at?: string | null
          hidden?: boolean
          last_read_at?: string | null
          updated_at?: string
          user_id: string
        }
        Update: {
          channel_id?: string
          cleared_at?: string | null
          hidden?: boolean
          last_read_at?: string | null
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "chat_channel_user_state_channel_id_fkey"
            columns: ["channel_id"]
            isOneToOne: false
            referencedRelation: "chat_channels"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "chat_channel_user_state_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "chat_channel_user_state_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "public_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      chat_channels: {
        Row: {
          competition_id: string | null
          created_at: string
          deleted_at: string | null
          friendship_id: string | null
          id: string
          is_archived: boolean
          match_id: string | null
          name: string | null
          type: string
        }
        Insert: {
          competition_id?: string | null
          created_at?: string
          deleted_at?: string | null
          friendship_id?: string | null
          id?: string
          is_archived?: boolean
          match_id?: string | null
          name?: string | null
          type: string
        }
        Update: {
          competition_id?: string | null
          created_at?: string
          deleted_at?: string | null
          friendship_id?: string | null
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
            foreignKeyName: "chat_channels_friendship_id_fkey"
            columns: ["friendship_id"]
            isOneToOne: false
            referencedRelation: "friendships"
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
          deleted_at: string | null
          id: string
          is_moderated: boolean
          media_type: string | null
          media_url: string | null
          moderated_at: string | null
          moderated_reason: string | null
          sender_id: string | null
          type: string
        }
        Insert: {
          channel_id: string
          content: string
          created_at?: string
          deleted_at?: string | null
          id?: string
          is_moderated?: boolean
          media_type?: string | null
          media_url?: string | null
          moderated_at?: string | null
          moderated_reason?: string | null
          sender_id?: string | null
          type?: string
        }
        Update: {
          channel_id?: string
          content?: string
          created_at?: string
          deleted_at?: string | null
          id?: string
          is_moderated?: boolean
          media_type?: string | null
          media_url?: string | null
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
          {
            foreignKeyName: "chat_messages_sender_id_fkey"
            columns: ["sender_id"]
            isOneToOne: false
            referencedRelation: "public_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      competition_registrations: {
        Row: {
          competition_id: string
          final_rank: number | null
          payment_id: string | null
          player_id: string
          registered_at: string
          status: string
        }
        Insert: {
          competition_id: string
          final_rank?: number | null
          payment_id?: string | null
          player_id: string
          registered_at?: string
          status?: string
        }
        Update: {
          competition_id?: string
          final_rank?: number | null
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
          {
            foreignKeyName: "competition_registrations_player_id_fkey"
            columns: ["player_id"]
            isOneToOne: false
            referencedRelation: "public_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      competitions: {
        Row: {
          android_store_url: string | null
          auto_generate_bracket: boolean
          banner_url: string | null
          commission_pct: number
          commission_xaf: number
          created_at: string
          created_by: string | null
          current_players: number
          description: string | null
          end_date: string | null
          format: Database["public"]["Enums"]["tournament_format"]
          format_config: Json
          game: string
          id: string
          ios_store_url: string | null
          is_pinned: boolean
          match_interval_minutes: number
          max_players: number
          mtn_momo_code: string | null
          name: string
          orange_money_code: string | null
          pinned_at: string | null
          prize_distribution: Json
          prize_pool_currency: string | null
          prize_pool_local: number
          referral_activity_mode: string
          referral_quota: number
          registration_closes_at: string | null
          registration_currency: string
          registration_fee: number
          registration_opens_at: string | null
          round_intervals: Json | null
          sponsor_bonus_local: number
          start_date: string
          status: Database["public"]["Enums"]["competition_status"]
          third_place_match: boolean
          updated_at: string
        }
        Insert: {
          android_store_url?: string | null
          auto_generate_bracket?: boolean
          banner_url?: string | null
          commission_pct?: number
          commission_xaf?: number
          created_at?: string
          created_by?: string | null
          current_players?: number
          description?: string | null
          end_date?: string | null
          format: Database["public"]["Enums"]["tournament_format"]
          format_config?: Json
          game: string
          id?: string
          ios_store_url?: string | null
          is_pinned?: boolean
          match_interval_minutes?: number
          max_players: number
          mtn_momo_code?: string | null
          name: string
          orange_money_code?: string | null
          pinned_at?: string | null
          prize_distribution?: Json
          prize_pool_currency?: string | null
          prize_pool_local?: number
          referral_activity_mode?: string
          referral_quota?: number
          registration_closes_at?: string | null
          registration_currency: string
          registration_fee?: number
          registration_opens_at?: string | null
          round_intervals?: Json | null
          sponsor_bonus_local?: number
          start_date: string
          status?: Database["public"]["Enums"]["competition_status"]
          third_place_match?: boolean
          updated_at?: string
        }
        Update: {
          android_store_url?: string | null
          auto_generate_bracket?: boolean
          banner_url?: string | null
          commission_pct?: number
          commission_xaf?: number
          created_at?: string
          created_by?: string | null
          current_players?: number
          description?: string | null
          end_date?: string | null
          format?: Database["public"]["Enums"]["tournament_format"]
          format_config?: Json
          game?: string
          id?: string
          ios_store_url?: string | null
          is_pinned?: boolean
          match_interval_minutes?: number
          max_players?: number
          mtn_momo_code?: string | null
          name?: string
          orange_money_code?: string | null
          pinned_at?: string | null
          prize_distribution?: Json
          prize_pool_currency?: string | null
          prize_pool_local?: number
          referral_activity_mode?: string
          referral_quota?: number
          registration_closes_at?: string | null
          registration_currency?: string
          registration_fee?: number
          registration_opens_at?: string | null
          round_intervals?: Json | null
          sponsor_bonus_local?: number
          start_date?: string
          status?: Database["public"]["Enums"]["competition_status"]
          third_place_match?: boolean
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
          {
            foreignKeyName: "competitions_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "public_profiles"
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
          guilty_party_id: string | null
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
          guilty_party_id?: string | null
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
          guilty_party_id?: string | null
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
            foreignKeyName: "disputes_guilty_party_id_fkey"
            columns: ["guilty_party_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "disputes_guilty_party_id_fkey"
            columns: ["guilty_party_id"]
            isOneToOne: false
            referencedRelation: "public_profiles"
            referencedColumns: ["id"]
          },
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
            foreignKeyName: "disputes_opened_by_fkey"
            columns: ["opened_by"]
            isOneToOne: false
            referencedRelation: "public_profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "disputes_resolved_by_fkey"
            columns: ["resolved_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "disputes_resolved_by_fkey"
            columns: ["resolved_by"]
            isOneToOne: false
            referencedRelation: "public_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      draughts_games: {
        Row: {
          black_clock_ms: number | null
          black_id: string
          board_fen: string
          created_at: string
          current_turn: string
          endgame_plies: number
          game_number: number
          id: string
          last_move_at: string
          match_id: string
          ply: number
          position_counts: Json
          status: string
          sterile_plies: number
          updated_at: string
          white_clock_ms: number | null
          white_id: string
        }
        Insert: {
          black_clock_ms?: number | null
          black_id: string
          board_fen: string
          created_at?: string
          current_turn?: string
          endgame_plies?: number
          game_number?: number
          id?: string
          last_move_at?: string
          match_id: string
          ply?: number
          position_counts?: Json
          status?: string
          sterile_plies?: number
          updated_at?: string
          white_clock_ms?: number | null
          white_id: string
        }
        Update: {
          black_clock_ms?: number | null
          black_id?: string
          board_fen?: string
          created_at?: string
          current_turn?: string
          endgame_plies?: number
          game_number?: number
          id?: string
          last_move_at?: string
          match_id?: string
          ply?: number
          position_counts?: Json
          status?: string
          sterile_plies?: number
          updated_at?: string
          white_clock_ms?: number | null
          white_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "draughts_games_black_id_fkey"
            columns: ["black_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "draughts_games_black_id_fkey"
            columns: ["black_id"]
            isOneToOne: false
            referencedRelation: "public_profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "draughts_games_match_id_fkey"
            columns: ["match_id"]
            isOneToOne: false
            referencedRelation: "matches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "draughts_games_white_id_fkey"
            columns: ["white_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "draughts_games_white_id_fkey"
            columns: ["white_id"]
            isOneToOne: false
            referencedRelation: "public_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      draughts_moves: {
        Row: {
          board_after_fen: string
          created_at: string
          game_id: string
          id: string
          move_json: Json
          parent_fen_hash: string
          player_id: string
          ply: number
        }
        Insert: {
          board_after_fen: string
          created_at?: string
          game_id: string
          id?: string
          move_json: Json
          parent_fen_hash: string
          player_id: string
          ply: number
        }
        Update: {
          board_after_fen?: string
          created_at?: string
          game_id?: string
          id?: string
          move_json?: Json
          parent_fen_hash?: string
          player_id?: string
          ply?: number
        }
        Relationships: [
          {
            foreignKeyName: "draughts_moves_game_id_fkey"
            columns: ["game_id"]
            isOneToOne: false
            referencedRelation: "draughts_games"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "draughts_moves_player_id_fkey"
            columns: ["player_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "draughts_moves_player_id_fkey"
            columns: ["player_id"]
            isOneToOne: false
            referencedRelation: "public_profiles"
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
      friendships: {
        Row: {
          addressee_id: string
          blocked_by: string | null
          created_at: string
          id: string
          requester_id: string
          status: Database["public"]["Enums"]["friendship_status"]
          updated_at: string
        }
        Insert: {
          addressee_id: string
          blocked_by?: string | null
          created_at?: string
          id?: string
          requester_id: string
          status?: Database["public"]["Enums"]["friendship_status"]
          updated_at?: string
        }
        Update: {
          addressee_id?: string
          blocked_by?: string | null
          created_at?: string
          id?: string
          requester_id?: string
          status?: Database["public"]["Enums"]["friendship_status"]
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "friendships_addressee_id_fkey"
            columns: ["addressee_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "friendships_addressee_id_fkey"
            columns: ["addressee_id"]
            isOneToOne: false
            referencedRelation: "public_profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "friendships_blocked_by_fkey"
            columns: ["blocked_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "friendships_blocked_by_fkey"
            columns: ["blocked_by"]
            isOneToOne: false
            referencedRelation: "public_profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "friendships_requester_id_fkey"
            columns: ["requester_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "friendships_requester_id_fkey"
            columns: ["requester_id"]
            isOneToOne: false
            referencedRelation: "public_profiles"
            referencedColumns: ["id"]
          },
        ]
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
          {
            foreignKeyName: "group_memberships_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: false
            referencedRelation: "public_profiles"
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
          expires_at: string | null
          generated_by: string | null
          id: string
          max_uses: number
          role: Database["public"]["Enums"]["user_role"]
          target_email: string | null
          used_at: string | null
          used_by: string | null
          uses_count: number
        }
        Insert: {
          code: string
          created_at?: string
          expires_at?: string | null
          generated_by?: string | null
          id?: string
          max_uses?: number
          role?: Database["public"]["Enums"]["user_role"]
          target_email?: string | null
          used_at?: string | null
          used_by?: string | null
          uses_count?: number
        }
        Update: {
          code?: string
          created_at?: string
          expires_at?: string | null
          generated_by?: string | null
          id?: string
          max_uses?: number
          role?: Database["public"]["Enums"]["user_role"]
          target_email?: string | null
          used_at?: string | null
          used_by?: string | null
          uses_count?: number
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
            foreignKeyName: "invitation_codes_generated_by_fkey"
            columns: ["generated_by"]
            isOneToOne: false
            referencedRelation: "public_profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "invitation_codes_used_by_fkey"
            columns: ["used_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "invitation_codes_used_by_fkey"
            columns: ["used_by"]
            isOneToOne: false
            referencedRelation: "public_profiles"
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
            foreignKeyName: "match_events_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "public_profiles"
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
      match_reminders_sent: {
        Row: {
          kind: string
          match_id: string
          player_id: string
          sent_at: string
        }
        Insert: {
          kind: string
          match_id: string
          player_id: string
          sent_at?: string
        }
        Update: {
          kind?: string
          match_id?: string
          player_id?: string
          sent_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "match_reminders_sent_match_id_fkey"
            columns: ["match_id"]
            isOneToOne: false
            referencedRelation: "matches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "match_reminders_sent_player_id_fkey"
            columns: ["player_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "match_reminders_sent_player_id_fkey"
            columns: ["player_id"]
            isOneToOne: false
            referencedRelation: "public_profiles"
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
          is_third_place: boolean
          match_config: Json
          match_number: number | null
          next_match_id: string | null
          peak_viewers_count: number
          phase_id: string | null
          player1_id: string | null
          player1_team_name: string | null
          player2_id: string | null
          player2_team_name: string | null
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
          is_third_place?: boolean
          match_config?: Json
          match_number?: number | null
          next_match_id?: string | null
          peak_viewers_count?: number
          phase_id?: string | null
          player1_id?: string | null
          player1_team_name?: string | null
          player2_id?: string | null
          player2_team_name?: string | null
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
          is_third_place?: boolean
          match_config?: Json
          match_number?: number | null
          next_match_id?: string | null
          peak_viewers_count?: number
          phase_id?: string | null
          player1_id?: string | null
          player1_team_name?: string | null
          player2_id?: string | null
          player2_team_name?: string | null
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
            foreignKeyName: "matches_home_player_id_fkey"
            columns: ["home_player_id"]
            isOneToOne: false
            referencedRelation: "public_profiles"
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
            foreignKeyName: "matches_player1_id_fkey"
            columns: ["player1_id"]
            isOneToOne: false
            referencedRelation: "public_profiles"
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
            foreignKeyName: "matches_player2_id_fkey"
            columns: ["player2_id"]
            isOneToOne: false
            referencedRelation: "public_profiles"
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
            foreignKeyName: "matches_streaming_activated_by_admin_id_fkey"
            columns: ["streaming_activated_by_admin_id"]
            isOneToOne: false
            referencedRelation: "public_profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "matches_winner_id_fkey"
            columns: ["winner_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "matches_winner_id_fkey"
            columns: ["winner_id"]
            isOneToOne: false
            referencedRelation: "public_profiles"
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
          image_url: string | null
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
          image_url?: string | null
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
          image_url?: string | null
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
          {
            foreignKeyName: "notifications_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "public_profiles"
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
          payer_method: string | null
          payer_phone: string | null
          provider: string
          provider_method: string | null
          provider_response: Json
          provider_transaction_id: string | null
          refunded_at: string | null
          rejection_reason: string | null
          status: string
          updated_at: string
          user_id: string
          validated_at: string | null
          validated_by_admin_id: string | null
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
          payer_method?: string | null
          payer_phone?: string | null
          provider: string
          provider_method?: string | null
          provider_response?: Json
          provider_transaction_id?: string | null
          refunded_at?: string | null
          rejection_reason?: string | null
          status?: string
          updated_at?: string
          user_id: string
          validated_at?: string | null
          validated_by_admin_id?: string | null
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
          payer_method?: string | null
          payer_phone?: string | null
          provider?: string
          provider_method?: string | null
          provider_response?: Json
          provider_transaction_id?: string | null
          refunded_at?: string | null
          rejection_reason?: string | null
          status?: string
          updated_at?: string
          user_id?: string
          validated_at?: string | null
          validated_by_admin_id?: string | null
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
          {
            foreignKeyName: "payments_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "public_profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "payments_validated_by_admin_id_fkey"
            columns: ["validated_by_admin_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "payments_validated_by_admin_id_fkey"
            columns: ["validated_by_admin_id"]
            isOneToOne: false
            referencedRelation: "public_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      payouts: {
        Row: {
          amount_local: number
          amount_usd: number | null
          auto_checks: Json
          claimed_at: string | null
          competition_id: string
          completed_at: string | null
          created_at: string
          currency: string
          exchange_rate: number | null
          id: string
          payee_method: string | null
          payee_phone: string | null
          payout_destination: Json | null
          payout_method: string | null
          payout_provider: string | null
          prize_id: string | null
          provider_response: Json
          provider_transaction_id: string | null
          rank: number | null
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
          amount_usd?: number | null
          auto_checks?: Json
          claimed_at?: string | null
          competition_id: string
          completed_at?: string | null
          created_at?: string
          currency: string
          exchange_rate?: number | null
          id?: string
          payee_method?: string | null
          payee_phone?: string | null
          payout_destination?: Json | null
          payout_method?: string | null
          payout_provider?: string | null
          prize_id?: string | null
          provider_response?: Json
          provider_transaction_id?: string | null
          rank?: number | null
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
          amount_usd?: number | null
          auto_checks?: Json
          claimed_at?: string | null
          competition_id?: string
          completed_at?: string | null
          created_at?: string
          currency?: string
          exchange_rate?: number | null
          id?: string
          payee_method?: string | null
          payee_phone?: string | null
          payout_destination?: Json | null
          payout_method?: string | null
          payout_provider?: string | null
          prize_id?: string | null
          provider_response?: Json
          provider_transaction_id?: string | null
          rank?: number | null
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
            foreignKeyName: "payouts_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "public_profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "payouts_validated_by_admin_id_fkey"
            columns: ["validated_by_admin_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "payouts_validated_by_admin_id_fkey"
            columns: ["validated_by_admin_id"]
            isOneToOne: false
            referencedRelation: "public_profiles"
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
          anonymized_at: string | null
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
          last_seen_at: string | null
          marketing_consent: boolean
          onboarding_completed: boolean
          onboarding_completed_at: string | null
          permanent_ban: boolean
          preferred_currency: string
          preferred_language: string
          privacy_policy_accepted_at: string | null
          referral_code: string
          referred_by: string | null
          role: Database["public"]["Enums"]["user_role"]
          stats: Json
          timezone: string
          totp_enabled: boolean
          totp_secret: string | null
          updated_at: string
          username: string
          voip_token: string | null
          whatsapp_number: string | null
        }
        Insert: {
          account_deletion_reason?: string | null
          account_deletion_requested_at?: string | null
          anonymized_at?: string | null
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
          last_seen_at?: string | null
          marketing_consent?: boolean
          onboarding_completed?: boolean
          onboarding_completed_at?: string | null
          permanent_ban?: boolean
          preferred_currency?: string
          preferred_language?: string
          privacy_policy_accepted_at?: string | null
          referral_code: string
          referred_by?: string | null
          role?: Database["public"]["Enums"]["user_role"]
          stats?: Json
          timezone?: string
          totp_enabled?: boolean
          totp_secret?: string | null
          updated_at?: string
          username: string
          voip_token?: string | null
          whatsapp_number?: string | null
        }
        Update: {
          account_deletion_reason?: string | null
          account_deletion_requested_at?: string | null
          anonymized_at?: string | null
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
          last_seen_at?: string | null
          marketing_consent?: boolean
          onboarding_completed?: boolean
          onboarding_completed_at?: string | null
          permanent_ban?: boolean
          preferred_currency?: string
          preferred_language?: string
          privacy_policy_accepted_at?: string | null
          referral_code?: string
          referred_by?: string | null
          role?: Database["public"]["Enums"]["user_role"]
          stats?: Json
          timezone?: string
          totp_enabled?: boolean
          totp_secret?: string | null
          updated_at?: string
          username?: string
          voip_token?: string | null
          whatsapp_number?: string | null
        }
        Relationships: []
      }
      promo_banner: {
        Row: {
          created_at: string
          id: string
          image_url: string
          is_active: boolean
          redirect_target: string
          redirect_type: string
          updated_at: string
          updated_by: string | null
        }
        Insert: {
          created_at?: string
          id?: string
          image_url: string
          is_active?: boolean
          redirect_target: string
          redirect_type: string
          updated_at?: string
          updated_by?: string | null
        }
        Update: {
          created_at?: string
          id?: string
          image_url?: string
          is_active?: boolean
          redirect_target?: string
          redirect_type?: string
          updated_at?: string
          updated_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "promo_banner_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "promo_banner_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "public_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      reintegration_requests: {
        Row: {
          created_at: string
          id: string
          message: string
          resolution_reason: string | null
          resolved_at: string | null
          resolved_by: string | null
          status: string
          updated_at: string
          user_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          message: string
          resolution_reason?: string | null
          resolved_at?: string | null
          resolved_by?: string | null
          status?: string
          updated_at?: string
          user_id: string
        }
        Update: {
          created_at?: string
          id?: string
          message?: string
          resolution_reason?: string | null
          resolved_at?: string | null
          resolved_by?: string | null
          status?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "reintegration_requests_resolved_by_fkey"
            columns: ["resolved_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "reintegration_requests_resolved_by_fkey"
            columns: ["resolved_by"]
            isOneToOne: false
            referencedRelation: "public_profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "reintegration_requests_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "reintegration_requests_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "public_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      stream_comments: {
        Row: {
          author_id: string | null
          content: string
          created_at: string
          id: string
          match_id: string
        }
        Insert: {
          author_id?: string | null
          content: string
          created_at?: string
          id?: string
          match_id: string
        }
        Update: {
          author_id?: string | null
          content?: string
          created_at?: string
          id?: string
          match_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "stream_comments_author_id_fkey"
            columns: ["author_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "stream_comments_author_id_fkey"
            columns: ["author_id"]
            isOneToOne: false
            referencedRelation: "public_profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "stream_comments_match_id_fkey"
            columns: ["match_id"]
            isOneToOne: false
            referencedRelation: "matches"
            referencedColumns: ["id"]
          },
        ]
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
          {
            foreignKeyName: "streams_player_id_fkey"
            columns: ["player_id"]
            isOneToOne: false
            referencedRelation: "public_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      totp_attempts: {
        Row: {
          failed_count: number
          locked_until: string | null
          updated_at: string
          user_id: string
        }
        Insert: {
          failed_count?: number
          locked_until?: string | null
          updated_at?: string
          user_id: string
        }
        Update: {
          failed_count?: number
          locked_until?: string | null
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "totp_attempts_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "totp_attempts_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "public_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      tutorial_video: {
        Row: {
          created_at: string
          display_days: number
          id: string
          is_active: boolean
          target_page: string
          title: string
          updated_at: string
          updated_by: string | null
          video_url: string
        }
        Insert: {
          created_at?: string
          display_days?: number
          id?: string
          is_active?: boolean
          target_page?: string
          title: string
          updated_at?: string
          updated_by?: string | null
          video_url: string
        }
        Update: {
          created_at?: string
          display_days?: number
          id?: string
          is_active?: boolean
          target_page?: string
          title?: string
          updated_at?: string
          updated_by?: string | null
          video_url?: string
        }
        Relationships: [
          {
            foreignKeyName: "tutorial_video_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "tutorial_video_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "public_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      tutorial_video_views: {
        Row: {
          first_seen_at: string
          tutorial_video_id: string
          user_id: string
        }
        Insert: {
          first_seen_at?: string
          tutorial_video_id: string
          user_id: string
        }
        Update: {
          first_seen_at?: string
          tutorial_video_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "tutorial_video_views_tutorial_video_id_fkey"
            columns: ["tutorial_video_id"]
            isOneToOne: false
            referencedRelation: "tutorial_video"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "tutorial_video_views_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "tutorial_video_views_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "public_profiles"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      public_profiles: {
        Row: {
          avatar_color: string | null
          country_code: string | null
          created_at: string | null
          id: string | null
          is_active: boolean | null
          last_seen_at: string | null
          permanent_ban: boolean | null
          role: Database["public"]["Enums"]["user_role"] | null
          stats: Json | null
          totp_enabled: boolean | null
          updated_at: string | null
          username: string | null
        }
        Insert: {
          avatar_color?: string | null
          country_code?: string | null
          created_at?: string | null
          id?: string | null
          is_active?: boolean | null
          last_seen_at?: string | null
          permanent_ban?: boolean | null
          role?: Database["public"]["Enums"]["user_role"] | null
          stats?: Json | null
          totp_enabled?: boolean | null
          updated_at?: string | null
          username?: string | null
        }
        Update: {
          avatar_color?: string | null
          country_code?: string | null
          created_at?: string | null
          id?: string | null
          is_active?: boolean | null
          last_seen_at?: string | null
          permanent_ban?: boolean | null
          role?: Database["public"]["Enums"]["user_role"] | null
          stats?: Json | null
          totp_enabled?: boolean | null
          updated_at?: string | null
          username?: string | null
        }
        Relationships: []
      }
    }
    Functions: {
      _dispatch_match_reminders: { Args: never; Returns: undefined }
      _require_super_admin: { Args: never; Returns: undefined }
      _webhook_secret: { Args: never; Returns: string }
      accept_friend_request: {
        Args: { p_friendship_id: string }
        Returns: undefined
      }
      admin_filter_users: {
        Args: {
          p_competition_ids?: string[]
          p_country_code?: string
          p_disputed?: boolean
          p_guilty_min?: number
          p_limit?: number
          p_paid?: boolean
          p_rewarded?: boolean
          p_search?: string
          p_status?: string
          p_won?: boolean
        }
        Returns: {
          account_deletion_reason: string | null
          account_deletion_requested_at: string | null
          anonymized_at: string | null
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
          last_seen_at: string | null
          marketing_consent: boolean
          onboarding_completed: boolean
          onboarding_completed_at: string | null
          permanent_ban: boolean
          preferred_currency: string
          preferred_language: string
          privacy_policy_accepted_at: string | null
          referral_code: string
          referred_by: string | null
          role: Database["public"]["Enums"]["user_role"]
          stats: Json
          timezone: string
          totp_enabled: boolean
          totp_secret: string | null
          updated_at: string
          username: string
          voip_token: string | null
          whatsapp_number: string | null
        }[]
        SetofOptions: {
          from: "*"
          to: "profiles"
          isOneToOne: false
          isSetofReturn: true
        }
      }
      admin_recompute_final_ranks: {
        Args: { p_competition_id: string }
        Returns: undefined
      }
      admin_run_cleanup_deleted_accounts: { Args: never; Returns: undefined }
      admin_run_cleanup_streams: { Args: never; Returns: undefined }
      anonymize_deleted_account: {
        Args: { p_user_id: string }
        Returns: undefined
      }
      auto_cancel_underfilled_competitions: { Args: never; Returns: number }
      block_user: { Args: { p_target: string }; Returns: undefined }
      can_register_via_referral: {
        Args: { p_competition_id: string; p_user_id: string }
        Returns: Json
      }
      cancel_competition: {
        Args: { p_competition_id: string }
        Returns: number
      }
      claim_payout: {
        Args: { p_method: string; p_payout_id: string; p_phone: string }
        Returns: undefined
      }
      competitions_pending_payout: {
        Args: never
        Returns: {
          completed_at: string
          currency: string
          id: string
          name: string
          prize_pool_local: number
        }[]
      }
      compute_competition_final_ranks: {
        Args: { p_competition_id: string }
        Returns: undefined
      }
      count_user_referrals:
        | { Args: { p_user_id: string }; Returns: number }
        | { Args: { p_mode?: string; p_user_id: string }; Returns: number }
      decline_friend_request: {
        Args: { p_friendship_id: string }
        Returns: undefined
      }
      delete_competition_cascade: {
        Args: { p_competition_id: string }
        Returns: undefined
      }
      ensure_friend_channel: {
        Args: { p_friendship_id: string }
        Returns: string
      }
      finalize_competition_if_complete: {
        Args: { p_competition_id: string }
        Returns: undefined
      }
      finalize_match_score: { Args: { p_match_id: string }; Returns: undefined }
      forfeit_match: {
        Args: { p_match_id: string; p_reason?: string }
        Returns: undefined
      }
      friend_pending_count: { Args: never; Returns: number }
      gen_referral_code: { Args: never; Returns: string }
      generate_groups_then_knockout_bracket: {
        Args: { p_competition_id: string }
        Returns: undefined
      }
      generate_payouts: { Args: { p_competition_id: string }; Returns: number }
      generate_round_robin_bracket: {
        Args: { p_competition_id: string }
        Returns: undefined
      }
      generate_single_elim_bracket: {
        Args: { p_competition_id: string }
        Returns: undefined
      }
      get_country_breakdown: {
        Args: never
        Returns: {
          country_code: string
          ratio: number
          user_count: number
        }[]
      }
      get_monthly_revenue: {
        Args: { p_months?: number }
        Returns: {
          margin_xaf: number
          month_start: string
          revenue_xaf: number
        }[]
      }
      get_monthly_signups: {
        Args: { p_months?: number }
        Returns: {
          count: number
          month_start: string
        }[]
      }
      get_revenue_breakdown: {
        Args: { p_end: string; p_start: string }
        Returns: Json
      }
      get_revenue_per_competition: {
        Args: { p_limit?: number }
        Returns: {
          commission_xaf: number
          competition_id: string
          game: string
          name: string
          registered_count: number
          revenue_xaf: number
        }[]
      }
      get_super_admin_kpis: { Args: never; Returns: Json }
      get_top_players_by_wins: {
        Args: { p_limit?: number }
        Returns: {
          avatar_color: string
          country_code: string
          id: string
          total_earnings_xaf: number
          username: string
          wins: number
        }[]
      }
      heartbeat: { Args: never; Returns: undefined }
      is_admin: { Args: never; Returns: boolean }
      is_blocked_pair: {
        Args: { p_user_a: string; p_user_b: string }
        Returns: boolean
      }
      is_super_admin: { Args: never; Returns: boolean }
      list_filterable_competitions: {
        Args: { p_limit?: number }
        Returns: {
          current_players: number
          game: string
          id: string
          max_players: number
          name: string
          start_date: string
          status: string
        }[]
      }
      mark_payment_refunded: {
        Args: { p_payment_id: string }
        Returns: undefined
      }
      mark_payout_paid: { Args: { p_payout_id: string }; Returns: undefined }
      next_power_of_two: { Args: { n: number }; Returns: number }
      recalculate_all_player_stats: { Args: never; Returns: number }
      recalculate_group_standings: {
        Args: { p_group_id: string }
        Returns: undefined
      }
      recalculate_player_stats: { Args: { p_player_id: string }; Returns: Json }
      regenerate_competition: {
        Args: { p_competition_id: string }
        Returns: {
          android_store_url: string | null
          auto_generate_bracket: boolean
          banner_url: string | null
          commission_pct: number
          commission_xaf: number
          created_at: string
          created_by: string | null
          current_players: number
          description: string | null
          end_date: string | null
          format: Database["public"]["Enums"]["tournament_format"]
          format_config: Json
          game: string
          id: string
          ios_store_url: string | null
          is_pinned: boolean
          match_interval_minutes: number
          max_players: number
          mtn_momo_code: string | null
          name: string
          orange_money_code: string | null
          pinned_at: string | null
          prize_distribution: Json
          prize_pool_currency: string | null
          prize_pool_local: number
          referral_activity_mode: string
          referral_quota: number
          registration_closes_at: string | null
          registration_currency: string
          registration_fee: number
          registration_opens_at: string | null
          round_intervals: Json | null
          sponsor_bonus_local: number
          start_date: string
          status: Database["public"]["Enums"]["competition_status"]
          third_place_match: boolean
          updated_at: string
        }[]
        SetofOptions: {
          from: "*"
          to: "competitions"
          isOneToOne: false
          isSetofReturn: true
        }
      }
      register_admin_check_lock: { Args: { p_ip: string }; Returns: Json }
      register_admin_record_failure: { Args: { p_ip: string }; Returns: Json }
      register_admin_record_success: {
        Args: { p_ip: string }
        Returns: undefined
      }
      remove_friend: { Args: { p_target: string }; Returns: undefined }
      resolve_dispute: {
        Args: {
          p_cancel?: boolean
          p_dispute_id: string
          p_justification: string
          p_match_id: string
          p_score1?: number
          p_score2?: number
          p_winner_id?: string
        }
        Returns: undefined
      }
      send_friend_request: { Args: { p_target: string }; Returns: string }
      totp_check_lock: { Args: { p_user_id: string }; Returns: Json }
      totp_record_failure: { Args: { p_user_id: string }; Returns: Json }
      totp_record_success: { Args: { p_user_id: string }; Returns: undefined }
      try_schedule_next_round: {
        Args: { p_match_id: string }
        Returns: undefined
      }
      tutorial_record_and_get_view: {
        Args: { p_tutorial_id: string }
        Returns: string
      }
      unblock_user: { Args: { p_target: string }; Returns: undefined }
    }
    Enums: {
      call_status:
        | "ringing"
        | "accepted"
        | "declined"
        | "cancelled"
        | "missed"
        | "ended"
      competition_status:
        | "draft"
        | "registration_open"
        | "registration_closed"
        | "ongoing"
        | "completed"
        | "cancelled"
      friendship_status: "pending" | "accepted" | "blocked"
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
      call_status: [
        "ringing",
        "accepted",
        "declined",
        "cancelled",
        "missed",
        "ended",
      ],
      competition_status: [
        "draft",
        "registration_open",
        "registration_closed",
        "ongoing",
        "completed",
        "cancelled",
      ],
      friendship_status: ["pending", "accepted", "blocked"],
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
