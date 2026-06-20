import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.108.2";
import type { Database } from "./database.types.ts";

export type { Database };

/// Type du client service-role tel que retourné par `createClient(url, key)`
/// (appelé sans générique). À utiliser pour typer les helpers EF qui reçoivent
/// ce client : `ReturnType<typeof createClient>` résout vers la mauvaise
/// surcharge sous supabase-js 2.45 (`<unknown, never, GenericSchema>`) et ne
/// matche pas le retour réel de l'appel (`<any, "public", any>`).
// deno-lint-ignore no-explicit-any
export type ServiceClient = SupabaseClient<any, "public", any>;

export type Tables<T extends keyof Database["public"]["Tables"]> =
  Database["public"]["Tables"][T]["Row"];

export type TablesInsert<T extends keyof Database["public"]["Tables"]> =
  Database["public"]["Tables"][T]["Insert"];

export type TablesUpdate<T extends keyof Database["public"]["Tables"]> =
  Database["public"]["Tables"][T]["Update"];

export type Enums<T extends keyof Database["public"]["Enums"]> =
  Database["public"]["Enums"][T];

// ──────────────────────────────────────────────────────────────────────────────
// Aliases — Tables (Row)
// ──────────────────────────────────────────────────────────────────────────────
export type Profile = Tables<"profiles">;
export type Competition = Tables<"competitions">;
export type Phase = Tables<"phases">;
export type Group = Tables<"groups">;
export type GroupMembership = Tables<"group_memberships">;
export type Prize = Tables<"prizes">;
export type Match = Tables<"matches">;
export type BracketNode = Tables<"bracket_nodes">;
export type MatchEvent = Tables<"match_events">;
export type AntiCheatEvent = Tables<"anti_cheat_events">;
export type ChatChannel = Tables<"chat_channels">;
export type ChatMessage = Tables<"chat_messages">;
export type Payment = Tables<"payments">;
export type Payout = Tables<"payouts">;
export type PlatformRevenue = Tables<"platform_revenue">;
export type PaymentWebhookLog = Tables<"payment_webhook_log">;
export type Dispute = Tables<"disputes">;
export type Notification = Tables<"notifications">;
export type CompetitionRegistration = Tables<"competition_registrations">;
export type Stream = Tables<"streams">;
export type AppConfig = Tables<"app_config">;
export type ExchangeRate = Tables<"exchange_rates">;
export type InvitationCode = Tables<"invitation_codes">;
export type BannedWord = Tables<"banned_words">;
export type AdminAuditLog = Tables<"admin_audit_log">;
export type AutoActionsLog = Tables<"auto_actions_log">;

// ──────────────────────────────────────────────────────────────────────────────
// Aliases — Insert payloads (champs default rendus optionnels)
// ──────────────────────────────────────────────────────────────────────────────
export type ProfileInsert = TablesInsert<"profiles">;
export type CompetitionInsert = TablesInsert<"competitions">;
export type MatchInsert = TablesInsert<"matches">;
export type PaymentInsert = TablesInsert<"payments">;
export type PayoutInsert = TablesInsert<"payouts">;
export type DisputeInsert = TablesInsert<"disputes">;
export type NotificationInsert = TablesInsert<"notifications">;
export type CompetitionRegistrationInsert = TablesInsert<"competition_registrations">;
export type StreamInsert = TablesInsert<"streams">;
export type ChatMessageInsert = TablesInsert<"chat_messages">;
export type MatchEventInsert = TablesInsert<"match_events">;
export type AntiCheatEventInsert = TablesInsert<"anti_cheat_events">;
export type AdminAuditLogInsert = TablesInsert<"admin_audit_log">;
export type AutoActionsLogInsert = TablesInsert<"auto_actions_log">;
export type PaymentWebhookLogInsert = TablesInsert<"payment_webhook_log">;
export type PlatformRevenueInsert = TablesInsert<"platform_revenue">;

// ──────────────────────────────────────────────────────────────────────────────
// Aliases — Enums
// ──────────────────────────────────────────────────────────────────────────────
export type UserRole = Enums<"user_role">;
export type CompetitionStatus = Enums<"competition_status">;
export type MatchStatus = Enums<"match_status">;
export type PhaseType = Enums<"phase_type">;
export type TournamentFormat = Enums<"tournament_format">;
