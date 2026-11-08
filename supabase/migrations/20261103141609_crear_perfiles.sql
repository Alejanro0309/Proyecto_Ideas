-- 1. Tabla de perfiles
create table public.perfiles (
  id uuid primary key references auth.users(id) on delete cascade,
  correo text not null unique,
  nombre text,
  apellido text,
  carnet_codigo text unique,
  verificado boolean not null default false,
  creado_en timestamptz not null default now()
);

-- 2. Seguridad por filas (RLS)
alter table public.perfiles enable row level security;

create policy "Ver mi propio perfil"
  on public.perfiles for select to authenticated
  using ((select auth.uid()) = id);

create policy "Editar mi propio perfil"
  on public.perfiles for update to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

-- El usuario solo puede cambiar nombre y apellido.
-- "verificado" y "carnet_codigo" los cambiará solo el servidor.
revoke update on public.perfiles from authenticated;
grant update (nombre, apellido) on public.perfiles to authenticated;

-- 3. Bloquear registros que no sean del dominio de la Unimet
create or replace function public.validar_dominio_unimet()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if lower(coalesce(new.email, '')) not like '%@correo.unimet.edu.ve' then
    raise exception 'Solo se permiten correos @correo.unimet.edu.ve';
  end if;
  return new;
end;
$$;

create trigger validar_dominio_antes_de_registro
  before insert on auth.users
  for each row execute function public.validar_dominio_unimet();

-- 4. Crear el perfil automáticamente al registrarse
create or replace function public.crear_perfil_nuevo_usuario()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.perfiles (id, correo)
  values (new.id, new.email);
  return new;
end;
$$;

create trigger crear_perfil_despues_de_registro
  after insert on auth.users
  for each row execute function public.crear_perfil_nuevo_usuario();