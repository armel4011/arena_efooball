-- The trigger function used the competition_status literal 'ongoing' to
-- detect a match starting, but match_status uses 'in_progress'. Every
-- UPDATE on public.matches was failing with "invalid input value for
-- enum match_status: 'ongoing'". Replace 'ongoing' with 'in_progress'.
create or replace function public.auto_publish_final_match()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  is_final boolean;
  channel_name text;
begin
  if new.status is distinct from 'in_progress' then
    return new;
  end if;
  if old.status is not distinct from new.status then
    return new;
  end if;

  select coalesce(bool_or(bn.is_grand_final), false)
    into is_final
    from public.bracket_nodes bn
   where bn.match_id = new.id;

  if not is_final then
    return new;
  end if;

  channel_name := 'match_' || new.id::text;

  update public.matches m
     set is_streamed                    = true,
         streaming_activation_type      = 'auto_final',
         streaming_activated_at         = coalesce(m.streaming_activated_at, now()),
         agora_stream_channel           = coalesce(m.agora_stream_channel, channel_name),
         stream_status                  = case
                                            when m.stream_status = 'none' then 'pending'
                                            else m.stream_status
                                          end
   where m.id = new.id
     and m.is_streamed = false;

  if new.home_player_id is not null then
    update public.streams s
       set is_public = true
     where s.match_id = new.id
       and s.player_id = new.home_player_id
       and s.is_active = true;
  end if;

  return new;
end;
$function$;
