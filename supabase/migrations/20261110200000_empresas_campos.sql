-- =====================================================================
-- RUMBO: tabla de empresas con los campos del formulario de registro.
--
-- `public.empresas` se creó en la migración 20261108210000 con solo
-- `nombre`, `correo` y `creada_en`. Aquí se le añaden:
--   tipo_empresa, telefono, sector, tamano, sitio_web, descripcion,
--   direccion, ciudad, pais, logo_url.
-- Además se crea la fila de empresa al registrarse y se vincula al perfil.
-- =====================================================================

-- 1. Campos nuevos de la empresa -------------------------------------------
alter table public.empresas
  add column if not exists tipo_empresa text,
  add column if not exists telefono text,
  add column if not exists sector text,
  add column if not exists tamano text,
  add column if not exists sitio_web text,
  add column if not exists descripcion text,
  add column if not exists direccion text,
  add column if not exists ciudad text,
  add column if not exists pais text,
  add column if not exists logo_url text,
  add column if not exists perfil_id uuid references public.perfiles(id)
    on delete set null;

-- 2. La empresa se crea sola al registrarse como empresa -------------------
create or replace function public.crear_empresa_nuevo_perfil()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_tipo text;
  v_telefono text;
  v_nombre text;
begin
  -- Solo actúa si el perfil recién creado es de empresa.
  if coalesce(new.tipo_cuenta, 'estudiante') <> 'empresa' then
    return new;
  end if;

  v_tipo := new.tipo_empresa;
  v_telefono := new.telefono;
  v_nombre := new.nombre;

  -- Si ya existe una empresa con ese correo, solo se vincula.
  update public.empresas
  set
    nombre = coalesce(nombre, v_nombre),
    tipo_empresa = coalesce(tipo_empresa, v_tipo),
    telefono = coalesce(telefono, v_telefono),
    perfil_id = new.id
  where correo = new.correo;

  if not found then
    insert into public.empresas
      (nombre, correo, tipo_empresa, telefono, perfil_id)
    values
      (coalesce(v_nombre, 'Empresa'), new.correo, v_tipo, v_telefono, new.id);
  end if;

  return new;
end;
$$;

drop trigger if exists crear_empresa_despues_de_perfil on public.perfiles;
create trigger crear_empresa_despues_de_perfil
  after insert on public.perfiles
  for each row execute function public.crear_empresa_nuevo_perfil();

-- 3. La empresa puede editar sus propios datos -----------------------------
-- RLS: el dueño del perfil empresa gestiona su fila de empresa.
drop policy if exists "empresas_dueno" on public.empresas;
create policy "empresas_dueno" on public.empresas
  for all to authenticated
  using (
    exists (
      select 1 from public.perfiles p
      where p.id = (select auth.uid())
        and p.rol = 'empresa'
        and p.id = public.empresas.perfil_id
    )
  )
  with check (
    exists (
      select 1 from public.perfiles p
      where p.id = (select auth.uid())
        and p.rol = 'empresa'
        and p.id = public.empresas.perfil_id
    )
  );

-- 4. Función para actualizar la empresa (desde la app) ---------------------
create or replace function public.actualizar_empresa(
  p_nombre text default null,
  p_tipo_empresa text default null,
  p_telefono text default null,
  p_sector text default null,
  p_tamano text default null,
  p_sitio_web text default null,
  p_descripcion text default null,
  p_direccion text default null,
  p_ciudad text default null,
  p_pais text default null,
  p_logo_url text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    return jsonb_build_object('success', false, 'error', 'unauthorized');
  end if;

  update public.empresas
  set
    nombre = coalesce(p_nombre, nombre),
    tipo_empresa = coalesce(p_tipo_empresa, tipo_empresa),
    telefono = coalesce(p_telefono, telefono),
    sector = coalesce(p_sector, sector),
    tamano = coalesce(p_tamano, tamano),
    sitio_web = coalesce(p_sitio_web, sitio_web),
    descripcion = coalesce(p_descripcion, descripcion),
    direccion = coalesce(p_direccion, direccion),
    ciudad = coalesce(p_ciudad, ciudad),
    pais = coalesce(p_pais, pais),
    logo_url = coalesce(p_logo_url, logo_url)
  where perfil_id = v_user_id;

  if not found then
    return jsonb_build_object('success', false, 'error', 'not_found');
  end if;

  return jsonb_build_object('success', true, 'message', 'Empresa actualizada.');
end;
$$;

grant execute on function public.actualizar_empresa(
  text, text, text, text, text, text, text, text, text, text, text
) to authenticated;
