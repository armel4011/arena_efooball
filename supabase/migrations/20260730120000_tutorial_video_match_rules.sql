-- Nouveau contexte de vidéo tutoriel : `match_rules` — dialogue de réglages
-- (prolongations / tirs au but) affiché au « Continuer » après le nom d'équipe.
-- Football uniquement, une vidéo de guide par jeu (comme match_role_intro /
-- match_locked). role_side null, country_code null.

alter table public.tutorial_video drop constraint tutorial_video_target_page_chk;
alter table public.tutorial_video add constraint tutorial_video_target_page_chk
  check (target_page = any (array[
    'home', 'competitions', 'profile', 'messages', 'all',
    'match_locked', 'match_role_intro', 'payment_tutorial', 'install_check',
    'match_rules'
  ]));

alter table public.tutorial_video
  drop constraint tutorial_video_context_coherence_chk;
alter table public.tutorial_video
  add constraint tutorial_video_context_coherence_chk check (
    case target_page
      when 'match_locked' then ((game is not null) and (country_code is null))
      when 'match_role_intro' then (
        coalesce(
          game = any (array['efootball', 'ea_sports_fc', 'dream_league']),
          false) and (country_code is null))
      when 'match_rules' then (
        coalesce(
          game = any (array['efootball', 'ea_sports_fc', 'dream_league']),
          false) and (country_code is null))
      when 'install_check' then (
        coalesce(
          game = any (array['efootball', 'ea_sports_fc', 'dream_league']),
          false) and (country_code is null))
      when 'payment_tutorial' then (
        (country_code is not null) and (game is null))
      else ((game is null) and (country_code is null))
    end
  );
