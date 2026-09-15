-- ─────────────────────────────────────────────────────────────────────
-- Notifications push (FCM via Supabase Edge Function "push")
-- À exécuter dans : Supabase Dashboard → SQL Editor
-- ─────────────────────────────────────────────────────────────────────

-- Token FCM par appareil / utilisateur
create table public.push_subscriptions (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.users(id) on delete cascade,
    fcm_token text not null,
    platform text not null default 'android' check (platform in ('android','ios','web')),
    created_at timestamptz not null default now(),
    unique (user_id, fcm_token)
);

alter table public.push_subscriptions enable row level security;
create policy "Users manage their own push tokens"
    on public.push_subscriptions for all
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);

-- Notifications "in-app" (badge de la cloche).
-- Seule la Edge Function (service role) peut insérer / supprimer.
create table public.notifications (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.users(id) on delete cascade,
    title text not null,
    body text not null default '',
    type text not null default 'post' check (type in ('post','comment','message','event')),
    ref_id uuid,
    read_at timestamptz,
    created_at timestamptz not null default now()
);

create index notifications_user_created_idx
    on public.notifications (user_id, created_at desc);

alter table public.notifications enable row level security;
create policy "Users read their own notifications"
    on public.notifications for select
    using (auth.uid() = user_id);
create policy "Users mark their own notifications as read"
    on public.notifications for update
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);
