-- Les trigger functions ne devraient pas être exposées via RPC.
revoke all on function public.enforce_three_strikes_ban()    from public, anon, authenticated;
revoke all on function public.apply_reintegration_decision() from public, anon, authenticated;
