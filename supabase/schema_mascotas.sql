-- ============================================================
-- Huellitas - Esquema COMPLETO para un proyecto Supabase NUEVO
-- Uso: Supabase -> SQL Editor -> New query -> pegar todo -> Run
-- ============================================================

-- 1) Usuarios (extiende a auth.users de Supabase Auth)
create table public.usuarios (
  id        uuid primary key references auth.users(id) on delete cascade,
  nombre    text not null,
  correo    text,
  telefono  text
);

-- Al registrarse alguien, se crea su fila en "usuarios"
create function public.crear_usuario() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.usuarios (id, nombre, correo, telefono)
  values (new.id,
          coalesce(new.raw_user_meta_data->>'nombre', 'Sin nombre'),
          new.email,
          new.raw_user_meta_data->>'telefono');
  return new;
end; $$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.crear_usuario();

-- 2) Reportes y avistamientos
create table public.reportes (
  id             uuid primary key,
  usuario_id     uuid not null references public.usuarios(id),
  nombre_mascota text not null,
  especie        text not null check (especie in ('perro','gato','otro')),
  descripcion    text not null,
  contacto       text not null,
  latitud        double precision not null,
  longitud       double precision not null,
  foto_url       text,
  estado         text not null default 'perdida'
                 check (estado in ('perdida','encontrada')),
  fecha          timestamptz not null default now()
);

create table public.avistamientos (
  id          uuid primary key default gen_random_uuid(),
  reporte_id  uuid not null references public.reportes(id) on delete cascade,
  usuario_id  uuid not null references public.usuarios(id),
  comentario  text,
  latitud     double precision not null,
  longitud    double precision not null,
  foto_url    text,
  fecha       timestamptz not null default now()
);

-- 3) Seguridad (RLS)
alter table public.usuarios      enable row level security;
alter table public.reportes      enable row level security;
alter table public.avistamientos enable row level security;

create policy usuarios_ver on public.usuarios
  for select to authenticated using (true);

create policy reportes_ver on public.reportes
  for select to authenticated using (true);
create policy reportes_crear on public.reportes
  for insert to authenticated with check (usuario_id = auth.uid());
create policy reportes_actualizar on public.reportes
  for update to authenticated using (usuario_id = auth.uid());

create policy avistamientos_ver on public.avistamientos
  for select to authenticated using (true);
create policy avistamientos_crear on public.avistamientos
  for insert to authenticated with check (usuario_id = auth.uid());

-- 4) Tiempo real
alter publication supabase_realtime add table public.reportes;
alter publication supabase_realtime add table public.avistamientos;

-- 5) Storage: bucket "fotos" (público para poder mostrar las imágenes)
insert into storage.buckets (id, name, public) values ('fotos', 'fotos', true)
on conflict (id) do nothing;

create policy fotos_subir on storage.objects
  for insert to authenticated with check (bucket_id = 'fotos');
create policy fotos_actualizar on storage.objects
  for update to authenticated using (bucket_id = 'fotos');
create policy fotos_ver on storage.objects
  for select using (bucket_id = 'fotos');
